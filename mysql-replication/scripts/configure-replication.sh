#!/usr/bin/env bash
set -euo pipefail

PRIMARY_HOST="${PRIMARY_HOST:-mysql-primary}"
REPLICA_HOST="${REPLICA_HOST:-mysql-replica1}"
REPL_USER="${REPL_USER:-repl}"

ROOT_PW="$(cat "${ROOT_PASSWORD_FILE:-/run/secrets/mysql_root_password}")"
REPL_PW="$(cat "${REPL_PASSWORD_FILE:-/run/secrets/mysql_repl_password}")"

CONNECT_RETRIES="${CONNECT_RETRIES:-60}"
CONNECT_SLEEP_SECS="${CONNECT_SLEEP_SECS:-2}"

echo "Waiting for MySQL primary at ${PRIMARY_HOST}:3306 ..."
for i in $(seq 1 "${CONNECT_RETRIES}"); do
  if mysqladmin ping -h "${PRIMARY_HOST}" -uroot -p"${ROOT_PW}" --silent; then
    break
  fi
  sleep "${CONNECT_SLEEP_SECS}"
done
mysqladmin ping -h "${PRIMARY_HOST}" -uroot -p"${ROOT_PW}" --silent

echo "Waiting for MySQL replica at ${REPLICA_HOST}:3306 ..."
for i in $(seq 1 "${CONNECT_RETRIES}"); do
  if mysqladmin ping -h "${REPLICA_HOST}" -uroot -p"${ROOT_PW}" --silent; then
    break
  fi
  sleep "${CONNECT_SLEEP_SECS}"
done
mysqladmin ping -h "${REPLICA_HOST}" -uroot -p"${ROOT_PW}" --silent

echo "Configuring replication (GTID auto-position) on replica '${REPLICA_HOST}' from primary '${PRIMARY_HOST}' ..."
mysql -h "${REPLICA_HOST}" -uroot -p"${ROOT_PW}" <<SQL
-- Make this idempotent: stop and reset replication metadata, then reconfigure.
STOP REPLICA;
RESET REPLICA ALL;

CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='${PRIMARY_HOST}',
  SOURCE_PORT=3306,
  SOURCE_USER='${REPL_USER}',
  SOURCE_PASSWORD='${REPL_PW}',
  SOURCE_AUTO_POSITION=1,
  GET_SOURCE_PUBLIC_KEY=1;

START REPLICA;
SQL

echo "Verifying replica status ..."
# We assert the two critical fields. If this fails, the container exits non-zero and you will see logs.
mysql -h "${REPLICA_HOST}" -uroot -p"${ROOT_PW}" -e "SHOW REPLICA STATUS\\G" | \
  awk -F': ' '
    $1 ~ /Replica_IO_Running/ {io=$2}
    $1 ~ /Replica_SQL_Running/ {sql=$2}
    END {
      if (io == "Yes" && sql == "Yes") { print "Replication OK"; exit 0 }
      print "Replication NOT OK. Replica_IO_Running=" io " Replica_SQL_Running=" sql; exit 1
    }'
