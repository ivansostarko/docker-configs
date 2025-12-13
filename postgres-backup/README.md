# PostgreSQL Backup (pg_dump) — Docker Compose

This repository provides a production-oriented **logical backup** stack for PostgreSQL using `pg_dump`, including:

- Scheduled backups via **supercronic**
- Retention policy (days + minimum count)
- Checksums per backup (`sha256`) + `latest` symlinks
- Healthcheck: fails if the last successful backup is too old
- Optional **Prometheus metrics** via **Pushgateway** (bundled Prometheus config included)
- Reasonable container hardening defaults

## What this is (and is not)

- This is **logical backup** (`pg_dump`). It is portable and restore-friendly.
- This is **not** a physical replica / PITR stack. If you need point-in-time recovery, use WAL archiving + `pg_basebackup`/`pgBackRest`/`barman`.

## Quick start

1) Create directories (already present, but safe to re-run):

```bash
mkdir -p data/backups data/state
```

2) Create your `.env`:

```bash
cp .env.example .env
```

3) Set secrets (do **not** commit these):

Edit the files under `./secrets/`:

- `pg_host.txt` (hostname reachable from the container; e.g., `postgres`)
- `pg_port.txt` (usually `5432`)
- `pg_user.txt`
- `pg_password.txt`
- `pg_databases.txt` (comma or space-separated list)

4) Start:

```bash
docker compose up -d --build
```

## Scheduling

Control `BACKUP_SCHEDULE` in `.env` using cron format. Example:

- Daily 02:00: `0 2 * * *`
- Every 6 hours: `0 */6 * * *`

## Backup formats

Set `BACKUP_FORMAT`:

- `custom` (recommended): `pg_dump -Fc` producing `.dump` files (use `pg_restore`).
- `plain`: SQL dump piped through gzip producing `.sql.gz`.

## Retention

- `BACKUP_KEEP_DAYS`: deletes backups older than N days
- `BACKUP_KEEP_MIN_COUNT`: keeps at least N newest backups per database

## Healthcheck

The container becomes **unhealthy** if the most recent successful backup is older than:

- `MAX_BACKUP_AGE_SECONDS` (default 26 hours)

This prevents “silent backup death.” If it’s unhealthy, treat it as an incident.

## Metrics (Prometheus)

If `PUSHGATEWAY_URL` is set (default points to the included `pushgateway` service), each run pushes:

- `pg_backup_last_run_timestamp`
- `pg_backup_last_duration_seconds`
- `pg_backup_last_exit_code`
- `pg_backup_last_bytes`

Prometheus is included for convenience and scrapes the Pushgateway.

## Restore test (you must do this)

A backup that hasn’t been restored is untrusted. Minimal restore drill:

### For `custom` format (.dump)

```bash
# Example restore into a test DB
createdb -h <host> -U <user> restore_test
pg_restore -h <host> -U <user> -d restore_test /path/to/appdb_YYYYmmddTHHMMSSZ.dump
```

### For `plain` format (.sql.gz)

```bash
gunzip -c /path/to/appdb_YYYYmmddTHHMMSSZ.sql.gz | psql -h <host> -U <user> -d restore_test
```

## Hard truths (don’t ignore)

1. **Local disk is not offsite.** If the host dies or gets ransomware, you lose backups.
2. **Rotate credentials.** Use a dedicated `backup_user` with least privileges necessary.
3. **Automate restore tests.** Weekly is a baseline; daily for high-value systems.

## Common next steps

- Add offsite replication (S3/Backblaze/NAS) with immutability/versioning.
- Add encryption at rest (e.g., restic to an encrypted repo).
- Add PITR via WAL archiving (pgBackRest/barman) if your RPO/RTO demands it.
