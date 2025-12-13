#!/usr/bin/env bash
set -euo pipefail

log() { echo "[fdroid-update] $*"; }

cd /repo

if [[ ! -f /repo/config.yml ]]; then
  log "ERROR: /repo/config.yml not found. Ensure ./config/config.yml is mounted to /repo/config.yml."
  exit 1
fi

mkdir -p /repo/repo /repo/metadata

# Optional: import a GPG key (only used if you enable FDROID_GPGSIGN=1 and your workflow needs it)
if [[ -f /run/secrets/gpg_private_key ]]; then
  log "Importing GPG private key..."
  gpg --batch --import /run/secrets/gpg_private_key || true
fi

EXTRA=()
if [[ "${FDROID_CREATE_METADATA:-0}" == "1" ]]; then
  EXTRA+=(--create-metadata)
fi

log "Running: fdroid update ${EXTRA[*]}"
fdroid update "${EXTRA[@]}"

if [[ "${FDROID_GPGSIGN:-0}" == "1" ]]; then
  log "Running: fdroid gpgsign"
  fdroid gpgsign
fi

log "Done. Repo artifacts are in /repo/repo (served by nginx at /fdroid/repo/)."
