#!/usr/bin/env bash
set -euo pipefail

echo "[flutter_builder] Preparing pub credentials (optional)..."
if [ -s /run/secrets/pub_credentials_json ]; then
  mkdir -p "${PUB_CACHE}"
  cp -f /run/secrets/pub_credentials_json "${PUB_CACHE}/credentials.json"
  chmod 600 "${PUB_CACHE}/credentials.json" || true
fi

echo "[flutter_builder] Flutter version:"
flutter --version

echo "[flutter_builder] Fetching dependencies..."
flutter pub get

echo "[flutter_builder] Building Flutter Web (release)..."
# If you serve behind a subpath, set FLUTTER_WEB_BASE_HREF accordingly (e.g. /myapp/)
flutter build web --release --base-href "${FLUTTER_WEB_BASE_HREF:-/}"

echo "[flutter_builder] Exporting build to /output ..."
rm -rf /output/*
cp -R build/web/* /output/

echo "[flutter_builder] Done."
