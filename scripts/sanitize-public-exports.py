#!/usr/bin/env python3
"""Sanitize n8n JSON exports before they enter the public repository."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


DISCORD_WEBHOOK = re.compile(
    r"https://(?:discord(?:app)?\.com)/api/webhooks/\d+/[A-Za-z0-9_-]{20,}"
)
CREDENTIALED_URL = re.compile(r"(https?://)[^\s/:@]+:[^\s/@]+@")
GITHUB_TOKEN = re.compile(r"\b(?:ghp|gho|github_pat)_[A-Za-z0-9_]{20,}\b")
JWT = re.compile(
    r"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"
)
SENSITIVE_KEYS = {
    "access_token",
    "accesstoken",
    "api_key",
    "apikey",
    "authorization",
    "client_secret",
    "clientsecret",
    "password",
    "private_key",
    "privatekey",
    "refresh_token",
    "refreshtoken",
    "secret",
    "token",
}


def sanitize_string(value: str) -> str:
    value = DISCORD_WEBHOOK.sub(
        "https://discord.com/api/webhooks/REDACTED/REDACTED", value
    )
    value = CREDENTIALED_URL.sub(r"\1REDACTED@", value)
    value = GITHUB_TOKEN.sub("REDACTED_GITHUB_TOKEN", value)
    return JWT.sub("REDACTED_JWT", value)


def is_runtime_expression(value: str) -> bool:
    stripped = value.strip()
    return (
        not stripped
        or stripped.startswith(("=", "{{", "${"))
        or "REDACTED" in stripped.upper()
        or "PLACEHOLDER" in stripped.upper()
        or stripped.upper().startswith(("YOUR_", "CHANGE_ME", "GENERATE_"))
    )


def sanitize(value, key: str | None = None):
    if isinstance(value, dict):
        return {k: sanitize(v, k) for k, v in value.items()}
    if isinstance(value, list):
        return [sanitize(item) for item in value]
    if isinstance(value, str):
        value = sanitize_string(value)
        if key and key.lower() in SENSITIVE_KEYS and not is_runtime_expression(value):
            return "[REDACTED]"
    return value


def main() -> int:
    if len(sys.argv) != 2:
        print(f"Usage: {Path(sys.argv[0]).name} <export-directory>", file=sys.stderr)
        return 2

    export_dir = Path(sys.argv[1])
    for path in sorted(export_dir.glob("*.json")):
        data = sanitize(json.loads(path.read_text(encoding="utf-8")))
        path.write_text(
            json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
        )

    remaining = []
    for path in sorted(export_dir.glob("*.json")):
        text = path.read_text(encoding="utf-8")
        if any(pattern.search(text) for pattern in (DISCORD_WEBHOOK, GITHUB_TOKEN, JWT)):
            remaining.append(path.name)

    if remaining:
        print("Refusing public export; secret patterns remain in: " + ", ".join(remaining))
        return 1

    print(f"Sanitized {len(list(export_dir.glob('*.json')))} workflow exports")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
