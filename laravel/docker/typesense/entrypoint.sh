#!/bin/sh
set -eu

API_KEY="$(cat /run/secrets/typesense_api_key)"

exec /opt/typesense-server   --data-dir /data   --api-key "$API_KEY"   --listen-port 8108   --enable-cors
