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
import os
import re
import shutil
import statistics
import shlex
import subprocess
import sys
import time
from pathlib import Path

BACKENDS = {0: "C", 1: "Montgomery", 2: "Montgomery+Keccak"}
PROFILE_NAMES = {"both": "Montgomery", "barrett": "Barrett", "montgomery-barrett": "Montgomery+Barrett",
                 "keccak": "Keccak", "all": "Montgomery+Keccak", "all-barrett": "Montgomery+Barrett+Keccak"}
OPS = ("keypair", "encaps", "decaps")
SAMPLES = 5
END_MARKERS = ("Done (No Console)", "No boot medium found")

def uart_inventory():
    from serial.tools import list_ports
    keys = ("device", "vid", "pid", "serial_number", "location", "interface", "description", "hwid")
    return [{key: getattr(port, key, None) for key in keys} for port in list_ports.comports()]


def select_uart(requested=None, ports=None, board_serial=None):
    """Select FT2232 interface B by USB metadata, never by ttyUSB numbering."""
    ports = uart_inventory() if ports is None else ports
    if requested:
        if not Path(requested).exists():
            raise RuntimeError(f"UART_DEV={requested} não existe; veja uart_dispositivos.json ou python3 -m serial.tools.list_ports -v")
        return requested
    candidates = [p for p in ports if p["vid"] == 0x0403 and p["pid"] == 0x6010
                  and (re.search(r":1\.1(?:\s|$)", p.get("location") or "")
                       or re.search(r"LOCATION=\S+:1\.1(?:\s|$)", p.get("hwid") or ""))]
    normalize = lambda value: re.sub(r"[^a-z0-9]", "", (value or "").lower())
    if board_serial:
        candidates = [p for p in candidates if normalize(p.get("serial_number")) == normalize(board_serial)]
    else:
        known = [p for p in candidates if any(word in normalize(" ".join(str(v or "") for v in p.values()))
                                             for word in ("sipeed", "factoryaiot", "tangprimer"))]
        if known:
            candidates = known
    if len(candidates) != 1:
        devices = ", ".join(str(p["device"]) for p in ports) or "nenhuma"
        raise RuntimeError(f"UART Tang não identificada de forma única ({len(candidates)} candidatas; portas: {devices}). "
                           "Confira python3 -m serial.tools.list_ports -v e defina UART_DEV=/dev/porta_correta. "
                           "Nenhum build/programação iniciado por esta checagem.")
    device = candidates[0]["device"]
    # Prefer udev's persistent name when available; USB numbering may change.
    aliases = sorted(p for p in Path("/dev/serial/by-id").glob("*") if p.exists() and p.resolve() == Path(device).resolve())
    return str(aliases[0]) if aliases else device


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def analyze(text, profile=None):
    """Separa a UART por backend e confere KAT, matches e ciclos de cada amostra."""
    clean = re.sub(r"\x1b\[[0-9;]*[A-Za-z]", "", text).replace("\r", "")
    parts = re.split(r"\[MLKEM\] backend=(\d+)", clean)
    expected = BACKENDS if profile is None else {0: "C", 1: PROFILE_NAMES[profile]}
    backends = []
    for index in range(1, len(parts), 2):
        backend, body = int(parts[index]), parts[index + 1]
        samples = []
        chunks = re.split(r"\[MLKEM\] sample=(\d+)", body)
        for pos in range(1, len(chunks), 2):
            sample_id, chunk = int(chunks[pos]), chunks[pos + 1]
            cycles = {op: re.findall(r"bench_%s_cycles=(\d+)" % op, chunk) for op in OPS}
            ok = (all(len(v) == 1 and int(v[0]) > 0 for v in cycles.values())
                  and chunk.count("[MLKEM] KAT PASS") == 1
                  and all("[MLKEM] %s match: ok" % n in chunk for n in ("pk", "sk", "ct", "ss"))
                  and "[MLKEM] ss self-match: ok" in chunk
                  and all("[MLKEM] %s: ok" % n in chunk for n in ("keypair", "encaps", "decaps"))
                  and not re.search(r"\[MLKEM\].*(?:FAIL|fail|first_diff)", chunk))
            row = {op: int(v[0]) if len(v) == 1 else None for op, v in cycles.items()}
            row["sample"] = sample_id
            row["total"] = sum(row[k] for k in OPS) if all(row[k] is not None for k in OPS) else None
            row["kat_pass"] = ok
            samples.append(row)
        clock = re.search(r"bench_clock_hz=(\d+)", body)
        backends.append({"backend": backend, "name": expected.get(backend, str(backend)),
                         "clock_hz": int(clock.group(1)) if clock else None, "samples": samples})
    complete = ([b["backend"] for b in backends] == list(expected)
                and all([s["sample"] for s in b["samples"]] == list(range(SAMPLES)) for b in backends))
    profile_ok = profile is None or all(
        re.findall(r"\[MLKEM\] %s_accel=([^\s]+)" % kind, clean) == [profile] * (2 * SAMPLES)
        for kind in ("hw", "sw"))
    passed = complete and profile_ok and all(s["kat_pass"] for b in backends for s in b["samples"])
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
    """Read UART during programming too, preserving partial data on all exits."""
    import serial

    uart = select_uart(args.uart, board_serial=os.environ.get("OFL_FTDI_SERIAL"))
    loader = ["openFPGALoader", "-b", "tangprimer20k"] + args.loader_arg + ["-m", str(args.bitstream)]
    target_kats = (2 if args.profile else 3) * SAMPLES
    process = None
    log = bytearray()
    with (out / "uart.log").open("wb") as raw, (out / "programador.log").open("w") as programmer:
        programmer.write("$ " + shlex.join(loader) + "\n")
        programmer.flush()
        try:
            with serial.Serial(uart, 115200, timeout=0.1) as port:
                port.reset_input_buffer()
                process = subprocess.Popen(loader, stdout=programmer, stderr=subprocess.STDOUT)
                start = time.monotonic()
                deadline = start + args.timeout
                while time.monotonic() < deadline:
                    chunk = port.read(port.in_waiting or 1)
                    if chunk:
                        raw.write(chunk)
                        raw.flush()
                        log += chunk
                        sys.stdout.write(chunk.decode(errors="replace"))
                        sys.stdout.flush()
                    code = process.poll()
                    if code is not None and code != 0:
                        raise RuntimeError(f"openFPGALoader falhou (código {code}); veja programador.log")
                    if code is None and time.monotonic() - start > 60:
                        raise RuntimeError("openFPGALoader excedeu 60s; captura parcial preservada")
                    text = log.decode(errors="replace")
                    if code == 0 and ("[MLKEM] BENCH DONE" in text or
                            len(re.findall(r"\[MLKEM\] KAT (?:PASS|FAIL)", text)) >= target_kats or
                            any(m in text for m in END_MARKERS)):
                        break
        finally:
            if process is not None and process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=3)
    return uart, shlex.join(loader), log.decode(errors="replace")


