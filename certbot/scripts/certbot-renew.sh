#!/bin/sh
set -eu

INTERVAL="${CERTBOT_RENEW_INTERVAL_SECONDS:-43200}"

STAGING_ARG=""
if [ "${LE_STAGING:-0}" = "1" ]; then
  STAGING_ARG="--staging"
fi

echo "Starting certbot renew loop (every ${INTERVAL}s)."

# Let's Encrypt will no-op unless within renewal window.
while :; do
  certbot renew \
    --webroot -w /var/www/certbot \
    $STAGING_ARG || true

  sleep "$INTERVAL"
done
