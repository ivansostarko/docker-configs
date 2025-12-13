# n8n + PostgreSQL (Docker Compose)

This bundle provides a production-leaning baseline to run **n8n** backed by **PostgreSQL** using Docker Compose, including:

- Postgres 16 persistence
- Healthchecks + dependency gating
- Docker secrets for DB password + n8n encryption key
- Metrics enabled (`/metrics`)
- Log rotation defaults (`json-file` driver)

## Contents

```
.
├─ docker-compose.yml
├─ .env.example
└─ secrets/
   ├─ n8n_db_password.txt        (create)
   └─ n8n_encryption_key.txt     (create)
```

## Quick start

1) Create a `.env` from the example:

```bash
cp .env.example .env
```

2) Create secrets (required)

```bash
mkdir -p secrets
openssl rand -base64 32 > secrets/n8n_db_password.txt
openssl rand -base64 48 > secrets/n8n_encryption_key.txt
chmod 600 secrets/*.txt
```

3) Ensure the external network exists (because this compose references an external network named `asterix_network`):

```bash
docker network create asterix_network || true
```

4) Start:

```bash
docker compose up -d
docker compose ps
```

## Access

- n8n UI: `http://localhost:${N8N_PORT}` (default `5678`)

If you are running behind a reverse proxy (recommended for HTTPS), set:

- `N8N_PROTOCOL=https`
- `WEBHOOK_URL=https://your-domain/`
- Keep `N8N_SECURE_COOKIE=true`

## Metrics

Metrics are exposed on:

- `http://<n8n-host>:5678/metrics`

Minimal Prometheus scrape config:

```yaml
scrape_configs:
  - job_name: "n8n"
    metrics_path: /metrics
    static_configs:
      - targets: ["n8n:5678"]
```

## Notes and operational guidance

- **Do not use `:latest` in production**. Pin `N8N_IMAGE_TAG` to a known-good version to avoid surprise breaking changes.
- Keep `N8N_ENCRYPTION_KEY` stable for the lifetime of your environment. Changing it can break decryption of stored credentials.
- `N8N_SECURE_COOKIE=false` is for local, HTTP-only testing. In real deployments, terminate TLS at a proxy and keep it `true`.
- If you don’t want an *external* network, change `networks.asterix_network` to a normal (internal) network definition.

## Troubleshooting

- Check logs:
  ```bash
  docker compose logs -f n8n
  docker compose logs -f n8n-postgres
  ```

- Verify health:
  ```bash
  curl -fsS http://localhost:${N8N_PORT}/healthz
  ```

## License

Use and adapt freely. No warranty.
