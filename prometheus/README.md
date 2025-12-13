# Prometheus (Docker Compose Bundle)

This bundle provides a hardened, production-leaning Prometheus deployment using Docker Compose, including:
- Explicit networks and named volume for TSDB data
- Bind-mounted configuration and rule files
- Healthcheck using Prometheus readiness endpoint
- Basic container hardening (read-only filesystem, dropped caps, no-new-privileges)
- Optional TLS + basic auth support via `--web.config.file` and Docker secrets

## Contents

```
.
├── docker-compose.yml
├── .env.example
├── config/
│   └── prometheus/
│       ├── prometheus.yml
│       ├── web.yml
│       └── rules/
│           └── node.rules.yml
└── secrets/
    └── prometheus/
        ├── tls.crt   (create)
        └── tls.key   (create)
```

## Quick start

1. Copy environment file:

```bash
cp .env.example .env
```

2. (Optional) Create TLS secrets (only if you want Prometheus to serve HTTPS directly):

```bash
mkdir -p secrets/prometheus
# Put your cert/key here:
# secrets/prometheus/tls.crt
# secrets/prometheus/tls.key
```

3. Start Prometheus:

```bash
docker compose up -d
```

4. Verify health:

```bash
curl -fsS http://localhost:${PROMETHEUS_PORT:-9090}/-/ready
curl -fsS http://localhost:${PROMETHEUS_PORT:-9090}/-/healthy
```

## Important operational notes (read this)

- Do **not** expose Prometheus to the public internet without strong access controls. Prefer a reverse proxy with auth/IP allowlists.
- Pin the image tag (`PROMETHEUS_IMAGE_TAG`) instead of using `latest`.
- If you enable `config/prometheus/web.yml` with basic auth, use bcrypt hashes only.
- Your scrape targets (`node-exporter`, `coredns`, `n8n`) must be on the same Docker network (`asterix_network`) and resolvable by service name.

## Customization

- Scrape jobs: edit `config/prometheus/prometheus.yml`
- Alert rules: drop more rule files into `config/prometheus/rules/`
- Retention: set `PROMETHEUS_RETENTION_TIME` and/or `PROMETHEUS_RETENTION_SIZE` in `.env`

## Reloading config without restart

This stack enables lifecycle API, so you can reload configuration after edits:

```bash
curl -X POST http://localhost:${PROMETHEUS_PORT:-9090}/-/reload
```

## Security stance

This compose uses:
- `read_only: true`
- `cap_drop: [ALL]`
- `security_opt: no-new-privileges:true`
- `tmpfs: /tmp`

If you add exporters or sidecars that need filesystem writes, don’t blindly disable hardening—scope the permissions to what is actually required.
