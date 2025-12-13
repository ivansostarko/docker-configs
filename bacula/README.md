# Bacula (Community) Backup Stack — Docker Compose

This repository provides a pragmatic Bacula Community deployment using Docker Compose:

- Bacula Director (`bacula-dir`)
- Bacula Storage Daemon (`bacula-sd`)
- Bacula File Daemon (`bacula-fd`)
- PostgreSQL Catalog (`db`)
- Optional: Bacula-Web UI (`--profile ui`)
- Optional: Prometheus + Grafana + Bacula exporter (`--profile monitoring`)
- Optional: Interactive `bconsole` container (`--profile tools`)

## What you get (and what you do not)

- You **do** get a functional end-to-end Bacula pipeline (catalog → director → storage → client) and a default job that backs up `/data` from the file-daemon container.
- You **do not** get “enterprise-style” support, hardening, or HA by default. If you need HA for the Catalog DB, you must add it.

## Prerequisites

- Docker Engine + Docker Compose v2
- A host path you want to back up (configured via `BACKUP_SOURCE_PATH`)

## Quick start

1) Create secrets (replace values with strong secrets):

```bash
mkdir -p secrets
printf "SuperStrongDbPassword"        > secrets/db_password.txt
printf "SuperStrongSdSecret"          > secrets/bacula_sd_password.txt
printf "SuperStrongFdSecret"          > secrets/bacula_fd_password.txt
printf "SuperStrongConsoleSecret"     > secrets/bacula_bconsole_password.txt
```

2) Edit `.env`

At minimum, set:

- `BACKUP_SOURCE_PATH` to the host path you want backed up
- `DB_PASSWORD_FALLBACK` only if you refuse to use secrets (not recommended)

3) Start core services:

```bash
docker compose up -d
```

4) Optional profiles

Bacula-Web UI:

```bash
docker compose --profile ui up -d
# UI at http://localhost:${BACULA_WEB_PORT}
```

Monitoring (Prometheus/Grafana + exporter):

```bash
docker compose --profile monitoring up -d
# Prometheus: http://localhost:${PROMETHEUS_PORT}
# Grafana:    http://localhost:${GRAFANA_PORT}
```

Interactive console:

```bash
docker compose --profile tools run --rm bconsole
```

## Default backup behavior

- The File Daemon mounts `${BACKUP_SOURCE_PATH}` at `/data` (read-only).
- The Director defines a `FileSet` containing `/data`.
- The schedule runs:
  - Full on 1st Sunday at 03:00
  - Differential on other Sundays at 03:00
  - Incremental Mon–Sat at 03:00

## Restores (high level)

From `bconsole`, typical workflow:

1. `status dir` to verify Director is running
2. `run` to trigger a job manually (for testing)
3. `restore` to select files and restore target

You will likely want to extend the config with:
- Dedicated restore jobs
- Separate pools for full/diff/incr
- Retention tuning and pruning policies

## Security notes (read this)

- **Do not publish ports 9101–9103 to the internet.** The compose keeps them internal.
- Bacula-Web `config.php` contains DB credentials by default. If you use Bacula-Web, put it behind a reverse proxy and treat it as sensitive.
- Back up the Bacula catalog (`pgdata`) or you will eventually lose metadata and hate your past self.

## Files / structure

- `docker-compose.yml` — full stack
- `.env` — environment defaults
- `secrets/` — docker secrets (you must create these)
- `config/templates/` — Bacula configuration templates rendered by `config-render`
- `bacula-web/config.php` — Bacula-Web configuration (optional)
- `monitoring/` — exporter + Prometheus config (optional)

## Operational sanity checks

- Verify core services are healthy:

```bash
docker compose ps
docker compose logs -f bacula-dir bacula-sd bacula-fd db
```

- Check storage volume grows under `bacula_storage` and Bacula logs appear under `bacula_working`.

## Hardening / next steps (recommended)

- Run the catalog DB on dedicated storage and regularly dump it.
- Add offsite replication for the storage archive directory.
- Add TLS (Bacula supports it) if you move any daemon traffic off the Docker host.
- Define separate clients instead of backing up only a mounted host folder.

