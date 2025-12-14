# Databack (long2ice/databack) — Docker Compose Stack

This repository provides a production-oriented `docker-compose.yml` for **Databack** with:

- Databack (Web UI)
- PostgreSQL (Databack metadata DB)
- Redis (Rearq queue backend)
- Optional dedicated worker(s)
- Optional Prometheus exporters (Postgres + Redis)
- Docker secrets (used by Postgres; Databack itself still requires URL-style envs)

Upstream docs show deployment using `network_mode: host` and a plain `.env` file. This stack avoids host networking and provides a more conventional Compose layout with explicit ports, network, volumes, and healthchecks. 

## Sources / upstream references

- Databack README (deployment/config/worker guidance): https://github.com/long2ice/databack 
- Awesome Docker Compose sample: https://awesome-docker-compose.com/apps/database-backup/databack

## Directory structure

```text
.
├─ docker-compose.yml
├─ .env
├─ README.md
├─ databack/
│  └─ app.env
├─ scripts/
│  └─ databack-entrypoint.sh
└─ secrets/
   ├─ postgres_password.txt
   ├─ databack_secret_key.txt
   └─ sentry_dsn.txt
```

## 1) Prerequisites

- Docker Engine + Docker Compose v2
- A reverse proxy is optional; by default this stack publishes Databack on `DATABACK_HTTP_PORT`.

## 2) Configure secrets (mandatory)

Edit these files:

- `secrets/postgres_password.txt`
- `secrets/databack_secret_key.txt`

Recommended commands:

```bash
openssl rand -base64 36 > secrets/postgres_password.txt
openssl rand -base64 48 > secrets/databack_secret_key.txt
```

If you use Sentry, set `secrets/sentry_dsn.txt`; otherwise leave it empty.

## 3) Configure environment

### Compose `.env`

Adjust ports and general settings in `.env`.

Important detail: **Upstream documentation does not state the internal container port** when not using `network_mode: host`. This stack defaults to `DATABACK_INTERNAL_PORT=8000`. If the UI is not reachable, check:

```bash
docker logs databack
```

…and update `DATABACK_INTERNAL_PORT` accordingly.

### Databack `databack/app.env`

Databack expects the following variables (as per upstream):

- `DB_URL`
- `REDIS_URL`
- `SENTRY_DSN` (optional)
- `ENV`
- `WORKER`
- `SECRET_KEY`

**You must change at least**:

- `SECRET_KEY`
- `DB_URL` password portion

Example (Postgres metadata DB in this stack):

```env
DB_URL=postgres://databack:<POSTGRES_PASSWORD>@postgres:5432/databack
SECRET_KEY=<LONG_RANDOM_STRING>
```

Blunt truth: Databack uses URL-based config, which means **you cannot fully avoid secrets in environment variables** unless you build a small wrapper image that reads Docker secrets and constructs `DB_URL`/`SECRET_KEY` at runtime. A placeholder helper script is included under `scripts/` for that scenario.

## 4) Start the stack

```bash
docker compose up -d
```

Databack will be reachable on:

- `http://localhost:${DATABACK_HTTP_PORT}`

## 5) Optional: dedicated workers

Upstream: Databack starts a builtin worker when `WORKER=True`. If you want multiple workers, you run:

```bash
rearq databack.tasks:rearq worker
```

This stack provides a `worker` service under a Compose profile.

Important: do not run both builtin worker and dedicated workers at the same time, or you risk duplicate job execution.

Enable worker profile:

```bash
docker compose --profile worker up -d
```

If you enable dedicated workers, set `WORKER=False` on the `databack` service (in `databack/app.env`) so only the dedicated workers process jobs.

## 6) Optional: metrics exporters

Enable exporters:

```bash
docker compose --profile metrics up -d
```

Exporters will be published to the host:

- Postgres exporter: `http://localhost:${POSTGRES_EXPORTER_PORT}/metrics`
- Redis exporter: `http://localhost:${REDIS_EXPORTER_PORT}/metrics`

## 7) Backups persistence

This stack creates a named volume:

- `databack_backups` mounted at `${BACKUP_LOCAL_DIR}`

If you use Databack “Local storage”, point it at `${BACKUP_LOCAL_DIR}` so backups land on the volume.

## 8) Operational guidance (what will bite you)

- If you bind Databack publicly, put it behind TLS + authentication at the reverse proxy layer. This is an admin UI.
- Backups are only as safe as your credentials: use least-privilege DB users and scoped S3 credentials.
- Verify restore procedures. If you do not test restores, you do not have backups.

## Useful commands

```bash
# Logs
docker logs -f databack

# Health/status
docker compose ps

# Stop
docker compose down

# Stop and delete volumes (destructive)
docker compose down -v
```
