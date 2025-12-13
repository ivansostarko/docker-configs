# WireGuard Prometheus Exporter (Docker Compose)

This bundle provides a hardened Docker Compose definition for `mindflavor/prometheus-wireguard-exporter`, plus an `.env` template.

## Contents

- `docker-compose.yml` — WireGuard exporter service with host networking, healthcheck, and basic security hardening
- `.env.example` — environment variable template

## Why `network_mode: host` is non-negotiable

WireGuard interfaces live in the **host** network namespace. If you run the exporter on a bridged Docker network, it often cannot see the host WireGuard interfaces and will export incomplete/empty data.

## Quick start

1. Copy the environment file:
   ```bash
   cp .env.example .env
   ```

2. Start the exporter:
   ```bash
   docker compose up -d
   ```

3. Validate metrics locally on the host:
   ```bash
   curl -s http://127.0.0.1:${WG_EXPORTER_PORT:-9586}/metrics | head
   ```

## Prometheus scraping

Because the service uses `network_mode: host`, you **do not** publish ports in Compose. The exporter listens directly on the host.

- Metrics endpoint: `http://<HOST_IP>:${WG_EXPORTER_PORT}/metrics`

Example scrape target:
- `targets: ['<HOST_IP>:9586']`

## Security and operational notes (read this)

- **Do not rely on `:latest` in production.** Pin a version tag or digest for repeatable deploys.
- The container mounts `/etc/wireguard` read-only. This can still expose sensitive material (keys). Treat this container as sensitive and limit who can access Docker on the host.
- `cap_add: NET_ADMIN` may be required for netlink queries in some environments. If it works without it, remove it.

## Configuration

See `.env.example` for the supported variables.

