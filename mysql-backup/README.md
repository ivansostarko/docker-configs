# MySQL Backup (Docker Compose)

This stack runs automated **mysqldump** backups on a schedule, stores backups in a durable Docker volume, enforces retention, provides a **healthcheck** based on the timestamp of the last successful backup, and can optionally publish metrics to a **Prometheus Pushgateway**.

## What you get

- Scheduled backups (cron format).
- Gzip compression (optional).
- Retention by age and by count.
- Credentials stored as Docker **secrets** (not in `.env`).
- Healthcheck that fails if there is no recent successful backup.
- Optional metrics pushed to Pushgateway (enable compose profile `metrics`).

## Folder layout

```
.
├─ docker-compose.yml
├─ .env.example
├─ secrets/
│  ├─ mysql_backup_user.txt
│  └─ mysql_backup_password.txt
└─ mysql_backup/
   ├─ Dockerfile
   ├─ entrypoint.sh
   ├─ backup.sh
   ├─ healthcheck.sh
   └─ config/
      └─ backup.defaults.env
```

## Quick start

1) Create secret files (do not commit these):

```bash
mkdir -p secrets
printf '%s' 'backup_user'     > secrets/mysql_backup_user.txt
printf '%s' 'strongpassword'  > secrets/mysql_backup_password.txt
chmod 600 secrets/*.txt
```

2) Create `.env` from example:

```bash
cp .env.example .env
# edit .env to point MYSQL_HOST / MYSQL_PORT to your database
```

3) Start the backup service:

```bash
docker compose up -d --build
```

Backups will appear in the `mysql_backup_data` volume under `/backups` inside the container.

## Enable metrics (optional)

If you have Prometheus scraping Pushgateway, enable the metrics profile:

```bash
docker compose --profile metrics up -d
```

Prometheus should scrape `pushgateway:9091` (if Prometheus is on the same Docker network) or `host:9091` (if Prometheus is outside Docker and you exposed the port).

Metrics pushed include:

- `mysql_backup_last_success_timestamp_seconds`
- `mysql_backup_last_duration_seconds`
- `mysql_backup_last_size_bytes`
- `mysql_backup_last_exit_code`

## Restore examples

### Restore a single database backup

```bash
# Example: restore into a running MySQL container/service
gunzip -c mysql_2025-01-01_03-00-00.sql.gz | mysql -h <host> -P 3306 -u <user> -p <db>
```

### Restore all databases

```bash
gunzip -c mysql_all_2025-01-01_03-00-00.sql.gz | mysql -h <host> -P 3306 -u <user> -p
```

## TLS/SSL

If your MySQL requires TLS:
- Mount CA/client certs into the backup container (add a bind mount in `docker-compose.yml`)
- Set `MYSQL_SSL_MODE` in `.env` (e.g., `VERIFY_CA` or `VERIFY_IDENTITY`)
- Optionally add extra `mysqldump` flags via `MYSQL_BACKUP_EXTRA_DUMP_ARGS`

## Operational notes (read this, it matters)

- If `MYSQL_HOST` is wrong or not reachable from the container, you will silently get *zero backups* unless you monitor logs/healthcheck/metrics.
- The healthcheck is only as good as your `HEALTH_MAX_AGE_SECONDS`. If you run weekly backups and keep the default (~25h), the container will look “unhealthy” most of the week. Set it realistically.
- Storing backups in a Docker volume does not automatically mean “safe”. If the host dies and you have no off-host copy, you still lose backups. For real resilience, add off-host replication (S3/rclone/NAS) to the script.

## Useful commands

Tail logs:

```bash
docker logs -f mysql_backup
```

List backups in the volume:

```bash
docker exec -it mysql_backup ls -lah /backups
```

Run an on-demand backup:

```bash
docker exec -it mysql_backup /usr/local/bin/backup.sh
```

## License

Use at your own risk. Verify restores regularly.
