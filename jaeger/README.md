# Jaeger (All-in-One) Docker Compose Stack

This repository provides a production-leaning **single-node** Jaeger stack:

- Jaeger **all-in-one** with **persistent local storage** (Badger)  
- OTLP enabled (**gRPC 4317** and **HTTP 4318**)  
- Optional Zipkin receiver (**9411**)  
- Optional metrics stack (Prometheus + Grafana) enabled via Compose profiles  
- A real container `HEALTHCHECK` (Jaeger images are often minimal, so a tiny BusyBox binary is added for `wget`)

## What you get

### Services
- `jaeger` (always)
- `prometheus` (optional, enabled with `--profile metrics`)
- `grafana` (optional, enabled with `--profile metrics`)

### Persistence
- `jaeger_badger` volume stores trace data locally (Badger)
- `prometheus_data` volume stores Prometheus TSDB data
- `grafana_data` volume stores Grafana state

## Prerequisites

- Docker Engine + Docker Compose v2

## Quick start

### 1) Configure environment
Edit `.env` as needed.

At minimum, set:
- `TZ`
- ports you want to expose
- `JAEGER_SPAN_STORAGE_TYPE` (`badger` recommended for persistence)

### 2) Set Grafana admin password (optional)
If you plan to run the metrics profile, change the secret:

```bash
echo "a-strong-password" > ./secrets/grafana_admin_password.txt
```

### 3) Start Jaeger only
```bash
docker compose up -d --build
```

### 4) Start Jaeger + Prometheus + Grafana
```bash
docker compose --profile metrics up -d --build
```

## Endpoints (default .env)

- Jaeger UI: `http://localhost:16686`
- OTLP gRPC: `localhost:4317`
- OTLP HTTP: `localhost:4318`
- Jaeger admin/health: `http://localhost:14269/`
- Jaeger metrics: `http://localhost:14269/metrics`
- Prometheus: `http://localhost:9090` (profile `metrics`)
- Grafana: `http://localhost:3000` (profile `metrics`)

## Configuration files

- `config/jaeger/sampling_strategies.json`  
  Remote sampling strategies (served to clients). Edit to match your services and desired sampling rates.

- `config/prometheus/prometheus.yml`  
  Scrapes Jaeger metrics from `jaeger:14269/metrics`.

- `config/grafana/provisioning/datasources/datasource.yml`  
  Auto-provisions Prometheus as Grafana’s default datasource.

## Healthchecks

- Jaeger is checked via `http://127.0.0.1:14269/` inside the container.
- Prometheus and Grafana healthchecks use their built-in health endpoints.

If healthchecks fail, check logs:
```bash
docker compose logs -f jaeger
docker compose logs -f prometheus grafana
```

## Security / hardening notes (do not ignore)

- Do not expose Grafana publicly without a reverse proxy + TLS + strong auth.
- The Jaeger UI should not be internet-exposed in most environments.
- If you run this on a shared host, bind ports to localhost (e.g., `127.0.0.1:16686:16686`) or put it behind a gateway.

## Common pitfalls

- **No traces showing up**: Your app must export to OTLP (4317/4318) or another enabled receiver. Validate app exporter settings.
- **Data lost after restart**: Ensure `JAEGER_SPAN_STORAGE_TYPE=badger` and `JAEGER_BADGER_EPHEMERAL=false`.
- **Port conflicts**: Adjust ports in `.env`.

## Upgrade

1. Bump `JAEGER_VERSION` in `.env`
2. Rebuild + restart:
```bash
docker compose up -d --build
```

## Reality check

Jaeger all-in-one is convenient, but it is **not** a scalable production topology. If you need HA, retention guarantees, or high ingest rates,
move to a distributed deployment (separate collector/query + a proper storage backend).
