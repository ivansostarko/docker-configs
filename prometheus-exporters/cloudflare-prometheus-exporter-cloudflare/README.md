# Cloudflare Prometheus Exporter (Docker Compose)

This bundle provides a hardened Docker Compose setup for exposing Cloudflare metrics to Prometheus using `lablabs/cloudflare_exporter`.

## What you get

- `docker-compose.yml` — simplest deployment using an API token in `.env`
- `docker-compose.secrets.yml` — recommended deployment using Docker secrets + reliable HTTP healthcheck (wrapper image)
- `.env.example` — configuration template
- `prometheus-scrape.yml` — Prometheus `scrape_configs` snippet
- `cloudflare-exporter-wrapper/` — wrapper image (Alpine) that reads token from Docker secret file

## Prerequisites

- Docker Engine + Docker Compose plugin
- A Cloudflare **API Token** with the minimum required permissions for the metrics you intend to scrape.

## Quick start (ENV mode)

1. Copy and edit the env file:

   ```bash
   cp .env.example .env
   ```

2. Set `CF_API_TOKEN` in `.env`.

3. Start:

   ```bash
   docker compose up -d
   ```

4. Validate:

   ```bash
   curl -s http://localhost:${CF_EXPORTER_PORT:-8080}/metrics | head
   ```

### ENV mode caveat (do not ignore)

The upstream exporter image is frequently distroless and may not include `sh`, `curl`, or `wget`. That is why `docker-compose.yml` does **not** provide a reliable container-level HTTP healthcheck.

If you require an actual healthcheck (you do, in production), use **Secrets mode** below.

## Recommended (Secrets mode + healthcheck)

1. Copy and edit `.env`:

   ```bash
   cp .env.example .env
   ```

2. Create the secrets file and put your token in it:

   ```bash
   mkdir -p secrets
   printf '%s' 'REPLACE_ME' > secrets/cf_api_token.txt
   chmod 600 secrets/cf_api_token.txt
   ```

3. Ensure `CF_API_TOKEN` in `.env` is empty (or remove it entirely).

4. Start with the secrets compose file:

   ```bash
   docker compose -f docker-compose.secrets.yml up -d --build
   ```

5. Confirm health:

   ```bash
   docker inspect --format='{{json .State.Health}}' cloudflare_exporter | jq
   ```

## Prometheus configuration

Add the following scrape job (see `prometheus-scrape.yml`):

```yaml
- job_name: cloudflare_exporter
  metrics_path: /metrics
  scrape_interval: 60s
  scrape_timeout: 20s
  static_configs:
    - targets:
        - cloudflare_exporter:8080
```

If Prometheus runs in the same Docker network, the target name `cloudflare_exporter:8080` will resolve automatically.

## Security posture (what this Compose does)

- Runs as non-root (`65532:65532`)
- Drops all Linux capabilities
- Enables `no-new-privileges`
- Sets filesystem read-only + ephemeral `/tmp`
- Limits PID count
- Rotates logs (json-file driver)

## Tuning guidance (rate limits, scale)

The exporter pulls from Cloudflare APIs. If you manage many zones or high-traffic properties, do not set aggressive scrape intervals. Start with:

- `CF_EXPORTER_SCRAPE_INTERVAL=60`
- `CF_EXPORTER_SCRAPE_DELAY=300`

Then adjust based on observed latency and Cloudflare API rate-limiting.

## File layout

```
.
├── docker-compose.yml
├── docker-compose.secrets.yml
├── .env.example
├── prometheus-scrape.yml
├── secrets/
│   └── cf_api_token.txt           # you create this
└── cloudflare-exporter-wrapper/
    ├── Dockerfile
    └── entrypoint.sh
```

## Operational warnings (read this)

- Do not commit `.env` or `secrets/` into git.
- Use the minimum Cloudflare token scope needed; broad tokens are operational debt.
- If you enable debug logging, assume the logs may reveal sensitive metadata; turn it off immediately after troubleshooting.
