# Mattermost (Team Edition) + Postgres (Docker Compose)

This folder provides a hardened, production-oriented Docker Compose setup for **Mattermost Team Edition** backed by **Postgres 15**.

## What’s improved vs a “basic” compose

- **No `:latest`**: the Mattermost image tag is pinned via `MM_IMAGE_TAG` (you upgrade deliberately).
- **Secrets**: DB password is stored as a **Docker secret** (`secrets/mm_db_password.txt`), not in `.env`.
- **Healthchecks**: Postgres and Mattermost are health-checked; Mattermost waits for DB readiness.
- **Network isolation**: database traffic runs on an **internal** bridge network; Postgres is not reachable from your shared app network.
- **Hardening**: `no-new-privileges`, `cap_drop: ALL`, and sane `ulimits`.

## Files

```text
.
├── docker-compose.yml
├── .env.example
├── config/
│   └── mattermost/
│       └── entrypoint.sh
└── secrets/
    ├── mm_db_password.txt.example
    └── (you create) mm_db_password.txt
```

## Prerequisites

- Docker + Docker Compose plugin (modern Docker Engine).
- An **external** network named `asterix_network` already created (because the compose declares it as `external: true`).

Create the external network once:

```bash
docker network create asterix_network
```

If you do not want an external shared network, change `asterix_network` to a normal compose-managed network.

## Quick start

1) Copy the environment file:

```bash
cp .env.example .env
```

2) Create the DB password secret file:

```bash
cp secrets/mm_db_password.txt.example secrets/mm_db_password.txt
# Edit secrets/mm_db_password.txt and set a strong random password.
chmod 0400 secrets/mm_db_password.txt
chmod +x config/mattermost/entrypoint.sh
```

3) Start:

```bash
docker compose up -d
```

4) Verify health:

```bash
docker ps
docker compose logs -f mattermost
```

## First admin user

Do **not** assume “first admin” environment variables exist or work for your image. Mattermost commonly makes the first created user a System Admin, or you manage users via CLI tooling (`mmctl`) after startup.

Recommendation: document your first-run procedure and keep it repeatable.

## Reverse proxy note (recommended)

If you are running Traefik or Nginx in front of Mattermost:

- Remove `ports:` from the `mattermost` service.
- Attach `mattermost` to your proxy network.
- Ensure the proxy is configured for **WebSockets** and correct headers.
- Keep Postgres on the internal network only.

## Metrics

This compose includes an **optional** `postgres-exporter` service for Prometheus scraping (DB metrics).

Mattermost application metrics:
- You can enable performance monitoring with `MM_METRICS_ENABLE=true`.
- Whether `/metrics` is accessible depends on your Mattermost edition/licensing and configuration.
- If metrics are blocked, you still get strong observability via node/container metrics + Postgres exporter.

## Operational guidance (non-negotiable)

- Pin versions; test upgrades in staging; then promote.
- Back up `mattermost_db_data` **and** Mattermost volumes (`mattermost_data`, etc.).
- Treat `.env` as sensitive (it still contains non-secret config that can help attackers).
- Do not publish Postgres ports to the host.

## Backup/restore (high-level)

Back up:
- `mattermost_db_data` (database)
- `mattermost_data`, `mattermost_config`, `mattermost_plugins`, `mattermost_client_plugins`, `mattermost_logs` (application state)

If you want, I can add:
- scheduled DB dumps (cron container),
- WAL archiving,
- S3-compatible backups (e.g., MinIO),
- or a full Prometheus scrape config snippet.
