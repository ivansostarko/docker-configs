# Matomo Docker Compose (Production-Oriented)

This repository provides a production-leaning Docker Compose stack for **Matomo** including:

- Matomo (PHP-FPM) + Nginx
- MariaDB (utf8mb4 by default)
- Docker **secrets** for credentials (DB, Grafana)
- Healthchecks and sane restart policies
- A dedicated **archiving** container (cron-style loop)
- Optional monitoring profile (Prometheus + Grafana + exporters)

If you do not run archiving, you are choosing slow dashboards and unnecessary DB load. Treat the archiver as required for real traffic.

---

## Contents

- `docker-compose.yml`
- `.env.example` (copy to `.env`)
- `nginx/` (site config)
- `mariadb/` (tuning + charset defaults)
- `matomo/` (wrapper entrypoint + archiver loop)
- `monitoring/` (Prometheus + Blackbox configs)
- `secrets/` (placeholders you must replace)

---

## Prerequisites

- Docker Engine + Docker Compose plugin
- A DNS name for Matomo (recommended)
- If terminating TLS via reverse proxy (recommended): Traefik / Caddy / Nginx Proxy Manager / etc.

---

## Quick start

1. Create `.env` from example:

   ```bash
   cp .env.example .env
   ```

2. Create secret values (replace placeholders):

   ```bash
   # DB user password (used by Matomo)
   openssl rand -base64 32 > secrets/mariadb_password.txt

   # DB root password (used by MariaDB and healthcheck)
   openssl rand -base64 32 > secrets/mariadb_root_password.txt

   # Matomo salt (used by Matomo; keep stable across restarts)
   openssl rand -base64 48 > secrets/matomo_salt.txt

   # Grafana admin password (only used if monitoring profile is enabled)
   openssl rand -base64 24 > secrets/grafana_admin_password.txt
   ```

3. Start the stack:

   ```bash
   docker compose up -d
   ```

4. Browse to `http://<host>:${HTTP_PORT}` and complete the Matomo installer.

5. Confirm archiving is running:

   ```bash
   docker logs -f matomo-cron
   ```

---

## Architecture

### Networks

- `matomo_internal` (internal-only): DB, app, metrics backplane
- `matomo_proxy` (non-internal): Nginx is attached so you can publish ports or integrate with a reverse proxy

### Volumes

- `mariadb_data`: DB persistence
- `matomo_data`: Matomo files (plugins, config, misc runtime files)

Backup both. Backing up only the DB is not enough, and backing up only Matomo is not enough.

---

## Why the Matomo image is built locally here

Matomo does not universally support `*_FILE` style env vars for secrets the way MariaDB does.  
This stack builds a tiny wrapper that:

- reads `MATOMO_DATABASE_PASSWORD_FILE` (mounted secret),
- exports `MATOMO_DATABASE_PASSWORD`,
- then hands off to the upstream Matomo entrypoint.

Files:
- `matomo/entrypoint-with-secrets` (wrapper)
- `matomo/Dockerfile`

---

## Nginx configuration

The Nginx config is a conservative, functional baseline for Matomo + PHP-FPM.

If you run TLS at a reverse proxy in front (recommended), ensure your proxy forwards:
- `Host`
- `X-Forwarded-Proto`
- `X-Forwarded-For`

And ensure Matomo is configured with the correct site URL (Settings → General Settings).

---

## Healthchecks

- MariaDB: `mariadb-admin ping`
- Matomo: validates php-fpm process and config
- Nginx: fetches `/matomo.php`

If you put Matomo behind an external reverse proxy, keep these internal checks as-is.

---

## Archiving (required)

Matomo’s “core:archive” should run on a schedule. This stack includes `matomo-cron` which runs:

- every `${ARCHIVE_FREQUENCY_MINUTES}` minutes
- with `${CONCURRENT_ARCHIVERS}` parallel runs (start at 1; increase only if CPU allows)

Tune frequency and concurrency based on traffic and hardware. If you increase concurrency without monitoring, you will create contention and blame Matomo.

---

## Optional monitoring

Enable the monitoring profile:

```bash
docker compose --profile monitoring up -d
```

This starts:

- Prometheus (`:${PROMETHEUS_PORT}`)
- Grafana (`:${GRAFANA_PORT}`)
- cAdvisor (`:${CADVISOR_PORT}`)
- mysqld-exporter (`:${MYSQLD_EXPORTER_PORT}`)
- blackbox-exporter (`:${BLACKBOX_EXPORTER_PORT}`)

### mysqld-exporter credentials

Edit `secrets/mysqld_exporter_my.cnf` and set a user that can read performance_schema metrics.

Minimum example (you must create the DB user yourself):

```ini
[client]
user=exporter
password=REPLACE_ME
host=mariadb
port=3306
```

Then grant in MariaDB (connect as root and run):

```sql
CREATE USER 'exporter'@'%' IDENTIFIED BY 'REPLACE_ME';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
FLUSH PRIVILEGES;
```

---

## Backups

At minimum:

- `mariadb_data` (database)
- `matomo_data` (Matomo files)

Example (basic, host-level):

```bash
docker exec -i matomo-mariadb mariadb-dump -uroot -p"$(cat secrets/mariadb_root_password.txt)" --single-transaction ${MARIADB_DATABASE} > matomo.sql
docker run --rm -v matomo_matomo_data:/data -v "$PWD":/backup alpine tar -czf /backup/matomo_data.tar.gz -C /data .
```

For serious environments: snapshot volumes at the storage layer, and verify restores.

---

## Upgrades

1. Stop containers:
   ```bash
   docker compose down
   ```
2. Update `MATOMO_IMAGE` / container tags intentionally.
3. Start:
   ```bash
   docker compose up -d --build
   ```
4. Review Matomo admin UI for any required DB migrations.

If you use `:latest`, you are asking for surprise breakage.

---

## Troubleshooting

- Nginx 502:
  - `docker logs matomo-app`
  - ensure Matomo container is healthy and PHP-FPM is running
- Installer can’t reach DB:
  - confirm secrets exist and contain no trailing spaces/newlines issues
  - `docker exec -it matomo-mariadb mariadb -u${MARIADB_USER} -p` from inside network
- High load:
  - confirm archiving is running
  - reduce archiving frequency if you’re saturating CPU
  - enable monitoring before guessing

---

## Security baseline (do this)

- Put Matomo behind TLS (reverse proxy).
- Restrict admin access (IP allowlists or VPN).
- Don’t publish MariaDB ports to the host.
- Regularly update images (controlled cadence).
- Enable backups and test restore.

