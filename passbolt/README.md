# Passbolt (CE) – Docker Compose (production-oriented)

This bundle provides a hardened-by-default Passbolt Community Edition stack using:
- Passbolt server container
- MariaDB (default DB for Passbolt Docker deployments)
- Optional monitoring profile (Prometheus, Grafana, cAdvisor, mysqld-exporter)

## 1) Files / directories

- `docker-compose.yml`
- `.env.example` (copy to `.env` and edit)
- `secrets/` (create files listed below; do **not** commit)
- `config/mariadb/init/` (DB init scripts)
- `config/mariadb/exporter/.my.cnf` (mysqld-exporter DSN file)
- `config/prometheus/prometheus.yml`
- `config/grafana/provisioning/`

## 2) Required prerequisites (non-negotiable)

1. **Set NTP / time sync on the host.** Passbolt explicitly calls out NTP as required to avoid GPG authentication issues.
2. **Set a real SMTP server** (registration/recovery flows depend on email).
3. **Set `APP_FULL_BASE_URL` correctly** (canonical URL; do not improvise).

If you skip any of these, you will waste time on avoidable, self-inflicted issues.

## 3) Create secrets

Create these files under `./secrets/`:

### Database (required)
- `db_host.txt`  (set to `db` if using the bundled DB container)
- `db_name.txt`
- `db_user.txt`
- `db_password.txt`

### SMTP (required)
- `smtp_user.txt`
- `smtp_password.txt`

### TLS cert/key (recommended)
- `tls_cert.crt`
- `tls_key.key`

### Passbolt GPG server keys (recommended to provide explicitly)
- `serverkey.asc`
- `serverkey_private.asc`

### Monitoring (optional)
- `mysql_exporter_password.txt`

## 4) First start

```bash
cp .env.example .env
# edit .env
docker compose up -d
```

### Create the first admin user

From the Passbolt Docker guide, create the first admin by exec'ing into the container and running `register_user` as `www-data`:

```bash
docker compose exec passbolt su -m -c "/usr/share/php/passbolt/bin/cake passbolt register_user   -u admin@example.com -f Admin -l User -r admin" -s /bin/sh www-data
```

It prints a one-time setup URL to finish in the browser.

## 5) Healthchecks

- MariaDB uses the **official** `healthcheck.sh` script with `--connect` and `--innodb_initialized`.
- Passbolt uses `cake passbolt healthcheck` executed as `www-data` (the upstream guidance: do not run Passbolt commands as root).

If you switch to a non-root Passbolt image and healthcheck fails, see the comment in `docker-compose.yml` and adjust the healthcheck command accordingly.

## 6) Monitoring (optional)

Start the monitoring profile:

```bash
docker compose --profile monitoring up -d
```

- Prometheus: `http://<host>:9090`
- Grafana: `http://<host>:3000` (credentials from `.env`)
- cAdvisor: `http://<host>:8081`
- mysqld-exporter: `http://<host>:9104/metrics`

This does **container + database** telemetry. Passbolt itself is not a Prometheus-native app, so do not pretend you have “app metrics” unless you instrument it separately.

## 7) Hard truths / operational notes

- **Pin image tags.** Running `latest` in production is amateur hour.
- **Backups**: you must back up *both* MariaDB and the Passbolt crypto volumes (`passbolt_gpg`, `passbolt_jwt`).
- **Secrets in env vars** are sloppy. Use Docker secrets (this compose does).
- **`APP_FULL_BASE_URL`** must match your real external URL or you will break links, email flows, and clients.


## 3b) DB root password (required in this bundle)

This compose uses `MARIADB_ROOT_PASSWORD_FILE` (via `./secrets/db_root_password.txt`) because:
- You will eventually need controlled admin access for maintenance/backups.
- The optional mysqld-exporter user creation is easiest and most deterministic when root is defined.


