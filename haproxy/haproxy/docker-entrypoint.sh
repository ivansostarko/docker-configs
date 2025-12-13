#!/usr/bin/env bash
set -euo pipefail

TEMPLATE=/templates/haproxy.cfg.tmpl
OUT=/usr/local/etc/haproxy/haproxy.cfg

# Support *_FILE convention for secrets.
if [[ -n "${HAPROXY_STATS_PASS_FILE:-}" ]] && [[ -f "${HAPROXY_STATS_PASS_FILE}" ]]; then
  export HAPROXY_STATS_PASS="$(cat "${HAPROXY_STATS_PASS_FILE}")"
fi

: "${HAPROXY_STATS_USER:=admin}"
: "${HAPROXY_STATS_PASS:=change_me}"
: "${HAPROXY_NODE_NAME:=haproxy}"
: "${HAPROXY_DEBUG:=0}"

mkdir -p /var/run/haproxy /usr/local/etc/haproxy

# Render config from template.
# Use envsubst (gettext) to expand env vars safely.
if [[ ! -f "${TEMPLATE}" ]]; then
  echo "ERROR: Missing template at ${TEMPLATE}" >&2
  exit 1
fi

# Reduce accidental leakage in logs.
if [[ "${HAPROXY_DEBUG}" == "1" ]]; then
  echo "Rendering HAProxy config from template: ${TEMPLATE} -> ${OUT}" >&2
fi

envsubst < "${TEMPLATE}" > "${OUT}"

# Strict permissioning for admin socket directory.
chown -R 99:99 /var/run/haproxy || true
chmod 0770 /var/run/haproxy || true

# Validate config before starting.
haproxy -c -f "${OUT}"

exec "$@"
