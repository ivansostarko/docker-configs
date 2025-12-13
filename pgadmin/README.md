# pgAdmin + Postgres (Docker Compose)

This stack provides:

- **PostgreSQL** (pinned image tag)
- **pgAdmin 4** web GUI
- **Prometheus Postgres Exporter** for metrics
- Docker **secrets** (no passwords in `.env`)
- Provisioned pgAdmin server config (`servers.json`)
- Custom `postgresql.conf` and `pg_hba.conf`
- Healthchecks

## Contents

- `docker-compose.yml`
- `.env` (non-secret configuration)
- `secrets/` (password files; **do not commit**)
- `postgres/conf/` (Postgres config)
- `postgres/init/` (first-run init scripts)
- `pgadmin/` (server provisioning + preferences)
- `postgres-exporter/` (exporter config)

## Prerequisites

- Docker Engine + Docker Compose v2
- Ports free on localhost:
  - pgAdmin: `127.0.0.1:${PGADMIN_PORT:-5050}`
  - Postgres: `127.0.0.1:${POSTGRES_PORT:-5432}`

## Quick start

1) Create secrets (replace the placeholder values):

```bash
mkdir -p secrets
openssl rand -base64 36 > secrets/pgadmin_password.txt
openssl rand -base64 36 > secrets/postgres_password.txt
openssl rand -base64 36 > secrets/pgadmin_db_password.txt
openssl rand -base64 36 > secrets/postgres_exporter_password.txt
```

2) Start the stack:

```bash
docker compose up -d
docker compose ps
```

3) Open pgAdmin:

- URL: `http://127.0.0.1:${PGADMIN_PORT:-5050}`
- Login:
  - Email: `${PGADMIN_DEFAULT_EMAIL}`
  - Password: content of `secrets/pgadmin_password.txt`

## pgAdmin: connecting to Postgres

This stack provisions a server definition via `pgadmin/servers.json`.
Default values:

- Host: `postgres`
- Port: `5432`
- Database: `${POSTGRES_DB}`
- User: `pgadmin`
- Password: content of `secrets/pgadmin_db_password.txt`

If you change DB/user names, update **both**:
- `.env`
- `pgadmin/servers.json`

## Metrics (Prometheus)

The exporter is exposed to the Docker network on:

- `http://pgadmin-postgres-exporter:9187/metrics` (from containers on `backend`)

If you run Prometheus in Docker, scrape that endpoint on the `backend` network.

### What exporter user can see

The init script creates a `postgres_exporter` role with `pg_monitor` grants.
If you need deeper metrics, you may be tempted to make it superuser. Don’t.
Fix the permission issue properly or accept the metric limitation.

## Security notes (read this, or you will create your own incident)

- **pgAdmin is not an Internet app by default.** This compose binds pgAdmin to `127.0.0.1`. Keep it that way unless you put:
  - TLS termination,
  - strong authentication (SSO/2FA),
  - IP allow-listing / VPN,
  - and monitoring in front of it.
- Postgres also binds to `127.0.0.1` on the host. Containers can still talk to it via the internal `backend` network.
- Keep `secrets/` out of git. Add this to `.gitignore` if you use git:

```gitignore
secrets/
postgres_data/
pgadmin_data/
```

## Important operational behavior

### Init scripts run only once

Files under `postgres/init/` run only when the `postgres_data` volume is **empty** (first boot).
If you change role passwords or permissions later, apply changes manually or recreate the volume:

```bash
docker compose down -v
docker compose up -d
```

That **destroys** your database. Use backups.

## Backup / restore (minimal)

Backup:

```bash
docker exec -t pgadmin-postgres pg_dump -U "${POSTGRES_USER}" "${POSTGRES_DB}" > backup.sql
```

Restore:

```bash
cat backup.sql | docker exec -i pgadmin-postgres psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}"
```

## Troubleshooting

- Check logs:

```bash
docker compose logs -f --tail=200 postgres
docker compose logs -f --tail=200 pgadmin
```

- If pgAdmin is “up” but login fails:
  - Confirm the secret file content has no trailing whitespace surprises.
  - Ensure you didn’t reuse an old `pgadmin_data` volume with a new password; pgAdmin stores internal state in that volume.

- If Postgres roles didn’t get created:
  - You likely already had an existing `postgres_data` volume, so init didn’t run.

## Upgrade guidance

- **Do not** change multiple moving parts at once.
- Upgrade Postgres only with a plan (pg_dump/pg_restore or `pg_upgrade`).
- Upgrade pgAdmin/exporter independently and verify.

---

Generated: 2025-12-13
