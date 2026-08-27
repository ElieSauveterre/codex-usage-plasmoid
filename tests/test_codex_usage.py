#!/usr/bin/env python3

import importlib.util
from pathlib import Path
import unittest


HELPER_PATH = (
    Path(__file__).parent.parent / "package" / "contents" / "code" / "codex_usage.py"
)
SPEC = importlib.util.spec_from_file_location("codex_usage", HELPER_PATH)
assert SPEC is not None and SPEC.loader is not None
CODEX_USAGE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CODEX_USAGE)


class NearestResetCreditExpiryTest(unittest.TestCase):
    def test_returns_the_nearest_available_expiry(self) -> None:
        summary = {
            "credits": [
                {"status": "available", "expiresAt": 1_800_000_000},
                {"status": "available", "expiresAt": 1_700_000_000},
                {"status": "available", "expiresAt": None},
            ]
        }

        self.assertEqual(
            CODEX_USAGE.nearest_reset_credit_expiry(summary),
            1_700_000_000,
        )

    def test_ignores_unavailable_and_malformed_credits(self) -> None:
        summary = {
            "credits": [
                {"status": "redeemed", "expiresAt": 1_600_000_000},
                {"status": "available", "expiresAt": True},
                {"status": "available", "expiresAt": "1700000000"},
                None,
            ]
        }

        self.assertIsNone(CODEX_USAGE.nearest_reset_credit_expiry(summary))

    def test_returns_none_when_credit_details_are_unavailable(self) -> None:
        self.assertIsNone(
            CODEX_USAGE.nearest_reset_credit_expiry(
                {"availableCount": 2, "credits": None}
            )
        )


if __name__ == "__main__":
    unittest.main()
