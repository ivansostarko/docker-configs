# OpenTelemetry Stack (Collector + Tempo + Loki + Prometheus + Grafana)

This repository provides a Docker Compose–based, self-contained observability stack built around the **OpenTelemetry Collector**.

## What you get

- **OpenTelemetry Collector (contrib)**: receives OTLP (gRPC/HTTP), processes, exports.
- **Tempo**: trace backend.
- **Loki**: log backend.
- **Prometheus**: metrics backend (scrapes Collector Prometheus exporter).
- **Grafana**: UI with pre-provisioned datasources.

## Folder structure

```text
otel-stack/
  docker-compose.yml
  .env
  config/
    otel-collector-config.yml
    prometheus.yml
    tempo.yml
    loki.yml
    grafana/
      provisioning/
        datasources/
          datasources.yml
        dashboards/
          dashboards.yml
      dashboards/
        otel-collector.placeholder.json
  secrets/
    grafana_admin_password.txt
```

## Quick start

1) Start the stack:

```bash
docker compose up -d
```

2) Verify containers:

```bash
docker compose ps
```

3) Open UIs:

- Grafana: `http://localhost:3000`
- Prometheus: `http://localhost:9090`
- Tempo: `http://localhost:3200`
- Loki: `http://localhost:3100`

Default Grafana login is controlled via `.env`:

- `GRAFANA_ADMIN_USER`
- `GRAFANA_ADMIN_PASSWORD`

## How to send telemetry to the Collector

Point instrumented apps/agents at the Collector:

- OTLP gRPC endpoint: `otel-collector:4317`
- OTLP HTTP endpoint: `http://otel-collector:4318`

Example environment variables for an application container:

```dotenv
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
OTEL_SERVICE_NAME=my-service
OTEL_RESOURCE_ATTRIBUTES=service.namespace=platform,deployment.environment=prod
```

## Health and metrics endpoints

Collector endpoints (published on the host for convenience):

- Health check: `http://localhost:13133/`
- Collector internal metrics: `http://localhost:8888/metrics`
- Prometheus exporter metrics (processed app metrics): `http://localhost:8889/metrics`
- zPages (debug): `http://localhost:55679/`
- pprof (debug): `http://localhost:1777/`

Prometheus is configured to scrape:

- `otel-collector:8888` (internal Collector telemetry)
- `otel-collector:8889` (exported metrics pipeline)

## What you should decide before calling this “production-ready”

If you deploy this beyond a single machine, you must make explicit decisions on:

1. **Sampling**
   - 100% trace ingestion in production is a cost/time bomb.
   - Implement head sampling in SDKs and/or tail sampling in the Collector.

2. **Cardinality control**
   - Uncontrolled labels/attributes will explode time-series and log costs.
   - Add `attributes`, `transform`, and/or `filter` processors to enforce policies.

3. **Security boundaries**
   - Do not expose OTLP to the public internet.
   - Use a private network, mTLS, or a gateway with authn/z.

## Common operations

View logs:

```bash
docker compose logs -f otel-collector
```

Restart a single service:

```bash
docker compose restart otel-collector
```

Tear down (keeps volumes):

```bash
docker compose down
```

Tear down and remove data (destructive):

```bash
docker compose down -v
```

## Notes on secrets

This stack includes a `secrets/` directory as a placeholder. For local usage, `.env` is sufficient.
For real deployments, move sensitive values to your platform secret manager (Docker Swarm secrets,
Kubernetes Secrets, Vault, SOPS, etc.) and avoid plaintext admin passwords.
