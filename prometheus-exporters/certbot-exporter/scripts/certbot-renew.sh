#!/bin/sh
set -eu

INTERVAL="${CERTBOT_RENEW_INTERVAL:-12h}"

echo "[certbot] starting renew loop (interval=$INTERVAL)"

# Graceful shutdown
trap 'echo "[certbot] received signal, exiting"; exit 0' INT TERM

while true; do
  echo "[certbot] renew run: $(date -Is)"

  # Renew any due certs. Non-zero exits should be surfaced in logs.
  # deploy-hook runs ONLY when a cert is actually renewed.
  certbot renew --non-interactive --deploy-hook "/usr/local/bin/deploy-hook.sh"

  echo "[certbot] sleeping for $INTERVAL"
  sleep "$INTERVAL"
done
