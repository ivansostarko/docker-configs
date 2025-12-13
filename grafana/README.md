# Grafana + Postgres (with Postgres Exporter) — Docker Compose Stack

This package provides a production-leaning Docker Compose setup for:
- **Grafana**
- **Postgres** (Grafana’s database backend)
- **postgres-exporter** (Prometheus metrics for Postgres)

It includes **healthchecks**, **Docker secrets**, a **Grafana ini config**, and **provisioning** for a Prometheus datasource.

## What you get

- `compose.yml` with hardened defaults (cap drops, no-new-privileges)
- `.env.example` pattern (non-secret variables only)
- `secrets/` folder (you create real secret files locally; do not commit)
- Grafana provisioning:
  - Prometheus datasource
  - Dashboards provider (loads JSON dashboards from disk)

## Folder structure

```
grafana-stack/
  compose.yml
  .env.example
  config/
    grafana/
      grafana.ini
      provisioning/
        datasources/
          datasources.yml
        dashboards/
          dashboards.yml
      dashboards/
        placeholder-dashboard.json
      postgres/
        init/
  secrets/
    grafana_admin_password.txt.example
    grafana_db_password.txt.example
    grafana_pg_password.txt.example
```

## Prerequisites

- Docker + Docker Compose (v2)
- An existing `prometheus` service on the same Compose network **or** in another Compose project with a shared network named `asterix_network`.

If your Prometheus is in a different Compose project, ensure both projects use the same externally-created network.

## Quick start

1. Copy env file:
   ```bash
   cp .env.example .env
   ```

2. Create secrets (examples are provided; you must create real values):
   ```bash
   cp secrets/grafana_admin_password.txt.example secrets/grafana_admin_password.txt
   cp secrets/grafana_db_password.txt.example secrets/grafana_db_password.txt
   cp secrets/grafana_pg_password.txt.example secrets/grafana_pg_password.txt

   chmod 600 secrets/*.txt
   ```

3. Start:
   ```bash
   docker compose up -d
   ```

4. Access Grafana:
   - URL: `http://localhost:${GF_PORT}`
   - Username: `${GF_SECURITY_ADMIN_USER}`
   - Password: from `secrets/grafana_admin_password.txt`

## Prometheus scrape targets

Add targets (or use service discovery) for:
- Grafana metrics: `grafana:3000/metrics`
- Postgres exporter: `grafana-postgres-exporter:9187/metrics`

Example scrape config snippet:
```yaml
scrape_configs:
  - job_name: grafana
    static_configs:
      - targets: ['grafana:3000']

  - job_name: grafana-postgres
    static_configs:
      - targets: ['grafana-postgres-exporter:9187']
```

## Operational notes (read this; it prevents predictable outages)

- **Stop using `latest` in real environments.** Pin image versions.
- Secrets belong in **Docker secrets** (as implemented) or an external secret manager.
- The `grafana` healthcheck uses `wget`. If your Grafana image variant lacks it, replace with `curl` or remove the healthcheck.
- Avoid `container_name` unless you *need* it. It breaks scaling and causes collisions.

## Files included

- `compose.yml` — the stack definition
- `config/grafana/grafana.ini` — minimal non-secret Grafana config
- `config/grafana/provisioning/**` — datasource + dashboards provisioning
- `config/grafana/dashboards/placeholder-dashboard.json` — example dashboard file
- `secrets/*.example` — secret templates

---

Generated on 2025-12-13.
