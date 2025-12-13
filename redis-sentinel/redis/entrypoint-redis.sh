#!/bin/sh
set -eu

TEMPLATE="/templates/redis.conf.tpl"
OUT="/usr/local/etc/redis/redis.conf"

if [ ! -f "$TEMPLATE" ]; then
  echo "Missing template: $TEMPLATE" >&2
  exit 1
fi

REDIS_PASSWORD="$(cat /run/secrets/redis_password)"
export REDIS_PASSWORD

# Render template by substituting known variables and injecting the secret.
sed \
  -e "s|__REDIS_PASSWORD__|${REDIS_PASSWORD}|g" \
  -e "s|\${REDIS_PORT}|${REDIS_PORT:-6379}|g" \
  -e "s|\${REDIS_BIND}|${REDIS_BIND:-0.0.0.0}|g" \
  -e "s|\${MASTER_HOST}|${MASTER_HOST:-redis-1}|g" \
  -e "s|\${MASTER_PORT}|${MASTER_PORT:-6379}|g" \
  "$TEMPLATE" > "$OUT"

echo "Rendered Redis config to $OUT"
exec redis-server "$OUT"
