# Ollama Exporter (Docker Compose)

This package runs **lucabecker42/ollama-exporter** as a sidecar-style Prometheus exporter in Docker Compose.
It polls an existing Ollama server and exposes:

- `GET /metrics` (Prometheus metrics)
- `GET /health` (basic health endpoint)

## Contents

- `docker-compose.yml` — exporter service + `monitoring` network
- `.env.example` — configuration template
- `prometheus/scrape_configs.yml` — Prometheus scrape config snippet

## Prerequisites

- Docker Engine + Docker Compose plugin
- A reachable Ollama API endpoint from the exporter container
  - If Ollama runs as a container on the same `monitoring` network, use `OLLAMA_HOST=ollama:11434`
  - If Ollama runs on the Docker host, use `OLLAMA_HOST=host.docker.internal:11434`

Note: Ollama typically binds to `127.0.0.1:11434` by default; if you need it accessible beyond localhost, configure it accordingly in your Ollama setup.

## Quick start

1. Create your env file:

   ```bash
   cp .env.example .env
   ```

2. Start the exporter:

   ```bash
   docker compose up -d
   ```

3. Verify health and metrics (if you published ports to localhost):

   ```bash
   curl -fsS http://127.0.0.1:${OLLAMA_EXPORTER_PORT:-8000}/health
   curl -fsS http://127.0.0.1:${OLLAMA_EXPORTER_PORT:-8000}/metrics | head
   ```

## Prometheus configuration

If Prometheus is running on the same Docker network (`monitoring`), add the following scrape job:

```yaml
scrape_configs:
  - job_name: "ollama_exporter"
    metrics_path: /metrics
    static_configs:
      - targets: ["ollama_exporter:8000"]
```

If your exporter port differs, align the target port with `OLLAMA_EXPORTER_PORT`.

## Security and operational notes

- The compose file defaults to publishing the exporter port on **localhost only** (`127.0.0.1`). If you publish to `0.0.0.0`, you are exposing metrics to your LAN/WAN unless a firewall/proxy blocks it.
- `read_only: true`, `cap_drop: [ALL]`, and `no-new-privileges` are enabled as baseline hardening.
- No volumes or secrets are required for this exporter. The only “sensitive” item may be your Ollama endpoint topology, which is not usually a secret but should be treated as internal configuration.

## Troubleshooting

### 1) Prometheus target shows DOWN
- Confirm the exporter container is running:
  ```bash
  docker compose ps
  docker logs --tail=200 ollama_exporter
  ```
- Confirm Prometheus can resolve/reach `ollama_exporter:8000` on the shared Docker network.

### 2) Exporter is UP but metrics are empty or stale
- The exporter can’t reach Ollama. Re-check `OLLAMA_HOST` from inside the container:
  ```bash
  docker exec -it ollama_exporter sh
  # inside container, try to reach Ollama (example using node):
  node -e "require('http').get('http://'+process.env.OLLAMA_HOST+'/api/tags',r=>console.log('status',r.statusCode)).on('error',e=>{console.error(e);process.exit(1)})"
  ```

### 3) You used the wrong env var name
This exporter expects `OLLAMA_HOST` (format `host:port`). A full URL (e.g., `http://...`) may break connectivity unless the app explicitly supports it.

## Updating the image safely
Avoid `:latest`. Pick a pinned tag (or digest) you have tested in your environment.
