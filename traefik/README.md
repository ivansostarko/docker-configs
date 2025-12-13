# Traefik Docker Compose Stack (Production-Oriented)

This repository contains a production-oriented Traefik v2 stack with:
- Docker provider via **socket-proxy** (safer than mounting Docker socket into Traefik)
- File provider for reusable middlewares and TLS options
- HTTPS with Let's Encrypt (ACME) using HTTP-01 by default
- JSON logs + access logs to a persistent volume
- Healthchecks (socket-proxy + traefik + prometheus)
- Prometheus metrics endpoint + optional Prometheus + Grafana

## Contents

- `docker-compose.yml` – main stack
- `.env` – runtime configuration
- `traefik/traefik.yml` – Traefik static configuration
- `traefik/dynamic/middlewares.yml` – headers, basic auth, optional IP allowlist & rate-limit
- `traefik/dynamic/tls-options.yml` – modern TLS options
- `prometheus/prometheus.yml` – scrape config for Traefik metrics
- `secrets/` – placeholders for secrets (do not commit real secrets)

## Prerequisites

- Docker Engine + Docker Compose v2
- A public DNS record for:
  - `traefik.<your-domain>` (dashboard)
  - optionally `whoami.<your-domain>`, `grafana.<your-domain>`
- Inbound connectivity to ports **80/443** if using HTTP-01 (default).

Hard requirement: if ports 80/443 are not reachable from the internet, HTTP-01 will fail. Use DNS-01 instead.

## Quick start

1) Copy and edit environment variables:

```bash
cp .env .env.local  # optional if you prefer not to edit .env directly
```

By default this repo includes `.env`. Update:
- `DOMAIN`
- `LETSENCRYPT_EMAIL`
- `TRAEFIK_DASHBOARD_HOST`

2) Create the dashboard basic-auth file (recommended: bcrypt):

```bash
mkdir -p secrets
docker run --rm httpd:2.4-alpine htpasswd -nbB admin 'CHANGE_THIS_PASSWORD' > secrets/traefik_dashboard_users.htpasswd
```

3) Start the stack:

```bash
docker compose up -d
docker compose ps
```

4) Validate:

- Dashboard: `https://traefik.<your-domain>`
- Test service: `https://whoami.<your-domain>`
- Grafana (optional): `https://grafana.<your-domain>`

## DNS-01 (optional, wildcard / behind NAT / CDN)

If you cannot expose ports 80/443 reliably, use DNS-01. This repo includes a **Cloudflare** example.

1) Put a real token in:

`secrets/cf_dns_api_token.txt`

2) Update Traefik static config:

Edit `traefik/traefik.yml` and uncomment:

```yaml
dnsChallenge:
  provider: cloudflare
  delayBeforeCheck: 0
```

3) Remove or keep HTTP-01; you typically use one method.

## ACME storage notes

Traefik stores certs in `/letsencrypt/acme.json` inside the named volume `traefik_letsencrypt`.

If you switch to mounting a host file instead of a named volume, the file must be `chmod 600` or ACME will fail.

## Security notes (read this, don’t skip)

- The Docker socket is equivalent to root on the host. Do not mount it into Traefik directly.
  This stack uses `tecnativa/docker-socket-proxy` and only enables endpoints Traefik needs.
- Do not expose the dashboard without authentication and TLS.
  This stack enforces HTTPS + basic auth by default.
- Restrict dashboard further using the `ipallowlist@file` middleware if you have stable office/VPN IPs.

## Observability

Traefik metrics are exposed on internal entrypoint `metrics` (`:8082`) and scraped by Prometheus.

Prometheus and Grafana are included as optional services:
- Prometheus: internal only (on `monitoring` network)
- Grafana: exposed via Traefik on `grafana.<domain>`

Default Grafana admin credentials are set in `docker-compose.yml`. Change them immediately.

## Adding your own apps behind Traefik

Attach your app to the `traefik-public` network and add labels like:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myapp.rule=Host(`myapp.${DOMAIN}`)"
  - "traefik.http.routers.myapp.entrypoints=websecure"
  - "traefik.http.routers.myapp.tls=true"
  - "traefik.http.services.myapp.loadbalancer.server.port=YOUR_INTERNAL_PORT"
  - "traefik.http.routers.myapp.middlewares=security-headers@file"
```

## Troubleshooting

- **ACME fails / no cert issued**
  - Confirm `DOMAIN` and DNS records are correct.
  - Confirm port 80/443 are reachable for HTTP-01.
  - Check logs:
    ```bash
    docker logs traefik --tail=200
    ```

- **Routers not created**
  - Ensure `traefik.enable=true` on the service.
  - Ensure the service is on `traefik-public` network.
  - Ensure `providers.docker.exposedByDefault=false` means you must opt-in with labels.

## License

Use and adapt freely within your organization.
