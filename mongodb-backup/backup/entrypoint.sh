#!/usr/bin/env bash
set -euo pipefail

: "${TZ:=Europe/Zagreb}"
: "${BACKUP_CRON:=15 02 * * *}"
: "${BACKUP_DIR:=/backups}"
: "${STATE_DIR:=/state}"

mkdir -p "${BACKUP_DIR}" "${STATE_DIR}"

CRON_FILE="/etc/cron.d/mongo-backup"
echo "${BACKUP_CRON} root /usr/local/bin/backup.sh >> /var/log/mongo-backup.log 2>&1" > "${CRON_FILE}"
chmod 0644 "${CRON_FILE}"

touch /var/log/mongo-backup.log

if [[ "${RUN_ON_STARTUP:-false}" == "true" ]]; then
  /usr/local/bin/backup.sh || true
fi

exec cron -f
