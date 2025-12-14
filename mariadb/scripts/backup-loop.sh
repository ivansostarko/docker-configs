#!/usr/bin/env bash
set -euo pipefail

ROOT_PW="$(cat /run/secrets/mariadb_root_password)"
DB_HOST="mariadb"
DB_PORT="3306"

mkdir -p /backups

while true; do
  TS="$(date +%F_%H%M%S)"
  OUT="/backups/mariadb_${TS}.sql"

  echo "[$(date -Iseconds)] Starting backup -> ${OUT}"
  mariadb-dump -h "${DB_HOST}" -P "${DB_PORT}" -uroot -p"${ROOT_PW}" \
    --single-transaction --routines --events --triggers --all-databases \
    > "${OUT}"

  echo "[$(date -Iseconds)] Backup complete."

  find /backups -type f -name "mariadb_*.sql" -mtime "+${BACKUP_RETENTION_DAYS}" -delete || true

  sleep "${BACKUP_SCHEDULE_SECONDS}"
done
