#!/bin/sh
set -eu

API_KEY_FILE="/run/secrets/typesense_api_key"

if [ ! -f "$API_KEY_FILE" ]; then
  echo "ERROR: missing Docker secret: typesense_api_key" >&2
  exit 1
fi

API_KEY="$(cat "$API_KEY_FILE" | tr -d '\r\n')"

if [ -z "$API_KEY" ]; then
  echo "ERROR: typesense_api_key secret is empty" >&2
  exit 1
fi

exec /opt/typesense-server \
  --api-key="${API_KEY}" \
  "$@"
