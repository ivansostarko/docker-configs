#!/bin/sh
set -eu

DB_PASS="$(cat /run/secrets/mm_db_password)"

# Construct datasource from non-secret env vars + secret password.
export MM_SQLSETTINGS_DATASOURCE="postgres://${MM_DB_USER}:${DB_PASS}@${MM_DB_HOST}:${MM_DB_PORT}/${MM_DB_NAME}?sslmode=disable&connect_timeout=10"

# Hand off to the image's default entrypoint/cmd.
exec /entrypoint.sh "$@"
