#!/bin/sh
set -eu

TEMPLATE="/templates/sentinel.conf.tpl"
OUT="/usr/local/etc/redis/sentinel.conf"

if [ ! -f "$TEMPLATE" ]; then
  echo "Missing template: $TEMPLATE" >&2
  exit 1
fi

REDIS_PASSWORD="$(cat /run/secrets/redis_password)"
export REDIS_PASSWORD

sed \
  -e "s|__REDIS_PASSWORD__|${REDIS_PASSWORD}|g" \
  -e "s|\${SENTINEL_PORT}|${SENTINEL_PORT:-26379}|g" \
  -e "s|\${SENTINEL_MONITOR_NAME}|${SENTINEL_MONITOR_NAME:-mymaster}|g" \
  -e "s|\${MASTER_HOST}|${MASTER_HOST:-redis-1}|g" \
  -e "s|\${MASTER_PORT}|${MASTER_PORT:-6379}|g" \
  -e "s|\${SENTINEL_QUORUM}|${SENTINEL_QUORUM:-2}|g" \
  -e "s|\${DOWN_AFTER_MS}|${DOWN_AFTER_MS:-5000}|g" \
  -e "s|\${FAILOVER_TIMEOUT_MS}|${FAILOVER_TIMEOUT_MS:-60000}|g" \
  -e "s|\${PARALLEL_SYNCS}|${PARALLEL_SYNCS:-1}|g" \
  "$TEMPLATE" > "$OUT"

echo "Rendered Sentinel config to $OUT"
exec redis-server "$OUT" --sentinel
