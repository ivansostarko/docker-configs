#!/bin/sh
set -eu

# Read token from Docker secret file if env var is not already set
if [ -z "${CF_API_TOKEN:-}" ] && [ -f /run/secrets/cf_api_token ]; then
  export CF_API_TOKEN="$(cat /run/secrets/cf_api_token)"
fi

exec /usr/local/bin/cloudflare_exporter
