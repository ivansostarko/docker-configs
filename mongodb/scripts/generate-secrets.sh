#!/usr/bin/env bash
set -euo pipefail

mkdir -p secrets

# Generate strong passwords. Overwrite only if files do not exist.
gen() {
  local file="$1"
  if [[ -f "$file" ]]; then
    echo "[skip] $file already exists"
  else
    openssl rand -base64 36 > "$file"
    chmod 600 "$file"
    echo "[ok]   created $file"
  fi
}

gen secrets/mongo_root_password.txt
gen secrets/mongo_app_password.txt
gen secrets/mongo_exporter_password.txt
gen secrets/mongo_express_password.txt

echo "Done. Keep these files private."
