#!/usr/bin/env python3
"""Preflight e identidade de builds do runner; não programa a placa."""
import argparse
import hashlib
import importlib.util
import json
import os
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEPS = ("ext/SpinalHDL", "ext/rvls")


def git(*args, cwd=ROOT):
    return subprocess.check_output(["git", "-C", str(cwd), *args], text=True).strip()


def dependencies(check=False):
    for name in DEPS:
        expected = git("ls-tree", "HEAD", name).split()[2]
        path = ROOT / name
        actual = git("rev-parse", "HEAD", cwd=path) if (path / ".git").exists() else None
        if actual != expected:
            if actual and git("status", "--porcelain", "--untracked-files=normal", cwd=path):
                raise RuntimeError(f"{name} possui alterações locais; preservadas. Esperado {expected}, atual {actual}.")
            if check:
                raise RuntimeError(f"{name}: esperado {expected}, atual {actual or 'não inicializado'}; execute o runner sem --check para sincronizar o submódulo limpo.")
            subprocess.run(["git", "-C", str(ROOT), "submodule", "update", "--init", "--", name], check=True, timeout=180)
            actual = git("rev-parse", "HEAD", cwd=path)
        if actual != expected:
            raise RuntimeError(f"{name} não corresponde ao gitlink {expected}")
        if git("status", "--porcelain", "--untracked-files=normal", cwd=path):
            raise RuntimeError(f"{name} modificado; preservado. Use a revisão fixada sem alterações para este benchmark.")
        print(f"{name}: {actual}", flush=True)


def external_identity():
    """Hash effective LiteX/Boards source trees, including local BIOS patches."""
    result = {}
    for name in ("litex", "litex_boards"):
        spec = importlib.util.find_spec(name)
        if spec is None or not spec.origin:
            raise RuntimeError(f"pacote ausente para identidade do build: {name}")
        package = Path(spec.origin).resolve().parent
        top = Path(git("rev-parse", "--show-toplevel", cwd=package))
        # Hash all versioned and non-ignored additions. Generated build outputs
        # remain excluded by each dependency's own .gitignore.
        names = git("ls-files", "--cached", "--others", "--exclude-standard", cwd=top).splitlines()
        h = hashlib.sha256()
        for filename in sorted(set(names)):
            path = top / filename
            h.update(filename.encode() + b"\0")
            h.update(path.read_bytes() if path.is_file() else b"MISSING")
        result[name] = {"path": str(top), "commit": git("rev-parse", "HEAD", cwd=top), "sha256": h.hexdigest()}
    return result


def identity(profile, architecture, selected):
    # Content hashes include tracked modifications and new source files; gitlinks
    # alone would miss local patches in mlkem-native and stale --skip-build images.
    paths = ["build.sbt", "project", "src/main", "litex/tang_primer_20k/bios",
             "litex/tang_primer_20k/deploy.sh", "litex/tang_primer_20k/prepare_runtime_backend.py",
             "litex/tang_primer_20k/patches"]
    files = git("ls-files", "--cached", "--others", "--exclude-standard", "--", *paths).splitlines()
    h = hashlib.sha256()
    for name in sorted(set(files)):
        p = ROOT / name
        h.update(name.encode() + b"\0")
        h.update(p.read_bytes() if p.is_file() else b"MISSING")
    for name in (*DEPS, "external/mlkem-native"):
        p = ROOT / name
        h.update(name.encode() + git("rev-parse", "HEAD", cwd=p).encode())
        # Include tracked diffs; external runtime overlays also depend on new files.
        h.update(subprocess.check_output(["git", "-C", str(p), "diff", "HEAD", "--"]))
        for f in git("ls-files", "--others", "--exclude-standard", cwd=p).splitlines():
            q = p / f
            if q.is_file():
                h.update(f.encode() + b"\0" + q.read_bytes())
    return {"profile": profile, "architecture": architecture, "selected": selected,
            "vexii_args": os.environ.get("VEXII_ARGS", ""),
            "cpu_variant": os.environ.get("CPU_VARIANT", "standard"),
            "external": external_identity(),
            "source_sha256": h.hexdigest(), "commit": git("rev-parse", "HEAD")}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("preflight", "begin", "stamp", "verify"))
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--profile", default="all")
    parser.add_argument("--architecture", default="sliced8")
    parser.add_argument("--selected", type=int, choices=(0, 1), default=0)
    parser.add_argument("--build-dir", type=Path)
    args = parser.parse_args()
    try:
        if args.action == "preflight":
            dependencies(args.check)
            return
        current = identity(args.profile, args.architecture, args.selected)
        stamp = args.build_dir / "bench_identity.json"
        pending = args.build_dir / "bench_build_pending.json"
        if args.action == "begin":
            args.build_dir.mkdir(parents=True, exist_ok=True)
            pending.write_text(json.dumps({"identity": current, "started_ns": time.time_ns()}))
            return
        if args.action == "stamp":
            started = json.loads(pending.read_text())
            if started["identity"] != current:
                raise RuntimeError("fontes/perfil mudaram durante o build; imagem não será programada")
            # LiteX copies impl/pnr/project.fs to gateware/<top>.fs. Both are
            # expected; accept copies only when their contents are identical.
            images = sorted((args.build_dir / "gateware").rglob("*.fs"), key=lambda p: (len(p.parts), str(p)))
            contents = {hashlib.sha256(p.read_bytes()).hexdigest() for p in images}
            if len(contents) != 1:
                raise RuntimeError(f"esperado um único conteúdo .fs, encontrados {len(contents)}; imagens divergentes/ausentes não serão programadas")
            fs = images[0]
            if fs.stat().st_mtime_ns < started["started_ns"]:
                raise RuntimeError("o build não atualizou o .fs; imagem antiga não será programada")
            current.update(bitstream=str(fs.resolve()), bitstream_sha256=hashlib.sha256(fs.read_bytes()).hexdigest())
            stamp.write_text(json.dumps(current, indent=2) + "\n")
            pending.unlink()
        else:
            if pending.exists():
                raise RuntimeError("build anterior interrompido/falhou; execute sem --skip-build")
            saved = json.loads(stamp.read_text())
            if any(saved.get(k) != v for k, v in current.items() if k != "commit"):
                raise RuntimeError("--skip-build: fontes/perfil mudaram; execute sem --skip-build para reconstruir")
            fs = Path(saved["bitstream"])
            if hashlib.sha256(fs.read_bytes()).hexdigest() != saved["bitstream_sha256"]:
                raise RuntimeError("--skip-build: bitstream mudou desde o build validado")
            print(fs)
    except (RuntimeError, OSError, ValueError, subprocess.SubprocessError) as exc:
        parser.exit(1, f"ERRO: {exc}\n")


if __name__ == "__main__":
    main()
