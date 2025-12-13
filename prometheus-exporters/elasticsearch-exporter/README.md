# Prometheus Elasticsearch Exporter (Docker Compose)

This package deploys the Prometheus Community **Elasticsearch Exporter** to expose Elasticsearch metrics for Prometheus.

## What you get

- Hardened Docker Compose service (read-only FS, dropped caps, tmpfs)
- Support for Elasticsearch auth via Docker secrets (basic auth or API key)
- Optional exporter endpoint protection via exporter-toolkit `web.yml`
- Example Prometheus scrape config
- Sensible defaults to avoid accidentally overloading Elasticsearch

## Directory layout

```text
elasticsearch-exporter/
├─ docker-compose.yml
├─ .env
├─ .gitignore
├─ config/
│  └─ elasticsearch_exporter/
│     ├─ entrypoint.sh
│     ├─ web.yml
│     └─ tls/
│        ├─ es-ca.pem                # optional (ES TLS)
│        ├─ es-client.crt            # optional (mTLS)
│        └─ es-client.key            # optional (mTLS)
└─ secrets/
   ├─ es_username.txt                # optional (basic auth to ES)
   ├─ es_password.txt                # optional (basic auth to ES)
   ├─ es_api_key.txt                 # optional (API key to ES)
   ├─ exporter_basic_auth_user.txt   # optional (protect exporter endpoint)
   └─ exporter_basic_auth_pass.txt   # optional (protect exporter endpoint)
```

## Prerequisites

- Docker + Docker Compose plugin
- Network connectivity from this exporter container to Elasticsearch
- A Prometheus instance that can scrape the exporter (same Docker network is simplest)

## Quick start

1) Put this folder next to your monitoring stack, or deploy standalone.

2) Edit `.env` and set:

- `ES_URI` (example: `https://elasticsearch:9200`)
- If your ES uses TLS, add CA/client certs under `config/elasticsearch_exporter/tls/`.
- Choose your auth method (basic auth or API key) and set secrets.

3) Create secrets (choose ONE auth approach):

### Option A — Basic auth to Elasticsearch

- `secrets/es_username.txt`
- `secrets/es_password.txt`

### Option B — API key to Elasticsearch

- `secrets/es_api_key.txt`

4) (Optional) Protect the exporter endpoint

If you expose port 9114 beyond localhost, add basic-auth/TLS in `config/elasticsearch_exporter/web.yml`.

Recommended: store bcrypt hash in `web.yml`. Do not store plaintext in git.

5) Start the exporter:

```bash
docker compose up -d
```

6) Verify:

- Exporter metrics: `http://127.0.0.1:9114/metrics` (from the host)
- Container logs: `docker logs -f elasticsearch_exporter`

## Prometheus scrape config

Add to `prometheus.yml` (adjust target to your environment):

```yaml
scrape_configs:
  - job_name: "elasticsearch_exporter"
    scrape_interval: 30s
    scrape_timeout: 10s
    metrics_path: /metrics
    static_configs:
      - targets: ["elasticsearch_exporter:9114"]
```

If you enabled exporter endpoint auth via `web.yml`, add `basic_auth:` (or use Prometheus secret management).

## Performance and safety guidance (read this)

- Do NOT enable every collector by default. `--es.all`, `--es.indices`, shards, and snapshots can increase scrape cost and load on Elasticsearch.
- Keep scrape interval reasonable (start at 30s or 60s). Watch `scrape_duration_seconds` and ES node CPU.
- Do NOT embed credentials in `ES_URI`. Use secrets for `ES_USERNAME`/`ES_PASSWORD` or `ES_API_KEY`.

## Common adjustments

### Bind exporter to all interfaces

In `docker-compose.yml`, change:

```yaml
ports:
  - "127.0.0.1:9114:9114"
```

to:

```yaml
ports:
  - "0.0.0.0:9114:9114"
```

Only do this if you also secure the endpoint (auth/TLS) and understand the network exposure.

### Join an existing monitoring network

Set in `.env`:

```dotenv
MONITORING_NETWORK=monitoring
MONITORING_NETWORK_EXTERNAL=true
```

Make sure that network exists:

```bash
docker network ls | grep monitoring
```

## Troubleshooting

- **401/403 to Elasticsearch**: your credentials/role is missing permissions.
- **TLS handshake errors**: mount the correct CA and set `ES_SSL_SKIP_VERIFY=false` (prefer correct CA over skipping verify).
- **Exporter not healthy**: the healthcheck uses `wget`. If your image lacks it, remove the healthcheck or replace it with a sidecar.
- **High scrape duration**: disable heavy collectors (`ES_INDICES`, `ES_SHARDS`, `ES_SNAPSHOTS`, etc.) or increase `scrape_interval`.

## License

This package is configuration glue. The exporter image has its own license and upstream project terms.
