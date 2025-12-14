# MariaDB Docker Compose (Production-Oriented Baseline)

This repository contains a production-grade Docker Compose stack for **MariaDB** with:
- Pinned MariaDB version (`mariadb:11.4`)
- Persistent storage (named volume)
- Docker **secrets** for credentials
- Custom MariaDB config mounted into `/etc/mysql/conf.d`
- Health checks
- Metrics via `prom/mysqld-exporter`
- Optional Adminer UI
- Optional simple logical backup loop (`mariadb-dump`)

## What you get (and what you do not)

### Included
- MariaDB service (`mariadb`)
- Idempotent provisioning job (`mariadb_provision`) to create:
  - app database + app user
  - exporter user for metrics
- Prometheus exporter (`mariadb_exporter`)
- Optional backups (`mariadb_backup`)
- Optional Adminer UI (`adminer`)

### Not included (because it’s environment-specific)
- TLS at the database layer (usually you terminate elsewhere or use a mesh)
- Perimeter controls (firewall/VPN), reverse proxy, SSO for Adminer
- Point-in-time recovery (PITR) / binary log shipping
- HA / replication / Galera cluster (different topology)

If you expose port **3306** to the public Internet, you are creating a predictable incident.

---

## Quick start

### 1) Create secrets

Create these files (use long random values):
- `secrets/mariadb_root_password.txt`
- `secrets/mariadb_app_password.txt`
- `secrets/mariadb_exporter_password.txt`

Placeholders exist in this repo; replace them before running.

### 2) Configure environment

Copy `.env.example` to `.env` and edit:
```bash
cp .env.example .env
```

Minimum required:
- `MARIADB_DATABASE`
- `MARIADB_USER`

### 3) Start MariaDB

```bash
docker compose up -d
```

### 4) (Optional) Enable ops profile (exporter, Adminer, provisioning job)

```bash
docker compose --profile ops up -d
docker compose --profile ops run --rm mariadb_provision
```

### 5) (Optional) Enable backups profile

```bash
docker compose --profile backup up -d
```

---

## Endpoints

- MariaDB is **not published** to the host by default (recommended).
- Exporter is published by default:
  - `http://localhost:${MARIADB_EXPORTER_PORT:-9104}/metrics`
- Adminer (ops profile):
  - `http://localhost:${ADMINER_PORT:-8080}`

---

## Prometheus scrape example

Add this to your Prometheus config:

```yaml
scrape_configs:
  - job_name: mariadb
    static_configs:
      - targets: ["mariadb_exporter:9104"]
```

---

## Files

- `docker-compose.yml` — stack definition
- `.env.example` — environment template
- `mariadb/conf.d/99-custom.cnf` — MariaDB configuration overrides
- `scripts/provision-users.sh` — creates app + exporter users (idempotent)
- `scripts/backup-loop.sh` — periodic logical dumps with retention
- `secrets/*.txt` — secret files (replace placeholders)

---

## Operational guidance (blunt but accurate)

- **Backups without restore tests are worthless.** Do a restore drill regularly.
- **Pin images.** Avoid `latest` for MariaDB.
- **Monitor.** At minimum scrape exporter and set alerts (disk, replication if any, connection saturation, slow queries).
- **Capacity tune** `innodb_buffer_pool_size`, `innodb_log_file_size`, and disk IOPS to your workload.
- If you need HA, do not bolt it onto this. Use a topology designed for it (replication/Galera) and plan failover.

---

## Common commands

```bash
# logs
docker compose logs -f mariadb

# open shell
docker exec -it mariadb bash

# connect with mariadb client
docker exec -it mariadb mariadb -uroot -p

# stop stack
docker compose down

# stop + remove volumes (DATA LOSS)
docker compose down -v
```
