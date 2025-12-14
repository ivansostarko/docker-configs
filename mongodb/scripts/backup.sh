#!/usr/bin/env bash
set -euo pipefail

# Simple backup via mongodump.
# Output goes to ./backups/<timestamp>

TS=$(date -u +"%Y%m%dT%H%M%SZ")
OUT_DIR="./backups/${TS}"
mkdir -p "$OUT_DIR"

ROOT_USER=${MONGO_ROOT_USER:-root}
ROOT_PASS_FILE=${MONGO_ROOT_PASS_FILE:-./secrets/mongo_root_password.txt}

if [[ ! -f "$ROOT_PASS_FILE" ]]; then
  echo "Missing root password file: $ROOT_PASS_FILE" >&2
  exit 1
fi
ROOT_PASS=$(cat "$ROOT_PASS_FILE")

# Run mongodump inside the mongodb container network namespace.
docker compose exec -T mongodb mongodump \
  --username "$ROOT_USER" \
  --password "$ROOT_PASS" \
  --authenticationDatabase admin \
  --out /tmp/backup

# Copy to host
CID=$(docker compose ps -q mongodb)
docker cp "${CID}:/tmp/backup" "$OUT_DIR"

docker compose exec -T mongodb rm -rf /tmp/backup

echo "Backup completed: ${OUT_DIR}/backup"
