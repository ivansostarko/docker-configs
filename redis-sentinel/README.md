# Redis + Sentinel (Docker Compose)

This repository provides a production-oriented **Redis + Redis Sentinel** stack using Docker Compose:

- **Redis:** 3 nodes (1 master, 2 replicas)
- **Sentinel:** 3 nodes (quorum=2) for automatic failover
- **Security hardening:** internal Docker network, secrets, no-new-privileges, cap-drop
- **Healthchecks:** Redis and Sentinel
- **Optional metrics:** Redis Exporter + Prometheus + Grafana (Compose profile: `metrics`)

## What you get (and what you do not)

- You **do** get HA via Sentinel failover.
- You **do not** get load-balancing or a single stable TCP endpoint automatically.
  - Your application must use a **Sentinel-aware Redis client** (recommended), or you must add a proxy layer.

## Directory structure

```text
redis-sentinel/
├─ docker-compose.yml
├─ .env
├─ .gitignore
├─ secrets/
│  └─ redis_password.txt
├─ redis/
│  ├─ redis-master.conf.tpl
│  ├─ redis-replica.conf.tpl
│  └─ entrypoint-redis.sh
├─ sentinel/
│  ├─ sentinel.conf.tpl
│  └─ entrypoint-sentinel.sh
└─ monitoring/
   ├─ prometheus.yml
   └─ grafana/
      └─ provisioning/
```

## Prerequisites

- Docker Engine + Docker Compose plugin
- Linux/macOS recommended for file permissions (Windows works, but beware line endings)

## Quick start

1) Set a strong Redis password

```bash
# Edit the file and replace the default value
nano secrets/redis_password.txt
```

2) Make scripts executable

```bash
chmod +x redis/entrypoint-redis.sh sentinel/entrypoint-sentinel.sh
```

3) Start the core stack

```bash
docker compose up -d
```

4) Verify

```bash
docker compose ps

# Check master
redis-cli -a "$(cat secrets/redis_password.txt)" -h 127.0.0.1 -p 6379 ping

# Check Sentinel (published on localhost by default)
redis-cli -h 127.0.0.1 -p 26379 ping

# Ask Sentinel who the current master is
redis-cli -h 127.0.0.1 -p 26379 sentinel get-master-addr-by-name mymaster
```

## Metrics (optional)

This stack includes optional monitoring via:

- `oliver006/redis_exporter`
- Prometheus
- Grafana

Start with:

```bash
docker compose --profile metrics up -d
```

By default (see `.env`):

- Prometheus: `http://127.0.0.1:9090`
- Grafana: `http://127.0.0.1:3000`

**Change Grafana credentials** (they are intentionally insecure by default).

## Configuration

### Environment variables (`.env`)

Key settings:

- `SENTINEL_QUORUM=2` (recommended for 3 Sentinels)
- `SENTINEL_DOWN_AFTER_MS=5000`
- `SENTINEL_FAILOVER_TIMEOUT_MS=60000`

Publish bindings (defaults are localhost-only, recommended):

- `REDIS_MASTER_PUBLISH_ADDR=127.0.0.1`
- `SENTINEL_PUBLISH_ADDR=127.0.0.1`

### Secrets

- `secrets/redis_password.txt` is mounted as a Docker secret into Redis/Sentinel containers.
- Do not commit it.

## Operational guidance (read this, or accept downtime)

### 1) Don’t expose Redis to your LAN/Internet

Publishing ports beyond localhost without strict network policy is negligent.
If you need remote access, do it via:

- VPN (WireGuard)
- SSH tunnel
- private overlay network

### 2) Sentinel is not a magic endpoint

Your clients must:

- Discover the master via Sentinel (`SENTINEL get-master-addr-by-name`), and
- Reconnect on topology change

If your app uses a simple `host:port` Redis connection, failover will look like an outage.

### 3) Test failover before you call this “production-ready”

Simulate a master failure:

```bash
# Stop the master container
docker stop redis-1

# Watch Sentinel logs
docker logs -f sentinel-1
```

Then ask Sentinel for the master:

```bash
redis-cli -h 127.0.0.1 -p 26379 sentinel get-master-addr-by-name mymaster
```

Bring the old master back:

```bash
docker start redis-1
```

### 4) Persistence and storage

This stack uses **named volumes** by default.
If you use bind mounts instead, make sure permissions and filesystem durability are acceptable.

## Useful commands

```bash
# Show health/status
docker compose ps

# Tail logs
docker compose logs -f --tail=200 sentinel-1

# Enter a Redis container
docker exec -it redis-1 sh

# Check replication state
redis-cli -a "$(cat secrets/redis_password.txt)" -h 127.0.0.1 -p 6379 INFO replication
```

## Hard truths

- If you publish Redis ports publicly, you are inviting ransomware operators.
- If you do not test failover, you do not have HA—you have a diagram.
- If your client library is not Sentinel-aware, you do not have automatic recovery.

## License

Internal / your discretion.
