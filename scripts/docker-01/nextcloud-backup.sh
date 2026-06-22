#!/usr/bin/env bash
set -euo pipefail

DATE="$(date +%F-%H%M)"
BASE="/opt/backups/nextcloud"
DB_DIR="$BASE/db"
DATA_DIR="$BASE/data"
HTML_DIR="$BASE/html"
CONFIG_DIR="$BASE/config"

mkdir -p "$DB_DIR" "$DATA_DIR" "$HTML_DIR" "$CONFIG_DIR"

echo "[*] Copying compose file..."
cp /opt/nextcloud-clean/docker-compose.yml "$CONFIG_DIR/docker-compose.yml"

echo "[*] Dumping database..."
docker exec nextcloud-db pg_dump -U nextcloud nextcloud | gzip > "$DB_DIR/nextcloud-db-$DATE.sql.gz"

echo "[*] Archiving data volume..."
tar -czf "$DATA_DIR/nextcloud-data-$DATE.tar.gz" -C /var/lib/docker/volumes/nextcloud-clean_nc_data/_data .

echo "[*] Archiving html volume..."
tar -czf "$HTML_DIR/nextcloud-html-$DATE.tar.gz" -C /var/lib/docker/volumes/nextcloud-clean_nc_html/_data .

echo "[*] Applying retention (keep last 1)..."
ls -1t "$DB_DIR"/nextcloud-db-*.sql.gz 2>/dev/null | tail -n +2 | xargs -r rm -f
ls -1t "$DATA_DIR"/nextcloud-data-*.tar.gz 2>/dev/null | tail -n +2 | xargs -r rm -f
ls -1t "$HTML_DIR"/nextcloud-html-*.tar.gz 2>/dev/null | tail -n +2 | xargs -r rm -f

echo "[+] Nextcloud backup completed successfully."
