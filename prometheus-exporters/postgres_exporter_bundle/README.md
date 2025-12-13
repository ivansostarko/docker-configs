# PostgreSQL Exporter (Prometheus) — Docker Compose Bundle

This bundle runs `prometheuscommunity/postgres-exporter` with basic operational hardening and *secrets-based* credentials handling.

## What you get

- `docker-compose.yml` with:
  - internal `monitoring` network
  - secrets for DB username/password
  - read-only filesystem, no-new-privileges, dropped caps
  - healthcheck against `/metrics`
- `postgres_exporter/entrypoint.sh` that builds `DATA_SOURCE_NAME` at runtime (so creds do not show in `docker inspect`)
- `postgres_exporter/queries.yml` for custom metrics
- `.env.example` template
- secrets placeholder files (you must replace them)

## Prerequisites

- Docker Engine + Docker Compose v2
- A reachable Postgres instance **on the same Docker network** as the exporter (recommended), or otherwise network-routable.

## Quick start

1) Create your `.env` from the template:

```bash
cp .env.example .env
```

2) Create the secrets (DO NOT commit these):

```bash
mkdir -p secrets
printf "exporter_user_here" > secrets/postgres_exporter_user.txt
printf "exporter_password_here" > secrets/postgres_exporter_password.txt
chmod 600 secrets/postgres_exporter_user.txt secrets/postgres_exporter_password.txt
```

3) Ensure the exporter can reach your Postgres service:

- If Postgres is another Compose stack, attach both to a shared network (e.g. `monitoring`), or set `POSTGRES_HOST` to a resolvable hostname/IP.

4) Start:

```bash
docker compose up -d
docker compose ps
```

5) Verify metrics locally (port is bound to localhost only):

```bash
curl -s http://127.0.0.1:${POSTGRES_EXPORTER_PORT:-9187}/metrics | head
```

## Prometheus scrape config

If Prometheus runs on the same `monitoring` network:

```yaml
scrape_configs:
  - job_name: "postgres_exporter"
    static_configs:
      - targets: ["postgres_exporter:9187"]
```

## Security and operational notes (read this)

- Exporters are not designed to be internet-facing. This bundle binds `9187` to **127.0.0.1** to reduce exposure.
- Do not put DB credentials directly in environment variables. Use Docker secrets (as in this bundle).
- Once stable, pin image versions instead of `:latest`.

## Troubleshooting

### Exporter cannot connect to Postgres
- Confirm `POSTGRES_HOST` is reachable from the exporter container:
  ```bash
  docker exec -it postgres_exporter sh -lc 'nc -vz "$POSTGRES_HOST" "$POSTGRES_PORT"'
  ```
  (If `nc` is not present, test from another utility container on the same network.)

- Check exporter logs:
  ```bash
  docker logs --tail=200 postgres_exporter
  ```

### Healthcheck failing
- Healthcheck validates `/metrics` locally inside the container.
- If the image lacks `wget`, switch to the `/dev/tcp` healthcheck option included in `docker-compose.yml`.

## File layout

```
.
├─ docker-compose.yml
├─ .env.example
├─ README.md
├─ postgres_exporter/
│  ├─ entrypoint.sh
│  └─ queries.yml
└─ secrets/
   ├─ postgres_exporter_user.txt
   └─ postgres_exporter_password.txt
```
