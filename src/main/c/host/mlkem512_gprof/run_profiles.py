#!/usr/bin/env python3
"""Build and run reproducible GNU gprof campaigns for ML-KEM-512."""

from __future__ import annotations

import argparse
import ctypes
import datetime as dt
import glob
import hashlib
import json
import os
import platform
import re
import shlex
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Sequence

from analyze_gprof import (
    elf_has_symbol,
    generate_report,
    inspect_riscv_symbol,
    inspect_symbol,
    sha256_file,
)


HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[4]
MLKEM_ROOT = REPO_ROOT / "external" / "mlkem-native"
BUILD_ROOT = HERE / "build"
LATEST_RESULT = BUILD_ROOT / "latest_result.txt"
DEFAULT_RESULTS_ROOT = REPO_ROOT / "understanding" / "benchmarks" / "gprof"
OPERATIONS = ("keypair", "encaps", "decaps", "all")
VARIANTS = {
    "c-os": {
        "opt": "0",
        "cflags": "-Os -g -pg -fno-omit-frame-pointer",
        "purpose": "primary portable-C profile matching the Vexii size optimization",
    },
    "c-o2": {
        "opt": "0",
        "cflags": "-O2 -g -pg -fno-omit-frame-pointer",
        "purpose": "optimizer sensitivity control",
    },
    "c-noinline": {
        "opt": "0",
        "cflags": (
            "-O2 -g -pg -fno-omit-frame-pointer -fno-inline "
            "-fno-inline-functions -fno-inline-small-functions"
        ),
        "purpose": "structural call graph and call-count control only",
    },
    "native-o2": {
        "opt": "1",
        "cflags": "-O2 -g -pg -fno-omit-frame-pointer",
        "purpose": "host-native backend bias control only",
    },
}


class CommandError(RuntimeError):
    pass


def run(
    command: Sequence[str],
    *,
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    capture: bool = False,
) -> subprocess.CompletedProcess[str]:
    print("+", shlex.join(str(item) for item in command), flush=True)
    completed = subprocess.run(
        [str(item) for item in command],
        cwd=cwd,
        env=env,
        text=True,
        capture_output=capture,
        check=False,
    )
    if completed.returncode != 0:
        details = (completed.stdout or "") + (completed.stderr or "")
        raise CommandError(
            f"command failed with exit code {completed.returncode}: "
            f"{shlex.join(str(item) for item in command)}\n{details}"
        )
    return completed


def command_output(command: Sequence[str], cwd: Path | None = None) -> str:
    return run(command, cwd=cwd, capture=True).stdout.strip()


def required_tool(name: str) -> str:
    path = shutil.which(name)
    if not path:
        raise CommandError(f"required tool not found: {name}")
    return path


def parse_variants(text: str) -> list[str]:
    variants = [item.strip() for item in text.split(",") if item.strip()]
    unknown = sorted(set(variants) - set(VARIANTS))
    if unknown:
        raise CommandError(f"unknown variants: {', '.join(unknown)}")
    if not variants:
        raise CommandError("at least one variant is required")
    return variants


def git_output(*args: str, cwd: Path = REPO_ROOT) -> str:
    return command_output(["git", *args], cwd=cwd)


