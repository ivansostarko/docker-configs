#!/bin/sh
set -eu

# Load secrets into environment variables expected by Keycloak
if [ -f /run/secrets/keycloak_admin_password ]; then
  export KEYCLOAK_ADMIN_PASSWORD="$(cat /run/secrets/keycloak_admin_password)"
fi

if [ -f /run/secrets/postgres_password ]; then
  export KC_DB_PASSWORD="$(cat /run/secrets/postgres_password)"
fi

exec /opt/keycloak/bin/kc.sh "$@"
