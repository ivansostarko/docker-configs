# MySQL Docker Compose Stack (MySQL 8.4 + Secrets + Healthchecks + Metrics)

This stack provides a practical, production-leaning baseline for running **MySQL** with:

- Persistent data and log volumes
- Custom `my.cnf` configuration
- Healthchecks
- Secrets-based credential handling
- Optional **metrics** via `mysqld_exporter` + optional Prometheus + Grafana
- Optional Adminer UI (for ops only)

## What you get (by default)

- **MySQL** on `127.0.0.1:3306` (safe default: not exposed publicly)
- Internal-only Docker network (`internal: true`) so only other containers can reach MySQL

## Profiles

- `monitoring`: enables `mysqld_exporter`, Prometheus, Grafana
- `ops`: enables Adminer

## 1) Quick start

```bash
# from the repo root
cp .env.example .env

# create secrets (strong random values)
mkdir -p secrets
openssl rand -base64 32 > secrets/mysql_root_password.txt
openssl rand -base64 32 > secrets/mysql_app_password.txt
openssl rand -base64 32 > secrets/mysql_exporter_password.txt
openssl rand -base64 32 > secrets/grafana_admin_password.txt
chmod 600 secrets/*.txt

# start MySQL
docker compose up -d

# optional: start monitoring stack
docker compose --profile monitoring up -d

# optional: start Adminer
docker compose --profile ops up -d
```

## 2) Connect to MySQL

From the host (default, local only):

```bash
mysql -h 127.0.0.1 -P 3306 -u appuser -p
```

Password is in `secrets/mysql_app_password.txt`.

From another container on the same `db_internal` network:

- Host: `mysql`
- Port: `3306`

## 3) Bootstrap behavior (important)

The MySQL image only runs initialization scripts when the data directory is empty.

- First boot creates:
  - database `${MYSQL_DATABASE}`
  - app user `${MYSQL_USER}` with password from `MYSQL_PASSWORD_FILE`
- The script `mysql/initdb/02-create-exporter-user.sh` creates the monitoring user `exporter` using the secret in `secrets/mysql_exporter_password.txt`.

If you need to re-run bootstrap, you must delete the volume **and you will lose all data**:

```bash
docker compose down
docker volume rm mysql_data
```

## 4) Metrics

Enable monitoring profile:

```bash
docker compose --profile monitoring up -d
```

Endpoints (defaults):

- Exporter metrics: `http://127.0.0.1:9104/metrics`
- Prometheus: `http://127.0.0.1:9090`
- Grafana: `http://127.0.0.1:3000` (admin user from `.env`; password from `secrets/grafana_admin_password.txt`)

## 5) Security notes you should not ignore

1. **Do not expose 3306 publicly** unless you have a clear private-network / VPN / TLS strategy.
2. Use **least-privilege** grants for your application user; do not grant global privileges.
3. Treat `secrets/` as sensitive. Do not commit it, do not copy it into images, do not paste it into logs.
4. Backups: a Docker volume is not a backup. Implement automated logical dumps or physical backups + off-host storage.

## 6) Files you will likely edit

- `mysql/conf.d/my.cnf` — MySQL server configuration
- `.env` — ports and non-secret parameters
- `mysql/initdb/*.sql` / `mysql/initdb/*.sh` — bootstrap logic

## 7) Operational commands

```bash
# status
docker compose ps

# follow logs
docker compose logs -f mysql

# exec into mysql container
docker exec -it mysql bash

# mysql shell inside container
docker exec -it mysql mysql -uroot -p
```

## 8) Troubleshooting

- If MySQL fails immediately, check:
  - `docker compose logs mysql`
  - whether secrets files exist and are readable
- If exporter is up but shows no metrics:
  - verify exporter user exists (created only on first init)
  - verify `secrets/mysql_exporter_password.txt` matches the user password

