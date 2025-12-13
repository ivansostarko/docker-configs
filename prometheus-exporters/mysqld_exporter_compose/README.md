# MySQL Exporter (mysqld_exporter) — Docker Compose Bundle

This bundle deploys Prometheus **mysqld_exporter** with:
- credentials stored as a **Docker secret** (`.my.cnf`) instead of environment variables
- optional **/metrics protection** (exporter-toolkit web config)
- basic hardening (read-only FS, dropped caps, no-new-privileges)
- a simple healthcheck

## Files

- `docker-compose.yml` — mysqld_exporter service + `asterix_network` + secrets
- `.env.example` — only needed if you publish the port
- `secrets/mysqld_exporter.my.cnf` — MySQL connection credentials (edit this)
- `secrets/mysqld_exporter_web.yml` — optional web config for basic auth (edit or remove)

## Prerequisites

- Docker + Docker Compose v2
- A MySQL-compatible server reachable on the Docker network (example service name: `wordpress-db`)
- Your monitoring stack (Prometheus) attached to the same Docker network (`asterix_network`)

## 1) Create / ensure the Docker network exists

The compose file assumes an **external** network named `asterix_network`.

Create it once:
```bash
docker network create asterix_network
```

If you do *not* want an external network, edit `docker-compose.yml` and set:
```yaml
networks:
  asterix_network:
    external: false
```
(or remove `external:` entirely).

## 2) Create an exporter user in MySQL (least privilege)

Run the following on your MySQL server (adjust host restriction if you can):

```sql
CREATE USER 'exporter'@'%' IDENTIFIED BY 'STRONG_PASSWORD' WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
FLUSH PRIVILEGES;
```

Why: the exporter needs a small set of privileges for status and replication-related metrics, and should not run as `root`.

## 3) Configure secrets

### 3.1 MySQL credentials
Edit:
- `secrets/mysqld_exporter.my.cnf`

Set:
- `user`
- `password`
- `host` (typically your DB container name on the Docker network)
- `port`

### 3.2 Protect /metrics (optional but recommended)
If you want to require basic auth to scrape metrics, edit:
- `secrets/mysqld_exporter_web.yml`

Replace the bcrypt hash.

If you do **not** want auth/TLS:
1. Remove the `mysqld_exporter_web_config` secret from `docker-compose.yml`
2. Remove this command flag:
   - `--web.config.file=/run/secrets/mysqld_exporter_web_config`

## 4) Start the exporter

From the bundle directory:
```bash
docker compose up -d
```

Check logs:
```bash
docker logs -f mysqld_exporter
```

## 5) Prometheus scrape config

Add a job similar to:

```yaml
scrape_configs:
  - job_name: "mysqld_exporter"
    static_configs:
      - targets: ["mysqld_exporter:9104"]
```

If you enabled basic auth on the exporter, configure Prometheus accordingly (use `basic_auth:` or `authorization:`).

## Metrics endpoint

- Container listens on **9104**
- Metrics path: **`/metrics`**
- Inside the Docker network, Prometheus should scrape: `mysqld_exporter:9104`

## Security notes (non-negotiable if you’re serious)

- Do **not** expose `9104` to the public internet.
- Do **not** keep DB credentials in `DATA_SOURCE_NAME` unless you accept credential leakage via inspection tools.
- Avoid `:latest` tags — upgrade deliberately.

## Healthcheck caveat

The included healthcheck uses `wget`. If the image tag you pin does not include `wget`, the healthcheck will fail.

Options:
- Remove the healthcheck, or
- Replace it with a healthcheck that uses an available binary, or
- Add a tiny sidecar to probe the endpoint.

## Upgrade process

1. Update the pinned image version in `docker-compose.yml`
2. `docker compose pull`
3. `docker compose up -d`
4. Verify `/metrics` and Prometheus ingestion
