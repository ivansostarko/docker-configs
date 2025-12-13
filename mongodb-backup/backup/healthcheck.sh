#!/usr/bin/env bash
set -euo pipefail

: "${STATE_DIR:=/state}"
: "${MAX_BACKUP_AGE_HOURS:=36}"

pgrep -x cron >/dev/null

if [[ ! -f "${STATE_DIR}/last_success_epoch" ]]; then
  echo "No successful backup recorded yet."
  exit 1
fi

last="$(cat "${STATE_DIR}/last_success_epoch" || echo 0)"
now="$(date +%s)"
max_age="$(( MAX_BACKUP_AGE_HOURS * 3600 ))"

if (( now - last > max_age )); then
  echo "Last successful backup is too old: $(( (now-last)/3600 )) hours"
  exit 1
fi

exit 0
