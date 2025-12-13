#!/bin/sh
set -eu

USER_FILE="/run/secrets/postgres_exporter_user"
PASS_FILE="/run/secrets/postgres_exporter_password"

if [ ! -r "$USER_FILE" ] || [ ! -r "$PASS_FILE" ]; then
  echo "ERROR: Missing secrets. Ensure postgres_exporter_user and postgres_exporter_password are configured." >&2
  exit 1
fi

PG_USER="$(cat "$USER_FILE")"
PG_PASS="$(cat "$PASS_FILE")"

: "${POSTGRES_HOST:=postgres}"
: "${POSTGRES_PORT:=5432}"
: "${POSTGRES_DATABASE:=postgres}"
: "${POSTGRES_SSLMODE:=disable}"

# Build DSN securely at runtime (keeps creds out of docker inspect)
DSN="postgresql://${PG_USER}:${PG_PASS}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DATABASE}?sslmode=${POSTGRES_SSLMODE}"

export DATA_SOURCE_NAME="${DATA_SOURCE_NAME:-$DSN}"

# Locate exporter binary
BIN="$(command -v postgres_exporter || true)"
if [ -z "$BIN" ]; then
  BIN="/bin/postgres_exporter"
fi

exec "$BIN"
