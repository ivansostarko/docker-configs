#!/usr/bin/env bash
set -euo pipefail

COOKIE_FILE="/run/secrets/rabbitmq_erlang_cookie"
PASS_FILE="/run/secrets/rabbitmq_admin_password"

# 1) Inject admin password from Docker secret (keeps it out of .env).
if [[ -f "${PASS_FILE}" ]]; then
  export RABBITMQ_DEFAULT_PASS="$(tr -d '\r\n' < "${PASS_FILE}")"
else
  echo "ERROR: Missing admin password secret at ${PASS_FILE}" >&2
  echo "Create ./secrets/admin_password before starting the stack." >&2
  exit 1
fi

# 2) Install Erlang cookie (required for clustering; also stabilizes node identity).
if [[ -f "${COOKIE_FILE}" ]]; then
  cookie="$(tr -d '\r\n' < "${COOKIE_FILE}")"
  mkdir -p /var/lib/rabbitmq
  echo -n "${cookie}" > /var/lib/rabbitmq/.erlang.cookie
  chmod 400 /var/lib/rabbitmq/.erlang.cookie
  # Best effort; may fail if volume permissions are unusual.
  chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie 2>/dev/null || true
else
  echo "ERROR: Missing Erlang cookie secret at ${COOKIE_FILE}" >&2
  echo "Create ./secrets/erlang.cookie before starting the stack." >&2
  exit 1
fi

# 3) Normalize permissions (best-effort).
chown -R rabbitmq:rabbitmq /var/lib/rabbitmq /var/log/rabbitmq 2>/dev/null || true

exec docker-entrypoint.sh rabbitmq-server