def save(out, result, meta):
    with open(out / "ciclos.csv", "w", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["backend", "nome", "amostra", *OPS, "total", "kat_pass"])
        for b in result["backends"]:
            for i, s in enumerate(b["samples"]):
                writer.writerow([b["backend"], b["name"], s["sample"], *(s[k] for k in OPS), s["total"], s["kat_pass"]])
    (out / "resultado.json").write_text(json.dumps({**meta, **result}, indent=2, ensure_ascii=False) + "\n")
    lines = [f"# Benchmark ML-KEM-512 Tang Primer 20K — {meta['data']}", "",
             f"- Status: **{meta.get('status', 'PASS' if result['passed'] else 'FALHA/INCOMPLETO')}**",
             *(f"- {k}: `{v}`" for k, v in meta.items() if k != "data"), "",
             "| backend | keypair | encaps | decaps | total (mediana) | speedup total vs C | KAT |",
             "|---|---:|---:|---:|---:|---:|---|"]
    for b in result["backends"]:
        m, s = b["median"], b["speedup_vs_c"]
        kats = sum(x["kat_pass"] for x in b["samples"])
        lines.append(f"| {b['name']} | {m['keypair']} | {m['encaps']} | {m['decaps']} | {m['total']} "
                     f"| {s['total']} | {kats}/{len(b['samples'])} PASS |")
    lines += ["", "Ciclos do `timer0` (frequência nominal informada pelo firmware). Medianas de 5 amostras do mesmo vetor KAT,",
              "em um único boot. Relatórios Gowin copiados em `relatorios/`; leia o timing antes",
              "de tirar conclusões físicas."]
    (out / "RESUMO.md").write_text("\n".join(lines) + "\n")
    table = lines.index("|---|---:|---:|---:|---:|---:|---|") - 1
    print("\n" + "\n".join(lines[2:3] + lines[table:table + 2 + len(result["backends"])]))


