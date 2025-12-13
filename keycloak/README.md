# Keycloak (Postgres) Docker Compose Stack

This bundle provides a production-leaning Keycloak setup backed by Postgres, with:
- Networks separated into `frontend`, `backend` (internal), and `monitoring` (internal)
- Docker secrets for admin and database credentials
- Healthchecks for Postgres, Keycloak, and optional services
- Optional profiles:
  - `proxy` (Nginx)
  - `monitoring` (Prometheus + Postgres exporter)

## What you must not screw up

1. **Do not publish port 9000 publicly.** That is the management port for `/health` and `/metrics`.
2. **Pin versions.** `latest` guarantees surprise outages.
3. **If behind a reverse proxy, set hostname + proxy headers correctly** or you will get bad redirects and/or trust forwarded headers from attackers.

## Quick start

1) Put secrets in `./secrets/`:

- `secrets/keycloak_admin_password.txt`
- `secrets/postgres_password.txt`

Optional (only if you run `--profile monitoring`):
- `secrets/postgres_exporter_dsn.txt`

Example DSN file content:

```text
postgresql://keycloak:REPLACE_ME@postgres:5432/keycloak?sslmode=disable
```

2) Edit `.env`:
- `KC_HOSTNAME` must match your real DNS name (e.g. `auth.example.com`)
- If you are not using a reverse proxy, you likely want `KC_HOSTNAME_STRICT=false` and different exposure rules.
- Keep `KC_HTTP_PUBLISH_ADDR=127.0.0.1` unless you intentionally expose Keycloak directly.

3) Start the stack:

```bash
docker compose up -d
```

### With Nginx reverse proxy (HTTP only)

```bash
docker compose --profile proxy up -d
```

Nginx config is at `nginx/conf.d/keycloak.conf`.

### With monitoring (Prometheus + Postgres exporter)

```bash
docker compose --profile monitoring up -d
```

Prometheus will be available on `http://localhost:9090`.

## URLs and ports

- Keycloak HTTP: `http://localhost:8080` (published to host based on `.env`)
- Keycloak management (internal only): `http://keycloak:9000`
  - readiness: `/health/ready`
  - liveness: `/health/live`
  - metrics: `/metrics`
- Postgres: internal only on the backend network

## Realm import

Place realm JSON exports in `keycloak/import/`.
The container is started with `--import-realm`, so it will attempt import at startup.

## Hardening checklist (recommended)

- Terminate TLS at a reverse proxy and restrict direct access to Keycloak.
- Tighten `KC_PROXY_TRUSTED_ADDRESSES` to only your proxy IPs/subnets.
- Put Postgres on an internal-only network (already done) and avoid host port publishing.
- Consider adding:
  - backup jobs for Postgres
  - alerting rules for Prometheus
  - log shipping (Loki/Vector/Filebeat)

## Commands

```bash
# status
docker compose ps

# logs
docker compose logs -f keycloak

# stop
docker compose down

# stop + delete volumes (destructive)
docker compose down -v
```

---

Generated on 2025-12-13.
