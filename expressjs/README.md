# ExpressJS Docker Compose Stack

This repository provides a production-leaning Docker Compose stack for an **ExpressJS** API with **Nginx** ingress, **PostgreSQL**, **Redis**, and an **optional observability profile** (Prometheus + Grafana + exporters + cAdvisor).

## What you get

### Core services (default)
- **api**: ExpressJS service (Node.js), built from `./app`
- **nginx**: reverse proxy (single entrypoint exposed to the host)
- **postgres**: PostgreSQL database (persistent volume)
- **redis**: Redis cache/queue (persistent volume)

### Optional services (`--profile monitoring`)
- **prometheus**: metrics scraping + time-series storage
- **grafana**: dashboards (provisioned with a Prometheus datasource)
- **postgres_exporter**: Postgres metrics
- **redis_exporter**: Redis metrics
- **cadvisor**: container-level metrics

## Architecture

Host → **Nginx** → **Express API**  
The database and Redis are **not exposed to the host** (internal network only).

Monitoring (when enabled) runs on a separate **internal** network.

## Prerequisites

- Docker Engine + Docker Compose plugin (v2)
- Ports available on your host (defaults):
  - HTTP ingress: `8080`
  - Prometheus (optional): `9090`
  - Grafana (optional): `3001`

## Quick start

1) Copy env file and set values
```bash
cp .env.example .env
```

2) Replace the placeholder secrets (do not skip this)
```bash
# Edit these files and set strong values
nano ./secrets/postgres_password.txt
nano ./secrets/jwt_secret.txt
```

3) Start the stack
```bash
docker compose up -d --build
```

4) Verify
```bash
curl -s http://localhost:${HTTP_PORT:-8080}/health | jq
curl -s http://localhost:${HTTP_PORT:-8080}/metrics | head
```

## Enable monitoring (Prometheus + Grafana)

```bash
docker compose --profile monitoring up -d --build
```

- Prometheus: `http://localhost:${PROMETHEUS_PORT:-9090}`
- Grafana: `http://localhost:${GRAFANA_PORT:-3001}`  
  Credentials default to `admin/admin` via `.env.example` (change them immediately).

## Endpoints

Via Nginx (host):
- `GET /` → basic status response from API
- `GET /health` → container health endpoint (used by Docker healthcheck)
- `GET /metrics` → Prometheus scrape endpoint (from `prom-client`)

Inside the Compose network:
- `postgres:5432`
- `redis:6379`
- `api:3000`

## Configuration

### `.env`
Copy `.env.example` to `.env` and adjust:
- `HTTP_PORT` – host port mapped to Nginx (default `8080`)
- `POSTGRES_DB`, `POSTGRES_USER` – DB name/user
- `DATABASE_URL` – used by the app; the password is intentionally a placeholder
- `REDIS_URL` – internal Redis URL
- `PROMETHEUS_PORT`, `GRAFANA_PORT` – monitoring ports (profile only)
- `GRAFANA_ADMIN_USER`, `GRAFANA_ADMIN_PASSWORD` – set real credentials

### Secrets
This stack uses file-based Docker secrets:
- `./secrets/postgres_password.txt`
- `./secrets/jwt_secret.txt`

**Reality check:** if you deploy without changing these, you have effectively published your credentials.

## Database initialization

A sample init script is provided:
- `./scripts/init-db.sql`

Postgres automatically executes files in `/docker-entrypoint-initdb.d` on first startup of an empty data volume.

If you need migrations, do them in the app pipeline, not manually inside the container.

## Healthchecks

Healthchecks are defined for:
- `api` (`/health`)
- `nginx`
- `postgres`
- `redis`
- monitoring components (when enabled)

Compose uses `depends_on: condition: service_healthy` for sensible startup ordering.

## Metrics

### API metrics
The Express app exports:
- default Node/process metrics via `prom-client`
- basic HTTP request counters/histograms via middleware

### Prometheus targets
Configured in `./prometheus/prometheus.yml`:
- `api:3000/metrics`
- exporters (`postgres_exporter`, `redis_exporter`)
- `cadvisor`
- Prometheus self-scrape

## Security and operational guidance (read this)

- **Change default credentials** (secrets + Grafana admin). Non-negotiable.
- **Do not expose Postgres/Redis** to the host unless you have a strong reason and a firewall policy to match.
- **Pin image versions** for real deployments. Using `:latest` is operational laziness that will bite you during an unplanned upgrade.
- **Add TLS** in front of Nginx for production (terminate at a real ingress/load balancer, or add cert management).
- **Treat cAdvisor and exporters as sensitive**: they reveal infrastructure details. Keep them on the internal monitoring network.

## Common operations

### View logs
```bash
docker compose logs -f api
docker compose logs -f nginx
```

### Restart a service
```bash
docker compose restart api
```

### Rebuild the API image
```bash
docker compose build --no-cache api
docker compose up -d api
```

### Tear down (keeps volumes)
```bash
docker compose down
```

### Tear down (DESTROYS data volumes)
```bash
docker compose down -v
```

## Troubleshooting

- **API not reachable**
  - Check Nginx is up: `docker compose ps`
  - Inspect Nginx logs: `docker compose logs -f nginx`
  - Confirm the API is healthy: `docker inspect --format='{{json .State.Health}}' express_api | jq`

- **Prometheus shows targets down**
  - Ensure you started the `monitoring` profile
  - Verify `api` exposes `/metrics` and Prometheus can reach `api:3000` inside the network

- **Postgres exporter authentication failures**
  - Confirm `./secrets/postgres_password.txt` matches Postgres password
  - The exporter reads the password at runtime from `/run/secrets/postgres_password`

## License
Use freely; adapt to your environment and security requirements.
