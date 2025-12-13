# Metabase Docker Compose Stack

## Overview
Production-ready Docker Compose setup for Metabase with:
- PostgreSQL backend
- Healthchecks
- Network isolation
- Persistent volumes
- Optional Prometheus metrics exporter

## Prerequisites
- Docker 24+
- Docker Compose v2+

## Setup

```bash
cp .env.example .env
# edit .env with strong secrets
docker compose up -d
```

Metabase will be available at:
http://localhost:3000

## Security Notes
- NEVER change MB_ENCRYPTION_SECRET_KEY after first startup
- Do not expose Postgres port publicly
- Use HTTPS via reverse proxy (Caddy / Traefik / Nginx)

## Metrics
Postgres exporter exposes metrics on:
http://localhost:9187/metrics

Integrate with Prometheus + Grafana for observability.

## Volumes
- metabase_data: Metabase runtime data
- metabase_pgdata: PostgreSQL data directory

## Upgrade Strategy
- Backup database
- Update image tags
- Run `docker compose pull && docker compose up -d`

## Disclaimer
If you run this in production without backups, monitoring, or TLS,
you are operating irresponsibly.
