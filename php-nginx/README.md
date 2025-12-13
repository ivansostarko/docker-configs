# PHP-FPM + Nginx (Docker Compose)

This repository provides a production-leaning Docker Compose stack for:
- **Nginx** serving static assets and proxying PHP requests to **PHP-FPM**
- **Healthchecks** for both services
- **Configs** managed via Compose `configs`
- **Secrets** managed via Compose `secrets`
- Optional **Prometheus exporters** (Nginx + PHP-FPM) via a `metrics` profile

## What you get (and what you do not)

### Included
- Network segmentation:
  - `edge` for public ingress
  - `backend` internal network for app-to-app
  - `monitoring` internal network for exporters
- Read-only containers by default (with explicit writable areas)
- Sensible baseline Nginx config + security headers snippet
- PHP-FPM config with `/ping` and `/status` enabled

### Not included
- A database container (wire your own)
- TLS termination (intentionally omitted; do it via a reverse proxy / ingress)
- Framework-specific writable directories (Laravel `storage/`, Symfony `var/`, etc.)

If you blindly run this in production without adjusting file permissions and framework storage volumes, you will break your app or weaken isolation.

## Quick start

```bash
cp .env.example .env

# Create secrets (do NOT commit real secrets)
mkdir -p secrets
openssl rand -hex 32 > secrets/app_key.txt
openssl rand -base64 32 > secrets/db_password.txt

docker compose up -d --build
```

Open:
- App: `http://localhost:8080/`
- Health: `http://localhost:8080/healthz`

## Enable metrics exporters

Exporters are behind a Compose profile called `metrics`.

```bash
docker compose --profile metrics up -d
```

Ports (host):
- Nginx exporter: `9113` (default)
- PHP-FPM exporter: `9253` (default)

You can override these in `.env`.

## Files

- `docker-compose.yml`: main stack
- `nginx/nginx.conf`: global Nginx settings
- `nginx/conf.d/app.conf`: vhost, FastCGI config, `/healthz`, `/stub_status`
- `nginx/snippets/security-headers.conf`: baseline response headers
- `php/Dockerfile`: PHP-FPM image build
- `php/php.ini`: runtime PHP settings
- `php/www.conf`: FPM pool (includes `/ping` + `/status`)
- `php/healthcheck.sh`: container healthcheck (FastCGI ping)

## Security notes you should not ignore

1. **Bind-mounting app code** (`./app:/var/www/html`) is fine for dev, risky for production. For production, bake the code into a versioned image.
2. `/status` and `/stub_status` are **not authentication-protected**. In this stack they are restricted by network exposure and allow-lists, but you should still treat them as sensitive.
3. If your framework needs writable directories, do NOT make the whole container writable. Add targeted named volumes for those paths.

## Common production upgrades

- Put Nginx behind a dedicated edge proxy (Traefik / Nginx Proxy Manager / HAProxy) for TLS and routing
- Add Prometheus + Grafana (separate Compose) and scrape the exporters
- Replace `.env` with CI/CD-managed environment injection
- Replace file-based `secrets/` with your secrets manager

## Commands

```bash
# View logs
docker compose logs -f

# Rebuild PHP image after changing extensions
docker compose build php

# Stop
docker compose down
```
