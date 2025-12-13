# Typesense Docker Compose Stack

This repository provides a production-oriented **Typesense** stack with:

- Typesense server (persistent data volume, log volume)
- Docker **secret** for the Typesense **admin API key**
- Healthcheck
- Optional **Prometheus + Grafana** monitoring (via a Typesense Prometheus exporter)
- Optional **Typesense Admin Dashboard** UI (requires CORS)

## 1) Quick start

### Prerequisites

- Docker Engine + Docker Compose v2

### Setup

1. Copy env template:

```bash
cp .env.example .env
```

2. Set a strong admin key (do not commit it):

```bash
# edit this file and replace placeholder
nano secrets/typesense_api_key.txt
```

3. Start Typesense:

```bash
docker compose up -d
```

4. Verify:

```bash
curl -s http://127.0.0.1:8108/health
```

Expected:

```json
{"ok":true}
```

## 2) Security posture (read this before you expose anything)

- **Do not publish Typesense to the public Internet** unless you understand the consequences.
- The **admin API key is effectively root**. If it leaks, assume total compromise of your Typesense data.
- Prefer:
  - Bind the port to `127.0.0.1` (default here), and
  - Put Typesense behind an internal reverse proxy / private network.

## 3) Configuration

### Typesense config

- `config/typesense/typesense-server.ini` contains server parameters.
- The container is started with `--config=/etc/typesense/typesense-server.ini`.

### Admin API key via Docker secret

- `secrets/typesense_api_key.txt` is mounted into the container as a Docker secret.
- `config/typesense/entrypoint.sh` reads that file and starts Typesense with `--api-key=...`.

## 4) Monitoring (Prometheus + Grafana)

This stack includes an optional Prometheus exporter that scrapes Typesense endpoints and exposes Prometheus metrics.

### Start monitoring profile

```bash
docker compose --profile monitoring up -d
```

Services:

- Exporter: `http://127.0.0.1:8908/metrics`
- Prometheus: `http://127.0.0.1:9090`
- Grafana: `http://127.0.0.1:3000` (defaults in `.env`)

### Important note about exporter API key

The exporter used in this stack expects `TYPESENSE_API_KEY` as an environment variable. If you want to avoid key exposure in container env:

- Fork/patch the exporter to support `*_FILE` secrets, or
- Put the exporter on a restricted network and treat it as sensitive.

## 5) Admin dashboard (optional)

This UI is convenient for inspection but is also **extra attack surface**.

### Start dashboard profile

```bash
docker compose --profile ui up -d
```

Open:

- `http://127.0.0.1:3005`

### CORS requirement

If the UI is running in a browser and calls Typesense directly, you must enable CORS:

- In `.env`:

```bash
TYPESENSE_ENABLE_CORS=true
TYPESENSE_CORS_DOMAINS=http://127.0.0.1:3005
```

## 6) Backups (what you should do next)

This stack **does not** implement snapshots/backup automation.

Minimum viable approach:

- Use Typesense snapshots (API) to write periodic snapshots into a dedicated directory.
- Back up that snapshot directory to object storage.
- Test restores.

If you want, I can extend the stack with a scheduled snapshot job + restic (encrypted S3-compatible backups) + retention rules.

## 7) Useful commands

```bash
# Logs
docker compose logs -f typesense

# Restart Typesense
docker compose restart typesense

# Stop everything
docker compose down

# Stop and remove volumes (DANGEROUS: deletes your index)
docker compose down -v
```

## 8) Files

- `docker-compose.yml` — main stack
- `.env.example` — environment template
- `config/typesense/typesense-server.ini` — Typesense configuration
- `config/typesense/entrypoint.sh` — starts Typesense using Docker secret admin key
- `config/prometheus/prometheus.yml` — Prometheus scrape config
- `config/grafana/provisioning/*` — Grafana provisioning
- `secrets/typesense_api_key.txt` — placeholder secret (replace it)
