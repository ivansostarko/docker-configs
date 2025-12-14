# Dashy (Dashboard) — Docker Compose

This bundle deploys **Dashy** (a self-hosted dashboard) with:
- Persistent `user-data` mounted on the host
- Built-in container **healthcheck**
- Optional **Traefik** routing via labels
- Optional **autoheal** profile
- Reasonable operational defaults (restart policy, logging rotation, security hardening)

## Files

```
.
├── docker-compose.yml
├── .env.example
└── data
    └── user-data
        └── conf.yml
```

## Quick start (Traefik / reverse proxy)

1. Create an external Docker network for your proxy if you don't already have one:

```bash
docker network create proxy
```

2. Copy env file and set values:

```bash
cp .env.example .env
# edit .env
```

3. Start Dashy:

```bash
docker compose up -d
```

Dashy will be reachable via the hostname you set in `DASHY_FQDN` (Traefik must be running on the same `proxy` network).

## Quick start (no reverse proxy)

1. In `docker-compose.yml`, uncomment the `ports:` section for Dashy.
2. Copy env file:

```bash
cp .env.example .env
```

3. Start:

```bash
docker compose up -d
```

Dashy will be reachable on `http://localhost:${DASHY_PORT}` (default 8080).

## Configuration

Dashy's main config is:

- `./data/user-data/conf.yml` on the host
- mounted into the container at `/app/user-data/conf.yml`

Edit `conf.yml` then restart:

```bash
docker compose restart dashy
```

### UI config editing

`allowConfigEdit` controls whether Dashy can write config changes back to disk from the UI.
This bundle defaults it to `false` to prevent accidental edits persisting.

## Healthcheck

The compose file uses Dashy's internal healthcheck script:

- `test: ["CMD", "node", "/app/services/healthcheck"]`

Docker will mark the container unhealthy if the healthcheck fails repeatedly.

## Optional: Autoheal

Autoheal restarts unhealthy containers but requires mounting the Docker socket (high-trust).

Run it with the `ops` profile:

```bash
docker compose --profile ops up -d
```

## Security notes (read this)

- Dashy’s in-app auth is not a substitute for real perimeter security when exposed publicly.
- If this instance is reachable outside your LAN, place it behind SSO/VPN and/or reverse-proxy authentication.
- Avoid using subpath routing if possible; a subdomain is typically more reliable.

## Backups

Back up the `data/user-data/` directory:

```bash
tar -czf dashy-backup.tgz data/user-data
```

## Troubleshooting

- Ensure the `proxy` network exists if Traefik is enabled.
- Validate your YAML syntax:
  ```bash
  docker compose config
  ```
- Check logs:
  ```bash
  docker compose logs -f dashy
  ```

