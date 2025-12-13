# RabbitMQ (Docker Compose) — Production-Oriented Single Node + Metrics

This repository provides a practical RabbitMQ stack with:
- RabbitMQ **management UI**
- RabbitMQ **Prometheus metrics** endpoint (native plugin)
- Prometheus + Grafana for monitoring

It is **single-node** by design (good for dev and simple workloads). If you require HA, you need a multi-node cluster and quorum queues.

## Services and Ports

| Service   | Container | Purpose                | Default Host Port |
|----------|-----------|------------------------|-------------------|
| RabbitMQ | rabbitmq  | AMQP                   | 5672              |
| RabbitMQ | rabbitmq  | Management UI / API    | 15672             |
| RabbitMQ | rabbitmq  | Prometheus metrics     | 15692             |
| Prometheus | prometheus | Metrics scraping    | 9090              |
| Grafana | grafana   | Dashboards             | 3000              |

## Quick Start

1) Copy the env file and adjust values:

```bash
cp .env.example .env
```

2) Set **real secrets** (required):

```bash
# Erlang cookie (must be stable; required for clustering too)
mkdir -p secrets
openssl rand -hex 32 > secrets/erlang.cookie

# RabbitMQ admin password
openssl rand -base64 32 > secrets/admin_password
```

3) Start:

```bash
docker compose up -d
```

4) Validate:

```bash
docker compose ps
docker logs -f rabbitmq
```

- Management UI: http://localhost:15672  
  User: `${RABBITMQ_DEFAULT_USER}`  
  Password: stored in `secrets/admin_password`

- Prometheus: http://localhost:9090  
- Grafana: http://localhost:3000  
  User: `${GRAFANA_ADMIN_USER}`  
  Password: `${GRAFANA_ADMIN_PASSWORD}` (from `.env`)

## Metrics

RabbitMQ metrics are exposed at:

- `http://rabbitmq:15692/metrics` (inside the Docker network)
- `http://localhost:15692/metrics` (if you mapped the port)

Prometheus scrapes this endpoint via `monitoring/prometheus/prometheus.yml`.

## Configuration Overview

- `config/rabbitmq.conf`
  - Enables management UI, Prometheus endpoint, and loads definitions on boot.
- `config/enabled_plugins`
  - Enables `rabbitmq_management` and `rabbitmq_prometheus`.
- `config/definitions.json`
  - Demonstrates where users/vhosts/policies live.
  - Note: RabbitMQ definitions do **not** store plaintext passwords. This stack injects the admin password from a Docker secret via `scripts/entrypoint.sh`.

## Persistence

Named volumes:
- `rabbitmq_data` → `/var/lib/rabbitmq`
- `rabbitmq_logs` → `/var/log/rabbitmq`
- `prometheus_data` → `/prometheus`
- `grafana_data` → `/var/lib/grafana`

## Backup (Practical, Not Theoretical)

If you care about your messages and definitions:
- Stop producers/consumers (or accept a consistent snapshot risk).
- Backup the RabbitMQ data volume.

Example:

```bash
docker compose stop rabbitmq
docker run --rm -v rabbitmq_data:/data -v "$PWD"/backup:/backup alpine   sh -c "cd /data && tar -czf /backup/rabbitmq_data_$(date +%F).tar.gz ."
docker compose start rabbitmq
```

## Security Notes (Read This, Don’t Skip It)

- Do **not** expose `15672` (management) or `15692` (metrics) publicly. Put them behind VPN/firewall or an authenticated reverse proxy.
- `.env` is **not** a secret store. Use a secret manager for real deployments.
- If you later build a cluster, the **Erlang cookie must match** across nodes. That’s why it is a Docker secret here.

## Troubleshooting

- RabbitMQ unhealthy:
  - `docker logs rabbitmq`
  - Check that `secrets/erlang.cookie` and `secrets/admin_password` exist (non-empty).
- Ports already in use:
  - Change host ports in `.env` (e.g., `RABBITMQ_MANAGEMENT_PORT=15673`).

## Next Step (If You Actually Need HA)

Single-node RabbitMQ is a single point of failure. If you need HA, ask for a **3-node compose**:
- quorum queues by default
- proper peer discovery
- per-node volumes
- correct cookie distribution and partition handling
