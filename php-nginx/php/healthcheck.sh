#!/bin/sh
set -eu

# 1) php-fpm master process exists
pgrep -f "php-fpm: master process" >/dev/null

# 2) FPM ping responds via FastCGI locally
OUT="$(SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 2>/dev/null || true)"

echo "$OUT" | grep -q "pong"
