# Tor Onion Service (v3) via Docker Compose

This repository provides a production-oriented Docker Compose stack to serve a website **only** via a **Tor v3 onion service** (a `.onion` domain). It includes:
- An internal NGINX web server (not published on clearnet)
- A Tor daemon container configured as an onion service
- Persistent onion keys/hostname via a Docker volume
- Healthchecks, locked-down container settings, and sane defaults
- Optional Prometheus + Grafana monitoring (Tor `MetricsPort` in Prometheus format)

## What this is (and is not)

This is an **onion-service reverse tunnel**: Tor accepts inbound requests on the onion address and forwards them to your internal `web` service.

It is **not**:
- A “make me anonymous” button
- A substitute for patching, hardening, logging strategy, backups, and incident response
- A SOCKS proxy stack (explicitly disabled)

## Prerequisites

- Docker Engine + Docker Compose v2
- A Linux host is strongly recommended for production deployments
- Enough disk to persist onion keys (and optionally monitoring data)

## Quick start

1. Copy the environment file and set values:
   ```bash
   cp .env.example .env
   ```

2. Set secrets (Grafana password is required if you enable monitoring):
   ```bash
   mkdir -p secrets
   echo "change-me-to-a-long-random-password" > secrets/grafana_admin_password.txt
   echo "unused-placeholder" > secrets/prometheus_basic_auth_password.txt
   ```

3. Start the onion service:
   ```bash
   docker compose up -d --build
   ```

4. Read the generated onion hostname:
   ```bash
   docker compose exec tor cat /var/lib/tor/hs_web/hostname
   ```

5. (Optional) Start monitoring:
   ```bash
   docker compose --profile monitoring up -d
   ```

Grafana: http://localhost:3000  
Prometheus: http://localhost:9090

## Operational notes you should not ignore

### 1) Persist and back up `tor_data`

The onion address is derived from the private key stored in the `tor_data` volume. If you lose it, your onion address changes.

Back up volume data in a controlled way (offline copy, encrypted storage).

### 2) Keep the web service internal-only

Do **not** publish NGINX ports to the host unless you intentionally want clearnet access. This stack does not.

### 3) Metrics are sensitive

Tor metrics can reveal operational details. The stack:
- Places Prometheus on an internal `monitoring` network
- Restricts Tor `MetricsPort` access via `MetricsPortPolicy` to the Prometheus container IP

If you publish Grafana/Prometheus ports to anything beyond localhost, put an auth gateway in front of them.

## Configuration

### Onion service mapping

The onion service is defined in `tor/torrc.tpl`:

- `HiddenServiceDir /var/lib/tor/hs_web`
- `HiddenServicePort 80 ${HS_WEB_TARGET}`

The target is set in `docker-compose.yml` as:
- `HS_WEB_TARGET=web:8080`

To add a second onion service, duplicate the block in `torrc.tpl` and add another backend service to Compose.

### Web content

Static HTML is in `web/html/`. Replace it with your site/app and adjust `web/nginx.conf` as needed.

## Common commands

```bash
# Logs
docker compose logs -f tor
docker compose logs -f web

# Restart Tor only
docker compose restart tor

# Rebuild Tor image
docker compose build tor --no-cache
```

## Troubleshooting

- **No onion hostname created**: Tor may still be bootstrapping; check `docker compose logs tor`.
- **Healthcheck failing**: Ensure the `web` health endpoint is reachable internally (`/healthz`).
- **Metrics not scraping**: Confirm `PROMETHEUS_STATIC_IP` matches the monitoring subnet and Prometheus container address.

## Security hardening ideas (your next steps)

- Put `grafana` and `prometheus` behind a reverse proxy with auth (or bind to `127.0.0.1` only)
- Add container image pinning (`image: nginx:1.27-alpine`, etc.) and a patching policy
- Run on a host with hardened kernel, firewall rules, and minimal exposed ports
- Consider onion client authorization if you want a private onion service
