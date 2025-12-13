# Redis Admin GUI (Redis Insight) + Redis + Metrics (Optional)

This repository provides a production-leaning Docker Compose stack for:

- **Redis** (single node)
- **Redis Insight** (primary Admin GUI)
- Optional: **Redis Commander** (alternate lightweight GUI)
- Optional: **redis_exporter** + **Prometheus** + **Grafana** for metrics

## What you get (and what you do not)

### Included
- Dedicated networks (`backend` internal, optional `edge`)
- Persistent volumes for Redis and UI/monitoring data
- Docker secrets for passwords/keys
- Healthchecks for all services
- Optional metrics stack

### Not included (on purpose)
- Internet-facing exposure by default. UI ports are bound to `127.0.0.1`.
- Reverse proxy / SSO. If you want to expose this remotely, add a reverse proxy (Caddy/Traefik/Nginx) with authentication and IP allowlisting.

## Directory structure

```text
redis-admin/
├─ docker-compose.yml
├─ .env
├─ secrets/
│  ├─ redis_password.txt
│  ├─ ri_encryption_key.txt
│  └─ grafana_admin_password.txt
└─ config/
   ├─ redis/
   │  └─ redis.conf
   └─ prometheus/
      └─ prometheus.yml
```

## Quick start

From this folder:

```bash
docker compose up -d
```

- Redis Insight: http://127.0.0.1:5540
- Redis is **not published** to the host. It is only reachable on the internal `backend` network.

### Enable metrics (recommended for anything beyond toy setups)

```bash
docker compose --profile metrics up -d
```

- Prometheus: http://127.0.0.1:9090
- Grafana: http://127.0.0.1:3000

### Enable alternative GUI (Redis Commander)

```bash
docker compose --profile alt-gui up -d
```

- Redis Commander: http://127.0.0.1:8081

## Secrets setup (do this first)

The repo ships with placeholder secrets. Replace them.

```bash
mkdir -p secrets

# Strong Redis password
openssl rand -base64 32 > secrets/redis_password.txt

# Redis Insight storage encryption key (keep stable if you persist redisinsight-data)
openssl rand -base64 48 > secrets/ri_encryption_key.txt

# Grafana admin password
openssl rand -base64 24 > secrets/grafana_admin_password.txt

chmod 0400 secrets/*.txt
```

## Connecting Redis Insight to Redis

1. Open Redis Insight at http://127.0.0.1:5540
2. Add database:
   - Host: `redis`
   - Port: `6379`
   - Username: `default`
   - Password: (from `secrets/redis_password.txt`)

Brutal truth: **do not** “preconfigure” the Redis password via environment variables unless you accept the leakage risk.

## Configuration

### Redis
- `config/redis/redis.conf` contains baseline persistence and operational settings.
- Redis password is enforced via `--requirepass` injected from `secrets/redis_password.txt`.

### Metrics
- `redis_exporter` scrapes Redis and exposes metrics on `:9121` (internal).
- Prometheus configuration is in `config/prometheus/prometheus.yml`.

## Operational notes you are likely underestimating

1. **Remote exposure risk**: If you bind Redis Insight to `0.0.0.0` without access controls, you are creating an avoidable incident.
2. **Host tuning**: For reliable Redis under load, tune host settings (e.g., `vm.overcommit_memory=1`, disable THP). Compose can’t fix your host.
3. **Backups**: Redis persistence is not “backup.” If you care about recovery, implement snapshot/append-only backup workflows.

## Common commands

```bash
# Start
docker compose up -d

# Stop
docker compose down

# View logs
docker compose logs -f --tail=200

# Health/status
docker compose ps

# Remove everything (DANGEROUS: deletes volumes)
docker compose down -v
```

## Ports

All ports are localhost-bound by default:

- Redis Insight: `127.0.0.1:5540`
- Redis Commander (profile `alt-gui`): `127.0.0.1:8081`
- Prometheus (profile `metrics`): `127.0.0.1:9090`
- Grafana (profile `metrics`): `127.0.0.1:3000`

If you change any `*_BIND` to `0.0.0.0`, you are taking responsibility for securing access.
