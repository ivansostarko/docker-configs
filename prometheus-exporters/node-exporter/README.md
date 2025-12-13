# Node Exporter (Docker Compose)

This package provides a hardened `docker-compose.yml` for running Prometheus Node Exporter on a Docker host.

## What you get
- Pinned image tag via `.env` (no uncontrolled `:latest` upgrades)
- Security hardening: `read_only`, `no-new-privileges`, `cap_drop: ALL`, `tmpfs`
- Accurate host metrics via `pid: host` and explicit host mounts
- Optional TLS and basic-auth via Node Exporter `web-config.yml`
- Consistent logging configuration

## Files
- `docker-compose.yml` — Node Exporter service + networks/configs/secrets
- `.env` — image tag + bind/port settings
- `config/node-exporter/web-config.yml` — TLS/basic-auth configuration
- `secrets/` — placeholders for TLS cert/key (do not commit real secrets)

## Quick start
1. Review `.env`:
   - Default binds to `127.0.0.1` to avoid accidental public exposure.
2. Add TLS cert/key files:
   - `./secrets/node-exporter.crt`
   - `./secrets/node-exporter.key`
3. (Optional) Enable basic auth in `config/node-exporter/web-config.yml` with a bcrypt hash.
4. Start:
   ```bash
   docker compose up -d
   ```

## Prometheus scrape example
If Prometheus runs on the same host (and you keep `NODE_EXPORTER_BIND=127.0.0.1`):
```yaml
scrape_configs:
  - job_name: "node-exporter"
    static_configs:
      - targets: ["127.0.0.1:9100"]
```

If Prometheus is remote, do **not** simply bind Node Exporter to `0.0.0.0` without compensating controls.
Use one of:
- a private network/VPN
- a reverse proxy with auth/IP allowlisting
- firewall rules restricting access to Prometheus only

## Operational notes
- Node Exporter images are often minimal/distroless, so in-container HTTP healthchecks are unreliable.
  The correct health signal is: Prometheus can scrape it and alerting is configured.
- Avoid exposing port `9100` to the public internet. Host telemetry is valuable to attackers.

## Minimal layout
```text
.
├── docker-compose.yml
├── .env
├── config/
│   └── node-exporter/
│       └── web-config.yml
└── secrets/
    ├── node-exporter.crt
    └── node-exporter.key
```
