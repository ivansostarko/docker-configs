# RabbitMQ Admin GUI (Management UI) Docker Compose

This repo provides a complete, production-leaning Docker Compose stack for:
- RabbitMQ **with the built-in Admin GUI** (Management UI)
- Optional metrics via **rabbitmq_prometheus** plus **Prometheus/Grafana**

## What you are actually deploying

RabbitMQ’s “Admin GUI tool” is the **Management plugin** (HTTP UI on port `15672`). This setup uses the `rabbitmq:* -management` image which already includes it.

If you expected a separate third-party “RabbitMQ Admin” container: you do not need one. RabbitMQ’s management UI is the canonical admin console for most operational tasks.

## Files included

- `docker-compose.yml` — main stack
- `.env.example` — port bindings and defaults
- `config/rabbitmq/`
  - `rabbitmq.conf`
  - `enabled_plugins`
  - `definitions.json` (bootstrap vhost + permissions)
- `secrets/` — local Docker secrets (file-backed)
- `observability/` — optional Prometheus and Grafana provisioning
- `scripts/generate-secrets.sh` — generates strong secrets locally

## Quick start (safe defaults)

### 1) Create `.env`
```bash
cp .env.example .env
```

### 2) Generate secrets (recommended)
```bash
sh scripts/generate-secrets.sh
```

If you skip this step, you **must** replace the placeholder values in:
- `secrets/rabbitmq_user.txt`
- `secrets/rabbitmq_password.txt`
- `secrets/erlang_cookie.txt`

### 3) Start RabbitMQ
```bash
docker compose up -d
```

### 4) Open the Admin GUI
- URL: `http://127.0.0.1:15672`
- Credentials: from `secrets/rabbitmq_user.txt` and `secrets/rabbitmq_password.txt`

## Enable observability (Prometheus + Grafana)

```bash
docker compose --profile observability up -d
```

- Prometheus: `http://127.0.0.1:9090`
- Grafana: `http://127.0.0.1:3000`

Grafana credentials come from `.env`:
- `GRAFANA_ADMIN_USER`
- `GRAFANA_ADMIN_PASSWORD`

## Brutal but necessary operational notes

1. **Do not expose** `15672` (Admin UI) or `5672` (AMQP) to the public internet.  
   This compose binds them to `127.0.0.1` by default for a reason. If you need remote access, use:
   - VPN, or
   - reverse proxy with strong auth + TLS, or
   - network segmentation/firewall rules

2. `definitions.json` is **bootstrap**, not a configuration management system.  
   Your real state is stored in the volume `rabbitmq_data`. Back up the volume if you care about recovery.

3. Durability is an application contract.  
   If you need message durability: define **durable queues/exchanges** and publish **persistent messages**. Volumes alone do not guarantee durability.

## Common operations

### Check health
```bash
docker compose ps
docker logs rabbitmq --tail 200
```

### Stop
```bash
docker compose down
```

### Stop and delete data (destructive)
```bash
docker compose down -v
```

## Ports

- AMQP: `5672`
- Admin GUI: `15672`
- Prometheus metrics (RabbitMQ plugin): `15692`

All are bound to localhost by default via `.env`.

---
Generated on: 2025-12-13
