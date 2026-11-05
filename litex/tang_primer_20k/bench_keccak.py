#!/usr/bin/env python3
"""Grava o bitstream na SRAM da Tang Primer 20K, captura a UART e salva o benchmark.

Pensado para o firmware MLKEM_RUNTIME_BENCH=1: um único boot executa 5 KATs em
cada backend (0 = C, 1 = Montgomery, 2 = Montgomery + Keccak). Nada é gravado na
flash. Normalmente é chamado por bench_keccak.sh; também pode reprocessar um log:

    python3 bench_keccak.py --parse-only uart.log --output /tmp/teste
"""
import argparse
import csv
import datetime
import hashlib
import json
import re
import shutil
import statistics
import subprocess
import sys
import time
from pathlib import Path

BACKENDS = {0: "C", 1: "Montgomery", 2: "Montgomery+Keccak"}
OPS = ("keypair", "encaps", "decaps")
SAMPLES = 5
END_MARKERS = ("Done (No Console)", "No boot medium found")
DEFAULT_UARTS = ("/dev/serial/by-id/usb-SIPEED_JTAG_Debugger_FactoryAIOT_Pro-if01-port0", "/dev/ttyUSB2")


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def analyze(text):
    """Separa a UART por backend e confere KAT, matches e ciclos de cada amostra."""
    clean = re.sub(r"\x1b\[[0-9;]*[A-Za-z]", "", text).replace("\r", "")
    parts = re.split(r"\[MLKEM\] backend=(\d+)", clean)
    backends = []
    for index in range(1, len(parts), 2):
        backend, body = int(parts[index]), parts[index + 1]
        samples = []
        for chunk in re.split(r"\[MLKEM\] sample=\d+", body)[1:]:
            cycles = {op: re.search(r"bench_%s_cycles=(\d+)" % op, chunk) for op in OPS}
            ok = (all(cycles.values())
                  and "[MLKEM] KAT PASS" in chunk
                  and all("[MLKEM] %s match: ok" % n in chunk for n in ("pk", "sk", "ct", "ss"))
                  and "[MLKEM] ss self-match: ok" in chunk
                  and not re.search(r"\[MLKEM\].*(?:FAIL|fail|first_diff)", chunk))
            row = {op: int(m.group(1)) if m else None for op, m in cycles.items()}
            row["total"] = sum(row.values()) if all(cycles.values()) else None
            row["kat_pass"] = ok
            samples.append(row)
        clock = re.search(r"bench_clock_hz=(\d+)", body)
        backends.append({"backend": backend, "name": BACKENDS.get(backend, str(backend)),
                         "clock_hz": int(clock.group(1)) if clock else None, "samples": samples})
    complete = ([b["backend"] for b in backends] == list(BACKENDS)
                and all(len(b["samples"]) == SAMPLES for b in backends))
    passed = complete and all(s["kat_pass"] for b in backends for s in b["samples"])
    # Medianas e speedup contra C (backend 0), a partir dos totais de cada amostra.
    base = None
    for b in backends:
        med = {k: statistics.median(s[k] for s in b["samples"]) if b["samples"]
               and all(s[k] is not None for s in b["samples"]) else None for k in OPS + ("total",)}
        b["median"] = med
        if b["backend"] == 0:
            base = med
    for b in backends:
        b["speedup_vs_c"] = {k: round(base[k] / b["median"][k], 4)
                             if base and base.get(k) and b["median"].get(k) else None
                             for k in OPS + ("total",)}
    return {"passed": passed, "complete": complete, "backends": backends}


def capture(args, out):
    """Abre a UART antes de gravar a SRAM e lê até 15 KATs, marcador final ou timeout."""
    import serial  # pyserial, já presente no ambiente LiteX

    uart = args.uart or next((p for p in DEFAULT_UARTS if Path(p).exists()), DEFAULT_UARTS[-1])
    loader = ["openFPGALoader", "-b", "tangprimer20k"] + args.loader_arg + ["-m", str(args.bitstream)]
    log = bytearray()
    with serial.Serial(uart, 115200, timeout=0.5) as port:
        port.reset_input_buffer()
        prog = subprocess.run(loader, capture_output=True, text=True)
        (out / "programador.log").write_text("$ " + " ".join(loader) + "\n" + prog.stdout + prog.stderr)
        if prog.returncode != 0:
            raise SystemExit(f"openFPGALoader falhou (código {prog.returncode}); veja {out/'programador.log'}")
        print(f"==> SRAM gravada; lendo {uart} por até {args.timeout}s")
        deadline = time.monotonic() + args.timeout
        while time.monotonic() < deadline:
            chunk = port.read(4096)
            if chunk:
                log += chunk
                sys.stdout.write(chunk.decode(errors="replace"))
                sys.stdout.flush()
            text = log.decode(errors="replace")
            if len(re.findall(r"\[MLKEM\] KAT (?:PASS|FAIL)", text)) >= len(BACKENDS) * SAMPLES:
                time.sleep(1.0)
                log += port.read(port.in_waiting or 1)
                break
            if any(m in text for m in END_MARKERS) and "[MLKEM]" in text:
                break
    (out / "uart.log").write_bytes(bytes(log))
    return uart, loader, log.decode(errors="replace")