def copy_reports(build_dir, out):
    """Copia relatórios pequenos do Gowin e o manifesto; arquivos grandes só têm hash registrado."""
    dest, large = out / "relatorios", {}
    for path in sorted(Path(build_dir).glob("gateware/**/*")):
        if path.is_file() and re.search(r"(\.rpt(\.txt|\.html)?|\.tr(\.html)?|_tr(_content)?\.html|_rsc\.xml|\.timing_paths)$", path.name):
            if path.stat().st_size <= 2_000_000:
                dest.mkdir(exist_ok=True)
                target = dest / path.relative_to(Path(build_dir) / "gateware")
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(path, target)
            else:
                large[str(path)] = sha256(path)
    manifest = Path(build_dir) / "mlkem_build_manifest.md"
    if manifest.is_file():
        shutil.copy2(manifest, out / "mlkem_build_manifest.md")
    return large


def finalize(out, exit_code, stage, build_dir=None):
    import gzip
    result_file = out / "resultado.json"
    if result_file.exists():
        result = json.loads(result_file.read_text())
    else:
        result = {"passed": False, "complete": False, "backends": [],
                  "data": datetime.datetime.now().astimezone().isoformat(timespec="seconds"), "rotulo": ""}
    result.update(process_exit_code=exit_code, stage=stage)
    if exit_code:
        result["passed"] = False
    if build_dir:
        result["relatorios_grandes_sha256"] = copy_reports(build_dir, out)
    build_log = out / "build.log"
    if build_log.is_file():
        with build_log.open("rb") as source, gzip.open(out / "build.log.gz", "wb") as dest:
            shutil.copyfileobj(source, dest)
        build_log.unlink()
    if stage == "checagem" and exit_code == 0:
        result["status"] = "AMBIENTE OK (benchmark não executado)"
    elif not result["passed"] and "error" not in result:
        result["error"] = f"Etapa {stage}, código {exit_code}; veja execucao.log e build.log.gz, quando presente."
    meta = {k: v for k, v in result.items() if k not in ("passed", "complete", "backends")}
    save(out, result, meta)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--bitstream", type=Path, help=".fs exato gerado pelo build")
    parser.add_argument("--build-dir", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--existing-output", action="store_true")
    parser.add_argument("--profile", choices=("both", "barrett", "montgomery-barrett", "keccak", "all", "all-barrett"),
                        help="compara C e perfil; omitido analisa modo legado de três backends")
    parser.add_argument("--uart", help="porta explícita; padrão: autodetectar interface B do FT2232")
    parser.add_argument("--detect-uart", action="store_true", help="identificar UART sem abrir/programar a placa")
    parser.add_argument("--loader-arg", action="append", default=[])
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--label", default="")
    parser.add_argument("--parse-only", type=Path)
    parser.add_argument("--finalize", type=Path, help=argparse.SUPPRESS)
    parser.add_argument("--exit-code", type=int, default=1, help=argparse.SUPPRESS)
    parser.add_argument("--stage", default="erro", help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.finalize:
        finalize(args.finalize, args.exit_code, args.stage, args.build_dir)
        return
    if args.detect_uart:
        try:
            ports = uart_inventory()
            if args.output:
                args.output.mkdir(parents=True, exist_ok=True)
                (args.output / "uart_dispositivos.json").write_text(json.dumps(ports, indent=2, ensure_ascii=False) + "\n")
            print(select_uart(args.uart, ports, os.environ.get("OFL_FTDI_SERIAL")))
        except Exception as exc:
            parser.exit(1, f"ERRO: {exc}\n")
        return
    if not args.output:
        parser.error("--output é obrigatório")
    if args.timeout <= 0:
        parser.error("--timeout deve ser positivo")
    args.output.mkdir(parents=True, exist_ok=args.existing_output)
    meta = {"data": datetime.datetime.now().astimezone().isoformat(timespec="seconds"), "rotulo": args.label}
    text = ""
    try:
        if args.parse_only:
            shutil.copy2(args.parse_only, args.output / "uart.log")
            text = args.parse_only.read_text(errors="replace")
        else:
            if not args.bitstream:
                raise RuntimeError("informe --bitstream exato; imagens não são escolhidas pela data")
            meta.update(bitstream=str(args.bitstream.resolve()), bitstream_sha256=sha256(args.bitstream))
            uart, loader, text = capture(args, args.output)
            meta.update(uart=uart, programador=loader)
    except (Exception, KeyboardInterrupt) as exc:
        meta["error"] = f"{type(exc).__name__}: {exc}"
        print(f"ERRO: {meta['error']}", file=sys.stderr)
        raw = args.output / "uart.log"
        text = raw.read_text(errors="replace") if raw.exists() else ""
    if args.build_dir:
        meta["relatorios_grandes_sha256"] = copy_reports(args.build_dir, args.output)
    result = analyze(text, args.profile)
    if "error" in meta:
        result["passed"] = False
    save(args.output, result, meta)
    print(f"\n==> Resultados salvos em {args.output}")
    sys.exit(0 if result["passed"] else 1)


if __name__ == "__main__":
    main()
