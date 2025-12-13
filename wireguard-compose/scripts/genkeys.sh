#!/usr/bin/env bash
set -euo pipefail

# Generates key material in the current directory.
# Usage:
#   ./genkeys.sh server
#   ./genkeys.sh client1
NAME="${1:-}"
if [[ -z "$NAME" ]]; then
  echo "Usage: $0 <name>" >&2
  exit 1
fi

umask 077
wg genkey | tee "${NAME}.privatekey" | wg pubkey > "${NAME}.publickey"
wg genpsk > "${NAME}.presharedkey"

echo "Generated: ${NAME}.privatekey ${NAME}.publickey ${NAME}.presharedkey"
