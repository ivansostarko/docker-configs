# Redis + Prometheus Redis Exporter (Docker Compose)

This project deploys:
- **Redis** (persistent storage, basic hardening)
- **Prometheus Redis Exporter** (exposes Redis metrics at `/metrics`)

It includes:
- Dedicated networks (`app_net` internal + `monitoring`)
- Persistent volume for Redis data
- Config file for Redis
- Docker secret for the Redis password
- Healthchecks for both services
- A Prometheus scrape example

## Quick start

1. Create an `.env` from the example:

```bash
cp .env.example .env
```

2. Set a strong Redis password (do **not** keep the default):

```bash
mkdir -p secrets
openssl rand -base64 32 > secrets/redis_password.txt
chmod 600 secrets/redis_password.txt
```

3. Start services:

```bash
docker compose up -d
```

4. Verify:
- Exporter metrics: `http://localhost:${REDIS_EXPORTER_PORT:-9121}/metrics`
- Redis port (only if you kept host publishing): `localhost:${REDIS_PORT:-6379}`

## Security notes (do not ignore)

- If Redis is only used by containers, **remove** the `ports:` mapping for Redis and keep it internal.
- The password is injected via a Docker secret to avoid leaking credentials through `docker inspect`.
- Image tags are pinned by default for the exporter. Consider pinning Redis too if you are serious about change control.

## Prometheus scrape config

### Single Redis instance (this compose defaults to this mode)

```yaml
scrape_configs:
  - job_name: redis_exporter
    static_configs:
      - targets: ['redis_exporter:9121']
```

### Multi-target pattern (one exporter scrapes many Redis endpoints)

If you want one exporter to scrape multiple Redis targets, configure Prometheus to call the exporter's `/scrape` endpoint.
You will need to adjust the exporter command accordingly (see exporter docs).

```yaml
scrape_configs:
  - job_name: redis_exporter_targets
    static_configs:
      - targets:
          - redis://redis-a:6379
          - redis://redis-b:6379
    metrics_path: /scrape
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: redis_exporter:9121

  - job_name: redis_exporter_self
    static_configs:
      - targets: ['redis_exporter:9121']
```

## Metrics you should expect (examples)

Common high-signal metrics include:
- `redis_up`
- `redis_connected_clients`
- `redis_memory_used_bytes`
- `redis_commands_processed_total`
- `redis_keyspace_hits_total` / `redis_keyspace_misses_total`
- `redis_evicted_keys_total`, `redis_expired_keys_total`

If you are not alerting on at least **`redis_up`**, memory saturation trends, and hit-rate regression, you are collecting metrics as decoration.

## Files

- `docker-compose.yml` – Redis + exporter deployment
- `config/redis/redis.conf` – Redis baseline configuration
- `.env.example` – Example environment variables
- `secrets/redis_password.txt` – **You must create/replace this** with a strong password

## License

Use at your own risk. Validate in staging before production.
