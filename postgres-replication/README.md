# PostgreSQL Streaming Replication (Docker Compose)

This package runs **PostgreSQL streaming replication** using Docker Compose:

- `pg-primary` — primary (WAL sender)
- `pg-replica1` — hot standby replica (WAL receiver)
- `postgres-exporter-primary` / `postgres-exporter-replica1` — Prometheus exporters
- `prometheus` — optional Prometheus server (scrapes exporters)

## What this is (and isn't)

- **Is:** physical streaming replication using `pg_basebackup` + `standby.signal`.
- **Isn't:** a complete DR/backup solution. Replication does not protect you from operator error, corruption, or ransomware. Add `pgBackrest` or `WAL-G` if you care about recoverability.

## Prerequisites

- Docker + Docker Compose plugin (`docker compose version`)
- Host ports (defaults; configurable in `.env`):
  - Primary: `5432`
  - Replica: `5433`
  - Exporters: `9187`, `9188`
  - Prometheus UI: `9090`

## Quick start

1) Configure secrets:

```bash
cd postgres-replication
vi secrets/postgres_password.txt
vi secrets/repl_password.txt
```

2) Start:

```bash
docker compose up -d
```

3) Validate replication (on primary):

```bash
docker exec -it pg-primary psql -U appuser -d appdb -c "SELECT * FROM pg_stat_replication;"
```

4) Validate replay delay (on replica):

```bash
docker exec -it pg-replica1 psql -U appuser -d appdb -c "SELECT now() - pg_last_xact_replay_timestamp() AS replay_delay;"
```

## Metrics

- Primary exporter: `http://localhost:9187/metrics`
- Replica exporter: `http://localhost:9188/metrics`
- Prometheus UI: `http://localhost:9090`

## Common operations

### Restart
```bash
docker compose restart
```

### Recreate replica from scratch
This deletes the replica volume and forces a fresh base backup:

```bash
docker compose down
docker volume rm pg-repl_pg_replica1_data || true
docker compose up -d
```

## Security and reliability notes (non-negotiable if this matters)

- Do **not** expose Postgres to the public Internet.
- Do **not** widen `pg_hba.conf` CIDRs casually (that is your blast radius).
- Replication slots can retain WAL and fill disks if a replica falls behind. Monitor slot and disk usage.
- WAL archiving to a local Docker volume is not a real backup. Use off-host backups.

## Troubleshooting

### Replica never shows up in `pg_stat_replication`
```bash
docker logs -f pg-replica1
docker logs -f pg-primary
```

Most common causes:
- `pg_hba.conf` doesn't allow replication user from Docker subnet
- wrong password in `secrets/repl_password.txt`
- subnet mismatch if you changed the Docker network range

### WAL / disk growth on primary
Inspect replication slots:

```bash
docker exec -it pg-primary psql -U appuser -d appdb -c "SELECT slot_name, active, restart_lsn FROM pg_replication_slots;"
```
