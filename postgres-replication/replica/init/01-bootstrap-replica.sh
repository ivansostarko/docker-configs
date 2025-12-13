#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="/var/lib/postgresql/data"
PRIMARY_HOST="${PRIMARY_HOST:-pg-primary}"
PRIMARY_PORT="${PRIMARY_PORT:-5432}"
REPL_USER="${REPL_USER:-repl_user}"
REPL_SLOT="${REPL_SLOT:-replica1_slot}"
REPL_PASS="$(cat /run/secrets/repl_password)"

# If PGDATA is already initialized, do nothing.
if [ -s "${DATA_DIR}/PG_VERSION" ]; then
  echo "Replica data directory already initialized; skipping base backup."
  exit 0
fi

echo "Waiting for primary to be ready..."
until pg_isready -h "${PRIMARY_HOST}" -p "${PRIMARY_PORT}" -U "${REPL_USER}" >/dev/null 2>&1; do
  sleep 2
done

echo "Initializing replica using pg_basebackup..."
rm -rf "${DATA_DIR:?}/"*

export PGPASSWORD="${REPL_PASS}"

# Take base backup and register replication slot usage
pg_basebackup \
  -h "${PRIMARY_HOST}" \
  -p "${PRIMARY_PORT}" \
  -U "${REPL_USER}" \
  -D "${DATA_DIR}" \
  -Fp -Xs -P -R \
  --slot="${REPL_SLOT}"

# Ensure standby mode (pg_basebackup -R should create standby.signal + primary_conninfo)
touch "${DATA_DIR}/standby.signal"

# Hard-set primary slot name to match (belt-and-suspenders)
grep -q "^primary_slot_name" "${DATA_DIR}/postgresql.auto.conf" 2>/dev/null \
  && sed -i "s/^primary_slot_name.*/primary_slot_name = '${REPL_SLOT}'/" "${DATA_DIR}/postgresql.auto.conf" \
  || echo "primary_slot_name = '${REPL_SLOT}'" >> "${DATA_DIR}/postgresql.auto.conf"

echo "Replica bootstrap complete."
