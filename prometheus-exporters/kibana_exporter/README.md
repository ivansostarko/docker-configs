# Kibana Prometheus Exporter (Docker Compose)

This bundle deploys a Prometheus exporter that polls Kibana's status endpoint (`/api/status`) and exposes
Prometheus/OpenMetrics at `http://<host>:9684/metrics`.

It is designed as a sidecar-style exporter: Kibana itself is **not** modified.

## Contents

```text
kibana_exporter/
  docker-compose.yml
  .env
  secrets/
    kibana_password.txt
  image/
    Dockerfile
    entrypoint.sh
```

## Prerequisites

- Docker Engine + Docker Compose plugin
- A running Kibana instance reachable from this exporter container
- An existing Docker network shared with Kibana (Compose uses an **external** network)

## Quick start

1. Put the exporter on the same Docker network as Kibana:

   - If your environment already uses a shared network (example: `asterix_network`), set it in `.env`:
     `MONITORING_NETWORK_NAME=asterix_network`

2. Set Kibana connectivity in `.env`:

   - `KIBANA_URI=http://kibana:5601` (must be reachable from within the Docker network)
   - `KIBANA_USERNAME=...` (optional; leave empty for no auth)
   - `KIBANA_SKIP_TLS=true|false` (only set `true` if you accept the security tradeoff)

3. Set Kibana password via Docker secret:

   - Edit `secrets/kibana_password.txt` and set the password.
   - Do **not** commit real passwords to git.

4. Start:

```bash
cd kibana_exporter
docker compose up -d --build
```

5. Verify:

```bash
curl -fsS http://localhost:9684/metrics | head
curl -fsS http://localhost:9684/healthz
```

## Prometheus scrape config

Add this job to your `prometheus.yml` (or your Prometheus configuration mechanism):

```yaml
- job_name: "kibana"
  scrape_interval: 1m
  static_configs:
    - targets: ["kibana_exporter:9684"]
```

## Configuration reference (env)

- `MONITORING_NETWORK_NAME`  
  External Docker network name where Kibana is reachable by DNS/service name.

- `KIBANA_URI`  
  Kibana base URL (e.g., `http://kibana:5601`).

- `KIBANA_USERNAME`  
  Username for basic auth (optional).

- `KIBANA_SKIP_TLS`  
  `true` to skip TLS verification for self-signed endpoints (risk: MITM). Default `false`.

- `KIBANA_EXPORTER_UPSTREAM_TAG`  
  Exporter tag; do not use `latest` casually. Pin this to the tag that matches your Kibana version.

- `KIBANA_EXPORTER_PORT`  
  Host port mapping for exporter (`9684` default).

- `KIBANA_EXPORTER_TELEMETRY_PATH`  
  Metrics path (default `/metrics`).

- `KIBANA_EXPORTER_WAIT`  
  `true` makes exporter wait until Kibana responds (useful at startup).

## Security posture (what this bundle enforces)

- Runs as non-root (UID/GID 65532)
- Drops all Linux capabilities
- `no-new-privileges`
- Read-only root filesystem + `tmpfs` for `/tmp`
- Uses Docker secrets for the password (not plain env vars)

## Common failure modes

1. **Wrong Kibana address**  
   Using `localhost:5601` will fail unless Kibana is in the same container. Use the Kibana service name
   or container DNS name on the shared network.

2. **Network mismatch**  
   `MONITORING_NETWORK_NAME` must exist and Kibana must be attached to it.

3. **Auth mismatch**  
   If Kibana requires auth but you didn't set `KIBANA_USERNAME` + password secret, exporter will return 401/403.

## Stop / remove

```bash
docker compose down
```
