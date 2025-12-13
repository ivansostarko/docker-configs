# Beanstalkd Prometheus Exporter (Docker Compose)

This bundle deploys a **Prometheus exporter for Beanstalkd** and (optionally) a local Beanstalkd instance.

## Why this exists

- Beanstalkd itself does not expose Prometheus metrics.
- The exporter scrapes Beanstalkd stats and exposes them at an HTTP `/metrics` endpoint for Prometheus.

## Contents

- `docker-compose.yml` — exporter + optional Beanstalkd (profile `stack`)
- `.env` — configuration defaults
- `secrets/beanstalkd_address.txt` — target `host:port` for the exporter
- `exporter/entrypoint.sh` — reads the Docker secret, builds exporter args
- `prometheus/scrape-beanstalkd.yml` — drop-in scrape config snippet
- `prometheus/alerts-beanstalkd.yml` — starter alert rules

## Security model (read this or accept you are taking risk blindly)

Beanstalkd has **no native auth** and is not intended to be Internet-facing.

Non-negotiable guidance:

1. Do **not** publish Beanstalkd port `11300` to the host/public network.
2. Keep Beanstalkd on a private/internal network segment.
3. If you must access it remotely, do so via a secure overlay (VPN, private VPC, etc.), not a public port.

This Compose uses an **internal Docker network** (`queue_internal`) to avoid accidental exposure.

## Prerequisites

- Docker Engine + Docker Compose v2
- A Prometheus instance connected to the same Docker network used for scraping (recommended)

Create the external monitoring network (only once):

```bash
docker network create monitoring
```

If your existing monitoring stack uses a different network name, set it in `.env` (`MONITORING_NETWORK=...`).

## Quick start

### 1) Exporter only (recommended when Beanstalkd is already deployed)

1. Put the Beanstalkd address in `secrets/beanstalkd_address.txt`:

```text
10.0.0.12:11300
```

2. Start the exporter:

```bash
docker compose up -d
```

### 2) Full local stack (Beanstalkd + exporter)

```bash
docker compose --profile stack up -d
```

In this mode, the secret default `beanstalkd:11300` is correct.

## Prometheus integration

Add `prometheus/scrape-beanstalkd.yml` into your Prometheus config. If you maintain a single `prometheus.yml`, copy the job section under `scrape_configs`.

Example (if using `prometheus.yml` includes):

```yaml
scrape_config_files:
  - /etc/prometheus/scrape-beanstalkd.yml
```

Then mount `scrape-beanstalkd.yml` into your Prometheus container.

## Metrics and cardinality controls

By default, the exporter exposes **system-level stats only**.

Tube metrics increase visibility but also increase cardinality:

- Enable all tubes (high risk in environments with dynamic tube names):
  - `.env`: `BEANSTALKD_ALL_TUBES=true`
- Restrict to specific tubes (recommended):
  - `.env`: `BEANSTALKD_TUBES=default,critical,emails`

If you have many tubes or frequent tube churn, enabling `ALL_TUBES` is an operational mistake.

## Healthcheck note

The exporter healthcheck uses `wget` + `grep` to verify the `beanstalkd_up` metric is present.

Some exporter images are minimal and may not include `wget`. If the container is healthy but the healthcheck fails:

- Option A: remove/disable the healthcheck in `docker-compose.yml`
- Option B: build a tiny wrapper image that adds `curl`/`wget`

## Operations

View exporter logs:

```bash
docker logs -f beanstalkd_exporter
```

Test metrics endpoint from within the network (requires a curl/wget-capable container):

```bash
docker run --rm --network monitoring curlimages/curl:8.5.0 -s http://beanstalkd_exporter:8080/metrics | head
```

## Common failure modes (and what they imply)

- `beanstalkd_up = 0`:
  - exporter cannot reach Beanstalkd (network/DNS/firewall)
  - Beanstalkd is down
  - wrong address in `secrets/beanstalkd_address.txt`

- Scrape timeouts:
  - Beanstalkd overloaded
  - tube metrics enabled with high cardinality
  - Prometheus scrape timeout too low

## Version pinning

The exporter is pinned (`dtannock/beanstalkd-exporter:0.2.0`).

The optional Beanstalkd image is not pinned in this bundle. In a production environment, you should pin it to a known-good tag (and keep a tested upgrade procedure).
