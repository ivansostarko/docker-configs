#!/bin/sh
set -eu

# Load Cloudflare token from Docker secret into TF_VAR_*
if [ -f /run/secrets/cloudflare_api_token ]; then
  export TF_VAR_cloudflare_api_token="$(cat /run/secrets/cloudflare_api_token | tr -d '\r')"
fi

exec terraform "$@"
