#!/usr/bin/env sh
set -eu

# Usage:
#   ./scripts/generate-htpasswd.sh <username> <password>
#
# Output:
#   ./secrets/adminer.htpasswd (bcrypt)

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <username> <password>" >&2
  exit 2
fi

USER="$1"
PASS="$2"

if ! command -v htpasswd >/dev/null 2>&1; then
  echo "Error: htpasswd not found. Install apache2-utils (Debian/Ubuntu) or httpd-tools (RHEL/CentOS/Fedora)." >&2
  exit 1
fi

mkdir -p ./secrets
htpasswd -nbB "$USER" "$PASS" > ./secrets/adminer.htpasswd
chmod 600 ./secrets/adminer.htpasswd

echo "Wrote ./secrets/adminer.htpasswd"
