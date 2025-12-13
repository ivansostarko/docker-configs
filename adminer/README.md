# Adminer Docker Compose Stack

This repository provides a production-leaning Docker Compose setup for **Adminer** behind an **NGINX reverse proxy** with **Basic Auth** (stored as a Docker secret). It also includes an optional **metrics** profile (NGINX exporter + Prometheus + Grafana).

## What you get

- Adminer isolated on an **internal backend network** (not directly exposed)
- NGINX proxy exposed on the host (default: `:8080`)
- Basic Auth via `./secrets/adminer.htpasswd` (Docker secret)
- Healthchecks and hardened container flags (`read_only`, `no-new-privileges`, `tmpfs`)
- Optional metrics stack: NGINX exporter + Prometheus + Grafana (`--profile metrics`)

## Repository layout

- `docker-compose.yml` – stack definition
- `.env.example` – environment template
- `nginx/nginx.conf` – reverse proxy config (includes `/stub_status` for exporter)
- `monitoring/prometheus.yml` – Prometheus scrape config
- `scripts/generate-htpasswd.sh` – helper to create the Basic Auth secret
- `secrets/` – secrets directory (do not commit real secrets)

## Prerequisites

- Docker Engine + Docker Compose v2
- `htpasswd` installed locally for generating Basic Auth file:
  - Debian/Ubuntu: `sudo apt-get install apache2-utils`
  - RHEL/Fedora/CentOS: `sudo dnf install httpd-tools`

## Quick start

1) Copy env template:

```bash
cp .env.example .env
```

2) Generate Basic Auth secret:

```bash
./scripts/generate-htpasswd.sh admin 'change-me-now'
```

3) Start the stack:

```bash
docker compose up -d
```

Open Adminer:

- `http://localhost:${ADMINER_HTTP_PORT:-8080}`

## Configure the default DB host

Adminer needs a hostname to connect to. Set:

- `ADMINER_DEFAULT_SERVER=db` (in `.env`)

Important: `db` must be resolvable on the **backend** network. This stack intentionally does **not** ship a database container because you may already have Postgres/MySQL elsewhere.

Common approaches:

- Put your database container on the same `backend` network
- Or connect to a reachable hostname/IP (if your environment allows it) — but be intentional about security and firewalling

## Enable metrics (optional)

Start with metrics profile:

```bash
docker compose --profile metrics up -d
```

Services/ports (defaults from `.env.example`):

- NGINX exporter: `:9113`
- Prometheus: `:9090`
- Grafana: `:3000`

Grafana credentials come from `.env`:

- `GRAFANA_ADMIN_USER`
- `GRAFANA_ADMIN_PASSWORD`

## Security warnings (do not ignore)

Adminer is a full-control database admin tool. Exposing it publicly is a classic foot-gun.

Minimum hardening you should implement if this is not strictly internal:

- Put it behind a **VPN** or private network access
- Add **TLS**
- Add **IP allowlisting** and/or SSO (forward-auth)
- Rotate credentials and treat the Adminer endpoint as privileged infrastructure

Basic Auth alone is not a serious control if this is on the public internet.

## Common commands

Stop:

```bash
docker compose down
```

View logs:

```bash
docker compose logs -f --tail=200
```

Recreate after config changes:

```bash
docker compose up -d --force-recreate
```

## Troubleshooting

- **403 on `/stub_status`**: the exporter scrapes from inside the Docker network, not from your laptop. It’s restricted by allow rules. Ensure exporter is on the backend network (it is by default).
- **Adminer shows no DB**: set `ADMINER_DEFAULT_SERVER` to your DB hostname reachable from the backend network.
- **Auth not working**: ensure `./secrets/adminer.htpasswd` exists and contains bcrypt hashes. Regenerate with the helper script.
