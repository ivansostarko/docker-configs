#!/bin/sh
set -eu

# Helper: load secret file content into env var, if file exists and non-empty
load_secret() {
  VAR_NAME="$1"
  FILE_PATH="$2"
  if [ -f "$FILE_PATH" ] && [ -s "$FILE_PATH" ]; then
    # shellcheck disable=SC2163
    export "$VAR_NAME=$(cat "$FILE_PATH")"
  fi
}

# Elasticsearch auth (choose ONE approach)
load_secret "ES_USERNAME" "${ES_USERNAME_FILE:-/run/secrets/es_username}"
load_secret "ES_PASSWORD" "${ES_PASSWORD_FILE:-/run/secrets/es_password}"
load_secret "ES_API_KEY"  "${ES_API_KEY_FILE:-/run/secrets/es_api_key}"

# Exporter endpoint basic auth for Prometheus scraping (optional; see web.yml)
load_secret "EXPORTER_BASIC_AUTH_USER" "${EXPORTER_BASIC_AUTH_USER_FILE:-/run/secrets/exporter_basic_auth_user}"
load_secret "EXPORTER_BASIC_AUTH_PASS" "${EXPORTER_BASIC_AUTH_PASS_FILE:-/run/secrets/exporter_basic_auth_pass}"

exec /bin/elasticsearch_exporter "$@"
