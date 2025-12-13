#!/bin/sh
set -eu

# Render torrc from template with environment variables.
envsubst < /etc/tor/torrc.tpl > /tmp/torrc

# Sanity: avoid accidentally running an open SOCKS proxy.
if grep -qE '^\s*SocksPort\s+[1-9]' /tmp/torrc; then
  echo "Refusing to start: SocksPort is enabled. This stack is for onion services, not a proxy."
  exit 1
fi

exec tor -f /tmp/torrc
