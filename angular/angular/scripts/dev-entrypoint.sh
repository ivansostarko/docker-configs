#!/usr/bin/env bash
set -euo pipefail

cd /workspace

if [ ! -f package.json ]; then
  echo "ERROR: ./app is empty. Put your Angular workspace in ./app (bind mount), then re-run."
  echo "Hint: docker compose --profile dev run --rm angular_dev ng new app --directory ."
  exit 1
fi

# Optional: configure npm auth via secret
if [ -f /run/secrets/npm_token ]; then
  NPM_TOKEN="$(cat /run/secrets/npm_token)"
  if [ -n "${NPM_TOKEN}" ]; then
    echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > ~/.npmrc
  fi
fi

# Install deps if missing; prefer npm ci when lockfile exists
if [ -f package-lock.json ]; then
  npm ci
else
  npm install
fi

# Start Angular dev server
exec ng serve --host 0.0.0.0 --port 4200 --poll "${CHOKIDAR_INTERVAL:-200}"
