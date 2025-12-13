#!/bin/sh
set -eu

# This runs during FIRST initialization of a fresh datadir.
# It creates the 'exporter' user only if the secret is present.
# If you don't enable the monitoring profile, leaving the password file as placeholder is harmless.

if [ -f /run/secrets/mysql_exporter_password ]; then
  PW="$(cat /run/secrets/mysql_exporter_password | tr -d '\r\n')"
  if [ -n "${PW}" ]; then
    echo "Creating mysqld-exporter user..."
    mariadb -uroot -p"$(cat /run/secrets/db_root_password | tr -d '\r\n')" <<-SQL
      CREATE USER IF NOT EXISTS 'exporter'@'%' IDENTIFIED BY '${PW}';
      GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
      GRANT SELECT ON performance_schema.* TO 'exporter'@'%';
      FLUSH PRIVILEGES;
SQL
  fi
fi
