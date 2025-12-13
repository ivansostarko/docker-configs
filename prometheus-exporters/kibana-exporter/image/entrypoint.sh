#!/bin/sh
set -eu

: "${KIBANA_URI:?KIBANA_URI must be set (e.g., http://kibana:5601)}"
: "${KIBANA_USERNAME:=}"
: "${KIBANA_SKIP_TLS:=false}"
: "${KIBANA_EXPORTER_TELEMETRY_PATH:=/metrics}"
: "${KIBANA_EXPORTER_WAIT:=true}"

KIBANA_PASSWORD_FILE="${KIBANA_PASSWORD_FILE:-/run/secrets/kibana_password}"
KIBANA_PASSWORD=""
if [ -f "$KIBANA_PASSWORD_FILE" ]; then
  KIBANA_PASSWORD="$(cat "$KIBANA_PASSWORD_FILE")"
fi

ARGS="-kibana.uri ${KIBANA_URI} -web.telemetry-path ${KIBANA_EXPORTER_TELEMETRY_PATH}"

if [ -n "$KIBANA_USERNAME" ] && [ -n "$KIBANA_PASSWORD" ]; then
  ARGS="$ARGS -kibana.username ${KIBANA_USERNAME} -kibana.password ${KIBANA_PASSWORD}"
fi

if [ "$KIBANA_SKIP_TLS" = "true" ]; then
  ARGS="$ARGS -kibana.skip-tls true"
fi

if [ "$KIBANA_EXPORTER_WAIT" = "true" ]; then
  ARGS="$ARGS -wait"
fi

exec /usr/local/bin/kibana-exporter $ARGS
