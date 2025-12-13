# Nginx Proxy Stack (nginx-proxy + Let's Encrypt + Prometheus metrics)

This repository contains a production-grade Docker Compose stack for:
- **nginxproxy/nginx-proxy** (reverse proxy with auto vhost config)
- **nginxproxy/acme-companion** (automatic Let's Encrypt TLS)
- **nginx/nginx-prometheus-exporter** (Prometheus metrics via `stub_status`)
- **tecnativa/docker-socket-proxy** (reduces the risk of exposing the raw Docker socket)

## Contents

- `docker-compose.yml`
- `.env.example` (copy to `.env` and adjust)
- `proxy/nginx/conf.d/00-health.conf` (health endpoint: `/healthz`)
- `proxy/nginx/conf.d/00-status.conf` (status endpoint for exporter: `127.0.0.1:8080/stub_status`)
- `secrets/status_htpasswd` (placeholder; optional)

## Prerequisites

- Docker + Docker Compose v2
- DNS A/AAAA records for the hostnames you will route (e.g., `whoami.example.com`)
- Inbound ports **80** and **443** open to this host

## Quick start

1. Create config and env:

```bash
cp .env.example .env
mkdir -p proxy/nginx/conf.d secrets
```

2. Edit `.env` and set at minimum:

- `BASE_DOMAIN`
- `LETSENCRYPT_EMAIL`

3. (Optional) Create Basic Auth file for `/stub_status`

If you want to enforce Basic Auth even on the localhost-only endpoint (defense-in-depth):

```bash
htpasswd -nbB status_user 'a-strong-password' > secrets/status_htpasswd
```

Then uncomment the `auth_basic` lines in `proxy/nginx/conf.d/00-status.conf`.

4. Start the stack:

```bash
docker compose up -d
```

5. Validate:

- HTTP: `http://whoami.<BASE_DOMAIN>/`
- HTTPS (after ACME issues certs): `https://whoami.<BASE_DOMAIN>/`

## How routing works

For any container you want to expose, attach it to the `proxy` network and set:

- `VIRTUAL_HOST=app.example.com`
- `LETSENCRYPT_HOST=app.example.com` (if you want TLS)
- `LETSENCRYPT_EMAIL=admin@example.com`
- `VIRTUAL_PORT=8080` (only if your app does not listen on port 80 inside the container)

Example service snippet:

```yaml
services:
  myapp:
    image: nginx:alpine
    networks:
      - proxy
    environment:
      - VIRTUAL_HOST=myapp.${BASE_DOMAIN}
      - LETSENCRYPT_HOST=myapp.${BASE_DOMAIN}
      - LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}
      - VIRTUAL_PORT=80

networks:
  proxy:
    external: true
```

## Metrics (Prometheus)

The stack exposes Nginx metrics through the exporter at:

- `nginx-proxy:9113` (from containers that can resolve `nginx-proxy`)

Example `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: nginx-proxy
    static_configs:
      - targets:
          - nginx-proxy:9113
```

If Prometheus runs **outside Docker**, expose `9113` on the host by uncommenting the port mapping in `docker-compose.yml` under `nginx-proxy`.

## Security notes (read this)

- **Do not mount `/var/run/docker.sock` into the proxy.** This stack uses `docker-socket-proxy` to reduce blast radius.
- Certificates are stored in named volumes. Back up:
  - `proxy_certs`
  - `proxy_acme`

## Troubleshooting

- Check logs:

```bash
docker compose logs -f nginx-proxy
docker compose logs -f acme-companion
```

- Verify generated vhost config:

```bash
docker exec -it nginx-proxy ls -la /etc/nginx/conf.d
```

- If ACME is failing:
  - confirm DNS points to this host
  - confirm ports 80/443 reachable from internet
  - try staging CA (set `ACME_CA_URI` in `.env`) to avoid rate limits during testing

## License

Use freely at your own risk.
