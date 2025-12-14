#!/bin/sh
set -eu

CONF_DIR=/etc/mysqld_exporter
CONF_FILE="$CONF_DIR/mysqld_exporter.cnf"
PW_FILE=/run/secrets/mysql_exporter_password

mkdir -p "$CONF_DIR"

if [ ! -f "$PW_FILE" ]; then
  echo "[exporter] Missing /run/secrets/mysql_exporter_password" >&2
  exit 1
fi

PASS="$(cat "$PW_FILE")"
HOST="${EXPORTER_MYSQL_HOST:-mysql}"
PORT="${EXPORTER_MYSQL_PORT:-3306}"
USER="${EXPORTER_MYSQL_USER:-exporter}"

cat > "$CONF_FILE" <<EOF
[client]
host=${HOST}
port=${PORT}
user=${USER}
password=${PASS}
EOF

exec /bin/mysqld_exporter --config.my-cnf="$CONF_FILE"
