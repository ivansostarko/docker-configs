#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   restore.sh /backups/mongodump_...archive.gz [mongodb://user:pass@host:27017/admin]
#
# WARNING: This can overwrite data depending on flags you pass. Use with discipline.

archive="${1:-}"
target_uri="${2:-}"

if [[ -z "${archive}" || ! -f "${archive}" ]]; then
  echo "ERROR: Provide an existing backup archive path."
  exit 2
fi

if [[ -z "${target_uri}" ]]; then
  echo "ERROR: Provide a target MongoDB URI for restore."
  exit 3
fi

echo "Restoring ${archive} to ${target_uri}"
mongorestore --uri="${target_uri}" --archive="${archive}" --gzip --drop
echo "Restore completed."
