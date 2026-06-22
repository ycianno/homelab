#!/usr/bin/env bash
# backup_server.sh - Full Proxmox daily backup for colmado-db, docker01, and automation-01
# Streaming backups directly to local /home/yzee/backups on automation-01.
# Keeps a strict retention of only the last 2 backups per server type.

set -euo pipefail

# Configurations
BACKUP_DIR="/home/yzee/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "========================================="
echo "Starting Homelab Unified Daily Backup"
echo "Time: $(date)"
echo "Destination: ${BACKUP_DIR}"
echo "========================================="

# Ensure backup directory exists
mkdir -p "${BACKUP_DIR}"

# Helper function to delete old backups, keeping only the last 2 (alphabetical/date sort)
cleanup_old_backups() {
    local pattern="$1"
    local count
    count=$(find "${BACKUP_DIR}" -name "${pattern}" | wc -l)
    if [ "${count}" -gt 2 ]; then
        echo "   Cleaning up old backups for pattern '${pattern}' (keeping last 2)..."
        find "${BACKUP_DIR}" -name "${pattern}" -print0 | tr '\0' '\n' | sort | head -n -2 | while read -r file; do
            if [ -n "${file}" ] && [ -f "${file}" ]; then
                rm -v "${file}"
            fi
        done
        echo "   Cleanup complete."
    else
        echo "   Retention OK (current files: ${count}/2)."
    fi
}

# Helper function to verify size
verify_backup() {
    local file_path="$1"
    if [ -s "${file_path}" ]; then
        echo "✅ Backup OK: $(basename "${file_path}") ($(du -sh "${file_path}" | cut -f1))"
        return 0
    else
        echo "❌ Error: Backup file is empty or missing: ${file_path}"
        rm -f "${file_path}"
        return 1
    fi
}

# --- 1. colmado-db: Vitrina Supabase DB Backup ---
echo "[1/4] Backing up Vitrina Database (colmado-db)..."
VITRINA_FILE="vitrina_db_${TIMESTAMP}.sql.gz"
VITRINA_PATH="${BACKUP_DIR}/${VITRINA_FILE}"

if ssh -o ConnectTimeout=10 colmado-db "docker exec -t supabase-db pg_dump -U postgres postgres" | gzip > "${VITRINA_PATH}"; then
    verify_backup "${VITRINA_PATH}"
    cleanup_old_backups "vitrina_db_*.sql.gz"
else
    echo "❌ Error: Failed to backup Vitrina DB."
fi
echo ""

# --- 2. docker01: Nextcloud DB Backup ---
echo "[2/4] Backing up Nextcloud Database (docker01)..."
NEXTCLOUD_FILE="docker01_nextcloud_${TIMESTAMP}.sql.gz"
NEXTCLOUD_PATH="${BACKUP_DIR}/${NEXTCLOUD_FILE}"

if ssh -o ConnectTimeout=10 docker01 "docker exec -t nextcloud-db pg_dump -U nextcloud nextcloud" | gzip > "${NEXTCLOUD_PATH}"; then
    verify_backup "${NEXTCLOUD_PATH}"
    cleanup_old_backups "docker01_nextcloud_*.sql.gz"
else
    echo "❌ Error: Failed to backup Nextcloud DB."
fi
echo ""

# --- 3. docker01: Configuration Stack Backup ---
echo "[3/4] Backing up Docker Configuration Stacks (docker01)..."
DOCKER01_CONFIG_FILE="docker01_config_${TIMESTAMP}.tar.gz"
DOCKER01_CONFIG_PATH="${BACKUP_DIR}/${DOCKER01_CONFIG_FILE}"

if ssh -o ConnectTimeout=10 docker01 "tar --ignore-failed-read -czf - --exclude='*/cache/*' --exclude='*/logs/*' --exclude='*/log/*' /opt/stacks /opt/nextcloud-clean 2>/dev/null" > "${DOCKER01_CONFIG_PATH}"; then
    verify_backup "${DOCKER01_CONFIG_PATH}"
    cleanup_old_backups "docker01_config_*.tar.gz"
else
    echo "❌ Error: Failed to backup docker01 configs."
fi
echo ""

# --- 4. automation-01: Control Plane Configurations ---
echo "[4/4] Backing up Control Plane Stacks (automation-01)..."
AUTO01_CONFIG_FILE="automation01_config_${TIMESTAMP}.tar.gz"
AUTO01_CONFIG_PATH="${BACKUP_DIR}/${AUTO01_CONFIG_FILE}"

if tar --ignore-failed-read -czf - --exclude='*/cache/*' --exclude='*/logs/*' --exclude='*/log/*' /opt/stacks 2>/dev/null > "${AUTO01_CONFIG_PATH}"; then
    verify_backup "${AUTO01_CONFIG_PATH}"
    cleanup_old_backups "automation01_config_*.tar.gz"
else
    echo "❌ Error: Failed to backup automation-01 configs."
fi

echo "========================================="
echo "Backup Process Finished Successfully!"
echo "========================================="
