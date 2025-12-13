# Node.js Docker Compose Stack (Template)

This repository is a **production-leaning Docker Compose blueprint** for a Node.js service. It includes the “stuff most people omit”:

- Networks (including an internal app network)
- Volumes for persistence
- Docker configs for non-secret configuration
- Docker secrets for sensitive values
- Healthchecks
- Optional Postgres and Redis (via Compose profiles)
- Optional Prometheus + Grafana for metrics (via profiles)

## What you get

- **app**: Node.js container with `/healthz` and `/metrics` implemented in `server.js`.
- **postgres**: optional database (`--profile db`).
- **redis**: optional cache/queue (`--profile cache`).
- **prometheus** + **grafana**: optional monitoring (`--profile monitoring`).

## Prerequisites

- Docker Engine + Docker Compose plugin (`docker compose`)

## Quick start

1. Copy environment template:

```bash
cp .env.example .env
```

2. (Recommended) Change secrets:

- `secrets/db_password.txt`
- `secrets/jwt_secret.txt`

3. Build and run **only the app**:

```bash
docker compose up -d --build
```

4. Open:

- App: `http://localhost:3000/`
- Health: `http://localhost:3000/healthz`
- Metrics: `http://localhost:3000/metrics`

## Enabling optional services (profiles)

### App + Postgres

```bash
docker compose --profile db up -d --build
```

### App + Redis

```bash
docker compose --profile cache up -d --build
```

### App + Postgres + Redis

```bash
docker compose --profile db --profile cache up -d --build
```

### Add monitoring (Prometheus + Grafana)

```bash
docker compose --profile db --profile cache --profile monitoring up -d --build
```

Monitoring endpoints:

- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3001` (default admin/admin unless you change `.env`)

## Configuration and secrets model

### `.env`

Use `.env` for **non-secret** config (ports, hostnames, feature flags). See `.env.example`.

### Docker configs (non-secret)

- `config/app.config.json` is mounted into the app at: `/app/config/app.config.json`
- The app receives `APP_CONFIG_PATH=/app/config/app.config.json`

### Docker secrets (secret)

- `secrets/db_password.txt` mounted as `/run/secrets/db_password`
- `secrets/jwt_secret.txt` mounted as `/run/secrets/jwt_secret`

Your app should read secret values from these file paths (not from environment variables). The sample `server.js` shows the pattern.

## Healthchecks

- App healthcheck expects: `GET /healthz` returns HTTP 200.
- Postgres uses `pg_isready`.
- Redis uses `redis-cli ping`.
- Prometheus uses `/-/healthy`.

If you remove or rename `/healthz`, the app container will be marked **unhealthy**. Fix the app or update the compose healthcheck.

## Metrics

Prometheus is configured to scrape:

- `app:3000/metrics`

If you change `APP_PORT`, remember this is the **host port**; inside Docker the app still listens on 3000 unless you change the container port mapping and the app’s `PORT`.

## Hardening choices (read this)

The `app` service includes:

- `read_only: true`
- `tmpfs: /tmp`
- `cap_drop: ALL`
- `no-new-privileges:true`

This will break apps that write to disk (logs, uploads, temp files). The template gives you **one explicit writable path**:

- `/app/data` (backed by the `app_data` volume)

If your app needs more, add explicit mounts; do not just remove hardening without understanding the impact.

## Common failure modes

1. **Healthcheck failing** because `/healthz` does not exist.
2. **Read-only filesystem** breaking the app due to unexpected disk writes.
3. **Metrics empty** because `/metrics` is not implemented or not reachable.
4. **Profiles confusion**: Postgres/Redis/Monitoring only run when you enable their profiles.

## Files

- `docker-compose.yml` – full stack
- `Dockerfile` – multi-stage build
- `.dockerignore`
- `.env.example`
- `server.js` – minimal Express app with health + metrics
- `config/app.config.json`
- `secrets/*.txt`
- `prometheus/prometheus.yml`

## License

Template content: use freely.
