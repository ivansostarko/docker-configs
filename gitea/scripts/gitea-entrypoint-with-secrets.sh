#!/bin/sh
set -eu

# Inject DB password from Docker secret into Gitea env config
if [ -f /run/secrets/postgres_password ]; then
  export GITEA__database__PASSWD="$(cat /run/secrets/postgres_password)"
fi

# Protect /metrics with a bearer token (recommended)
if [ -f /run/secrets/gitea_metrics_token ]; then
  export GITEA__metrics__TOKEN="$(cat /run/secrets/gitea_metrics_token)"
fi

# Chain to the image’s normal entrypoint.
exec /usr/bin/dumb-init -- /usr/local/bin/docker-entrypoint.sh "$@"
