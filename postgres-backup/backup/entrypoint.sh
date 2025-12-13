#!/usr/bin/env bash
set -euo pipefail

: "${BACKUP_SCHEDULE:=0 2 * * *}"

CRON_FILE="/state/crontab"
echo "${BACKUP_SCHEDULE} /usr/local/bin/backup.sh >> /state/backup.log 2>&1" > "${CRON_FILE}"

exec /usr/local/bin/supercronic "${CRON_FILE}"
