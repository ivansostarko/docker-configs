#!/usr/bin/env sh
set -eu

mkdir -p secrets

# MariaDB passwords (used only if you run with --profile mariadb)
if [ ! -f secrets/kuma_db_password.txt ]; then
  openssl rand -base64 36 > secrets/kuma_db_password.txt
  echo "Created secrets/kuma_db_password.txt"
fi

if [ ! -f secrets/kuma_db_root_password.txt ]; then
  openssl rand -base64 48 > secrets/kuma_db_root_password.txt
  echo "Created secrets/kuma_db_root_password.txt"
fi

chmod 600 secrets/*.txt
echo "Done."
