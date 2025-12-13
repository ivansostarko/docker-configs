# Beanstalkd Docker Compose Stack (with optional Monitoring)

This repository provides a production-leaning Docker Compose setup for **Beanstalkd** with:
- Isolated networks
- Persistent binlog (recommended)
- Healthchecks
- Optional admin console
- Optional Prometheus exporter + Prometheus + Grafana (via Compose profiles)
- A simple `.env` for configuration and a Grafana admin password secret

## Quick Start

### 1) Configure environment

Edit `.env` as needed.

**Security default:** Beanstalkd is published to **localhost only** by default:
- `BEANSTALKD_PUBLISH_ADDR=127.0.0.1`

Do not publish Beanstalkd to the public internet. Beanstalkd has no built-in authentication.

### 2) Set Grafana admin password (optional)

If you will run the `monitoring` profile, set a strong Grafana admin password in:

- `./secrets/grafana_admin_password.txt`

### 3) Start services

**Core only (Beanstalkd):**
```bash
docker compose up -d
```

**With monitoring (exporter + Prometheus + Grafana):**
```bash
docker compose --profile monitoring up -d
```

**With admin console too:**
```bash
docker compose --profile monitoring --profile admin up -d
```

## Services and Ports

### Core
- **beanstalkd**
  - Internal port: `11300`
  - Host publish (default): `127.0.0.1:11300`

### Optional (profiles)
- **beanstalkd_console** (`admin` profile)
  - Host publish (default): `127.0.0.1:2080`

- **beanstalkd_exporter** (`monitoring` profile)
  - Host publish (default): `127.0.0.1:8080`
  - Metrics endpoint: `/metrics`

- **prometheus** (`monitoring` profile)
  - Host publish (default): `127.0.0.1:9090`

- **grafana** (`monitoring` profile)
  - Host publish (default): `127.0.0.1:3000`
  - Default admin user: `admin` (configurable via `.env`)
  - Admin password: read from Docker secret `grafana_admin_password`

## Persistence

- `beanstalkd-binlog` volume persists Beanstalkd binlogs and related data.
- `prometheus-data` persists Prometheus TSDB (if enabled).
- `grafana-data` persists Grafana state (if enabled).

If you disable binlog (`BEANSTALKD_ENABLE_BINLOG=0`), you are accepting higher risk of job loss on restarts.

## Operational Notes (Read This)

- **Do not expose Beanstalkd publicly.** There is no authentication layer. Use a private network boundary.
- If you must access remotely, do it via:
  - VPN + private subnet, or
  - SSH tunnel, or
  - Reverse proxy with auth in front of the console (not in this template)
- Monitoring is shipped as a baseline. You should add queue depth / latency SLO alerts based on your actual workloads.

## Common Commands

Show logs:
```bash
docker compose logs -f beanstalkd
```

Check health:
```bash
docker compose ps
```

Stop:
```bash
docker compose down
```

Stop and remove volumes (destructive):
```bash
docker compose down -v
```

## Files

- `docker-compose.yml` - full stack with profiles
- `.env` - configuration
- `monitoring/prometheus.yml` - Prometheus scrape config
- `monitoring/alert.rules.yml` - starter alert rules
- `grafana/provisioning/datasources/datasource.yml` - auto-provision Prometheus datasource
- `secrets/grafana_admin_password.txt` - Grafana admin password secret (optional)

## License

Internal template / sample configuration. Adapt as needed.
