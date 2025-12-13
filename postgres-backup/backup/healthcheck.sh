#!/usr/bin/env bash
set -euo pipefail

MAX_AGE="${MAX_BACKUP_AGE_SECONDS:-93600}"

if [[ ! -f /state/last_success ]]; then
  echo "No successful backup recorded yet."
  exit 1
fi

LAST_SUCCESS="$(cat /state/last_success || echo 0)"
NOW="$(date +%s)"
AGE=$(( NOW - LAST_SUCCESS ))

if (( AGE > MAX_AGE )); then
  echo "Last successful backup is too old: ${AGE}s > ${MAX_AGE}s"
  exit 1
fi

exit 0
