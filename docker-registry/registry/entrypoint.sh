#!/bin/sh
set -eu

# Load secret into env var for registry runtime usage.
export REGISTRY_HTTP_SECRET="$(cat /run/secrets/registry_http_secret)"

exec /entrypoint registry serve /etc/docker/registry/config.yml
