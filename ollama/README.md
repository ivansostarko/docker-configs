# Ollama Docker Compose (Hardened-ish)

This bundle provides a production-leaning Docker Compose setup for **Ollama** with:
- Persistent model storage (named volume)
- Healthcheck against a real API endpoint (`/api/tags`)
- Optional **Prometheus metrics exporter** (profile: `metrics`)
- Resource limits, ulimits, JSON-file log rotation
- Safer host binding defaults (bind to `127.0.0.1` unless you choose otherwise)

## Files

- `docker-compose.yml` — main Compose definition
- `.env.example` — environment template (copy to `.env`)
- `config/ollama/` — optional place for your Ollama artifacts (Modelfiles, notes, etc.)
- `prometheus-scrape.yml` — snippet for Prometheus scrape config (optional)

## Quick start

1. Copy env template:
   ```bash
   cp .env.example .env
   ```

2. Start Ollama:
   ```bash
   docker compose up -d
   ```

3. (Optional) Start metrics exporter:
   ```bash
   docker compose --profile metrics up -d
   ```

## Security notes (read this)

- **Ollama’s API is not authenticated by default.**
  If you bind to `0.0.0.0` and publish the port publicly, you are exposing an unauthenticated API.
- The Compose file defaults to publishing on **localhost** via:
  `OLLAMA_BIND=127.0.0.1` in `.env`.

If you must expose it to a LAN/WAN, put it behind:
- a reverse proxy with auth (basic auth / OIDC), **and**
- firewall rules / IP allowlisting, **and**
- TLS.

## Ports

- Ollama API: `${OLLAMA_BIND}:${OLLAMA_PORT}` -> container `11434`
- Metrics exporter (optional): `${OLLAMA_EXPORTER_BIND}:${OLLAMA_EXPORTER_PORT}`

## Common operations

- Check health:
  ```bash
  docker compose ps
  ```

- View logs:
  ```bash
  docker compose logs -f ollama
  ```

- Update images:
  ```bash
  docker compose pull && docker compose up -d
  ```

## GPU

The Compose uses the `deploy.resources.reservations.devices` stanza for NVIDIA GPU access.
Your host must have the NVIDIA Container Toolkit configured.

If you are CPU-only, either:
- set `OLLAMA_GPU_COUNT=0` and remove the deploy block, or
- remove the whole `deploy:` section.

## Prometheus

This setup does **not** assume Ollama provides a native `/metrics` endpoint.
Instead it includes an optional exporter service enabled via profile `metrics`.

See `prometheus-scrape.yml`.
