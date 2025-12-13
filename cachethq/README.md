# CachetHQ + MariaDB (Docker Compose)

This repository contains a hardened, production-oriented Docker Compose stack for **CachetHQ** (status page) backed by **MariaDB**, with an **optional Prometheus mysqld_exporter** profile.

## Why this exists (and what you need to accept)

Cachet is effectively **stale** (the upstream Docker image has not had frequent releases for years). Running it in production is a conscious security and maintenance trade-off. If you can choose a maintained status page, you should.

What this stack improves over a minimal compose:
- Pinned Cachet image (no `:latest` in production)
- Healthchecks and dependency gating (Cachet waits for DB)
- Durable volumes for Cachet + MariaDB
- Docker secrets for MariaDB passwords (`*_FILE`)
- Optional metrics exporter (Prometheus) via Compose profile
- Basic container hardening (no-new-privileges, drop caps, tmpfs for `/tmp`)

## Repository layout

```
.
├── docker-compose.yml
├── .env.example
├── .gitignore
├── config/
│   └── cachet-db/
│       ├── z-cachet.cnf
│       └── initdb/
│           └── 01_exporter.sql
└── secrets/
    ├── cachet_db_password.txt
    ├── cachet_db_root_password.txt
    └── mysqld_exporter_my.cnf
```

## Quick start

### 1) Create (or reuse) the shared Docker network

This compose expects an **external** network named `asterix_network`:

```bash
docker network create asterix_network
```

If you do not want an external network, edit `docker-compose.yml`:
- set `external: false`
- or remove the `external`/`name` lines and let Compose create it.

### 2) Create your `.env`

Copy the template and edit values:

```bash
cp .env.example .env
```

Mandatory:
- `CACHET_APP_URL`
- `CACHET_APP_KEY` (see below)
- DB variables

### 3) Create secrets (do not commit these)

The included `secrets/` files are **examples**. Replace their contents with real passwords:

- `secrets/cachet_db_password.txt`
- `secrets/cachet_db_root_password.txt`
- `secrets/mysqld_exporter_my.cnf` (only if you use metrics profile)

### 4) Start the stack

```bash
docker compose up -d
```

### 5) Generate `APP_KEY` (required)

Run inside the container (after the stack is up):

```bash
docker compose exec cachet php artisan key:generate --show
```

Copy the output (should start with `base64:`) into `.env` as `CACHET_APP_KEY`, then restart:

```bash
docker compose up -d
```

## Metrics (optional)

This stack includes `cachet-db-exporter` under the Compose profile `metrics`.

To start with metrics:

```bash
docker compose --profile metrics up -d
```

- Exporter binds to host port `CACHET_DB_EXPORTER_PORT` (default `9104`).
- If your Prometheus is on the same Docker network, you can remove the exporter `ports:` block and scrape it over the internal network.

### Exporter user

If you want automatic provisioning of an exporter user on first DB init:
- edit `config/cachet-db/initdb/01_exporter.sql`
- set the password (or provision manually)

If the MariaDB volume already exists, init scripts will **not** re-run. In that case, create the exporter user manually.

## Operational hard truths (do not ignore)

- Do not expose Cachet publicly without TLS and security controls. Put it behind a reverse proxy (Traefik/Nginx/Caddy) with HTTPS.
- Cachet is old. Treat it like legacy software: isolate it, limit exposure, and patch the host aggressively.

## Commands

Stop:
```bash
docker compose down
```

Stop and remove volumes (deletes all DB data):
```bash
docker compose down -v
```

Logs:
```bash
docker compose logs -f --tail=200
```

## License

Use at your own risk.
