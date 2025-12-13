# Certbot + Nginx (webroot) Docker Compose Stack

This repository provides a production-oriented Docker Compose stack for **Let's Encrypt TLS certificates** using **Certbot (HTTP-01 via webroot)** and **Nginx**.

The key operational point: **Certbot renews certificate files; Nginx must reload to start serving renewed certificates**. This stack includes an Nginx periodic reload loop to make renewals effective without mounting the Docker socket.

## What you get

- **Nginx** serving:
  - `/.well-known/acme-challenge/` from a shared webroot volume
  - `/healthz` health endpoint
  - Optional `/stub_status` for Prometheus scraping (restricted)
- **Certbot init** (one-shot) for initial issuance
- **Certbot renew** (long-running) renewal loop
- Optional metrics:
  - `nginx/nginx-prometheus-exporter`
  - `joeelliott/cert-exporter` (certificate expiry)
  - `prom/prometheus`

## Prerequisites

1. Your domain(s) must resolve to the host running this stack.
2. **Inbound TCP/80 must be reachable from the public Internet** for HTTP-01. If port 80 is blocked (CGNAT, ISP filtering, corporate firewall), HTTP-01 will fail; use DNS-01 instead.
3. Docker Engine + Docker Compose plugin.

## Quick start

### 1) Configure environment

Copy the example and edit:

```bash
cp .env.example .env
```

Set at minimum:

- `PRIMARY_DOMAIN` (e.g., `example.com`)
- `DOMAINS` comma-separated (e.g., `example.com,www.example.com`)
- `LE_STAGING=1` for first validation (prevents rate-limit pain)

Set your email in `secrets/le_email.txt`.

### 2) Start the runtime services

```bash
docker compose --profile webroot up -d
```

Verify:

```bash
curl -sSf http://localhost/healthz
```

### 3) Issue the first certificate (one-shot)

```bash
docker compose --profile webroot --profile init run --rm certbot-init
```

If this fails, do **not** guess. Check:

- DNS is correct
- port 80 is reachable from outside
- Nginx is serving `/.well-known/acme-challenge/` from the shared webroot

### 4) Enable your real TLS vhost

This stack includes an example TLS server block at:

- `nginx/conf.d/10-site-ssl.conf`

Edit the `server_name` and cert paths to match your `PRIMARY_DOMAIN`, then:

```bash
docker compose restart nginx
```

### 5) Switch to production issuance

After staging issuance is validated end-to-end:

- set `LE_STAGING=0`
- re-run `certbot-init`

```bash
docker compose --profile webroot --profile init run --rm certbot-init
```

## Renewal behavior

- `certbot-renew` runs `certbot renew` every `CERTBOT_RENEW_INTERVAL_SECONDS` (default 12h).
- Nginx reloads every `NGINX_RELOAD_INTERVAL_SECONDS` (default 6h).

This is intentionally simple and robust.

## Metrics (optional)

Start Prometheus + exporters:

```bash
docker compose --profile metrics up -d
```

- Prometheus: `http://localhost:${PROMETHEUS_PORT:-9090}`
- Nginx exporter: `http://localhost:${NGINX_EXPORTER_PORT:-9113}/metrics`
- Cert exporter: `http://localhost:${CERT_EXPORTER_PORT:-9219}/metrics`

## Files and volumes

Persistent volumes:

- `letsencrypt`: `/etc/letsencrypt` (certificates, keys)
- `certbot_webroot`: `/var/www/certbot` (ACME challenges)
- `nginx_logs`: `/var/log/nginx`
- `prometheus_data`: Prometheus TSDB

## Security notes (practical, not theoretical)

- Do not mount the Docker socket just to reload Nginx; it expands your attack surface unnecessarily.
- Ensure `secrets/` is not committed to git. Add it to `.gitignore` in your own repo.
- Consider using an external reverse proxy (Caddy/Traefik) if you want ACME fully automated without this plumbing.

## Common failure modes

- **Port 80 not reachable** → HTTP-01 cannot work.
- DNS points to the wrong IP.
- Another process is already binding to 80/443.
- You issued for `PRIMARY_DOMAIN` but edited `10-site-ssl.conf` for a different name.

## Commands

Stop:

```bash
docker compose down
```

Logs:

```bash
docker compose logs -f nginx
docker compose logs -f certbot-renew
```

Inspect issued certs:

```bash
docker compose exec nginx ls -la /etc/letsencrypt/live
```
