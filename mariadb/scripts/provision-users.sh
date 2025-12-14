#!/usr/bin/env bash
set -euo pipefail

ROOT_PW="$(cat /run/secrets/mariadb_root_password)"
EXPORTER_PW="$(cat /run/secrets/mariadb_exporter_password)"
APP_PW="$(cat /run/secrets/mariadb_app_password)"

DB_HOST="mariadb"
DB_PORT="3306"

echo "Provisioning users on ${DB_HOST}:${DB_PORT} ..."

mariadb -h "${DB_HOST}" -P "${DB_PORT}" -uroot -p"${ROOT_PW}" <<SQL
CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${APP_PW}';
GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';

CREATE USER IF NOT EXISTS 'exporter'@'%' IDENTIFIED BY '${EXPORTER_PW}';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
GRANT SELECT ON performance_schema.* TO 'exporter'@'%';

FLUSH PRIVILEGES;
SQL

echo "Done."
