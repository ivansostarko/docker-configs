# Coturn Exporter (Prometheus) — Docker Compose Stack

This bundle contains a hardened Docker Compose setup for running a **coturn metrics exporter** that probes your TURN server and exposes Prometheus metrics at `/metrics`.

## What you get

- `docker-compose.yml` with:
  - Dedicated `monitoring` network
  - Docker secret support (static auth secret)
  - Read-only filesystem + dropped Linux capabilities
  - Healthcheck on `/metrics`
  - Bounded json-file logs
- Template-based config rendering so secrets are not committed to git
- Example `.env` and config template

## Folder layout

```text
.
├─ docker-compose.yml
├─ .env
├─ secrets/
│  └─ coturn_static_auth_secret.txt
└─ coturn_exporter/
   ├─ Dockerfile
   └─ config.yml.tmpl
```

## Quick start

1. **Set TURN target and interval**
   - Edit `.env`:
     - `COTURN_IP`
     - `COTURN_PORT`
     - `COTURN_EXPORTER_INTERVAL`

2. **Set your static auth secret**
   - Edit `secrets/coturn_static_auth_secret.txt`
   - Keep this file out of git and restrict permissions on the host.

3. **Build & run**
   ```bash
   docker compose up -d --build
   ```

4. **Verify**
   - Localhost-only metrics endpoint:
     ```bash
     curl -fsS http://127.0.0.1:9524/metrics | head
     ```

## Prometheus scrape config

Add this to your `prometheus.yml` (Prometheus must be on the same `monitoring` network):

```yaml
scrape_configs:
  - job_name: "coturn_exporter"
    static_configs:
      - targets: ["coturn_exporter:9524"]
```

## Security notes (do not ignore)

- **Do not expose `/metrics` publicly.** This stack binds the published port to `127.0.0.1` by default.
- The secret is injected at runtime via Docker secrets and written only to an in-memory file (tmpfs).
- Container runs as a non-root user, with a read-only root filesystem and all capabilities dropped.

## Dockerfile caveat (important)

`coturn_exporter/Dockerfile` is a **wrapper template**. You must ensure the exporter binary is available at build time:

- Replace:
  ```dockerfile
  COPY coturn_exporter /usr/local/bin/coturn_exporter
  ```
  with the correct build output (or merge in your existing exporter build steps).

If your exporter needs arguments (e.g., config path), append them in the final `exec` line in the Dockerfile.

## Operations

- Logs are bounded with `max-size=10m` and `max-file=3`.
- Healthcheck runs every 30s and fails if `/metrics` is not reachable.

## Common pitfalls

- Wrong `COTURN_IP` or closed TURN port will make the exporter fail probes.
- If you run Prometheus in Docker, remove the `ports:` section entirely and rely on the Docker network.
- If you enable `networks.monitoring.internal: true`, the service becomes unreachable from the host (by design).

