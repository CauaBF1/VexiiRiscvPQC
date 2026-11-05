#!/usr/bin/env python3
"""Copy a patched mlkem-native checkout and add optional runtime Montgomery selection.

The input checkout and its local modifications are preserved. The generated
overlay must be built with MLK_RUNTIME_ACCEL and the project runtime header.
"""
import argparse
import hashlib
import json
import shutil
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    def hashes(root):
        return {str(f.relative_to(root)): hashlib.sha256(f.read_bytes()).hexdigest()
                for f in sorted(root.rglob("*")) if f.is_file()
                and not any(v in f.relative_to(root).parts for v in (".git", "build", "__pycache__"))
                and f.name != "runtime_overlay.json"}
    before = hashes(args.source)
    manifest = args.destination / "runtime_overlay.json"
    if args.destination.exists():
        if not manifest.is_file():
            raise SystemExit("Existing overlay has no manifest; refusing to overwrite")
        saved = json.loads(manifest.read_text())
        if saved.get("source_sha256") == before and saved.get("overlay_sha256") == hashes(args.destination):
            return
        # The overlay is a derived artifact owned by this script (it has our manifest):
        # regenerate it after a `git pull` instead of forcing a new build directory.
        print(f"runtime overlay desatualizado; regenerando {args.destination}")
        shutil.rmtree(args.destination)
    args.destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(args.source, args.destination, ignore=shutil.ignore_patterns(".git", "build", "__pycache__"))
    changes = {}
    for name in ["poly.c", "poly_k.c"]:
        path = args.destination / "mlkem/src" / name
        original = path.read_text()
        if name == "poly.c":
            anchor = "  {\n    int32_t hw;\n    __asm__(\".insn r 0x0B, 0, 1,"
            if original.count(anchor) != 1:
                raise ValueError("Expected the existing Montgomery multiply hook")
            modified = original.replace(anchor, """#if defined(MLK_RUNTIME_ACCEL)
  if (mlkem_runtime_mode == 0) {
    res = mlk_montgomery_reduce((int32_t)a * (int32_t)b);
  } else
#endif
""" + anchor)
        else:
            anchor = "static MLK_INLINE int16_t mlk_montred_hw(int32_t a)\n{\n"
            if original.count(anchor) != 1:
                raise ValueError("Expected the existing Montgomery reduction hook")
            modified = original.replace(anchor, anchor + """#if defined(MLK_RUNTIME_ACCEL)
  if (mlkem_runtime_mode == 0) return mlk_montgomery_reduce(a);
#endif
""")
        path.write_text(modified)
        changes[name] = {"before": hashlib.sha256(original.encode()).hexdigest(),
                         "after": hashlib.sha256(modified.encode()).hexdigest()}
    (args.destination / "runtime_overlay.json").write_text(json.dumps({"source_sha256": before, "overlay_sha256": hashes(args.destination), "changes": changes}, indent=2) + "\n")


if __name__ == "__main__":
    main()
