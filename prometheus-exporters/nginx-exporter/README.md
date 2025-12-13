# NGINX Prometheus Exporter (stub_status) — Docker Compose

This repository provides a hardened, practical Docker Compose stack for:
- **NGINX (OSS)** with a dedicated internal **`/stub_status`** endpoint
- **nginx/nginx-prometheus-exporter** exposing Prometheus metrics on **`:9113/metrics`**

## What you get

- A complete `docker-compose.yml` with:
  - dedicated network
  - persistent log volume
  - sane restart policy, logging limits, basic hardening
  - healthchecks
- NGINX config:
  - normal HTTP server on `:80`
  - status server on `:8080` **NOT published to the host**
- `.env` to control ports

## Folder structure

```
nginx-exporter-stack/
├─ docker-compose.yml
├─ .env
├─ nginx/
│  ├─ nginx.conf
│  └─ conf.d/
│     ├─ default.conf
│     └─ status.conf
└─ secrets/
   ├─ nginx_status_user.txt
   └─ nginx_status_pass.txt
```

> Note: The `secrets/` files are placeholders. This stub_status setup is restricted by IP allow-list instead of basic auth.
> If you insist on auth, implement it at a proxy layer (or use NGINX Plus API). NGINX OSS `stub_status` itself does not support auth directly.

## Quick start

1. From this directory, start services:

```bash
docker compose up -d
```

2. Confirm NGINX is up:

```bash
curl -s http://localhost:${NGINX_HTTP_PORT}/healthz
```

3. Confirm exporter metrics are up:

```bash
curl -s http://localhost:${NGINX_EXPORTER_PORT}/metrics | head
```

## Prometheus scrape config

Add this to your `prometheus.yml` (Prometheus must be on the same Docker network, or you must target the published host port):

```yaml
scrape_configs:
  - job_name: "nginx_exporter"
    static_configs:
      - targets: ["nginx_exporter:9113"]
```

## Expected metrics

You should see a subset of these (exact names depend on exporter version):

- `nginx_up`
- `nginx_connections_active`
- `nginx_connections_accepted_total`
- `nginx_connections_handled_total`
- `nginx_connections_reading`
- `nginx_connections_writing`
- `nginx_connections_waiting`
- `nginx_http_requests_total`

## Non-negotiable security notes (read this)

- **Do not expose `/stub_status` publicly.** This stack keeps it internal by not publishing port 8080 to the host.
- The `status.conf` uses a coarse RFC1918 allow-list. Tighten it to the actual Docker bridge subnet if possible.
- If you are scraping a host-level NGINX, do not “just open it to the world.” Put it behind a firewall or internal network.

## Troubleshooting

### Exporter healthcheck fails
The exporter image may not ship with `wget`/`curl`. If the exporter container becomes `unhealthy`:
- Remove the exporter `healthcheck` stanza; or
- Build a tiny wrapper image that includes curl/wget.

### Stub status not reachable from exporter
Check:
- The `nginx` service is healthy
- The exporter command uses `http://nginx:8080/stub_status`
- The `allow` rules in `status.conf` permit your Docker subnet

## License

Use at your own risk. This is infrastructure glue, not a product.
