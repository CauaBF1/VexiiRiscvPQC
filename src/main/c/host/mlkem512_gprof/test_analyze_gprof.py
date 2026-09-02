import tempfile
import unittest
from pathlib import Path

from analyze_gprof import (
    FlatEntry,
    is_structural_candidate,
    normalize_symbol,
    parse_flat_profile,
    write_entries,
)


FIXTURE = """Flat profile:

Each sample counts as 0.01 seconds.
  %   cumulative   self              self     total
 time   seconds   seconds    calls   s/call   s/call  name
 36.50      4.07     4.07 14929600     0.00     0.00  mlk_keccakf1600_permute_c
 18.65      6.15     2.08  1750000     0.00     0.00  PQCP_MLKEM_NATIVE_MLKEM512_poly_ntt
  0.00      6.15     0.00                             helper_without_calls

Call graph
"""


class ParseFlatProfileTest(unittest.TestCase):
    def test_parses_entries_with_and_without_calls(self):
        entries = parse_flat_profile(FIXTURE)
        self.assertEqual(len(entries), 3)
        self.assertEqual(entries[0].calls, 14929600)
        self.assertEqual(entries[1].display_symbol, "poly_ntt")
        self.assertIsNone(entries[2].calls)

    def test_rejects_missing_table(self):
        with self.assertRaises(ValueError):
            parse_flat_profile("not a profile")

    def test_writes_csv_and_json(self):
        entries = parse_flat_profile(FIXTURE)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            write_entries(entries, root / "profile.csv", root / "profile.json")
            self.assertIn("display_symbol", (root / "profile.csv").read_text())
            self.assertIn("poly_ntt", (root / "profile.json").read_text())

    def test_normalizes_only_known_prefix(self):
        self.assertEqual(
            normalize_symbol("PQCP_MLKEM_NATIVE_MLKEM512_poly_ntt"), "poly_ntt"
        )
        self.assertEqual(normalize_symbol("mlk_keccak"), "mlk_keccak")

    def test_identifies_inlined_arithmetic_candidates(self):
        entry = FlatEntry(9.7, 1.1, 0.2, 100, 0.0, 0.0, "mlk_fqmul")
        cold = FlatEntry(0.4, 1.1, 0.01, 100, 0.0, 0.0, "mlk_barrett_reduce")
        generic = FlatEntry(9.7, 1.1, 0.2, 100, 0.0, 0.0, "helper")
        self.assertTrue(is_structural_candidate(entry))
        self.assertFalse(is_structural_candidate(cold))
        self.assertFalse(is_structural_candidate(generic))


if __name__ == "__main__":
    unittest.main()
