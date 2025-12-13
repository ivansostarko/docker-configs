#!/usr/bin/env sh
set -eu

BIN="/tmp/elasticsearch_exporter"
PORT="${EXPORTER_PORT:-9114}"

# You can pin a version here if you want deterministic builds.
# If your environment blocks GitHub, replace this with a dedicated image in docker-compose.yml.
if [ ! -x "$BIN" ]; then
  echo "[es-exporter] Downloading exporter binary ..."
  # Alpine tools aren't guaranteed; prom image has busybox + wget typically.
  # If this fails in your environment, switch to:
  # quay.io/prometheuscommunity/elasticsearch-exporter
  wget -qO /tmp/esexp.tar.gz https://github.com/prometheus-community/elasticsearch_exporter/releases/latest/download/elasticsearch_exporter-*.linux-amd64.tar.gz || true
  if [ ! -s /tmp/esexp.tar.gz ]; then
    echo "[es-exporter] Download failed. Use the dedicated exporter image instead." >&2
    exit 1
  fi
  tar -xzf /tmp/esexp.tar.gz -C /tmp
  # Move the binary (pattern match)
  EX="$(find /tmp -maxdepth 2 -type f -name elasticsearch_exporter | head -n 1)"
  if [ -z "${EX:-}" ]; then
    echo "[es-exporter] Could not locate extracted exporter binary." >&2
    exit 1
  fi
  mv "$EX" "$BIN"
  chmod +x "$BIN"
fi

PASS="$(cat "${ES_PASS_FILE}")"

exec "$BIN" \
  --web.listen-address=":${PORT}" \
  --es.uri="${ES_URI}" \
  --es.ca="${ES_CA}" \
  --es.all \
  --es.timeout=30s \
  --es.ssl-skip-verify=false \
  --es.username="${ES_USER}" \
  --es.password="${PASS}"
