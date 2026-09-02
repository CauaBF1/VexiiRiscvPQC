#!/usr/bin/env python3
"""Parse GNU gprof output and produce reproducible ML-KEM candidate reports."""

from __future__ import annotations

import csv
import hashlib
import json
import re
import shutil
import subprocess
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable, Sequence


SYMBOL_PREFIX = "PQCP_MLKEM_NATIVE_MLKEM512_"
EXCLUDED_PATTERNS = (
    "main",
    "moncontrol",
    "mcount",
    "gmon",
    "randombytes",
    "clock_gettime",
    "printf",
    "fprintf",
    "memcmp",
    "memcpy",
    "memset",
    "qsort",
    "strtoull",
    "execute_once",
    "prepare_operation",
    "validate_operation",
)

STRUCTURAL_PATTERNS = (
    "fqmul",
    "montgomery",
    "barrett",
    "ntt_layer",
    "invntt_layer",
    "scalar_compress",
    "scalar_decompress",
)


@dataclass(frozen=True)
class FlatEntry:
    self_percent: float
    cumulative_seconds: float
    self_seconds: float
    calls: int | None
    self_seconds_per_call: float | None
    total_seconds_per_call: float | None
    symbol: str

    @property
    def display_symbol(self) -> str:
        return normalize_symbol(self.symbol)


def normalize_symbol(symbol: str) -> str:
    return symbol.removeprefix(SYMBOL_PREFIX)


def is_number(token: str) -> bool:
    try:
        float(token)
    except ValueError:
        return False
    return True


def parse_flat_profile(text: str) -> list[FlatEntry]:
    entries: list[FlatEntry] = []
    in_table = False

    for raw_line in text.splitlines():
        line = raw_line.strip()
        if line.startswith("time") and "seconds" in line and "name" in line:
            in_table = True
            continue
        if not in_table:
            continue
        if not line or line.startswith("Call graph") or line.startswith("granularity"):
            if entries and (not line or line.startswith("Call graph")):
                break
            continue

        fields = line.split()
        if len(fields) < 4 or not all(is_number(token) for token in fields[:3]):
            continue

        numeric_count = 3
        while numeric_count < len(fields) and is_number(fields[numeric_count]):
            numeric_count += 1
        if numeric_count >= len(fields):
            continue

        tail = fields[3:numeric_count]
        calls = int(float(tail[0])) if len(tail) >= 1 else None
        self_per_call = float(tail[1]) if len(tail) >= 2 else None
        total_per_call = float(tail[2]) if len(tail) >= 3 else None
        entries.append(
            FlatEntry(
                self_percent=float(fields[0]),
                cumulative_seconds=float(fields[1]),
                self_seconds=float(fields[2]),
                calls=calls,
                self_seconds_per_call=self_per_call,
                total_seconds_per_call=total_per_call,
                symbol=" ".join(fields[numeric_count:]),
            )
        )
    if not entries:
        raise ValueError("flat profile table not found or empty")
    return entries


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_entries(entries: Sequence[FlatEntry], csv_path: Path, json_path: Path) -> None:
    csv_path.parent.mkdir(parents=True, exist_ok=True)
    fields = [
        "rank",
        "self_percent",
        "cumulative_seconds",
        "self_seconds",
        "calls",
        "self_seconds_per_call",
        "total_seconds_per_call",
        "symbol",
        "display_symbol",
    ]
    with csv_path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        for rank, entry in enumerate(entries, 1):
            row = asdict(entry)
            row["rank"] = rank
            row["display_symbol"] = entry.display_symbol
            writer.writerow(row)
    json_path.write_text(
        json.dumps(
            [
                {"rank": rank, **asdict(entry), "display_symbol": entry.display_symbol}
                for rank, entry in enumerate(entries, 1)
            ],
            indent=2,
            ensure_ascii=False,
        )
        + "\n",
        encoding="utf-8",
    )


def candidate_entries(entries: Iterable[FlatEntry]) -> list[FlatEntry]:
    return [
        entry
        for entry in entries
        if not any(pattern in entry.display_symbol.lower() for pattern in EXCLUDED_PATTERNS)
    ]


def is_structural_candidate(entry: FlatEntry) -> bool:
    name = entry.display_symbol.lower()
    return entry.self_percent >= 1.0 and any(token in name for token in STRUCTURAL_PATTERNS)


