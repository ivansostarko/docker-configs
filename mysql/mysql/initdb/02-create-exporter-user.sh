#!/bin/sh
set -eu

ROOT_PW_FILE=/run/secrets/mysql_root_password
EXPORTER_PW_FILE=/run/secrets/mysql_exporter_password

if [ ! -f "$ROOT_PW_FILE" ] || [ ! -f "$EXPORTER_PW_FILE" ]; then
  echo "[initdb] Missing required secrets; skipping exporter user creation." >&2
  exit 0
fi

ROOT_PW="$(cat "$ROOT_PW_FILE")"
EXPORTER_PW="$(cat "$EXPORTER_PW_FILE")"

# During initialization, the MySQL entrypoint runs scripts with a local server available.
# We create a dedicated user for Prometheus mysqld_exporter.
mysql -uroot -p"$ROOT_PW" <<SQL
CREATE USER IF NOT EXISTS 'exporter'@'%' IDENTIFIED BY '${EXPORTER_PW}';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
GRANT SELECT ON performance_schema.* TO 'exporter'@'%';
FLUSH PRIVILEGES;
SQL

echo "[initdb] Exporter user ensured."
