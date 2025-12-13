# Laravel 12 Platform Docker Compose (Octane + FrankenPHP)

This repository provides a *platform-style* Docker Compose setup for a Laravel 12 application with:
- PHP 8.3 + Composer (in image)
- Laravel Octane on FrankenPHP
- Optional: Reverb, Horizon, multiple queue backends, MySQL/MariaDB/MongoDB, Typesense (Scout), Logstash, Prometheus/Grafana

## What this is (and is not)

This is **not** a minimal starter. It is a **feature-complete platform template** that uses Docker Compose **profiles** so you only run what you actually need.

If you try to run all queues + all DBs all the time, you will:
- waste resources
- expand the attack surface
- create failure modes you won’t debug quickly

Use profiles. Be deliberate.

---

## Prerequisites

- Docker + Docker Compose v2
- A Laravel 12 codebase in the repository root (this template does not generate Laravel for you)

---

## Quick start (default: app + redis + typesense)

1) Copy env file:

```bash
cp .env.example .env
```

2) Create secrets (sample placeholders exist in `secrets/` — replace them):

```bash
# Example (generate strong values yourself)
openssl rand -hex 32 > secrets/redis_password.txt
openssl rand -hex 32 > secrets/typesense_api_key.txt
```

3) Build and start:

```bash
docker compose up -d --build
```

App: `http://localhost:8000`

---

## Compose profiles

Enable only what you need:

### Databases
- `db-mysql`
- `db-mariadb`
- `db-mongo`

Examples:

```bash
docker compose --profile db-mysql up -d
docker compose --profile db-mongo up -d
```

### Queues
- `queue-redis` (Horizon)
- `queue-beanstalkd`
- `queue-rabbitmq`
- `queue-kafka`

Examples:

```bash
docker compose --profile queue-redis up -d
docker compose --profile queue-rabbitmq up -d
```

### Realtime
- `realtime` (Reverb)

```bash
docker compose --profile realtime up -d
```

### Logging
- `logging` (Logstash TCP input on port 5000)

```bash
docker compose --profile logging up -d
```

### Monitoring
- `monitoring` (Prometheus + Grafana + Redis exporter)

```bash
docker compose --profile monitoring up -d
```

---

## Developer tools (ephemeral containers)

Run Composer:

```bash
docker compose --profile devtools run --rm composer install
```

Run Artisan:

```bash
docker compose --profile devtools run --rm artisan migrate
```

Run tests:

```bash
docker compose --profile devtools run --rm test
```

---

## Healthchecks

Most services include healthchecks so dependency order is sane:
- app depends on redis + typesense
- queue workers depend on their brokers
- db services are probed before app tries to connect

---

## Laravel-side wiring (you must do this)

This repository **only provides infrastructure**. You still need to configure Laravel packages and config files:

### Telescope / Pulse / Horizon
- Install and configure per Laravel docs/packages
- Restrict access in production (route gates, auth, IP allowlist, etc.)

### Prometheus `/metrics`
- Your chosen Laravel Prometheus exporter must expose `/metrics` on the app service.
- `docker/prometheus/prometheus.yml` assumes `http://app:8000/metrics`.

### Logstash logging
- Configure Monolog to ship JSON logs over TCP to `logstash:5000`.
- Use a dedicated logging channel to avoid blocking request threads if Logstash is down.

### Sentry
- Configure via `SENTRY_DSN` (prefer Docker secret and map into env at runtime if needed).

### Kafka/RabbitMQ queue drivers
- Laravel does not support these as first-class queue backends without packages.
- Pick a package and define semantics (retry, DLQ, consumer groups, ordering).

---

## Security notes (do not ignore)

- Do **not** commit real secrets. Replace placeholder files in `secrets/`.
- Do **not** expose Telescope/Pulse/Horizon publicly.
- For production, terminate TLS at a reverse proxy (Traefik/Caddy/etc.) and run this stack on an internal network.

---

## File overview

- `docker-compose.yml` — full stack with profiles
- `Dockerfile` — PHP 8.3 + extensions (redis/mongodb/rdkafka)
- `docker/php/99-custom.ini` — PHP settings
- `docker/typesense/entrypoint.sh` — reads API key from Docker secret
- `docker/logstash/*` — Logstash config and pipeline
- `docker/prometheus/prometheus.yml` — Prometheus scrape config
- `.env.example` — environment template
- `secrets/*.txt` — placeholder secret files (replace)

---

## Common commands

Stop:

```bash
docker compose down
```

Stop + remove volumes (destructive):

```bash
docker compose down -v
```

Logs:

```bash
docker compose logs -f app
```