def rank_map(entries: Sequence[FlatEntry]) -> dict[str, int]:
    return {entry.symbol: rank for rank, entry in enumerate(entries, 1)}


def entry_map(entries: Sequence[FlatEntry]) -> dict[str, FlatEntry]:
    return {entry.symbol: entry for entry in entries}


def hardware_heuristics(symbol: str) -> tuple[int, int, str]:
    name = normalize_symbol(symbol).lower()
    if any(token in name for token in ("fqmul", "montgomery", "barrett")):
        return 3, 3, "kernel escalar aritmético"
    if "keccak" in name:
        return 1, 3, "estado grande e datapath regular"
    if any(token in name for token in ("polyvec", "matrix", "indcpa")):
        return 1, 2, "interface de vetores/estado grande"
    if any(token in name for token in ("poly_", "ntt", "cbd", "compress")):
        return 2, 3, "kernel polinomial regular"
    if any(token in name for token in ("check", "verify", "compare")):
        return 2, 1, "controle/verificação"
    return 1, 2, "classificação automática genérica"


def time_score(percent: float) -> int:
    if percent >= 10.0:
        return 3
    if percent >= 3.0:
        return 2
    if percent >= 1.0:
        return 1
    return 0


def frequency_score(calls_per_flow: float) -> int:
    if calls_per_flow >= 100.0:
        return 3
    if calls_per_flow >= 10.0:
        return 2
    if calls_per_flow >= 1.0:
        return 1
    return 0


def read_profile(path: Path) -> list[FlatEntry]:
    return parse_flat_profile(path.read_text(encoding="utf-8", errors="replace"))


def find_profile(result_dir: Path, variant: str, operation: str) -> Path | None:
    path = result_dir / variant / operation / "aggregate-flat.txt"
    return path if path.exists() else None


def load_manifest(result_dir: Path) -> dict:
    return json.loads((result_dir / "manifest.json").read_text(encoding="utf-8"))


def profile_lookup(result_dir: Path, variant: str, operation: str) -> list[FlatEntry]:
    path = find_profile(result_dir, variant, operation)
    return read_profile(path) if path else []


def stability_count(result_dir: Path, variant: str, operation: str, symbol: str) -> int:
    count = 0
    for path in sorted((result_dir / variant / operation).glob("run-*-flat.txt")):
        ranks = rank_map(candidate_entries(read_profile(path)))
        if ranks.get(symbol, 10**9) <= 15:
            count += 1
    return count


def inspect_symbol(elf: Path, symbol: str, output: Path, gdb: str = "gdb") -> None:
    command = [
        gdb,
        "-q",
        "-batch",
        "-ex",
        f"info address {symbol}",
        "-ex",
        f"disassemble /m {symbol}",
        str(elf),
    ]
    completed = subprocess.run(command, text=True, capture_output=True, check=False)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        "$ " + " ".join(command) + "\n\n" + completed.stdout + completed.stderr,
        encoding="utf-8",
    )


def elf_has_symbol(elf: Path, symbol: str) -> bool:
    completed = subprocess.run(
        ["nm", "-a", str(elf)], text=True, capture_output=True, check=False
    )
    if completed.returncode != 0:
        return False
    return any(line.split()[-1:] == [symbol] for line in completed.stdout.splitlines())


def inspect_riscv_symbol(elf: Path, display_symbol: str, output: Path) -> None:
    gdb = "riscv64-unknown-elf-gdb"
    if not shutil.which(gdb):
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(
            f"{gdb} não encontrado; inspeção RISC-V não executada.\n",
            encoding="utf-8",
        )
        return
    command = [
        gdb,
        "-q",
        "-batch",
        "-ex",
        f"info functions {display_symbol}",
        str(elf),
    ]
    completed = subprocess.run(command, text=True, capture_output=True, check=False)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        "$ " + " ".join(command) + "\n\n" + completed.stdout + completed.stderr,
        encoding="utf-8",
    )


