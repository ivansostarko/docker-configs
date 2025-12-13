#!/usr/bin/env bash
set -euo pipefail

read_secret() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing secret file: $path" >&2
    exit 2
  fi
  tr -d '\r\n' < "$path"
}

now_utc() { date -u +"%Y%m%dT%H%M%SZ"; }
epoch() { date +%s; }

PGHOST="$(read_secret /run/secrets/pg_host)"
PGPORT="$(read_secret /run/secrets/pg_port)"
PGUSER="$(read_secret /run/secrets/pg_user)"
PGPASSWORD="$(read_secret /run/secrets/pg_password)"
DBLIST_RAW="$(read_secret /run/secrets/pg_databases)"

export PGHOST PGPORT PGUSER PGPASSWORD
export PGSSLMODE="${PGSSLMODE:-prefer}"

BACKUP_KEEP_DAYS="${BACKUP_KEEP_DAYS:-14}"
BACKUP_KEEP_MIN_COUNT="${BACKUP_KEEP_MIN_COUNT:-14}"
BACKUP_FORMAT="${BACKUP_FORMAT:-custom}"
PG_DUMP_EXTRA_ARGS="${PG_DUMP_EXTRA_ARGS:-}" 

PUSHGATEWAY_URL="${PUSHGATEWAY_URL:-}"
METRICS_JOB="${METRICS_JOB:-pg_backup}"
METRICS_INSTANCE="${METRICS_INSTANCE:-pg_backup}"

mkdir -p /backups /state

touch /state/last_run
echo "$(epoch)" > /state/last_run

START_EPOCH="$(epoch)"
RUN_ID="$(now_utc)"

EXIT_CODE=0
TOTAL_BYTES=0

push_metrics() {
  local exit_code="$1"
  local duration="$2"
  local bytes="$3"
  local ts="$(epoch)"

  [[ -z "${PUSHGATEWAY_URL}" ]] && return 0

  cat <<EOF | curl -fsS --data-binary @- \
    "${PUSHGATEWAY_URL}/metrics/job/${METRICS_JOB}/instance/${METRICS_INSTANCE}" >/dev/null || true
pg_backup_last_run_timestamp ${ts}
pg_backup_last_duration_seconds ${duration}
pg_backup_last_exit_code ${exit_code}
pg_backup_last_bytes ${bytes}
EOF
}

on_exit() {
  local end="$(epoch)"
  local duration=$(( end - START_EPOCH ))
  push_metrics "${EXIT_CODE}" "${duration}" "${TOTAL_BYTES}"
}
trap on_exit EXIT

# Normalize DB list: allow comma or space separated
DBLIST="$(echo "${DBLIST_RAW}" | tr ',' ' ')"

echo "[$(date)] Starting pg backups. host=${PGHOST} port=${PGPORT} user=${PGUSER} dbs=${DBLIST} format=${BACKUP_FORMAT}"

for DB in ${DBLIST}; do
  DB_DIR="/backups/${DB}"
  mkdir -p "${DB_DIR}"

  if [[ "${BACKUP_FORMAT}" == "custom" ]]; then
    OUT="${DB_DIR}/${DB}_${RUN_ID}.dump"
    echo "[$(date)] Backing up ${DB} -> ${OUT}"
    if ! pg_dump -d "${DB}" -Fc ${PG_DUMP_EXTRA_ARGS} -f "${OUT}"; then
      EXIT_CODE=10
      echo "[$(date)] ERROR: pg_dump failed for ${DB}" >&2
      exit "${EXIT_CODE}"
    fi
    # Archive integrity check
    pg_restore -l "${OUT}" >/dev/null

  elif [[ "${BACKUP_FORMAT}" == "plain" ]]; then
    OUT="${DB_DIR}/${DB}_${RUN_ID}.sql.gz"
    echo "[$(date)] Backing up ${DB} -> ${OUT}"
    if ! pg_dump -d "${DB}" ${PG_DUMP_EXTRA_ARGS} | gzip -c > "${OUT}"; then
      EXIT_CODE=11
      echo "[$(date)] ERROR: pg_dump+gzip failed for ${DB}" >&2
      exit "${EXIT_CODE}"
    fi
    gzip -t "${OUT}"

  else
    echo "Invalid BACKUP_FORMAT=${BACKUP_FORMAT} (use: custom|plain)" >&2
    EXIT_CODE=3
    exit "${EXIT_CODE}"
  fi

  BYTES="$(stat -c%s "${OUT}")"
  TOTAL_BYTES=$(( TOTAL_BYTES + BYTES ))

  sha256sum "${OUT}" > "${OUT}.sha256"
  ln -sf "$(basename "${OUT}")" "${DB_DIR}/latest"
  ln -sf "$(basename "${OUT}.sha256")" "${DB_DIR}/latest.sha256"

  echo "[$(date)] Done ${DB}. size=${BYTES} bytes"
done

# Retention per DB directory
for DB in ${DBLIST}; do
  DB_DIR="/backups/${DB}"

  # Delete by age
  find "${DB_DIR}" -type f \( -name "*.dump" -o -name "*.sql.gz" -o -name "*.sha256" \) -mtime +"${BACKUP_KEEP_DAYS}" -print0 \
    | xargs -0 -r rm -f

  # Enforce minimum count (keep newest N)
  mapfile -t FILES2 < <(ls -1t "${DB_DIR}"/*.{dump,sql.gz} 2>/dev/null || true)
  if (( ${#FILES2[@]} > BACKUP_KEEP_MIN_COUNT )); then
    for (( i=BACKUP_KEEP_MIN_COUNT; i<${#FILES2[@]}; i++ )); do
      rm -f "${FILES2[$i]}" "${FILES2[$i]}.sha256" || true
    done
  fi
done

echo "$(epoch)" > /state/last_success
echo "[$(date)] All backups completed successfully. total_bytes=${TOTAL_BYTES}"
exit 0
