#!/usr/bin/env bash
set -euo pipefail

# Restore from a backup created by backup.sh
# Usage: bash ./scripts/restore.sh ./backups/<timestamp>/backup

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <backup_dir>" >&2
  exit 1
fi

BACKUP_DIR="$1"
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "Backup dir not found: $BACKUP_DIR" >&2
  exit 1
fi

ROOT_USER=${MONGO_ROOT_USER:-root}
ROOT_PASS_FILE=${MONGO_ROOT_PASS_FILE:-./secrets/mongo_root_password.txt}

if [[ ! -f "$ROOT_PASS_FILE" ]]; then
  echo "Missing root password file: $ROOT_PASS_FILE" >&2
  exit 1
fi
ROOT_PASS=$(cat "$ROOT_PASS_FILE")

CID=$(docker compose ps -q mongodb)
docker cp "$BACKUP_DIR" "${CID}:/tmp/restore"

docker compose exec -T mongodb mongorestore \
  --username "$ROOT_USER" \
  --password "$ROOT_PASS" \
  --authenticationDatabase admin \
  /tmp/restore

docker compose exec -T mongodb rm -rf /tmp/restore

echo "Restore completed from: $BACKUP_DIR"
