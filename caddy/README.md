# Caddy Docker Compose Stack

This repository provides a production-grade Caddy setup with:
- HTTP + HTTPS + optional HTTP/3
- Persistent volumes for certificates/state
- Healthcheck
- Built-in Prometheus metrics exposed on an internal-only listener
- Optional Prometheus + Grafana (Compose profile: `metrics`)
- Optional Caddy build with Cloudflare DNS module for DNS-01 / wildcard certificates (Compose profile: `dns`)

## Directory structure

```text
caddy/
  compose.yaml
  .env
  conf/
    Caddyfile
  site/
    index.html
  prometheus/
    prometheus.yml
  secrets/
    (do not commit)
```

## Prerequisites
- Docker Engine + Docker Compose v2

## Quick start (static site)

1. Edit `.env`:
   - Set `DOMAIN` to your real hostname (must resolve to this host)
   - Set `ACME_EMAIL`

2. Start Caddy:

```bash
docker compose up -d
```

3. Validate:
- `http://DOMAIN` should redirect to HTTPS once a cert is issued.
- Container health should become `healthy`.

## Reload config (no restart)

```bash
docker compose exec -w /etc/caddy caddy caddy reload
```

## Reverse proxy an upstream application

Edit `conf/Caddyfile` and replace the `file_server` portion with something like:

```caddyfile
{$DOMAIN} {
  reverse_proxy app:8080
}
```

Then ensure your upstream service is attached to the `backend` network (recommended) or to the same network as `caddy`.

## Metrics (Caddy built-in + optional Prometheus/Grafana)

Caddy metrics are exposed at:

- `http://caddy:9100/metrics` (internal listener; not published to host)

Run with Prometheus and Grafana:

```bash
docker compose --profile metrics up -d
```

Grafana will be on `http://localhost:${GRAFANA_PORT:-3000}`.

## Wildcard certificates / DNS-01 (Cloudflare)

If you need wildcard certs (e.g., `*.example.com`), you must use DNS-01 with a DNS provider module.
This stack includes a Cloudflare example build via `xcaddy`.

1. Set `CLOUDFLARE_API_TOKEN` in `.env`
2. Start the DNS-enabled Caddy service:

```bash
docker compose --profile dns up -d --build
```

3. Update `conf/Caddyfile` to use DNS challenge, for example:

```caddyfile
{$DOMAIN} {
  tls {
    dns cloudflare {$CLOUDFLARE_API_TOKEN}
  }
  respond "ok" 200
}
```

Important: Run either `caddy` **or** `caddy_dns`, not both. The profiles ensure this, but do not manually start both services.

## Security posture (read this, then decide if you actually mean “production”)

- The Caddy admin API is powerful. This stack does **not** publish port `2019` to the host. Keep it that way.
- Certificates and keys live under `/data`. If you don’t persist it, you will churn certificates and cause outages.
- The `backend` network is marked `internal: true` so it cannot be reached from outside the Docker host.
- Metrics are exposed only to containers on `backend`. If you attach untrusted containers to `backend`, you have created your own problem.

## Environment variables

See `.env` for defaults. Common ones:
- `DOMAIN` (required)
- `ACME_EMAIL` (required)
- `HTTP_PORT`, `HTTPS_PORT` (optional)
- `METRICS_LISTEN` (optional; default `:9100`)
- `CLOUDFLARE_API_TOKEN` (only for profile `dns`)
- `GRAFANA_*` (only for profile `metrics`)

## Logs

- Access logs: `caddy_logs` volume at `/var/log/caddy/access.log`
- Admin logs: `caddy_logs` volume at `/var/log/caddy/admin.log`

If you want log shipping, add a collector (Promtail/Vector/Fluent Bit) and mount the same logs volume read-only.

## Operational commands

```bash
# Base stack
docker compose up -d

# Optional metrics stack
docker compose --profile metrics up -d

# DNS-enabled Caddy build
docker compose --profile dns up -d --build

# View logs
docker compose logs -f caddy
```

## What you still need to decide (don’t avoid these)

- Are you behind a CDN (Cloudflare)? If yes, configure trusted proxies and real client IP handling.
- Do you need WAF/rate limiting at the edge? Caddy can do some, but you may need upstream tooling.
- Do you need mTLS between Caddy and upstream services? That is not optional in hostile networks.
