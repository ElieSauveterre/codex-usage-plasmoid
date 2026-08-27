#!/usr/bin/env python3
"""Read ChatGPT-backed Codex limits through the documented Codex app-server."""

from __future__ import annotations

import argparse
import json
import os
import selectors
import shutil
import subprocess
import sys
import time
from typing import Any


def emit(payload: dict[str, Any]) -> None:
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))


def sanitized_window(window: Any) -> dict[str, Any] | None:
    if not isinstance(window, dict):
        return None

    used = window.get("usedPercent")
    if not isinstance(used, (int, float)):
        return None

    used = min(100.0, max(0.0, float(used)))
    return {
        "usedPercent": round(used, 1),
        "remainingPercent": round(100.0 - used, 1),
        "windowDurationMins": window.get("windowDurationMins"),
        "resetsAt": window.get("resetsAt"),
    }


def sanitized_limit(limit_id: str, raw: Any) -> dict[str, Any] | None:
    if not isinstance(raw, dict):
        return None

    primary = sanitized_window(raw.get("primary"))
    secondary = sanitized_window(raw.get("secondary"))
    if primary is None and secondary is None:
        return None

    return {
        "id": str(raw.get("limitId") or limit_id),
        "name": raw.get("limitName"),
        "planType": raw.get("planType"),
        "primary": primary,
        "secondary": secondary,
        "reachedType": raw.get("rateLimitReachedType"),
    }


def nearest_reset_credit_expiry(raw: Any) -> int | None:
    if not isinstance(raw, dict):
        return None

    credits = raw.get("credits")
    if not isinstance(credits, list):
        return None

    expiries = []
    for credit in credits:
        if not isinstance(credit, dict):
            continue
        if credit.get("status") not in (None, "available"):
            continue

        expires_at = credit.get("expiresAt")
        if (
            isinstance(expires_at, (int, float))
            and not isinstance(expires_at, bool)
            and expires_at > 0
        ):
            expiries.append(int(expires_at))

    return min(expiries) if expiries else None


def read_limits(timeout_seconds: float) -> dict[str, Any]:
    codex_binary = os.environ.get("CODEX_BIN") or shutil.which("codex")
    if not codex_binary:
        raise RuntimeError("Codex CLI introuvable dans PATH")

    process = subprocess.Popen(
        [codex_binary, "app-server"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        encoding="utf-8",
        bufsize=1,
    )

    messages = [
        {
            "method": "initialize",
            "id": 0,
            "params": {
                "clientInfo": {
                    "name": "kde_codex_usage_widget",
                    "title": "KDE Codex Usage Widget",
                    "version": "0.1.0",
                }
            },
        },
        {"method": "initialized", "params": {}},
        {"method": "account/rateLimits/read", "id": 1},
    ]

    try:
        if process.stdin is None or process.stdout is None:
            raise RuntimeError("Impossible de communiquer avec Codex app-server")

        for message in messages:
            process.stdin.write(json.dumps(message, separators=(",", ":")) + "\n")
        process.stdin.flush()

        selector = selectors.DefaultSelector()
        selector.register(process.stdout, selectors.EVENT_READ)
        deadline = time.monotonic() + timeout_seconds

        while time.monotonic() < deadline:
            remaining = max(0.0, deadline - time.monotonic())
            if not selector.select(timeout=min(0.5, remaining)):
                if process.poll() is not None:
                    raise RuntimeError("Codex app-server s'est arrêté sans réponse")
                continue

            line = process.stdout.readline()
            if not line:
                if process.poll() is not None:
                    raise RuntimeError("Codex app-server s'est arrêté sans réponse")
                continue

            try:
                message = json.loads(line)
            except json.JSONDecodeError:
                continue

            if message.get("id") != 1:
                continue

            if "error" in message:
                detail = message.get("error", {}).get("message") or "réponse refusée"
                raise RuntimeError(f"Codex: {detail}")

            result = message.get("result") or {}
            raw_limits = result.get("rateLimitsByLimitId")
            if not isinstance(raw_limits, dict) or not raw_limits:
                fallback = result.get("rateLimits")
                raw_limits = {"codex": fallback} if fallback else {}

            limits = []
            for limit_id, raw_limit in raw_limits.items():
                limit = sanitized_limit(str(limit_id), raw_limit)
                if limit is not None:
                    limits.append(limit)

            if not limits:
                raise RuntimeError("Aucune limite Codex disponible pour ce compte")

            reset_credits = result.get("rateLimitResetCredits") or {}
            return {
                "ok": True,
                "updatedAt": int(time.time()),
                "limits": limits,
                "resetCreditsAvailable": int(reset_credits.get("availableCount") or 0),
                "nextResetCreditExpiresAt": nearest_reset_credit_expiry(reset_credits),
            }

        raise RuntimeError("Délai dépassé en attendant les limites Codex")
    finally:
        if process.stdin is not None:
            process.stdin.close()
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=2)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--timeout", type=float, default=15.0)
    parser.add_argument("--request-id", help="Ignored cache-busting value from Plasma")
    args = parser.parse_args()

    try:
        emit(read_limits(max(2.0, args.timeout)))
        return 0
    except Exception as error:  # Keep the executable data engine contract simple.
        emit({"ok": False, "error": str(error), "updatedAt": int(time.time())})
        return 1


if __name__ == "__main__":
    sys.exit(main())
