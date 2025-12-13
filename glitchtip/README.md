# GlitchTip Docker Compose Stack

This repository contains a hardened, production-oriented Docker Compose setup for **GlitchTip** with:
- Postgres 16 (persistent storage)
- Redis 7 (AOF enabled)
- Separate services for **migrations**, **web**, and **worker**
- Healthchecks, persistent uploads volume, conservative security defaults

## Contents

```
.
├── docker-compose.yml
├── .env.example
├── secrets/
│   └── glitchtip_postgres_password.txt
└── README.md
```

## Preconditions

- Docker Engine + Docker Compose v2
- A reverse proxy (recommended) in front of GlitchTip for TLS termination (Traefik/Nginx/Caddy)
- A DNS name for `GLITCHTIP_DOMAIN`

## Quick start

1. Create your environment file:

```bash
cp .env.example .env
```

2. Create the Postgres password secret:

```bash
mkdir -p secrets
openssl rand -base64 32 > secrets/glitchtip_postgres_password.txt
chmod 600 secrets/glitchtip_postgres_password.txt
```

3. Set the GlitchTip `SECRET_KEY`:

```bash
# Put the output into GLITCHTIP_SECRET_KEY inside .env
openssl rand -hex 32
```

4. (Strongly recommended) Disable user self-registration after initial admin is created:

- Set `GLITCHTIP_ENABLE_USER_REGISTRATION=true` temporarily.
- After creating your first admin user, set it to `false` and restart.

5. Start the stack:

```bash
docker compose up -d
```

6. Check status:

```bash
docker compose ps
docker compose logs -f glitchtip
```

## Operational notes (read this if you care about uptime)

### 1) Do not expose Redis/Postgres
This Compose file **does not publish ports** for Redis/Postgres. Keep it that way unless you have a hard requirement.
If you publish these ports to the internet, you are asking to be compromised.

### 2) Why a migration service exists
GlitchTip requires database migrations. Running migrations as a one-off service avoids race conditions and broken boots
when you upgrade.

### 3) Persistent uploads
`glitchtip_uploads` is mounted at `/code/uploads` so uploaded artifacts survive restarts and upgrades.
If you scale horizontally across multiple nodes, move this to shared storage or object storage.

### 4) Reverse proxy headers
If you front this with a reverse proxy, ensure it passes standard `X-Forwarded-*` headers and you set:
- `GLITCHTIP_DOMAIN` to the **external** HTTPS URL.

### 5) Updating images
Do not use `:latest` blindly in production unless you accept surprise changes.
If you want repeatable deployments, pin tags:

```yaml
image: glitchtip/glitchtip:<tag>
image: postgres:16.<patch>
image: redis:7.<patch>
```

### 6) Metrics (Prometheus)
Some GlitchTip builds can expose Prometheus metrics (commonly `/metrics`).
Verify by curling the endpoint from inside the network:

```bash
docker compose exec glitchtip wget -qO- http://127.0.0.1:8000/metrics | head
```

If it returns 404, you do **not** have metrics enabled in your build; don’t pretend.

## Troubleshooting

### “Web is up but background jobs don’t run”
Check the worker logs:

```bash
docker compose logs -f glitchtip-worker
```

### “Migrations failed”
Inspect migrate logs:

```bash
docker compose logs glitchtip-migrate
```

Fix the error, then rerun:

```bash
docker compose up -d --force-recreate glitchtip-migrate
```

## Security stance (blunt)
- Secrets in `.env` are not secrets. Use `secrets/` for anything that matters.
- Do not expose Postgres/Redis publicly.
- Pin image versions if you want predictable upgrades.
