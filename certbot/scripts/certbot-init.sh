#!/bin/sh
set -eu

EMAIL="$(cat /run/secrets/le_email)"
DOMAINS="${DOMAINS:-}"
PRIMARY_DOMAIN="${PRIMARY_DOMAIN:-}"

if [ -z "$DOMAINS" ] || [ -z "$PRIMARY_DOMAIN" ]; then
  echo "ERROR: DOMAINS and PRIMARY_DOMAIN must be set."
  exit 1
fi

# Build -d args: "a,b,c" -> "-d a -d b -d c"
DOMAIN_ARGS=""
OLDIFS="$IFS"
IFS=","
for d in $DOMAINS; do
  d="$(echo "$d" | xargs)"
  [ -n "$d" ] && DOMAIN_ARGS="$DOMAIN_ARGS -d $d"
done
IFS="$OLDIFS"

STAGING_ARG=""
if [ "${LE_STAGING:-0}" = "1" ]; then
  STAGING_ARG="--staging"
fi

echo "Requesting certificate for: $DOMAINS"
echo "Using staging: ${LE_STAGING:-0}"

certbot certonly \
  --non-interactive \
  --agree-tos \
  --email "$EMAIL" \
  --rsa-key-size "${CERTBOT_RSA_KEY_SIZE:-4096}" \
  --webroot -w /var/www/certbot \
  $STAGING_ARG \
  $DOMAIN_ARGS

echo "Done. Certs are in /etc/letsencrypt/live/${PRIMARY_DOMAIN}/"
