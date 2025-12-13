# Elasticsearch + Kibana (Docker Compose) — hardened, secrets-aware

This package provides a production-leaning Docker Compose for **Elasticsearch + Kibana** with:
- TLS between Kibana and Elasticsearch (self-generated CA + node certs)
- No credentials in environment variables (passwords injected via **keystores**)
- Healthchecks for both services
- Optional Prometheus exporters for Elasticsearch and Kibana via a `metrics` profile

## Quick start

### 1) Configure environment
```bash
cp .env.example .env
```

### 2) Create secrets
```bash
mkdir -p secrets

openssl rand -base64 24 > secrets/elastic_password.txt
openssl rand -base64 24 > secrets/kibana_system_password.txt

openssl rand -base64 48 > secrets/kibana_enc_security.txt
openssl rand -base64 48 > secrets/kibana_enc_saved_objects.txt
openssl rand -base64 48 > secrets/kibana_enc_reporting.txt

# Optional (only if you enable the metrics profile)
openssl rand -base64 24 > secrets/kibana_exporter_password.txt

chmod -R go-rwx secrets
```

### 3) Start
```bash
docker compose up -d
```

Open:
- Kibana: http://localhost:5601
- Elasticsearch: https://localhost:9200 (will respond 401 without auth)

Login:
- user: `elastic`
- password: contents of `secrets/elastic_password.txt`

## Metrics (optional)
```bash
docker compose --profile metrics up -d
```

Exporters:
- Elasticsearch exporter: http://localhost:9114/metrics
- Kibana exporter: http://localhost:9684/metrics

## Notes you should not ignore
- This is **single-node** (`discovery.type=single-node`). It is not HA.
- Do not expose Kibana publicly without a reverse proxy + TLS + access control.
- If you change the ES node name or hostnames, regenerate certs (wipe `es-config` volume).