def patch_state() -> str:
    patch = REPO_ROOT / "external" / "mlkem-native.patch"
    reverse = subprocess.run(
        ["git", "apply", "--reverse", "--check", str(patch)],
        cwd=MLKEM_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if reverse.returncode == 0:
        return "applied"
    forward = subprocess.run(
        ["git", "apply", "--check", str(patch)],
        cwd=MLKEM_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    return "not-applied" if forward.returncode == 0 else "unknown-or-conflicting"


def check_environment() -> dict:
    tools = {name: required_tool(name) for name in ("gcc", "gprof", "gdb", "make", "git")}
    try:
        getattr(ctypes.CDLL(None), "moncontrol")
    except AttributeError as exc:
        raise CommandError("host libc does not export moncontrol(); GNU gprof runtime is required") from exc
    if not (MLKEM_ROOT / "Makefile").exists():
        raise CommandError("external/mlkem-native is not initialized")
    if platform.system() != "Linux":
        raise CommandError("the current harness requires a Linux host with GNU gprof")

    versions = {}
    for name in ("gcc", "gprof", "gdb"):
        versions[name] = command_output([tools[name], "--version"]).splitlines()[0]
    information = {
        "tools": tools,
        "versions": versions,
        "platform": platform.platform(),
        "machine": platform.machine(),
        "processor": platform.processor(),
        "cpu_count": os.cpu_count(),
        "allowed_cpus": sorted(os.sched_getaffinity(0)) if hasattr(os, "sched_getaffinity") else [],
        "repo_commit": git_output("rev-parse", "HEAD"),
        "repo_status": git_output("status", "--short"),
        "submodule_commit": git_output("rev-parse", "HEAD", cwd=MLKEM_ROOT),
        "submodule_status": git_output("status", "--short", cwd=MLKEM_ROOT),
        "patch_state": patch_state(),
    }
    print(json.dumps(information, indent=2, ensure_ascii=False))
    return information


def variant_build_dir(variant: str) -> Path:
    return BUILD_ROOT / variant


def variant_elf(variant: str) -> Path:
    return variant_build_dir(variant) / "mlkem512_gprof"


def build_variant(variant: str) -> dict:
    config = VARIANTS[variant]
    build_dir = variant_build_dir(variant)
    upstream_dir = build_dir / "upstream"
    library = upstream_dir / "libmlkem512.a"
    elf = variant_elf(variant)
    build_dir.mkdir(parents=True, exist_ok=True)

    env = os.environ.copy()
    env["CFLAGS"] = config["cflags"]
    env["LDFLAGS"] = "-pg"
    make_command = [
        "make",
        "-B",
        "-C",
        str(MLKEM_ROOT),
        f"BUILD_DIR={upstream_dir}",
        f"OPT={config['opt']}",
        "AUTO=1",
        "CYCLES=NO",
        str(library),
    ]
    run(make_command, cwd=REPO_ROOT, env=env)

    compile_command = [
        "gcc",
        *shlex.split(config["cflags"]),
        "-std=c99",
        "-DMLK_CONFIG_PARAMETER_SET=512",
        "-I",
        str(MLKEM_ROOT / "mlkem"),
        "-I",
        str(MLKEM_ROOT / "test" / "notrandombytes"),
        str(HERE / "main.c"),
        str(MLKEM_ROOT / "test" / "notrandombytes" / "notrandombytes.c"),
        str(library),
        "-pg",
        "-o",
        str(elf),
    ]
    run(compile_command, cwd=REPO_ROOT)
    undefined = command_output(["nm", "-u", str(elf)])
    if "_mcount" in undefined:
        raise CommandError(f"{variant}: unresolved _mcount in final ELF")
    return {
        "elf": str(elf),
        "elf_sha256": sha256_file(elf),
        "library": str(library),
        "library_sha256": sha256_file(library),
        "opt": config["opt"],
        "cflags": config["cflags"],
        "ldflags": "-pg",
        "purpose": config["purpose"],
    }


def build_variants(variants: Sequence[str]) -> dict[str, dict]:
    check_environment()
    builds = {}
    for variant in variants:
        builds[variant] = build_variant(variant)
    return builds


def cpu_prefix() -> list[str]:
    if not shutil.which("taskset") or not hasattr(os, "sched_getaffinity"):
        return []
    allowed = sorted(os.sched_getaffinity(0))
    return ["taskset", "-c", str(allowed[0])] if allowed else []


def execute_profile(
    elf: Path,
    operation: str,
    iterations: int,
    warmup: int,
    prefix: Path,
) -> tuple[str, Path]:
    prefix.parent.mkdir(parents=True, exist_ok=True)
    before = set(glob.glob(str(prefix) + ".*"))
    env = os.environ.copy()
    env["GMON_OUT_PREFIX"] = str(prefix)
    command = [
        *cpu_prefix(),
        str(elf),
        "--operation",
        operation,
        "--iterations",
        str(iterations),
        "--warmup",
        str(warmup),
    ]
    completed = run(command, env=env, capture=True)
    print(completed.stdout, end="")
    after = set(glob.glob(str(prefix) + ".*"))
    created = sorted(after - before)
    if len(created) != 1:
        raise CommandError(f"expected one gmon file for {prefix}, found {len(created)}")
    gmon = Path(created[0])
    if gmon.stat().st_size == 0:
        raise CommandError(f"empty gmon file: {gmon}")
    return completed.stdout, gmon


PROFILE_RE = re.compile(
    r"PROFILE operation=(?P<operation>\w+) iterations=(?P<iterations>\d+) "
    r"warmup=(?P<warmup>\d+) elapsed_seconds=(?P<elapsed>[0-9.]+) status=(?P<status>\w+)"
)


def parse_driver_output(output: str) -> dict:
    match = PROFILE_RE.search(output)
    if not match:
        raise CommandError(f"driver output is not parseable: {output!r}")
    parsed = match.groupdict()
    if parsed["status"] != "PASS":
        raise CommandError(f"driver reported failure: {output!r}")
    return {
        "operation": parsed["operation"],
        "iterations": int(parsed["iterations"]),
        "warmup": int(parsed["warmup"]),
        "elapsed_seconds": float(parsed["elapsed"]),
        "status": parsed["status"],
    }


def calibrate(elf: Path, variant: str, operation: str, seconds: float) -> int:
    calibration_dir = BUILD_ROOT / variant / "calibration"
    output, gmon = execute_profile(
        elf, operation, 2000, 10, calibration_dir / f"{operation}-gmon"
    )
    parsed = parse_driver_output(output)
    gmon.unlink(missing_ok=True)
    elapsed = max(parsed["elapsed_seconds"], 0.001)
    estimated = int(round(2000 * seconds / elapsed))
    return max(1000, min(estimated, 5_000_000))


def run_gprof(elf: Path, gmons: Sequence[Path], mode: str, output: Path) -> None:
    flags = {"flat": "-p", "callgraph": "-q", "line": "-l"}
    command = ["gprof", "-b", flags[mode], str(elf), *(str(path) for path in gmons)]
    completed = run(command, capture=True)
    output.write_text(completed.stdout, encoding="utf-8")


def create_result_dir(output: str | None) -> Path:
    if output:
        result = Path(output).expanduser().resolve()
    else:
        stamp = dt.datetime.now().astimezone().strftime("%Y%m%d-%H%M%S")
        result = DEFAULT_RESULTS_ROOT / stamp
    result.mkdir(parents=True, exist_ok=False)
    BUILD_ROOT.mkdir(parents=True, exist_ok=True)
    return result


def archive_builds(builds: dict[str, dict], result_dir: Path) -> dict[str, dict]:
    archived = {}
    for variant, build in builds.items():
        artifact_dir = result_dir / variant / "artifacts"
        artifact_dir.mkdir(parents=True, exist_ok=True)
        source_elf = Path(build["elf"])
        source_library = Path(build["library"])
        archived_elf = artifact_dir / source_elf.name
        archived_library = artifact_dir / source_library.name
        shutil.copy2(source_elf, archived_elf)
        shutil.copy2(source_library, archived_library)
        if sha256_file(archived_elf) != build["elf_sha256"]:
            raise CommandError(f"{variant}: archived ELF hash mismatch")
        if sha256_file(archived_library) != build["library_sha256"]:
            raise CommandError(f"{variant}: archived library hash mismatch")
        archived[variant] = {
            **build,
            "build_elf": build["elf"],
            "build_library": build["library"],
            "elf": str(archived_elf),
            "library": str(archived_library),
        }
    return archived


def profile_campaign(variants: Sequence[str], seconds: float, runs: int, output: str | None) -> Path:
    if seconds <= 0 or runs <= 0:
        raise CommandError("seconds and runs must be positive")
    environment = check_environment()
    builds = {variant: build_variant(variant) for variant in variants}
    result_dir = create_result_dir(output)
    builds = archive_builds(builds, result_dir)
    manifest = {
        "schema": 1,
        "created_at": dt.datetime.now().astimezone().isoformat(),
        "environment": environment,
        "campaign": {
            "seconds": seconds,
            "runs": runs,
            "operations": list(OPERATIONS),
            "variants": list(variants),
            "primary_variant": "c-os",
        },
        "builds": builds,
        "runs": [],
    }
    (result_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )

    for variant in variants:
        elf = Path(builds[variant]["elf"])
        for operation in OPERATIONS:
            operation_dir = result_dir / variant / operation
            operation_dir.mkdir(parents=True, exist_ok=True)
            iterations = calibrate(elf, variant, operation, seconds)
            gmons = []
            for run_index in range(1, runs + 1):
                prefix = operation_dir / f"gmon-run-{run_index}"
                stdout, gmon = execute_profile(elf, operation, iterations, 50, prefix)
                parsed = parse_driver_output(stdout)
                stdout_path = operation_dir / f"run-{run_index}.stdout.txt"
                stdout_path.write_text(stdout, encoding="utf-8")
                gmons.append(gmon)
                run_record = {
                    "variant": variant,
                    "operation": operation,
                    "run": run_index,
                    **parsed,
                    "gmon": str(gmon),
                    "gmon_sha256": sha256_file(gmon),
                    "stdout": str(stdout_path),
                }
                manifest["runs"].append(run_record)
                for mode in ("flat", "callgraph", "line"):
                    run_gprof(
                        elf,
                        [gmon],
                        mode,
                        operation_dir / f"run-{run_index}-{mode}.txt",
                    )
            for mode in ("flat", "callgraph", "line"):
                run_gprof(elf, gmons, mode, operation_dir / f"aggregate-{mode}.txt")
            (result_dir / "manifest.json").write_text(
                json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
            )

    manifest["completed_at"] = dt.datetime.now().astimezone().isoformat()
    (result_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    LATEST_RESULT.write_text(str(result_dir) + "\n", encoding="utf-8")
    print(f"PROFILE COMPLETE: {result_dir}")
    return result_dir


def resolve_result(text: str | None) -> Path:
    if text:
        result = Path(text).expanduser().resolve()
    elif LATEST_RESULT.exists():
        result = Path(LATEST_RESULT.read_text(encoding="utf-8").strip())
    else:
        candidates = sorted(path for path in DEFAULT_RESULTS_ROOT.glob("*") if path.is_dir())
        if not candidates:
            raise CommandError("no profiling result found; run the profile target first")
        result = candidates[-1]
    if not (result / "manifest.json").exists():
        raise CommandError(f"not a profiling result directory: {result}")
    return result


def clean_build() -> None:
    if BUILD_ROOT.exists():
        shutil.rmtree(BUILD_ROOT)
    print(f"removed build artifacts: {BUILD_ROOT}")


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(description=__doc__)
    subparsers = root.add_subparsers(dest="command", required=True)
    subparsers.add_parser("check")

    build = subparsers.add_parser("build")
    build.add_argument("--variants", default=",".join(VARIANTS))

    profile = subparsers.add_parser("profile")
    profile.add_argument("--variants", default=",".join(VARIANTS))
    profile.add_argument("--seconds", type=float, default=5.0)
    profile.add_argument("--runs", type=int, default=3)
    profile.add_argument("--output")

    report = subparsers.add_parser("report")
    report.add_argument("--input")
    report.add_argument("--riscv-elf")

    inspect = subparsers.add_parser("inspect")
    inspect.add_argument("--input")
    inspect.add_argument("--symbol", required=True)
    inspect.add_argument("--riscv-elf")

    subparsers.add_parser("clean")
    return root


def main() -> int:
    arguments = parser().parse_args()
    try:
        if arguments.command == "check":
            check_environment()
        elif arguments.command == "build":
            build_variants(parse_variants(arguments.variants))
        elif arguments.command == "profile":
            profile_campaign(
                parse_variants(arguments.variants),
                arguments.seconds,
                arguments.runs,
                arguments.output,
            )
        elif arguments.command == "report":
            result = resolve_result(arguments.input)
            riscv = Path(arguments.riscv_elf).resolve() if arguments.riscv_elf else None
            print(generate_report(result, riscv))
        elif arguments.command == "inspect":
            result = resolve_result(arguments.input)
            manifest = json.loads((result / "manifest.json").read_text(encoding="utf-8"))
            elf = Path(manifest["builds"]["c-os"]["elf"])
            if not elf_has_symbol(elf, arguments.symbol):
                noinline_elf = Path(manifest["builds"]["c-noinline"]["elf"])
                if elf_has_symbol(noinline_elf, arguments.symbol):
                    elf = noinline_elf
            output = result / "gdb" / "manual-host.txt"
            inspect_symbol(elf, arguments.symbol, output)
            if arguments.riscv_elf:
                inspect_riscv_symbol(
                    Path(arguments.riscv_elf).resolve(),
                    arguments.symbol.removeprefix("PQCP_MLKEM_NATIVE_MLKEM512_"),
                    result / "gdb" / "manual-riscv.txt",
                )
            print(output)
        elif arguments.command == "clean":
            clean_build()
    except (CommandError, ValueError, OSError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
