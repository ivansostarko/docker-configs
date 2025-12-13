#!/usr/bin/env sh
set -eu

# Generates strong local secrets for RabbitMQ.
# Requires: openssl OR python3 OR /dev/urandom + tr.

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SECRETS_DIR="$ROOT_DIR/secrets"
mkdir -p "$SECRETS_DIR"

gen() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 48 | tr -d '\n'
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<'PY'
import secrets, string
alphabet = string.ascii_letters + string.digits
print(''.join(secrets.choice(alphabet) for _ in range(64)))
PY
    return 0
  fi
  # Fallback
  tr -dc 'A-Za-z0-9' </dev/urandom | head -c 64
}

# You can change the username if you want.
printf "%s\n" "admin" > "$SECRETS_DIR/rabbitmq_user.txt"
gen > "$SECRETS_DIR/rabbitmq_password.txt"
gen > "$SECRETS_DIR/erlang_cookie.txt"

chmod 600 "$SECRETS_DIR/"*.txt || true

echo "Secrets generated in: $SECRETS_DIR"
echo "rabbitmq_user.txt: admin"
echo "rabbitmq_password.txt: (random)"
echo "erlang_cookie.txt: (random)"
