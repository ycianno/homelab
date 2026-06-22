#!/usr/bin/env python3
"""Replace local runtime values with safe examples before public publication."""

import os
from pathlib import Path


ENV_EXAMPLE_VALUES = {
    "POSTGRES_PASSWORD": "generate-a-local-postgres-password",
    "JWT_SECRET": "generate-a-local-jwt-secret-at-least-32-characters",
    "ANON_KEY": "generate-a-local-anon-jwt",
    "SERVICE_ROLE_KEY": "generate-a-local-service-role-jwt",
    "DASHBOARD_PASSWORD": "generate-a-local-dashboard-password",
    "SECRET_KEY_BASE": "generate-a-local-secret-key-base",
    "VAULT_ENC_KEY": "generate-a-local-vault-encryption-key",
    "PG_META_CRYPTO_KEY": "generate-a-local-pg-meta-crypto-key",
    "SMTP_ADMIN_EMAIL": "admin@example.com",
    "SMTP_HOST": "smtp.example.com",
    "SMTP_PORT": "587",
    "SMTP_USER": "smtp-user@example.com",
    "SMTP_PASS": "generate-a-provider-smtp-password",
    "SMTP_SENDER_NAME": "Homelab",
    "OPENAI_API_KEY": "",
    "LOGFLARE_PUBLIC_ACCESS_TOKEN": "generate-a-local-public-access-token",
    "LOGFLARE_PRIVATE_ACCESS_TOKEN": "generate-a-local-private-access-token",
}


def sanitize_env_example(path: Path) -> int:
    if not path.exists():
        return 0

    changes = 0
    output = []
    for line in path.read_text(encoding="utf-8").splitlines(keepends=True):
        if "=" not in line or line.lstrip().startswith("#"):
            output.append(line)
            continue
        key = line.split("=", 1)[0].strip()
        if key not in ENV_EXAMPLE_VALUES:
            output.append(line)
            continue
        newline = "\n" if line.endswith("\n") else ""
        replacement = f"{key}={ENV_EXAMPLE_VALUES[key]}{newline}"
        changes += replacement != line
        output.append(replacement)

    path.write_text("".join(output), encoding="utf-8")
    return changes


def replace_private_domain(root: Path) -> int:
    private_domain = os.environ.get("PRIVATE_DOMAIN", "").strip()
    if not private_domain:
        return 0

    changes = 0
    for path in root.rglob("*"):
        if not path.is_file() or ".git" in path.parts:
            continue
        try:
            content = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        replacement = content.replace(private_domain, "yourdomain.com")
        if replacement != content:
            path.write_text(replacement, encoding="utf-8")
            changes += 1
    return changes


def main() -> None:
    root = Path(os.environ.get("PUBLIC_REPO_ROOT", ".")).resolve()
    env_changes = sanitize_env_example(
        root / "docker/colmado-db/supabase/.env.example"
    )
    domain_changes = replace_private_domain(root)
    print(
        f"Sanitized {env_changes} example values and "
        f"{domain_changes} files containing the private domain"
    )


if __name__ == "__main__":
    main()
