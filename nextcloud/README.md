# Nextcloud Docker Compose (Caddy + Postgres + Redis + Cron + Optional Monitoring)

This repository provides a production-focused Nextcloud stack with:
- **Caddy** reverse proxy with automatic HTTPS (ACME)
- **Postgres 16** database
- **Redis** for distributed locking and caching
- **Dedicated cron container** to run background jobs properly
- **Docker secrets** for credentials (no passwords in environment variables)
- Optional **Prometheus + Grafana** monitoring profile plus exporters

## Quick start

1) Copy environment file and edit:

```bash
cp .env.example .env
```

Set at minimum:
- `DOMAIN` (public FQDN)
- `ACME_EMAIL`
- `NEXTCLOUD_ADMIN_USER` (admin username)

2) Create secrets (single-line files)

```bash
mkdir -p secrets
openssl rand -base64 36 > secrets/postgres_password.txt
openssl rand -base64 36 > secrets/redis_password.txt
openssl rand -base64 36 > secrets/nextcloud_admin_password.txt
openssl rand -base64 36 > secrets/grafana_admin_password.txt
```

Exporter token is created after Nextcloud is up (see Monitoring section):
```bash
touch secrets/nextcloud_exporter_token.txt
chmod 600 secrets/*.txt
```

3) Start the stack:

```bash
docker compose up -d
docker compose ps
```

Open:
- `https://$DOMAIN`

## Configure Nextcloud cron mode (important)

After initial install, set background jobs to **Cron** in Nextcloud:
- Administration settings → Basic settings → Background jobs → select **Cron**

(If you skip this, you will eventually get slow file scans, slow previews, stale shares, and random “why is Nextcloud sluggish” symptoms.)

## Monitoring (optional)

Enable monitoring profile:

```bash
docker compose --profile monitoring up -d
```

### Nextcloud exporter token

Create a dedicated Nextcloud user (recommended) such as `exporter` and create an **app password** for it:
- User settings → Security → create app password
Paste that token into:

```bash
secrets/nextcloud_exporter_token.txt
```

Then restart exporter:

```bash
docker compose --profile monitoring restart nextcloud_exporter
```

Grafana:
- Default URL (internal): `http://grafana:3000`
- If you want external access, put Grafana behind Caddy or your existing reverse proxy (recommended with authentication).

## Backups (you are responsible for restores)

At minimum you need:
- Postgres dumps
- Nextcloud volumes (`nextcloud_html`, `nextcloud_data`)
- Caddy state (`caddy_data`, `caddy_config`)

Example Postgres dump:

```bash
docker exec -t nextcloud-postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" > backup.sql
```

A backup you cannot restore is not a backup. Test restores on a separate host.

## Upgrades (do not freestyle)

1) Put Nextcloud into maintenance mode:
```bash
docker exec -u www-data nextcloud-app php occ maintenance:mode --on
```

2) Update image tags intentionally in `docker-compose.yml` (do not run `latest` in production).
3) `docker compose pull && docker compose up -d`
4) Run upgrade:
```bash
docker exec -u www-data nextcloud-app php occ upgrade
```

5) Disable maintenance mode:
```bash
docker exec -u www-data nextcloud-app php occ maintenance:mode --off
```

## Hardening checklist (minimum)

- Use strong secrets and restrict filesystem permissions on `secrets/`
- Keep the host OS patched
- Ensure firewall only exposes 80/443 (and anything else you explicitly intend)
- Set up host-level log rotation
- Implement off-host backups with retention

## Troubleshooting

- Check logs:
```bash
docker compose logs -f --tail=200 nextcloud
docker compose logs -f --tail=200 caddy
```

- Health status:
```bash
docker inspect --format='{{json .State.Health}}' nextcloud-app | jq
```

## Included files

- `docker-compose.yml`
- `caddy/Caddyfile`
- `nextcloud/php-custom.ini`, `nextcloud/opcache.ini`
- Optional monitoring: `monitoring/prometheus.yml`, Grafana provisioning under `monitoring/grafana/`
