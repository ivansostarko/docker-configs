# Postgres Archive Stack (Docker Compose)

This package provides a hardened PostgreSQL 16 service with:
- Docker **secrets** for the database password (no plaintext password in `docker-compose.yml`)
- Docker **configs** for `postgresql.conf` and `pg_hba.conf`
- Healthcheck (`pg_isready`)
- Sensible operational defaults (ulimits, shm_size, stop grace period)
- Prometheus **metrics** via `postgres-exporter`

## Contents

```
.
├─ docker-compose.yml
├─ .env.example
├─ secrets/
│  └─ pg_archive_db_password.txt
└─ config/
   └─ postgres/
      ├─ postgresql.conf
      ├─ pg_hba.conf
      └─ initdb/        (optional init scripts)
```

## Quick start

1) Create your `.env` from the example:

```bash
cp .env.example .env
```

2) Set a real password:

```bash
# Edit this file and replace CHANGE_ME...
nano secrets/pg_archive_db_password.txt
```

3) Start the stack:

```bash
docker compose up -d
```

4) Validate health:

```bash
docker ps
docker inspect --format='{{json .State.Health}}' postgres | jq
```

## Connectivity guidance (do not skip)

By default the compose file publishes Postgres on **localhost** only:

- `${PG_ARCHIVE_DB_BIND:-127.0.0.1}:${PG_ARCHIVE_DB_PORT:-5432}:5432`

If you change this to `0.0.0.0`, you are choosing to expose your database to the network. Do that only if you also have:
- strict firewall rules
- strong auth (SCRAM)
- ideally TLS
- monitoring and alerting

## Prometheus metrics

The exporter exposes metrics on:

- `:${POSTGRES_EXPORTER_PORT:-9187}`

In Prometheus, scrape the exporter target (typically `postgres-exporter:9187` if Prometheus is on the same Docker network).

## Notes on config

- `config/postgres/postgresql.conf` contains a conservative baseline. Tune memory settings for your host.
- `config/postgres/pg_hba.conf` is a starter. Lock the CIDRs down to your actual network ranges.

## Operational checklist (brutally practical)

- You do **not** have “security” because you used Docker. If port 5432 is reachable, you are a target.
- Backups are not optional. Add scheduled `pg_dump` or physical backups (e.g., pgBackRest) before you call this “production”.
- Monitor disk: Postgres fails badly when storage fills up.
- Consider TLS if any traffic leaves the host.

## License

Use at your own risk.
