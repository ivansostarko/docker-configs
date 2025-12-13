#!/bin/sh
set -eu

# Read Docker secret files into environment variables.
# Spring Boot does not automatically map *_FILE -> value.
read_secret() {
  key="$1"
  file_var="$2"
  eval file_path="\${$file_var:-}"
  if [ -n "${file_path:-}" ] && [ -r "$file_path" ]; then
    val="$(cat "$file_path")"
    # shellcheck disable=SC2163
    export "$key=$val"
  fi
}

read_secret DB_PASSWORD DB_PASSWORD_FILE
read_secret APP_JWT_SECRET APP_JWT_SECRET_FILE
read_secret APP_ADMIN_PASSWORD APP_ADMIN_PASSWORD_FILE

exec java -jar /opt/app/app.jar
