#!/bin/sh
set -eu

# Load agent token from Docker secret
if [ -f /run/secrets/tfc_agent_token ]; then
  export TFC_AGENT_TOKEN="$(cat /run/secrets/tfc_agent_token | tr -d '\r')"
fi

: "${TFC_AGENT_TOKEN:?Missing TFC_AGENT_TOKEN. Provide it via Docker secret (tfc_agent_token_*.txt) or env var.}"

# Start agent (binary name differs between packaging formats; try common locations)
if command -v tfc-agent >/dev/null 2>&1; then
  exec tfc-agent
elif [ -x /bin/tfc-agent ]; then
  exec /bin/tfc-agent
elif [ -x ./tfc-agent ]; then
  exec ./tfc-agent
else
  echo "ERROR: tfc-agent binary not found in container PATH." >&2
  exit 127
fi