def save(out, result, meta):
    with open(out / "ciclos.csv", "w", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["backend", "nome", "amostra", *OPS, "total", "kat_pass"])
        for b in result["backends"]:
            for i, s in enumerate(b["samples"]):
                writer.writerow([b["backend"], b["name"], i, *(s[k] for k in OPS), s["total"], s["kat_pass"]])
    (out / "resultado.json").write_text(json.dumps({**meta, **result}, indent=2, ensure_ascii=False) + "\n")
    lines = [f"# Benchmark ML-KEM-512 Tang Primer 20K — {meta['data']}", "",
             f"- Status: **{'PASS' if result['passed'] else 'FALHA/INCOMPLETO'}**",
             *(f"- {k}: `{v}`" for k, v in meta.items() if k != "data"), "",
             "| backend | keypair | encaps | decaps | total (mediana) | speedup total vs C | KAT |",
             "|---|---:|---:|---:|---:|---:|---|"]
    for b in result["backends"]:
        m, s = b["median"], b["speedup_vs_c"]
        kats = sum(x["kat_pass"] for x in b["samples"])
        lines.append(f"| {b['name']} | {m['keypair']} | {m['encaps']} | {m['decaps']} | {m['total']} "
                     f"| {s['total']} | {kats}/{len(b['samples'])} PASS |")
    lines += ["", "Ciclos do `timer0` (clock nominal da UART). Medianas de 5 amostras do mesmo vetor KAT,",
              "em um único boot. Relatórios Gowin copiados em `relatorios/`; leia o timing antes",
              "de tirar conclusões físicas."]
    (out / "RESUMO.md").write_text("\n".join(lines) + "\n")
    table = lines.index("|---|---:|---:|---:|---:|---:|---|") - 1
    print("\n" + "\n".join(lines[2:3] + lines[table:table + 2 + len(result["backends"])]))


def copy_reports(build_dir, out):
    """Copia relatórios pequenos do Gowin e o manifesto; arquivos grandes só têm hash registrado."""
    dest, large = out / "relatorios", {}
    for path in sorted(Path(build_dir).glob("gateware/**/*")):
        if path.is_file() and re.search(r"(\.rpt(\.txt|\.html)?|\.tr(\.html)?|_rsc\.xml|\.timing_paths)$", path.name):
            if path.stat().st_size <= 2_000_000:
                dest.mkdir(exist_ok=True)
                shutil.copy2(path, dest / path.name)
            else:
                large[str(path)] = sha256(path)
    manifest = Path(build_dir) / "mlkem_build_manifest.md"
    if manifest.is_file():
        shutil.copy2(manifest, out / "mlkem_build_manifest.md")
    return large


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--bitstream", type=Path, help=".fs gerado (padrão: o mais novo em BUILD_DIR/gateware)")
    parser.add_argument("--build-dir", type=Path, help="diretório de build do deploy.sh")
    parser.add_argument("--output", type=Path, required=True, help="diretório de resultados (é criado)")
    parser.add_argument("--uart", help="porta serial (padrão: by-id da Sipeed, senão /dev/ttyUSB2)")
    parser.add_argument("--loader-arg", action="append", default=[], help="argumento extra do openFPGALoader")
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--label", default="", help="texto livre registrado no resultado")
    parser.add_argument("--parse-only", type=Path, help="apenas analisa um uart.log existente")
    args = parser.parse_args()

    args.output.mkdir(parents=True, exist_ok=False)
    meta = {"data": datetime.datetime.now().astimezone().isoformat(timespec="seconds"), "rotulo": args.label}
    if args.parse_only:
        shutil.copy2(args.parse_only, args.output / "uart.log")
        text = args.parse_only.read_text(errors="replace")
    else:
        if not args.bitstream:
            if not args.build_dir:
                raise SystemExit("informe --bitstream ou --build-dir (ou --parse-only)")
            found = sorted(Path(args.build_dir).glob("gateware/**/*.fs"), key=lambda p: p.stat().st_mtime)
            if not found:
                raise SystemExit(f"nenhum .fs em {args.build_dir}/gateware")
            args.bitstream = found[-1]
        meta.update(bitstream=str(args.bitstream.resolve()), bitstream_sha256=sha256(args.bitstream))
        uart, loader, text = capture(args, args.output)
        meta.update(uart=uart, programador=" ".join(loader))
    if args.build_dir:
        large = copy_reports(args.build_dir, args.output)
        if large:
            meta["relatorios_grandes_sha256"] = large
    result = analyze(text)
    save(args.output, result, meta)
    print(f"\n==> Resultados salvos em {args.output}")
    sys.exit(0 if result["passed"] else 1)


if __name__ == "__main__":
    main()
