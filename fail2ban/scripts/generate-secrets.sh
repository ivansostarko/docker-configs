#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$DIR/secrets"

# Username is intentionally simple; change if you want.
printf "metrics" > "$DIR/secrets/exporter_basic_auth_user.txt"

if command -v openssl >/dev/null 2>&1; then
  openssl rand -base64 32 > "$DIR/secrets/exporter_basic_auth_pass.txt"
else
  # Fallback if openssl isn't available
  head -c 48 /dev/urandom | base64 > "$DIR/secrets/exporter_basic_auth_pass.txt"
fi

echo "Wrote: secrets/exporter_basic_auth_user.txt"
echo "Wrote: secrets/exporter_basic_auth_pass.txt"