def generate_report(result_dir: Path, riscv_elf: Path | None = None) -> Path:
    manifest = load_manifest(result_dir)
    parsed: dict[tuple[str, str], list[FlatEntry]] = {}
    for flat_path in result_dir.glob("*/*/aggregate-flat.txt"):
        variant = flat_path.parent.parent.name
        operation = flat_path.parent.name
        entries = read_profile(flat_path)
        parsed[(variant, operation)] = entries
        write_entries(
            entries,
            flat_path.with_name("aggregate-flat.csv"),
            flat_path.with_name("aggregate-flat.json"),
        )

    primary_all = candidate_entries(parsed.get(("c-os", "all"), []))
    c_o2_all = candidate_entries(parsed.get(("c-o2", "all"), []))
    pool: dict[str, FlatEntry] = {entry.symbol: entry for entry in primary_all[:20]}
    for operation in ("keypair", "encaps", "decaps"):
        for entry in candidate_entries(parsed.get(("c-os", operation), [])):
            if entry.self_percent >= 3.0:
                pool.setdefault(entry.symbol, entry)
    c_o2_top = {entry.symbol for entry in c_o2_all[:10]}
    for entry in primary_all[:10]:
        if entry.symbol in c_o2_top:
            pool.setdefault(entry.symbol, entry)

    noinline_all = candidate_entries(parsed.get(("c-noinline", "all"), []))
    structural_symbols = {
        entry.symbol for entry in noinline_all if is_structural_candidate(entry)
    }
    for entry in noinline_all:
        if entry.symbol in structural_symbols:
            pool.setdefault(entry.symbol, entry)

    profile_runs = int(manifest["campaign"]["runs"])
    iterations_all = sum(
        int(run["iterations"])
        for run in manifest["runs"]
        if run["variant"] == "c-noinline" and run["operation"] == "all" and not run.get("calibration")
    )
    noinline_map = entry_map(noinline_all)
    primary_map = entry_map(primary_all)
    o2_map = entry_map(c_o2_all)

    rows = []
    for symbol in pool:
        primary = primary_map.get(symbol)
        noinline = noinline_map.get(symbol)
        primary_percent = primary.self_percent if primary else 0.0
        noinline_percent = noinline.self_percent if noinline else 0.0
        calls_per_flow = (
            float(noinline.calls or 0) / iterations_all if noinline and iterations_all else 0.0
        )
        primary_reuse = sum(
            1
            for operation in ("keypair", "encaps", "decaps")
            if symbol in entry_map(candidate_entries(parsed.get(("c-os", operation), [])))
        )
        noinline_reuse = sum(
            1
            for operation in ("keypair", "encaps", "decaps")
            if symbol
            in entry_map(candidate_entries(parsed.get(("c-noinline", operation), [])))
        )
        structural_only = primary is None and symbol in structural_symbols
        reuse = noinline_reuse if structural_only else primary_reuse
        interface, regularity, rationale = hardware_heuristics(symbol)
        stability_variant = "c-noinline" if structural_only else "c-os"
        stable_runs = stability_count(result_dir, stability_variant, "all", symbol)
        score = (
            time_score(primary_percent)
            + frequency_score(calls_per_flow)
            + min(reuse, 3)
            + interface
            + regularity
        )
        rows.append(
            {
                "symbol": symbol,
                "display_symbol": normalize_symbol(symbol),
                "scope": "structural-noinline" if structural_only else "primary-hotspot",
                "c_os_self_percent": primary_percent,
                "c_o2_self_percent": o2_map.get(symbol).self_percent if symbol in o2_map else 0.0,
                "c_noinline_self_percent": noinline_percent,
                "calls_per_flow_noinline": calls_per_flow,
                "operation_reuse": reuse,
                "stable_runs": stable_runs,
                "confirmed": stable_runs >= min(2, profile_runs),
                "interface_score": interface,
                "regularity_score": regularity,
                "priority_score": score,
                "heuristic_rationale": rationale,
                "amdahl_infinite_host": (
                    1.0 / (1.0 - primary_percent / 100.0)
                    if primary is not None and primary_percent < 100.0
                    else None
                ),
            }
        )
    rows.sort(
        key=lambda row: (row["confirmed"], row["priority_score"], row["c_os_self_percent"]),
        reverse=True,
    )

    candidates_csv = result_dir / "candidates.csv"
    if rows:
        with candidates_csv.open("w", encoding="utf-8", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)
    (result_dir / "candidates.json").write_text(
        json.dumps(rows, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )

    top_five = rows[:5]
    for index, row in enumerate(top_five, 1):
        safe_name = re.sub(r"[^A-Za-z0-9_.-]+", "_", row["display_symbol"])
        inspection_variant = (
            "c-noinline" if row["scope"] == "structural-noinline" else "c-os"
        )
        host_elf = Path(manifest["builds"][inspection_variant]["elf"])
        inspect_symbol(
            host_elf,
            row["symbol"],
            result_dir
            / "gdb"
            / f"{index:02d}-{safe_name}-host-{inspection_variant}.txt",
        )
        if riscv_elf and riscv_elf.exists():
            inspect_riscv_symbol(
                riscv_elf,
                row["display_symbol"],
                result_dir / "gdb" / f"{index:02d}-{safe_name}-riscv.txt",
            )

    lines = [
        "# Relatório GPROF — ML-KEM-512",
        "",
        f"- Execução: `{result_dir.name}`",
        f"- Repetições: {profile_runs}",
        f"- Duração-alvo por repetição: {manifest['campaign']['seconds']} s",
        "- Resultado principal: C portátil `-Os`; `-O2`, sem inlining e x86 nativo são controles.",
        "",
        "## Cinco primeiros candidatos",
        "",
        "| # | função | origem | self C -Os | self sem inline | chamadas/fluxo | estabilidade | score |",
        "|---:|---|---|---:|---:|---:|---:|---:|",
    ]
    for index, row in enumerate(top_five, 1):
        lines.append(
            f"| {index} | `{row['display_symbol']}` | `{row['scope']}` | "
            f"{row['c_os_self_percent']:.2f}% | {row['c_noinline_self_percent']:.2f}% | "
            f"{row['calls_per_flow_noinline']:.2f} | "
            f"{row['stable_runs']}/{profile_runs} | {row['priority_score']} |"
        )
    lines.extend(
        [
            "",
            "## Hotspots brutos do C portátil `-Os`",
            "",
            "Esta tabela é ordenada somente por tempo próprio medido; não é um ranking de RTL.",
            "",
            "| operação | 1º | 2º | 3º |",
            "|---|---|---|---|",
        ]
    )
    for operation in ("keypair", "encaps", "decaps", "all"):
        hot = candidate_entries(parsed.get(("c-os", operation), []))[:3]
        cells = [f"`{entry.display_symbol}` ({entry.self_percent:.2f}%)" for entry in hot]
        cells.extend(["—"] * (3 - len(cells)))
        lines.append(f"| {operation} | {' | '.join(cells)} |")

    native_hot = candidate_entries(parsed.get(("native-o2", "all"), []))[:5]
    lines.extend(
        [
            "",
            "## Controle x86 nativo",
            "",
            "O backend nativo serve apenas para revelar viés da máquina hospedeira. "
            "Assembly AVX2 e o Vexii RV32 têm custos diferentes.",
            "",
        ]
    )
    for index, entry in enumerate(native_hot, 1):
        lines.append(f"{index}. `{entry.display_symbol}` — {entry.self_percent:.2f}%")
    lines.extend(
        [
            "",
            "## Critério",
            "",
            "A lista combina tempo próprio, frequência, reutilização entre operações, "
            "simplicidade de interface e regularidade. As duas últimas notas são heurísticas "
            "e precisam ser confirmadas pela inspeção do código/RTL.",
            "",
            "`primary-hotspot` significa que o símbolo existe no binário C `-Os`. "
            "`structural-noinline` significa que a função estava inlined no build principal e "
            "só pôde ser medida isoladamente no controle sem inlining. O percentual dessa "
            "segunda variante não pode ser transplantado para o build principal.",
            "",
            "O teto de Amdahl em `candidates.csv` é somente uma estimativa do host; não é "
            "uma previsão de ganho no VexiiRiscv.",
            "",
            "## Próxima validação no Vexii",
            "",
            "Correlacionar os candidatos com os buckets `rdcycle`, localizar código inlined "
            "no ELF RISC-V e medir de forma dirigida qualquer candidato que hoje caia em `misc`. "
            "Nenhum novo RTL deve ser escolhido apenas com os percentuais do host.",
            "",
        ]
    )
    report = result_dir / "REPORT.md"
    report.write_text("\n".join(lines), encoding="utf-8")
    return report
