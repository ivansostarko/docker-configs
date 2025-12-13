#!/usr/bin/env bash
set -euo pipefail

# This script runs only on FIRST initialization of the primary (empty datadir).
# It creates:
# - replication user
# - exporter user (for mysqld_exporter)
# - optional hardening defaults

ROOT_PW="$(cat /run/secrets/mysql_root_password)"
REPL_PW="$(cat /run/secrets/mysql_repl_password)"
EXPORTER_PW="$(cat /run/secrets/mysql_exporter_password)"
REPL_USER="${MYSQL_REPL_USER:-repl}"
EXPORTER_USER="${MYSQL_EXPORTER_USER:-exporter}"

mysql --protocol=socket -uroot -p"${ROOT_PW}" <<SQL
-- Replication user (caching_sha2_password is default on MySQL 8+)
CREATE USER IF NOT EXISTS '${REPL_USER}'@'%' IDENTIFIED BY '${REPL_PW}';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO '${REPL_USER}'@'%';

-- Metrics exporter user
CREATE USER IF NOT EXISTS '${EXPORTER_USER}'@'%' IDENTIFIED BY '${EXPORTER_PW}';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO '${EXPORTER_USER}'@'%';
-- Recommended additional privileges for mysqld_exporter depending on collectors enabled:
GRANT SELECT ON performance_schema.* TO '${EXPORTER_USER}'@'%';
GRANT SELECT ON sys.* TO '${EXPORTER_USER}'@'%';

FLUSH PRIVILEGES;

-- Optional: make sure time zone tables aren't required (we set MYSQL_INITDB_SKIP_TZINFO=1)
SQL
