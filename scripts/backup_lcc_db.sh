#!/usr/bin/env bash
# Daily consistent backup of The Forge SQLite database (originally Life Control Center).
# All work runs INSIDE the container (which owns the root-mounted data volume),
# using better-sqlite3's online backup API so the snapshot is consistent even
# while the app writes. Snapshots land in data/backups, swept up by the
# /opt/stacks offsite tar.
set -euo pipefail

CONTAINER="life-control-center"
KEEP=14
STAMP="$(date +%Y-%m-%d)"

docker exec "${CONTAINER}" mkdir -p /app/data/backups

docker exec "${CONTAINER}" node -e "
  const Database = require('better-sqlite3');
  const db = new Database('/app/data/database.sqlite', { readonly: true });
  db.backup('/app/data/backups/db-${STAMP}.sqlite')
    .then(() => { db.close(); process.exit(0); })
    .catch((e) => { console.error(e); process.exit(1); });
"

# Keep only the most recent ${KEEP} snapshots
docker exec "${CONTAINER}" sh -c "ls -1t /app/data/backups/db-*.sqlite 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f"

COUNT="$(docker exec "${CONTAINER}" sh -c 'ls -1 /app/data/backups/db-*.sqlite 2>/dev/null | wc -l' | tr -d ' ')"
echo "[backup_lcc_db] $(date '+%F %T') wrote db-${STAMP}.sqlite (${COUNT} snapshots kept)"
