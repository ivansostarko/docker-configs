# Logstash Stack (Logstash + Beats Agents + Metrics)

This repository provides a production-oriented Docker Compose stack for:
- **Logstash** ingestion (Beats / Syslog TCP+UDP / HTTP JSON & NDJSON)
- **Filebeat** (host + Docker container logs) → Logstash
- **Metricbeat** (Docker + host metrics + Logstash API metrics) → Elasticsearch
- **Heartbeat** (basic port/API checks) → Elasticsearch
- **Logstash Prometheus Exporter** (optional)
- **Prometheus** (optional)

## What you get (and why it matters)

- **Persistent Queue** enabled in Logstash to tolerate downstream outages/spikes.
- **Dead Letter Queue** enabled for indexing failures (mapping conflicts, etc.).
- **Secrets** handled via a **Logstash keystore** (credentials do not belong in env vars).
- **Profiles** so you can run only what you need:
  - `setup` (one-time keystore creation)
  - `agents` (Filebeat/Metricbeat/Heartbeat)
  - `metrics` (Exporter/Prometheus)

## Prerequisites

- Docker Engine + Docker Compose v2
- An Elasticsearch endpoint reachable from this stack (can be external).
- If using TLS to Elasticsearch: the CA certificate available as `./secrets/elastic_ca.crt`.

## Quick start

1) Copy and edit environment variables:

```bash
cp .env .env
# Edit values as needed
```

2) Create secret files:

```bash
mkdir -p secrets
printf "YOUR_ELASTIC_PASSWORD_HERE" > secrets/elastic_password.txt
printf "SOME_LONG_RANDOM_STRING" > secrets/logstash_keystore_password.txt

# If Elasticsearch uses a custom CA, place it here:
# cp /path/to/elastic-ca.crt secrets/elastic_ca.crt
```

3) Run the one-time keystore setup:

```bash
docker compose --profile setup up --no-deps logstash-setup
```

4) Start Logstash:

```bash
docker compose up -d logstash
```

5) Start agents (optional):

```bash
docker compose --profile agents up -d
```

6) Start Prometheus exporter and Prometheus (optional):

```bash
docker compose --profile metrics up -d
```

## Services and ports

| Service | Purpose | Ports |
|---|---|---|
| `logstash` | log ingestion + processing | 5044 (Beats), 5514/tcp+udp (syslog JSON), 8080 (HTTP ingest), 9600 (Logstash API) |
| `filebeat` | collect logs → Logstash | none (outbound only) |
| `metricbeat` | metrics → Elasticsearch | none (outbound only) |
| `heartbeat` | uptime checks → Elasticsearch | none (outbound only) |
| `logstash-exporter` | Prometheus metrics | 9198 |
| `prometheus` | scrape + store metrics | 9090 |

## Configuration overview

### Logstash
- `./logstash/config/logstash.yml` enables persistent queue + DLQ and exposes the HTTP API on `:9600`.
- `./logstash/pipeline/*.conf` includes:
  - Beats input (`5044`)
  - Syslog JSON over TCP/UDP (`5514`)
  - HTTP ingest (`8080`)
  - A minimal normalization filter
  - Elasticsearch output using `ES_PWD` from keystore
  - Optional stdout debug output controlled by `ENABLE_DEBUG_STDOUT=true`

### Filebeat
- Reads Docker JSON logs from `/var/lib/docker/containers/*/*.log`
- Reads host logs from `/var/log` (tune for your distro)
- Ships to Logstash `logstash:5044`

### Metricbeat
- Collects Docker metrics via `/var/run/docker.sock`
- Collects host metrics via `/proc`, `/sys/fs/cgroup`, and `/` mounts
- Collects Logstash node/node_stats via `http://logstash:9600`
- Ships to Elasticsearch

### Heartbeat
- TCP check for `logstash:5044`
- HTTP check for `http://logstash:9600`
- Ships to Elasticsearch

## Operational hard truths (read this)

1. **ILM / retention is your job.** The default index pattern is daily indices:
   - `logs-YYYY.MM.dd`
   If you do not implement ILM or retention policies, you will fill disks and the stack will fail.

2. **Guard your mappings.** If you ingest arbitrary JSON with unbounded fields, Elasticsearch mappings will explode.
   Once you know your log formats, implement field whitelisting and/or flattening rules.

3. **Heap sizing and queue sizing are not optional.**
   Under-provisioned Logstash will cause backpressure and upstream drops during rotations/spikes.

## Common commands

Show status:
```bash
docker compose ps
```

Tail Logstash logs:
```bash
docker compose logs -f logstash
```

Validate Logstash pipeline syntax (inside container):
```bash
docker compose exec logstash bash -lc "/usr/share/logstash/bin/logstash --config.test_and_exit -f /usr/share/logstash/pipeline"
```

Restart Logstash:
```bash
docker compose restart logstash
```

## Troubleshooting

### Logstash is unhealthy
- Check `docker compose logs logstash`
- Confirm API is reachable:
  ```bash
  curl -s http://localhost:9600/?pretty
  ```
- If API is up but pipelines fail, validate config (see command above).

### Filebeat cannot connect
- Ensure Logstash is healthy and `5044` is reachable.
- Ensure your Docker logging driver is `json-file` if using the Docker container log input.

### TLS / certificate problems
- Ensure `ELASTICSEARCH_HOSTS` uses `https://...`
- Ensure the CA cert is correct and mounted as `./secrets/elastic_ca.crt`
- If you are not using TLS, set `ELASTICSEARCH_HOSTS=http://...` and adjust the Logstash output accordingly.

## Security recommendations

- Put this stack on a private network and only expose needed ports.
- Use TLS from agents → Logstash and Logstash → Elasticsearch in real environments.
- Replace the default `elastic` user with a dedicated least-privilege user and role.
- Do not enable stdout debug output in production (`ENABLE_DEBUG_STDOUT=false`).

## Repository structure

See folder layout:
- `docker-compose.yml`
- `.env`
- `secrets/`
- `logstash/`
- `filebeat/`
- `metricbeat/`
- `heartbeat/`
- `prometheus/`
