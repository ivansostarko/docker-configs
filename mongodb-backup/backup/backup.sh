#!/usr/bin/env bash
set -euo pipefail

now_epoch="$(date +%s)"
ts="$(date +%Y%m%dT%H%M%S)"
host_tag="$(hostname)"

: "${BACKUP_DIR:=/backups}"
: "${STATE_DIR:=/state}"
: "${RETENTION_DAYS:=14}"
: "${USE_OPLOG:=true}"
: "${MONGODUMP_EXTRA_ARGS:=}"

: "${ENCRYPTION_ENABLED:=false}"
: "${ENCRYPTION_CIPHER:=aes-256-cbc}"
: "${ENCRYPTION_PBKDF2:=true}"

: "${S3_ENABLED:=false}"
: "${S3_BUCKET:=}"
: "${S3_PREFIX:=mongodb}"
: "${AWS_REGION:=eu-central-1}"
: "${S3_ENDPOINT:=}"

: "${PUSHGATEWAY_URL:=}"
: "${METRICS_JOB:=mongodb_backup}"
: "${METRICS_INSTANCE:=mongo_backup}"

read_secret() {
  local f="${1:-}"
  [[ -n "${f}" && -f "${f}" ]] || return 1
  tr -d '\r\n' < "${f}"
}

MONGO_URI="$(read_secret "${MONGO_URI_FILE:-}" || true)"
if [[ -z "${MONGO_URI}" ]]; then
  echo "ERROR: MONGO_URI is empty. Provide it via MONGO_URI_FILE secret."
  exit 2
fi

AWS_ACCESS_KEY_ID="$(read_secret "${AWS_ACCESS_KEY_ID_FILE:-}" || true)"
AWS_SECRET_ACCESS_KEY="$(read_secret "${AWS_SECRET_ACCESS_KEY_FILE:-}" || true)"
ENCRYPTION_PASSPHRASE="$(read_secret "${ENCRYPTION_PASSPHRASE_FILE:-}" || true)"

backup_name="mongodump_${host_tag}_${ts}.archive.gz"
backup_path="${BACKUP_DIR}/${backup_name}"
sha_path="${backup_path}.sha256"

start_epoch="$(date +%s)"
exit_code=0
bytes=0

oplog_arg=()
if [[ "${USE_OPLOG}" == "true" ]]; then
  oplog_arg+=(--oplog)
fi

echo "Starting mongodump: ${backup_name}"

set +e
mongodump   --uri="${MONGO_URI}"   --archive="${backup_path}"   --gzip   "${oplog_arg[@]}"   ${MONGODUMP_EXTRA_ARGS} 2>&1
exit_code=$?
set -e

if [[ $exit_code -ne 0 ]]; then
  echo "ERROR: mongodump failed with exit code ${exit_code}"
else
  sha256sum "${backup_path}" > "${sha_path}"
  bytes="$(stat -c%s "${backup_path}" 2>/dev/null || wc -c < "${backup_path}")"

  if [[ "${ENCRYPTION_ENABLED}" == "true" ]]; then
    if [[ -z "${ENCRYPTION_PASSPHRASE}" ]]; then
      echo "ERROR: ENCRYPTION_ENABLED=true but passphrase secret is empty."
      exit_code=3
    else
      enc_path="${backup_path}.enc"
      pbkdf2_flag=()
      [[ "${ENCRYPTION_PBKDF2}" == "true" ]] && pbkdf2_flag=(-pbkdf2)

      openssl enc -"${ENCRYPTION_CIPHER}" "${pbkdf2_flag[@]}"         -salt -pass pass:"${ENCRYPTION_PASSPHRASE}"         -in "${backup_path}" -out "${enc_path}"

      rm -f "${backup_path}"
      mv "${enc_path}" "${backup_path}"
      sha256sum "${backup_path}" > "${sha_path}"
      bytes="$(stat -c%s "${backup_path}" 2>/dev/null || wc -c < "${backup_path}")"
    fi
  fi

  echo "${now_epoch}" > "${STATE_DIR}/last_success_epoch"
  echo "${backup_name}" > "${STATE_DIR}/last_success_file"
fi

end_epoch="$(date +%s)"
duration="$(( end_epoch - start_epoch ))"

find "${BACKUP_DIR}" -type f -name "mongodump_*.archive.gz*" -mtime +"${RETENTION_DAYS}" -print -delete || true
find "${BACKUP_DIR}" -type f -name "mongodump_*.sha256" -mtime +"${RETENTION_DAYS}" -print -delete || true

if [[ "${S3_ENABLED}" == "true" && $exit_code -eq 0 ]]; then
  if [[ -z "${S3_BUCKET}" ]]; then
    echo "ERROR: S3_ENABLED=true but S3_BUCKET is empty."
    exit_code=4
  elif [[ -z "${AWS_ACCESS_KEY_ID}" || -z "${AWS_SECRET_ACCESS_KEY}" ]]; then
    echo "ERROR: S3_ENABLED=true but AWS credentials secrets are empty."
    exit_code=5
  else
    export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION
    s3_uri="s3://${S3_BUCKET}/${S3_PREFIX}/${backup_name}"
    s3_sha="s3://${S3_BUCKET}/${S3_PREFIX}/${backup_name}.sha256"

    endpoint_args=()
    [[ -n "${S3_ENDPOINT}" ]] && endpoint_args=(--endpoint-url "${S3_ENDPOINT}")

    aws "${endpoint_args[@]}" s3 cp "${backup_path}" "${s3_uri}"
    aws "${endpoint_args[@]}" s3 cp "${sha_path}" "${s3_sha}"
  fi
fi

if [[ -n "${PUSHGATEWAY_URL}" ]]; then
  payload="$(cat <<EOF
# TYPE mongo_backup_last_exit_code gauge
mongo_backup_last_exit_code{instance="${METRICS_INSTANCE}"} ${exit_code}
# TYPE mongo_backup_duration_seconds gauge
mongo_backup_duration_seconds{instance="${METRICS_INSTANCE}"} ${duration}
# TYPE mongo_backup_bytes gauge
mongo_backup_bytes{instance="${METRICS_INSTANCE}"} ${bytes}
# TYPE mongo_backup_last_run_timestamp gauge
mongo_backup_last_run_timestamp{instance="${METRICS_INSTANCE}"} ${now_epoch}
EOF
)"
  curl -fsS --data-binary "${payload}"     "${PUSHGATEWAY_URL}/metrics/job/${METRICS_JOB}/instance/${METRICS_INSTANCE}" || true
fi

echo "Backup finished. exit_code=${exit_code} duration=${duration}s bytes=${bytes}"
exit "${exit_code}"
