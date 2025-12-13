#!/bin/sh
set -eu

SECRET_PATH="/run/secrets/beanstalkd_address"

if [ -f "$SECRET_PATH" ] && [ -s "$SECRET_PATH" ]; then
  BEANSTALKD_ADDRESS="$(cat "$SECRET_PATH")"
else
  BEANSTALKD_ADDRESS="${BEANSTALKD_ADDRESS_FALLBACK:-localhost:11300}"
fi

ARGS="--beanstalkd.address=${BEANSTALKD_ADDRESS}"

# Enable tube metrics explicitly (exporter defaults to system-only)
if [ "${BEANSTALKD_ALL_TUBES:-false}" = "true" ]; then
  ARGS="$ARGS --beanstalkd.allTubes"
fi

if [ -n "${BEANSTALKD_TUBES:-}" ]; then
  ARGS="$ARGS --beanstalkd.tubes=${BEANSTALKD_TUBES}"
fi

# Optional filters
if [ -n "${BEANSTALKD_SYSTEM_METRICS:-}" ]; then
  ARGS="$ARGS --beanstalkd.systemMetrics=${BEANSTALKD_SYSTEM_METRICS}"
fi

if [ -n "${BEANSTALKD_TUBE_METRICS:-}" ]; then
  ARGS="$ARGS --beanstalkd.tubeMetrics=${BEANSTALKD_TUBE_METRICS}"
fi

echo "Starting beanstalkd_exporter with: $ARGS"
exec /beanstalkd_exporter $ARGS
