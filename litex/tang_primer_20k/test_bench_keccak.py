#!/usr/bin/env python3
"""Offline regressions: no Gowin, programmer or serial port is invoked."""
import importlib.util
import json
import subprocess
import tempfile
import types
import unittest
from pathlib import Path
from unittest.mock import patch
from unittest.mock import Mock

DIR = Path(__file__).resolve().parent


def load(name):
    spec = importlib.util.spec_from_file_location(name, DIR / (name + ".py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


bench = load("bench_keccak")
support = load("bench_support")


def uart(profile=None):
    lines = []
    for backend in range(2 if profile else 3):
        lines.append(f"[MLKEM] backend={backend}")
        for sample in range(5):
            lines.extend((f"[MLKEM] sample={sample}", "[MLKEM] bench_clock_hz=48000000"))
            if profile:
                lines += [f"[MLKEM] {kind}_accel={profile}" for kind in ("hw", "sw")]
            for op in bench.OPS:
                lines += [f"[MLKEM] {op}: ok", f"[MLKEM] bench_{op}_cycles={1000 // (backend + 1)}"]
            lines += [f"[MLKEM] {name} match: ok" for name in ("pk", "sk", "ct", "ss")]
            lines += ["[MLKEM] ss self-match: ok", "[MLKEM] KAT PASS"]
    return "\n".join(lines)


class ParserTests(unittest.TestCase):
    def test_legacy_and_selected_profiles(self):
        for profile in (None, "both", "montgomery-barrett", "keccak", "barrett", "all", "all-barrett"):
            with self.subTest(profile=profile):
                result = bench.analyze(uart(profile), profile)
                self.assertTrue(result["passed"])
                self.assertEqual(result["backends"][1]["speedup_vs_c"]["total"], 2.0)

    def test_incomplete_duplicate_ids_cycles_and_errors_fail(self):
        text = uart("keccak")
        for bad in (text.replace("sample=1", "sample=0"), text[:text.rfind("[MLKEM] KAT PASS")],
                    text.replace("bench_encaps_cycles=500", "bench_encaps_cycles=0", 1),
                    text.replace("[MLKEM] pk match: ok", "[MLKEM] pk match: fail", 1),
                    text.replace("bench_encaps_cycles=500", "bench_encaps_cycles=500\n[MLKEM] bench_encaps_cycles=500", 1)):
            self.assertFalse(bench.analyze(bad, "keccak")["passed"])

    def test_wrong_profile_and_legacy_image_rejected(self):
        self.assertFalse(bench.analyze(uart("both"), "keccak")["passed"])
        self.assertFalse(bench.analyze(uart(), "keccak")["passed"])

    def test_failure_package_and_gowin_html(self):
        with tempfile.TemporaryDirectory() as tmp:
            out, build = Path(tmp) / "out", Path(tmp) / "build"
            out.mkdir()
            report = build / "gateware/impl/pnr/project_tr_content.html"
            report.parent.mkdir(parents=True)
            report.write_text("timing failed")
            (out / "build.log").write_text("Scala compile failed")
            bench.finalize(out, 1, "build", build)
            data = json.loads((out / "resultado.json").read_text())
            self.assertFalse(data["passed"])
            self.assertEqual(data["stage"], "build")
            self.assertTrue((out / "build.log.gz").exists())
            self.assertTrue((out / "relatorios/impl/pnr/project_tr_content.html").exists())
            self.assertTrue((out / "RESUMO.md").exists())

    def test_capture_failure_still_saves_result(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "out"
            # Missing bitstream fails before opening serial/programmer.
            run = subprocess.run(["python3", str(DIR / "bench_keccak.py"), "--output", str(out)], capture_output=True)
            self.assertEqual(run.returncode, 1)
            self.assertFalse(json.loads((out / "resultado.json").read_text())["passed"])
            self.assertIn("RuntimeError", (out / "resultado.json").read_text())


class CliTests(unittest.TestCase):
    def test_profiles_and_combinations(self):
        cases = (([], "all", "15"), (["-montgomery"], "both", "10"),
                 (["-montgomery_barret"], "montgomery-barrett", "10"),
                 (["-montgomery_barrett"], "montgomery-barrett", "10"),
                 (["-keccak"], "keccak", "10"), (["-barrett"], "barrett", "10"),
                 (["-montgomery", "-keccak"], "all", "10"), (["-all"], "all-barrett", "10"))
        for flags, profile, count in cases:
            run = subprocess.run([str(DIR / "bench_keccak.sh"), *flags, "--plan"], capture_output=True, text=True)
            self.assertEqual(run.returncode, 0, run.stderr)
            self.assertIn(f"hw={profile} sw={profile}", run.stdout)
            self.assertIn("KATs=" + count, run.stdout)
            if profile == "both":
                self.assertNotIn("_keccak_", run.stdout)

    def test_invalid_option(self):
        for flags in (["--arch"], ["--arch", "nope", "--plan"], ["--unknown"]):
            self.assertEqual(subprocess.run([str(DIR / "bench_keccak.sh"), *flags], capture_output=True).returncode, 2)


class DependencyTests(unittest.TestCase):
    def test_dirty_submodule_is_preserved(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name in support.DEPS:
                (root / name).mkdir(parents=True)
                (root / name / ".git").touch()
            with patch.object(support, "ROOT", root), patch.object(support, "git", side_effect=["160000 commit expected ext/SpinalHDL", "old", " M file"]), patch.object(support.subprocess, "run") as run:
                with self.assertRaisesRegex(RuntimeError, "alterações locais"):
                    support.dependencies()
                run.assert_not_called()

    def test_clean_mismatch_is_updated_to_gitlink(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "dep").mkdir()
            (root / "dep/.git").touch()
            values = ["160000 commit expected dep", "old", "", "expected", ""]
            with patch.object(support, "ROOT", root), patch.object(support, "DEPS", ("dep",)), patch.object(support, "git", side_effect=values), patch.object(support.subprocess, "run") as run:
                support.dependencies()
                self.assertEqual(run.call_count, 1)

    def test_check_does_not_sync(self):
        with tempfile.TemporaryDirectory() as tmp:
            with patch.object(support, "ROOT", Path(tmp)), patch.object(support, "git", return_value="160000 commit expected ext/SpinalHDL"), patch.object(support.subprocess, "run") as run:
                with self.assertRaisesRegex(RuntimeError, "não inicializado"):
                    support.dependencies(check=True)
                run.assert_not_called()


class IdentityTests(unittest.TestCase):
    def invoke(self, action, directory):
        with patch("sys.argv", ["bench_support.py", action, "--build-dir", str(directory)]):
            support.main()

    def test_skip_build_rejects_failed_build_changed_inputs_and_changed_image(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(support, "identity", return_value={"source_sha256": "source", "commit": "commit"}):
            build = Path(tmp)
            self.invoke("begin", build)
            fs = build / "gateware/project.fs"
            fs.parent.mkdir()
            fs.write_bytes(b"image")
            duplicate = build / "gateware/impl/pnr/project.fs"
            duplicate.parent.mkdir(parents=True)
            duplicate.write_bytes(b"image")
            self.invoke("stamp", build)
            self.invoke("verify", build)
            fs.write_bytes(b"different")
            with self.assertRaises(SystemExit):
                self.invoke("verify", build)
            fs.write_bytes(b"image")
            with patch.object(support, "identity", return_value={"source_sha256": "changed", "commit": "commit"}):
                with self.assertRaises(SystemExit):
                    self.invoke("verify", build)
            self.invoke("begin", build)
            with self.assertRaises(SystemExit):
                self.invoke("verify", build)

    def test_old_fs_is_not_stamped_after_unsuccessful_rebuild(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(support, "identity", return_value={"source_sha256": "source"}):
            build = Path(tmp)
            fs = build / "gateware/project.fs"
            fs.parent.mkdir()
            fs.write_bytes(b"old")
            self.invoke("begin", build)
            with self.assertRaises(SystemExit):
                self.invoke("stamp", build)

    def test_effective_external_sources_invalidate_reuse(self):
        # Real Git fixtures in /tmp; no Git writes in the project checkout.
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            specs = {}
            inputs = []
            for name in ("litex", "litex_boards"):
                tree = base / name
                tree.mkdir()
                subprocess.run(["git", "init", "-q", str(tree)], check=True)
                package = tree / name
                package.mkdir()
                (package / "__init__.py").touch()
                for filename in ("core.py", "target.py", "constraints.cst", "bios/Makefile", "bios/main.c"):
                    path = package / filename
                    path.parent.mkdir(exist_ok=True)
                    path.write_text("prepared input\n")
                    inputs.append(path)
                subprocess.run(["git", "-C", str(tree), "add", "."], check=True)
                subprocess.run(["git", "-C", str(tree), "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "-c", "commit.gpgsign=false", "commit", "-qm", "fixture"], check=True)
                specs[name] = types.SimpleNamespace(origin=str(package / "__init__.py"))
            with patch.object(support.importlib.util, "find_spec", side_effect=lambda name: specs[name]):
                # Simulate deploy --install producing the effective BIOS before begin.
                inputs[-1].write_text("installed BIOS\n")
                header = inputs[-1].parent / "mlkem_accel_select.h"
                header.write_text("selected profile\n")
                build = base / "build"
                self.invoke("begin", build)
                fs = build / "gateware/project.fs"
                fs.parent.mkdir()
                fs.write_bytes(b"image")
                self.invoke("stamp", build)
                self.invoke("verify", build)
                for path in [*inputs, header]:
                    previous = path.read_text()
                    path.write_text(previous + "changed\n")
                    with self.assertRaises(SystemExit):
                        self.invoke("verify", build)
                    path.write_text(previous)


class CaptureTests(unittest.TestCase):
    def capture(self, out, code, times=None):
        port = Mock()
        port.__enter__ = Mock(return_value=port)
        port.__exit__ = Mock(return_value=False)
        port.in_waiting = 1
        port.read.return_value = b"partial UART"
        process = Mock()
        process.poll.return_value = code
        args = types.SimpleNamespace(uart="fake", loader_arg=[], bitstream=Path("image.fs"), profile="keccak", timeout=300)
        with patch.dict("sys.modules", {"serial": types.SimpleNamespace(Serial=Mock(return_value=port))}), patch.object(bench.subprocess, "Popen", return_value=process) as popen:
            if times:
                with patch.object(bench.time, "monotonic", side_effect=times):
                    with self.assertRaisesRegex(RuntimeError, "60s"):
                        bench.capture(args, out)
                process.terminate.assert_called_once()
            else:
                with self.assertRaisesRegex(RuntimeError, "openFPGALoader falhou"):
                    bench.capture(args, out)
            command = popen.call_args.args[0]
            self.assertIn("-m", command)
            self.assertNotIn("-f", command)
            self.assertEqual((out / "uart.log").read_bytes(), b"partial UART")

    def test_programmer_failure_preserves_partial_uart(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.capture(Path(tmp), 1)

    def test_programmer_timeout_terminates_process_and_preserves_uart(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.capture(Path(tmp), None, [0, 0, 61])


if __name__ == "__main__":
    unittest.main()
