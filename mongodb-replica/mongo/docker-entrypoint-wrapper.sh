#!/usr/bin/env bash
set -euo pipefail

# The official entrypoint is still used (it handles initdb, users, etc).
ORIG_ENTRYPOINT="/usr/local/bin/docker-entrypoint.sh"

KEYFILE_SECRET="/run/secrets/mongo_keyfile"
KEYFILE_TARGET="/etc/mongo-keyfile"

if [ -f "${KEYFILE_SECRET}" ]; then
  # MongoDB requires keyFile to be owned by mongodb user and NOT group/world readable (typically 600).
  # The mongo image uses uid/gid 999 for user "mongodb".
  install -m 600 -o 999 -g 999 "${KEYFILE_SECRET}" "${KEYFILE_TARGET}"
fi

exec "${ORIG_ENTRYPOINT}" "$@"
