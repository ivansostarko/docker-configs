# Uptime Kuma — Docker Compose (Production-leaning)

This repository contains a **production-leaning** Docker Compose setup for **Uptime Kuma** with:
- Persistent storage (`/app/data`) via a named volume (SQLite by default)
- Built-in container healthcheck
- Optional **MariaDB** backend (Uptime Kuma v2)
- Optional **Prometheus** scraper (scrapes Kuma `/metrics`)
- Optional **Traefik** labels for reverse-proxy routing

## What you get (and what you do not)

You get a solid baseline. You do **not** get security by default just because it is containerized.
If you expose Kuma directly to the Internet without TLS and an auth boundary, you are choosing risk.

## Folder structure

```
.
├─ compose.yml
├─ .env.example
├─ README.md
├─ .gitignore
├─ scripts/
│  └─ generate-secrets.sh
├─ prometheus/
│  └─ prometheus.yml
└─ secrets/
   └─ .gitkeep
```

## Prerequisites

- Docker + Docker Compose v2
- (Optional) A reverse proxy network named `proxy` if you keep `proxy` network as `external: true`

Create the external proxy network once:

```bash
docker network create proxy || true
```

## Quick start (SQLite)

1) Copy environment file:

```bash
cp .env.example .env
```

2) Start:

```bash
docker compose -f compose.yml up -d
```

3) Open:

- If you kept local binding: `http://127.0.0.1:3001`

## Healthcheck

The container uses the image’s built-in healthcheck binary:

```yaml
healthcheck:
  test: ["CMD", "extra/healthcheck"]
```

Check status:

```bash
docker ps --format "table {{.Names}}	{{.Status}}"
```

## Option A — Use Traefik (recommended for Internet exposure)

This compose file includes Traefik labels, but they are **disabled by default**.

1) Set in `.env`:

```dotenv
TRAEFIK_ENABLE=true
KUMA_FQDN=kuma.example.com
TRAEFIK_NETWORK=proxy
```

2) Ensure the Traefik container is also on the same external network (`proxy`).

3) Remove port publishing if you want Kuma **only** behind Traefik:
- Comment out the `ports:` section on `uptime-kuma` service.

## Option B — MariaDB backend (Uptime Kuma v2)

Blunt truth: you do not *need* MariaDB for most single-node Kuma installs. SQLite is fine.
Use MariaDB if you know why you need it (HA, external DB policies, etc.).

1) Generate secrets:

```bash
sh scripts/generate-secrets.sh
```

2) Enable DB environment variables (in `compose.yml`, uncomment under `uptime-kuma.environment`):
- `UPTIME_KUMA_DB_TYPE=mariadb`
- `UPTIME_KUMA_DB_HOSTNAME=kuma-mariadb`
- `UPTIME_KUMA_DB_NAME`, `UPTIME_KUMA_DB_USERNAME`
- `UPTIME_KUMA_DB_PASSWORD=/run/secrets/kuma_db_password`

3) Start with profile:

```bash
docker compose -f compose.yml --profile mariadb up -d
```

## Metrics (Prometheus)

### Kuma metrics endpoint

Kuma exposes metrics at:

- `GET /metrics`

You must **enable metrics in the Kuma UI** for the endpoint to emit data.

### Start Prometheus

```bash
docker compose -f compose.yml --profile metrics up -d
```

Prometheus will be available locally (default):

- `http://127.0.0.1:9090`

### Authentication note

Kuma’s `/metrics` authentication behavior changes if you add API keys.
If you care about metrics access control, decide your security model early and enforce it at the reverse proxy.

## Backups

If using SQLite (default), the data lives in the named volume `uptime-kuma-data`.

Backup (example):

```bash
docker run --rm   -v uptime-kuma-data:/data:ro   -v "$PWD":/backup   alpine sh -c "cd /data && tar czf /backup/uptime-kuma-data.tgz ."
```

Restore is the reverse operation.

## Security posture (non-negotiables)

- Do **not** mount `/var/run/docker.sock` unless you accept host-compromise risk.
- Do **not** publish Kuma port to `0.0.0.0` unless you have TLS + an auth boundary.
- Keep `.env` and `secrets/` out of git. This repo includes `.gitignore` for that.

## Common operations

Restart:

```bash
docker compose -f compose.yml restart uptime-kuma
```

Logs:

```bash
docker compose -f compose.yml logs -f uptime-kuma
```

Update (safe-ish baseline):

```bash
docker compose -f compose.yml pull
docker compose -f compose.yml up -d
```

## Troubleshooting

- If the container is `unhealthy`, check logs first:
  ```bash
  docker compose -f compose.yml logs --tail=200 uptime-kuma
  ```
- If Traefik routing fails: confirm both containers share the same Docker network and labels match your Traefik entrypoints.
- If Prometheus shows `DOWN`: confirm metrics are enabled in Kuma UI and the `/metrics` endpoint is reachable from Prometheus.

---

If you want this aligned to your standard stack (your Traefik conventions, your monitoring network, your logging/ELK pipeline), you should treat this as a template and impose your platform standards intentionally.
