#!/bin/sh
set -eu

ADMIN_USER="${GITEA_ADMIN_USER:-gitea_admin}"
ADMIN_EMAIL="${GITEA_ADMIN_EMAIL:-admin@example.com}"
ADMIN_PASS="$(cat /run/secrets/gitea_admin_password)"

# small delay for FS readiness
sleep 2

# If user exists, do nothing
if gitea admin user list --admin 2>/dev/null | awk '{print $2}' | grep -qx "${ADMIN_USER}"; then
  echo "Admin user '${ADMIN_USER}' already exists. Skipping."
  exit 0
fi

echo "Creating admin user '${ADMIN_USER}'..."
gitea admin user create   --username "${ADMIN_USER}"   --password "${ADMIN_PASS}"   --email "${ADMIN_EMAIL}"   --admin   --must-change-password=false

echo "Done."
