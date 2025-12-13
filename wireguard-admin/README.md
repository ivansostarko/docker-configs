# WireGuard Admin GUI (wg-easy) — Docker Compose

This bundle deploys **wg-easy v15** (WireGuard + Admin Web UI) with optional:
- **Caddy reverse proxy** (HTTPS for the admin UI)
- **Prometheus** scraping (wg-easy `/metrics/prometheus`)

## Contents

```
wireguard-admin-gui/
  docker-compose.yml
  .env.example
  caddy/
    Caddyfile
  prometheus/
    prometheus.yml
```

## Prerequisites

- Linux host (recommended) with Docker + Docker Compose plugin
- UDP port opened on the host firewall (default `51820/udp`)
- Kernel support for WireGuard (module available). Container mounts `/lib/modules` read-only.
- You accept the security implications of `NET_ADMIN` + `/dev/net/tun` for the VPN container.

## Quick start

1. Copy and edit environment file:

```bash
cp .env.example .env
nano .env
```

Set at minimum:
- `WG_INIT_PASSWORD` to a strong random secret
- `WG_INIT_HOST` to your public DNS name or public IP (clients will use this)

2. Start the stack:

```bash
docker compose up -d
```

This starts:
- WireGuard UDP service on `${WG_UDP_PORT}`
- Admin UI bound to `127.0.0.1:${WG_UI_PORT}` by default

3. Open the admin UI from the host:

- Locally: `http://127.0.0.1:${WG_UI_PORT}`
- Or via SSH tunnel from your workstation:

```bash
ssh -L 51821:127.0.0.1:51821 user@vpn-host
```

Then open `http://127.0.0.1:51821` on your workstation.

## Important: Remove init secrets after first login

The `WG_INIT_*` variables are intended for **first boot only**.
After you can log in and see the UI, remove these from `.env` and redeploy:

```bash
# edit .env and delete WG_INIT_* lines
docker compose up -d
```

Leaving init secrets around is an unnecessary risk.

## Enable HTTPS for the UI (Caddy)

1. Edit `caddy/Caddyfile` and replace the hostname:

- change `wg-admin.example.com` to your real DNS name

2. Run the proxy profile:

```bash
docker compose --profile proxy up -d
```

This exposes ports `80/443` and reverse-proxies to `wg-easy:51821`.

## Enable monitoring (Prometheus)

Run the monitoring profile:

```bash
docker compose --profile monitoring up -d
```

Prometheus is bound to `127.0.0.1:9090` by default.

If you enable metric auth inside wg-easy Admin Panel, you must update `prometheus/prometheus.yml` with the required auth headers.

## Hardening recommendations

- Do **not** expose the admin UI directly to the internet (`WG_UI_BIND=0.0.0.0`) unless you have a strong reason.
- If you must expose it, put it behind HTTPS + access control and consider IP allowlisting.
- Back up the WireGuard config volume (`etc_wireguard`) regularly.

## Useful commands

```bash
# Logs
docker compose logs -f wg-easy

# Restart
docker compose restart wg-easy

# Stop
docker compose down

# Stop and remove volumes (DANGEROUS: deletes VPN config)
docker compose down -v
```

## Troubleshooting

- Clients connect but no traffic:
  - host firewall forwarding/NAT is usually the problem
  - ensure `net.ipv4.ip_forward=1` (compose sets it inside container, but host policies may still block forwarding)
- UI not reachable:
  - confirm port binding `WG_UI_BIND` / `WG_UI_PORT`
  - check health: `docker inspect --format='{{json .State.Health}}' wg-easy`
