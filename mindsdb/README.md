# MindsDB Docker Compose Stack

This repository provides a production-leaning Docker Compose stack for **MindsDB** with:
- MindsDB service (HTTP UI/API + MySQL wire protocol)
- Postgres for MindsDB config storage (recommended)
- Optional Redis (queue profile)
- Optional observability stack: OpenTelemetry Collector → Prometheus → Grafana (observability profile)
- Healthchecks, persistent volumes, and a configurable `config.json`

## Prerequisites
- Docker Engine + Docker Compose v2
- `curl` available on the host (for quick tests)

## Quick start

1. Create secret files (required/optional):
- `./secrets/postgres_password.txt` (required)
- `./secrets/mindsdb_admin_password.txt` (template; not wired into MindsDB by default)
- `./secrets/openai_api_key.txt` (optional)

Example:
```bash
mkdir -p secrets
openssl rand -base64 32 > secrets/postgres_password.txt
openssl rand -base64 32 > secrets/mindsdb_admin_password.txt
```

2. Configure environment:
- Copy/edit `.env` (already included).
- Replace `MINDSDB_PASSWORD`, `GRAFANA_ADMIN_PASSWORD`.
- If using Postgres, ensure `MINDSDB_DB_CON` password matches `secrets/postgres_password.txt`.

3. Start the core stack:
```bash
docker compose up -d
```

### Optional profiles

Redis queue:
```bash
docker compose --profile queue up -d
```

Observability (OTEL collector + Prometheus + Grafana):
```bash
docker compose --profile observability up -d
```

Auto-heal (mounts docker.sock; treat as privileged):
```bash
docker compose --profile ops up -d
```

## Endpoints

- MindsDB UI/API: `http://localhost:47334`
- MindsDB MySQL wire protocol: `localhost:47335`
- MindsDB healthcheck: `GET http://localhost:47334/api/util/ping`
- MCP API: `http://localhost:47334/mcp/`
- A2A API: `http://localhost:47334/a2a/`

If observability profile enabled:
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000`

## Persistence

- `mindsdb_data`: MindsDB storage at `/mindsdb/var`
- `postgres_data`: Postgres data directory
- `redis_data`: Redis AOF persistence (queue profile)
- `prom_data`: Prometheus TSDB (observability profile)
- `grafana_data`: Grafana database (observability profile)

## Configuration

- MindsDB config file: `./configs/mindsdb/config.json` mounted read-only to `/etc/mindsdb/config.json`
- Prometheus config: `./configs/prometheus/prometheus.yml`
- OTEL Collector config: `./configs/otel/otel-collector-config.yaml`

## Security notes (read this before exposing anything)

1. **Do not expose MindsDB directly to the internet** without a reverse proxy, TLS, and some form of access control.
2. Docker Compose secrets are used for Postgres (`POSTGRES_PASSWORD_FILE`). MindsDB does not consistently support `*_FILE` env var patterns, so if you set API keys/DB connection strings via `.env`, that is plaintext at rest.
3. If you need strong secret hygiene, use Kubernetes/Swarm or a dedicated secret injector (Vault/SSM/Secrets Manager) rather than `.env`.

## Troubleshooting

- Check service logs:
```bash
docker compose logs -f mindsdb
docker compose logs -f postgres
```

- Verify health:
```bash
curl -fsS http://localhost:47334/api/util/ping && echo "OK"
```

- If MindsDB cannot reach Postgres, verify `MINDSDB_DB_CON` and that Postgres is healthy:
```bash
docker compose ps
```

## Stop
```bash
docker compose down
```

To remove volumes (destructive):
```bash
docker compose down -v
```
