#!/usr/bin/env sh
set -eu

# Generates DEVELOPMENT-ONLY secrets:
# - self-signed TLS certificate/key
# - basic auth htpasswd file
#
# Replace these with real certs and credentials for production.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS_DIR="$ROOT_DIR/secrets"
mkdir -p "$SECRETS_DIR"

command -v openssl >/dev/null 2>&1 || {
  echo "ERROR: openssl not found. Install openssl and re-run."
  exit 1
}

# TLS (dev self-signed)
if [ ! -f "$SECRETS_DIR/tls.crt" ] || [ ! -f "$SECRETS_DIR/tls.key" ]; then
  echo "Generating self-signed TLS cert/key (dev only)..."
  openssl req -x509 -newkey rsa:2048 -sha256 -days 365     -nodes     -keyout "$SECRETS_DIR/tls.key"     -out "$SECRETS_DIR/tls.crt"     -subj "/CN=localhost"
else
  echo "TLS cert/key already exist. Skipping."
fi

# Basic Auth (htpasswd). Uses openssl for APR1-like hash is not portable; prefer 'htpasswd' if available.
# We'll generate a bcrypt-style hash if 'htpasswd' exists; otherwise create a placeholder and warn.
if command -v htpasswd >/dev/null 2>&1; then
  if [ ! -f "$SECRETS_DIR/basic_auth.htpasswd" ]; then
    echo "Creating htpasswd file (user: admin, password: change-me)..."
    htpasswd -bc "$SECRETS_DIR/basic_auth.htpasswd" admin change-me
  else
    echo "basic_auth.htpasswd already exists. Skipping."
  fi
else
  if [ ! -f "$SECRETS_DIR/basic_auth.htpasswd" ]; then
    echo "WARNING: htpasswd not found. Creating a placeholder file."
    echo "admin:{PLAIN}change-me" > "$SECRETS_DIR/basic_auth.htpasswd"
    echo "Replace secrets/basic_auth.htpasswd with a real htpasswd file before production."
  else
    echo "basic_auth.htpasswd already exists. Skipping."
  fi
fi

echo "Done. Files in: $SECRETS_DIR"
