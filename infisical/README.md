# Infisical + Postgres + Redis (Docker Compose)

This bundle provides a hardened baseline `docker-compose.yml` for running **Infisical** with **Postgres** and **Redis**, including:
- Healthchecks (Infisical `/api/status`, Redis `PING`, Postgres `pg_isready`)
- A private internal backend network for DB/Redis
- Optional Prometheus scrape configuration (OTEL Prometheus exporter)
- Config scaffolding for Redis and Postgres init scripts

## What’s included

- `docker-compose.yml`
- `.env.example` (copy to `.env` and fill in secrets)
- `config/infisical/redis/redis.conf`
- `config/infisical/postgres/init/001_extensions.sql`
- `prometheus/infisical_scrape.yml`

## Quick start

1. Create your environment file:

   ```bash
   cp .env.example .env
   ```

2. Fill these values **at minimum**:
   - `INFISICAL_ENCRYPTION_KEY`
   - `INFISICAL_AUTH_SECRET`
   - `INFISICAL_SITE_URL`
   - `INFISICAL_POSTGRES_PASSWORD`
   - Update `INFISICAL_DB_CONNECTION_URI` with the same password

3. Start:

   ```bash
   docker compose up -d
   ```

4. Check status:

   ```bash
   docker compose ps
   docker logs -f infisical
   ```

## Security and operational notes (read this)

- **Do not publish Redis/Postgres ports** unless you have a concrete requirement. The compose file keeps them private by default.
- **Do not use `:latest` in production**. Pin Infisical to a specific version tag after validating upgrades.
- Put Infisical behind a reverse proxy with TLS and authentication controls appropriate for your environment.
- Treat `.env` as a secret. Keep it out of Git and restrict permissions (e.g., `chmod 600 .env`).

## Metrics (Prometheus)

The compose config enables OTEL Prometheus export. Prometheus can scrape Infisical at:

- Target: `infisical:9464`
- Path: `/metrics`

See `prometheus/infisical_scrape.yml` for a ready-to-merge snippet.

## Customization

### Redis password

If you enable `requirepass` in `config/infisical/redis/redis.conf`, update:

- `INFISICAL_REDIS_URL=redis://:PASSWORD@infisical_redis:6379`

### Postgres init

Place initialization SQL files in:

- `config/infisical/postgres/init/`

They will be executed on first DB initialization only (when the data volume is empty).

## Files

```
.
├── docker-compose.yml
├── .env.example
├── config
│   └── infisical
│       ├── postgres
│       │   └── init
│       │       └── 001_extensions.sql
│       └── redis
│           └── redis.conf
└── prometheus
    └── infisical_scrape.yml
```
