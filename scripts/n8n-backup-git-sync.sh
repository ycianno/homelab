#!/bin/bash
set -e

REPO_DIR="/home/yzee/repos/homelab"
DATE_STR=$(date +%F)
EXPORT_DIR="${REPO_DIR}/n8n-workflows/active"

echo "Starting n8n workflow export backup..."

# Ensure we are in the repo directory
cd "${REPO_DIR}"

# Pull latest changes from remote just in case
git pull origin main

# Create active backup directory if it doesn't exist
mkdir -p "${EXPORT_DIR}"

# Clean up old files in active directory to capture deleted workflows
rm -f "${EXPORT_DIR}"/*.json

# Run n8n CLI export command inside the container to /tmp
docker exec n8n n8n export:workflow --backup --output=/tmp/n8n-workflows-export

# Copy exported JSON files to the repo active export directory
docker cp n8n:/tmp/n8n-workflows-export/. "${EXPORT_DIR}/"

# Clean up tmp files inside the container
docker exec n8n rm -rf /tmp/n8n-workflows-export

# Remove literal credentials that may be embedded directly in workflow nodes.
python3 "${REPO_DIR}/scripts/sanitize-public-exports.py" "${EXPORT_DIR}"
PUBLIC_REPO_ROOT="${REPO_DIR}" python3 "${REPO_DIR}/scripts/sanitize-public-config.py"

echo "Export completed successfully. Checking for changes..."

# Check if there are changes to commit in n8n-workflows
if [[ -n $(git status --porcelain n8n-workflows/) ]]; then
  echo "Changes detected in n8n-workflows/active. Committing and pushing..."
  git add n8n-workflows/
  git commit -m "Backup: Auto-update n8n workflows export for ${DATE_STR}"
  git push origin main
  echo "Backup successfully committed and pushed to GitHub (origin)."
else
  echo "No changes detected in n8n-workflows. Skipping Git commit."
fi
