#!/bin/sh
# Optional helper if you later decide to build a tiny wrapper image so Databack can read secrets.
# Not used by default in this compose, because upstream docs do not publish an official entrypoint/cmd.
set -eu

# Example pattern (implement in your own wrapper):
# export DB_URL="postgres://${DB_USER}:$(cat /run/secrets/postgres_password)@postgres:5432/${DB_NAME}"
# export SECRET_KEY="$(cat /run/secrets/databack_secret_key)"
# exec /path/to/original/entrypoint "$@"

echo "This script is a placeholder for a custom wrapper image." >&2
exec "$@"
