# Portainer Docker Compose (Hardened Baseline)

This package provides a production-oriented Docker Compose configuration for Portainer CE:
- Avoids `:latest` in favor of the `:lts` channel
- Exposes **HTTPS UI (9443)** by default
- Keeps **8000 (Edge Agent tunnel)** and **9000 (legacy HTTP)** available but clearly marked as optional
- Defines `networks`, `volumes`, `.env`, and an initial admin password via a Docker secret

## Included Files

- `docker-compose.yml` — Portainer service (plus optional templates service)
- `.env.example` — environment variables used by Compose
- `secrets/portainer_admin_password.txt` — initial admin password (replace immediately)
- `templates/templates.json` — placeholder templates file (optional)

## Quick Start

1) Copy the env file:

```bash
cp .env.example .env
```

2) Set the initial admin password:

Edit `secrets/portainer_admin_password.txt` and replace the placeholder password with a long unique value.

3) Start Portainer:

```bash
docker compose up -d
```

4) Open the UI (recommended):

- `https://<host>:9443`

## Optional: Templates Service

The Compose file includes an optional Nginx container that serves `templates/templates.json` over HTTP inside the Docker network.

Start it with:

```bash
docker compose --profile templates up -d
```

If you want Portainer to load templates automatically at first initialization, add an extra command flag to the `portainer` service:

```yaml
command:
  - "--admin-password-file=/run/secrets/portainer_admin_password"
  - "--templates=http://portainer-templates/templates.json"
```

## Security Notes (Read This)

- Mounting `/var/run/docker.sock` grants Portainer effectively root-equivalent control of the host.
  If Portainer is exposed to the internet and compromised, your host is compromised.
- If you don't use Edge Agents, do **not** publish port `8000`.
- Prefer putting Portainer behind a reverse proxy and binding to `127.0.0.1` via `PORTAINER_BIND_ADDR`.

## Structure

```
.
├── docker-compose.yml
├── .env.example
├── secrets/
│   └── portainer_admin_password.txt
└── templates/
    └── templates.json
```

Generated on: 2025-12-13
