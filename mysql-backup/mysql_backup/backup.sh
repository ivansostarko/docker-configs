#!/usr/bin/env bash
set -euo pipefail

log() { printf '%s %s\n' "$(date -Iseconds)" "$*"; }

# Required
: "${DB_HOST:?}"
: "${DB_PORT:=3306}"
: "${DB_USER:?}"
: "${DB_PASSWORD:?}"

# Optional
BACKUP_DIR="${BACKUP_DIR:-/backups}"
STATE_DIR="${STATE_DIR:-/state}"
BACKUP_PREFIX="${BACKUP_PREFIX:-mysql}"
DB_NAMES="${DB_NAMES:-all}"                      # all|db1,db2
BACKUP_COMPRESS="${BACKUP_COMPRESS:-gzip}"       # gzip|none
BACKUP_KEEP_LAST="${BACKUP_KEEP_LAST:-30}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-14}"
PUSHGATEWAY_URL="${PUSHGATEWAY_URL:-}"
METRICS_JOB="${METRICS_JOB:-mysql_backup}"
METRICS_INSTANCE="${METRICS_INSTANCE:-mysql_backup}"

BACKUP_NICE="${BACKUP_NICE:-10}"
BACKUP_IONICE_CLASS="${BACKUP_IONICE_CLASS:-2}"
BACKUP_IONICE_LEVEL="${BACKUP_IONICE_LEVEL:-7}"

DEFAULT_DUMP_ARGS="${DEFAULT_DUMP_ARGS:-"--single-transaction --quick --routines --events --triggers --hex-blob --set-gtid-purged=OFF"}"
BACKUP_EXTRA_DUMP_ARGS="${BACKUP_EXTRA_DUMP_ARGS:-}"
MYSQL_SSL_MODE="${MYSQL_SSL_MODE:-}"

mkdir -p "${BACKUP_DIR}" "${STATE_DIR}"

timestamp="$(date '+%F_%H-%M-%S')"
start_ts="$(date +%s)"

# Determine dump target args + filename hint
dump_target_args=()
name_hint="all"

if [[ "${DB_NAMES}" == "all" || "${DB_NAMES}" == "--all-databases" ]]; then
  dump_target_args+=(--all-databases)
  name_hint="all"
else
  # Comma-separated list -> mysqldump accepts: --databases db1 db2 ...
  IFS=',' read -r -a db_array <<< "${DB_NAMES}"
  dump_target_args+=(--databases "${db_array[@]}")
  # For filename, keep it compact
  name_hint="$(echo "${DB_NAMES}" | tr ',' '-')"
fi

# SSL mode support (MySQL 8 client)
ssl_args=()
if [[ -n "${MYSQL_SSL_MODE}" ]]; then
  ssl_args+=(--ssl-mode="${MYSQL_SSL_MODE}")
fi

# Output path
out_base="${BACKUP_PREFIX}_${name_hint}_${timestamp}.sql"
out_path="${BACKUP_DIR}/${out_base}"

# Dump command
dump_cmd=(mysqldump
  --host="${DB_HOST}"
  --port="${DB_PORT}"
  --user="${DB_USER}"
  ${DEFAULT_DUMP_ARGS}
  ${BACKUP_EXTRA_DUMP_ARGS}
  "${dump_target_args[@]}"
  "${ssl_args[@]}"
)

# Avoid password in process list by using MYSQL_PWD (still sensitive inside container)
export MYSQL_PWD="${DB_PASSWORD}"

log "Starting backup: ${out_base}"
log "Host=${DB_HOST}:${DB_PORT} DB_NAMES=${DB_NAMES} compress=${BACKUP_COMPRESS}"

exit_code=0
size_bytes=0

set +e
if [[ "${BACKUP_COMPRESS}" == "gzip" ]]; then
  out_path="${out_path}.gz"
  nice -n "${BACKUP_NICE}" ionice -c "${BACKUP_IONICE_CLASS}" -n "${BACKUP_IONICE_LEVEL}" \
    "${dump_cmd[@]}" | gzip -c > "${out_path}"
  exit_code=$?
else
  nice -n "${BACKUP_NICE}" ionice -c "${BACKUP_IONICE_CLASS}" -n "${BACKUP_IONICE_LEVEL}" \
    "${dump_cmd[@]}" > "${out_path}"
  exit_code=$?
fi
set -e

end_ts="$(date +%s)"
duration="$((end_ts - start_ts))"

if [[ "${exit_code}" -eq 0 ]]; then
  size_bytes="$(stat -c %s "${out_path}" 2>/dev/null || echo 0)"
  log "Backup OK: ${out_path} (${size_bytes} bytes) duration=${duration}s"

  # Mark success
  echo "${end_ts}" > "${STATE_DIR}/last_success_epoch"
  echo "${out_path}" > "${STATE_DIR}/last_success_path"
else
  log "Backup FAILED: exit_code=${exit_code} duration=${duration}s"
fi

# Retention: by age
if [[ -n "${BACKUP_RETENTION_DAYS}" && "${BACKUP_RETENTION_DAYS}" -gt 0 ]]; then
  find "${BACKUP_DIR}" -type f -name "${BACKUP_PREFIX}_*.sql*" -mtime +"${BACKUP_RETENTION_DAYS}" -print -delete || true
fi

# Retention: keep last N
if [[ -n "${BACKUP_KEEP_LAST}" && "${BACKUP_KEEP_LAST}" -gt 0 ]]; then
  # List newest first, delete everything after N
  ls -1t "${BACKUP_DIR}"/"${BACKUP_PREFIX}"_*.sql* 2>/dev/null | tail -n +"$((BACKUP_KEEP_LAST + 1))" | xargs -r rm -f
fi

# Pushgateway metrics (optional)
push_metrics() {
  local metrics payload_url
  metrics="$1"
  payload_url="${PUSHGATEWAY_URL%/}/metrics/job/${METRICS_JOB}/instance/${METRICS_INSTANCE}"

  curl -sS --max-time 10 \
    --data-binary "${metrics}" \
    -X PUT "${payload_url}" >/dev/null || true
}

if [[ -n "${PUSHGATEWAY_URL}" ]]; then
  metrics_payload=""
  metrics_payload+="mysql_backup_last_exit_code ${exit_code}\n"
  metrics_payload+="mysql_backup_last_duration_seconds ${duration}\n"
  metrics_payload+="mysql_backup_last_success_timestamp_seconds $(cat "${STATE_DIR}/last_success_epoch" 2>/dev/null || echo 0)\n"
  metrics_payload+="mysql_backup_last_size_bytes ${size_bytes}\n"
  push_metrics "$(printf "%b" "${metrics_payload}")"
fi

exit "${exit_code}"
