#!/usr/bin/env python3
"""Formal equivalence checks for the ML-KEM Montgomery custom instructions.

The three checks deliberately separate the upstream C contract from the total
32-bit wrap semantics implemented by the RTL. No input space is enumerated:
Z3 proves each bit-vector property or returns a concrete counterexample.
"""

from __future__ import annotations

import argparse
import json
import platform
import sys
from datetime import datetime, timezone
from pathlib import Path

try:
    import z3
except ImportError as exc:  # pragma: no cover - exercised only without test deps
    print(
        "ERROR: z3-solver is required; install src/test/python/requirements.txt",
        file=sys.stderr,
    )
    raise SystemExit(2) from exc


Q = 3329
QINV = 62209
UINT16_MOD = 1 << 16
UINT32_MOD = 1 << 32
C_CONTRACT_BOUND = (1 << 31) - 1 - (1 << 15) * Q


def inverted_lift_bv(value32: z3.BitVecRef) -> z3.BitVecRef:
    """The uint16 multiply followed by the int16 lift used by the C reference."""
    low = z3.Extract(15, 0, value32)
    return z3.Extract(15, 0, z3.ZeroExt(16, low) * z3.BitVecVal(QINV, 32))


def rtl_reduce(value32: z3.BitVecRef) -> z3.BitVecRef:
    """Literal bit-vector model of MontgomeryDatapath.reduce (16-bit result)."""
    inverted = inverted_lift_bv(value32)
    t32 = z3.SignExt(16, inverted)
    difference = value32 - t32 * z3.BitVecVal(Q, 32)
    return z3.Extract(31, 16, difference)


def c_reference_bv(value32: z3.BitVecRef) -> z3.BitVecRef:
    """C expression in a wide vector, so its subtraction cannot wrap."""
    value64 = z3.SignExt(32, value32)
    inverted64 = z3.SignExt(48, inverted_lift_bv(value32))
    difference64 = value64 - inverted64 * z3.BitVecVal(Q, 64)
    return z3.Extract(15, 0, difference64 >> 16)


def wrapped_rtl_spec_bv(value32: z3.BitVecRef) -> z3.BitVecRef:
    """Independent total spec: exact wide subtraction truncated to int32."""
    value64 = z3.SignExt(32, value32)
    inverted64 = z3.SignExt(48, inverted_lift_bv(value32))
    exact_difference = value64 - inverted64 * z3.BitVecVal(Q, 64)
    wrapped32 = z3.Extract(31, 0, exact_difference)
    return z3.Extract(31, 16, wrapped32)


def solve_property(
    name: str,
    variables: list[z3.BitVecRef],
    mismatch: z3.BoolRef,
    constraints: list[z3.BoolRef] | None = None,
) -> dict[str, object]:
    solver = z3.Solver()
    for constraint in constraints or []:
        solver.add(constraint)
    solver.add(mismatch)
    status = solver.check()
    result: dict[str, object] = {"name": name, "solver_status": str(status)}

    if status == z3.sat:
        model = solver.model()
        result["pass"] = False
        result["counterexample"] = {
            str(variable): model.eval(variable, model_completion=True).as_long()
            for variable in variables
        }
    elif status == z3.unsat:
        result["pass"] = True
    else:
        result["pass"] = False
        result["reason"] = solver.reason_unknown()
    return result


def run_checks() -> list[dict[str, object]]:
    mul_a = z3.BitVec("mul_a", 16)
    mul_b = z3.BitVec("mul_b", 16)
    product = z3.SignExt(16, mul_a) * z3.SignExt(16, mul_b)
    mul_reference = c_reference_bv(product)
    mul_rtl = rtl_reduce(product)

    red_contract_a = z3.BitVec("red_contract_a", 32)
    contract = z3.And(
        red_contract_a
        > z3.BitVecVal((-C_CONTRACT_BOUND) & (UINT32_MOD - 1), 32),
        red_contract_a < z3.BitVecVal(C_CONTRACT_BOUND, 32),
    )

    red_total_a = z3.BitVec("red_total_a", 32)

    return [
        solve_property(
            "montmul_all_int16_pairs_vs_c_reference",
            [mul_a, mul_b],
            mul_rtl != mul_reference,
        ),
        solve_property(
            "montred_c_contract_vs_c_reference",
            [red_contract_a],
            rtl_reduce(red_contract_a) != c_reference_bv(red_contract_a),
            [contract],
        ),
        solve_property(
            "montred_all_int32_vs_wrapped_rtl_spec",
            [red_total_a],
            rtl_reduce(red_total_a) != wrapped_rtl_spec_bv(red_total_a),
        ),
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--json-out",
        type=Path,
        help="write a machine-readable result file in addition to stdout",
    )
    args = parser.parse_args()

    checks = run_checks()
    report = {
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "python": platform.python_version(),
        "z3": z3.get_version_string(),
        "constants": {
            "q": Q,
            "qinv": QINV,
            "c_contract_exclusive_bound": C_CONTRACT_BOUND,
        },
        "checks": checks,
        "pass": all(bool(check["pass"]) for check in checks),
    }

    for check in checks:
        state = "PASS" if check["pass"] else "FAIL"
        print(f"{state}: {check['name']} ({check['solver_status']})")
        if "counterexample" in check:
            print(f"  counterexample: {check['counterexample']}")

    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print(f"JSON: {args.json_out}")

    return 0 if report["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
