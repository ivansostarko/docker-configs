#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${STATE_DIR:-/state}"
HEALTH_MAX_AGE_SECONDS="${HEALTH_MAX_AGE_SECONDS:-90000}"

last_success_file="${STATE_DIR}/last_success_epoch"

if [[ ! -f "${last_success_file}" ]]; then
  echo "No last_success_epoch file found"
  exit 1
fi

last_success="$(cat "${last_success_file}" 2>/dev/null || echo 0)"
now="$(date +%s)"

if ! [[ "${last_success}" =~ ^[0-9]+$ ]]; then
  echo "Invalid last_success_epoch value: ${last_success}"
  exit 1
fi

age="$((now - last_success))"

if [[ "${age}" -gt "${HEALTH_MAX_AGE_SECONDS}" ]]; then
  echo "Last backup too old: age=${age}s > ${HEALTH_MAX_AGE_SECONDS}s"
  exit 1
fi

echo "OK: last backup age=${age}s"
exit 0
