#!/bin/sh
set -eu

echo "[certbot] deploy-hook fired: certificate renewed at $(date -Is)"

# IMPORTANT:
# A renewal is not operationally complete until your webserver / reverse proxy reloads
# and starts serving the renewed certificate.
#
# Option A (recommended): your proxy/container handles reload itself (watcher, SIGHUP endpoint, etc.)
# Example: call an internal endpoint in your proxy stack:
#   wget -qO- http://nginx:8080/-/reload || true
#
# Option B (not recommended by default): mount docker.sock into this container and signal your proxy container.
# This expands blast radius and should be avoided unless you fully trust this container.

exit 0
