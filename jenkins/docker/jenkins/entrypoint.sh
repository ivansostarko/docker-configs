#!/usr/bin/env bash
set -euo pipefail

# Map Docker secrets -> env vars for JCasC variable substitution.
if [[ -f /run/secrets/jenkins_admin_user ]]; then
  export JENKINS_ADMIN_USER="$(cat /run/secrets/jenkins_admin_user)"
fi

if [[ -f /run/secrets/jenkins_admin_password ]]; then
  export JENKINS_ADMIN_PASSWORD="$(cat /run/secrets/jenkins_admin_password)"
fi

exec /usr/local/bin/jenkins.sh
