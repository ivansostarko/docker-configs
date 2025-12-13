#!/bin/sh
set -eu

PASS_FILE="/run/secrets/redis_password"
ACL_TEMPLATE="/usr/local/etc/redis/users.acl.template"
ACL_OUT="/data/users.acl"

if [ ! -f "$PASS_FILE" ]; then
  echo "ERROR: Missing redis_password secret at $PASS_FILE" >&2
  exit 1
fi

REDIS_PASSWORD="$(cat "$PASS_FILE")"
if [ -z "$REDIS_PASSWORD" ]; then
  echo "ERROR: redis_password secret is empty" >&2
  exit 1
fi

# Generate ACL file into the persistent volume.
sed "s/__REDIS_PASSWORD__/${REDIS_PASSWORD}/g" "$ACL_TEMPLATE" > "$ACL_OUT"
chmod 600 "$ACL_OUT"

# Exec the original command, injecting requirepass (keeps redis.conf free of secrets)
exec "$@" --requirepass "$REDIS_PASSWORD"
