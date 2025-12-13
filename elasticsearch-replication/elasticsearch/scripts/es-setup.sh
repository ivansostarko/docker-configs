#!/usr/bin/env bash
set -euo pipefail

CERTS_DIR="/certs"
READY_FLAG="${CERTS_DIR}/.ready"

if [[ -f "${READY_FLAG}" ]]; then
  echo "[es-setup] Certs already exist; skipping."
  exit 0
fi

echo "[es-setup] Generating CA + node certs in ${CERTS_DIR} ..."

mkdir -p "${CERTS_DIR}"
cd "${CERTS_DIR}"

# Generate CA (PEM)
if [[ ! -f "${CERTS_DIR}/ca/ca.crt" ]]; then
  echo "[es-setup] Creating CA ..."
  /usr/share/elasticsearch/bin/elasticsearch-certutil ca --silent --pem -out ca.zip
  unzip -q ca.zip -d "${CERTS_DIR}"
  rm -f ca.zip
fi

# Create instances config
cat > instances.yml <<'YAML'
instances:
  - name: es01
    dns: [ "es01", "localhost" ]
    ip:  [ "127.0.0.1" ]
  - name: es02
    dns: [ "es02" ]
  - name: es03
    dns: [ "es03" ]
YAML

# Generate node certs signed by CA (PEM)
echo "[es-setup] Creating node certificates ..."
/usr/share/elasticsearch/bin/elasticsearch-certutil cert --silent --pem \
  --in instances.yml \
  --out certs.zip \
  --ca-cert "${CERTS_DIR}/ca/ca.crt" \
  --ca-key  "${CERTS_DIR}/ca/ca.key"

unzip -q certs.zip -d "${CERTS_DIR}"
rm -f certs.zip instances.yml

# Permissions: Elasticsearch runs as uid 1000 in the official image
chown -R 1000:0 "${CERTS_DIR}"
chmod -R go-rwx "${CERTS_DIR}" || true

touch "${READY_FLAG}"
echo "[es-setup] Done."
