#!/usr/bin/env python3
"""Independent Keccak-f[1600] reference used by RTL differential tests."""

from __future__ import annotations

import argparse
import json
import random
from pathlib import Path

MASK64 = (1 << 64) - 1
ROUND_CONSTANTS = (
    0x0000000000000001, 0x0000000000008082, 0x800000000000808A,
    0x8000000080008000, 0x000000000000808B, 0x0000000080000001,
    0x8000000080008081, 0x8000000000008009, 0x000000000000008A,
    0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
    0x000000008000808B, 0x800000000000008B, 0x8000000000008089,
    0x8000000000008003, 0x8000000000008002, 0x8000000000000080,
    0x000000000000800A, 0x800000008000000A, 0x8000000080008081,
    0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
)
RHO = (
    0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43,
    25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14,
)
ZERO_KNOWN_ANSWER = (
    0xF1258F7940E1DDE7, 0x84D5CCF933C0478A, 0xD598261EA65AA9EE,
    0xBD1547306F80494D, 0x8B284E056253D057, 0xFF97A42D7F8E6FD4,
    0x90FEE5A0A44647C4, 0x8C5BDA0CD6192E76, 0xAD30A6F71B19059C,
    0x30935AB7D08FFC64, 0xEB5AA93F2317D635, 0xA9A6E6260D712103,
    0x81A57C16DBCF555F, 0x43B831CD0347C826, 0x01F22F1A11A5569F,
    0x05E5635A21D9AE61, 0x64BEFEF28CC970F2, 0x613670957BC46611,
    0xB87C5A554FD00ECB, 0x8C3EE88A1CCF32C8, 0x940C7922AE3A2614,
    0x1841F924A2C509E4, 0x16F53526E70465C2, 0x75F644E97F30A13B,
    0xEAF1FF7B5CECA249,
)


def rol64(value: int, amount: int) -> int:
    if amount == 0:
        return value & MASK64
    return ((value << amount) | (value >> (64 - amount))) & MASK64


def round_steps(state: list[int], rc: int) -> dict[str, list[int]]:
    a = [value & MASK64 for value in state]
    c = [a[x] ^ a[x + 5] ^ a[x + 10] ^ a[x + 15] ^ a[x + 20] for x in range(5)]
    d = [c[(x - 1) % 5] ^ rol64(c[(x + 1) % 5], 1) for x in range(5)]
    theta = [(a[i] ^ d[i % 5]) & MASK64 for i in range(25)]
    rho_pi = [0] * 25
    for y in range(5):
        for x in range(5):
            source = x + 5 * y
            destination = y + 5 * ((2 * x + 3 * y) % 5)
            rho_pi[destination] = rol64(theta[source], RHO[source])
    chi = [0] * 25
    for y in range(5):
        for x in range(5):
            i = x + 5 * y
            chi[i] = (rho_pi[i] ^ ((~rho_pi[(x + 1) % 5 + 5 * y]) &
                                     rho_pi[(x + 2) % 5 + 5 * y])) & MASK64
    iota = chi.copy()
    iota[0] ^= rc
    return {"theta": theta, "rho_pi": rho_pi, "chi": chi, "iota": iota}


def permute(state: list[int]) -> list[int]:
    current = list(state)
    for rc in ROUND_CONSTANTS:
        current = round_steps(current, rc)["iota"]
    return current


def hex_state(state: list[int]) -> list[str]:
    return [f"{value:016x}" for value in state]


def self_test(samples: int) -> None:
    assert permute([0] * 25) == list(ZERO_KNOWN_ANSWER)
    rng = random.Random(0x4B454343414B)
    for _ in range(samples):
        state = [rng.getrandbits(64) for _ in range(25)]
        assert len(permute(state)) == 25


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state", help="JSON array containing 25 integers or hex strings")
    parser.add_argument("--round", type=int, choices=range(24))
    parser.add_argument("--json-out", type=Path)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--samples", type=int, default=1000)
    args = parser.parse_args()

    if args.self_test:
        self_test(args.samples)
        result = {"status": "PASS", "known_answer": hex_state(list(ZERO_KNOWN_ANSWER)),
                  "samples": args.samples}
    else:
        raw = json.loads(args.state) if args.state else [0] * 25
        if len(raw) != 25:
            raise SystemExit("state must contain exactly 25 lanes")
        state = [int(value, 0) if isinstance(value, str) else int(value) for value in raw]
        if args.round is None:
            result = {"state": hex_state(permute(state))}
        else:
            steps = round_steps(state, ROUND_CONSTANTS[args.round])
            result = {name: hex_state(value) for name, value in steps.items()}

    encoded = json.dumps(result, indent=2, sort_keys=True)
    if args.json_out:
        args.json_out.write_text(encoded + "\n", encoding="utf-8")
    print(encoded)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
