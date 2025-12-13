#!/usr/bin/env bash
set -euo pipefail

log() { printf '%s %s\n' "$(date -Iseconds)" "$*"; }

# Read <VAR> from <VAR>_FILE if set (Docker secrets pattern)
read_file_var() {
  local var="$1"
  local file_var="${var}_FILE"
  local file_path="${!file_var:-}"

  if [[ -n "${file_path}" && -f "${file_path}" ]]; then
    # shellcheck disable=SC2034
    export "${var}=$(< "${file_path}")"
  fi
}

# Load baked defaults (non-sensitive)
if [[ -f /etc/mysql-backup/backup.defaults.env ]]; then
  # shellcheck disable=SC1091
  source /etc/mysql-backup/backup.defaults.env
fi

# Directories
BACKUP_DIR="${BACKUP_DIR:-/backups}"
STATE_DIR="${STATE_DIR:-/state}"
mkdir -p "${BACKUP_DIR}" "${STATE_DIR}"

# Secrets -> env
read_file_var "DB_USER"
read_file_var "DB_PASSWORD"

: "${DB_HOST:?DB_HOST is required}"
: "${DB_PORT:=3306}"
: "${DB_USER:?DB_USER is required (use DB_USER_FILE secret)}"
: "${DB_PASSWORD:?DB_PASSWORD is required (use DB_PASSWORD_FILE secret)}"

# Scheduling
BACKUP_SCHEDULE="${BACKUP_SCHEDULE:-0 3 * * *}"

# Optional: initial backup on startup
if [[ "${INIT_BACKUP:-1}" == "1" ]]; then
  log "INIT_BACKUP=1: running initial backup now."
  if /usr/local/bin/backup.sh; then
    log "Initial backup succeeded."
  else
    log "Initial backup failed (continuing to run scheduler)."
  fi
fi

# Setup cron
log "Installing cron schedule: ${BACKUP_SCHEDULE}"
# Alpine crond reads /etc/crontabs/<user>
echo "${BACKUP_SCHEDULE} /usr/local/bin/backup.sh" > /etc/crontabs/root

log "Starting cron in foreground."
exec crond -f -l 8 -L /dev/stdout
