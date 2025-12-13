# Redis Docker Compose Stack (Redis + Exporter + Optional Prometheus/Grafana)

This repository provides a production-leaning Redis deployment using Docker Compose, including:

- Redis (persistent storage, ACL, password via Docker secret, healthcheck)
- `redis_exporter` for Prometheus metrics
- Optional Prometheus + Grafana (enabled via a Compose profile)

## Contents

```text
redis-stack/
├─ docker-compose.yml
├─ .env
├─ secrets/
│  ├─ redis_password.txt
│  └─ redis_password.txt.example
├─ redis/
│  ├─ redis.conf
│  ├─ users.acl.template
│  └─ docker-entrypoint.sh
└─ monitoring/
   └─ prometheus.yml
```

## Quick start

1) Set the Redis password (required):

```bash
cp secrets/redis_password.txt.example secrets/redis_password.txt
# Edit secrets/redis_password.txt and set a strong random value (single line).
# Example:
# openssl rand -base64 48 > secrets/redis_password.txt
```

2) Start Redis + exporter:

```bash
docker compose up -d
```

3) Validate:

```bash
docker compose ps
docker logs redis --tail=200
```

### Optional monitoring stack

Enable Prometheus and Grafana with the `monitoring` profile:

```bash
docker compose --profile monitoring up -d
```

- Prometheus: `http://localhost:${PROMETHEUS_PORT:-9090}`
- Grafana: `http://localhost:${GRAFANA_PORT:-3000}`

## Configuration notes (do not ignore)

### 1) Network exposure
By default, `docker-compose.yml` publishes Redis to the host port `${REDIS_PORT}`. If you do not explicitly need host access, remove the `ports:` section from the Redis service to keep Redis private to Docker networks.

Publishing Redis to anything reachable from the Internet is an avoidable security failure.

### 2) Memory limits
For production, set these in `redis/redis.conf` based on your use case:

- `maxmemory`
- `maxmemory-policy` (e.g. `allkeys-lru` for cache workloads)

Leaving defaults is how you get unpredictable eviction behavior or OOM events under pressure.

### 3) Persistence model
This stack enables AOF (`appendonly yes`) with `appendfsync everysec` and also keeps RDB snapshots. Tune based on your RPO/RTO and IO budget.

### 4) ACLs / least privilege
The ACL file is generated at container start and written to `/data/users.acl` (persisted). The template is in `redis/users.acl.template`.

If multiple apps share Redis, create separate users and restrict commands + key patterns per app. Do not reuse one “god-mode” credential everywhere.

## Files

- `docker-compose.yml` — services, networks, volumes, secrets, healthchecks, metrics
- `.env` — local configuration defaults
- `redis/redis.conf` — Redis settings (no secrets)
- `redis/users.acl.template` — ACL template (password injected at runtime)
- `redis/docker-entrypoint.sh` — reads Docker secret and generates ACL file
- `monitoring/prometheus.yml` — Prometheus scrape config for the exporter

## Common operations

### Connect to Redis
From inside the Redis container:

```bash
docker exec -it redis sh
redis-cli -a "$(cat /run/secrets/redis_password)" ping
```

### Rotate the password
1) Update `secrets/redis_password.txt`
2) Restart services:

```bash
docker compose up -d --force-recreate
```

## Safety check (recommended)
If this is anything beyond dev/test, remove host port exposure and place Redis behind a private network boundary.
