# RabbitMQ + Prometheus Metrics (Docker Compose)

This bundle runs RabbitMQ with the **built-in Prometheus metrics endpoint** enabled via the `rabbitmq_prometheus` plugin.
It also includes an **optional legacy exporter** container for **RabbitMQ 3.x only** (disabled by default).

## What you get

- RabbitMQ (Management UI enabled)
- Prometheus metrics endpoint exposed from RabbitMQ
- Healthchecks, logging limits, ulimits
- Network separation: `apps` and `monitoring`
- Docker secrets for initial credentials (recommended)
- Optional legacy exporter (profile gated)

## Folder layout

```text
.
├── docker-compose.yml
├── .env
├── config/
│   └── rabbitmq/
│       ├── rabbitmq.conf
│       └── enabled_plugins
└── secrets/
    ├── rabbitmq_default_user.txt
    └── rabbitmq_default_pass.txt
```

## Quick start

1) Edit credentials (do not reuse defaults):

- `./secrets/rabbitmq_default_user.txt`
- `./secrets/rabbitmq_default_pass.txt`

2) (Optional) Adjust ports in `.env` if you have conflicts.

3) Start:

```bash
docker compose up -d
```

4) Verify:

- Management UI: `http://localhost:${RABBITMQ_MGMT_PORT:-15672}`
- Prometheus metrics: `http://localhost:${RABBITMQ_METRICS_PORT:-15692}/metrics`

## Prometheus scrape config

### Recommended (RabbitMQ built-in endpoint)

```yaml
scrape_configs:
  - job_name: "rabbitmq"
    metrics_path: /metrics
    static_configs:
      - targets: ["rabbitmq:15692"]
```

### Legacy exporter (RabbitMQ 3.x only)

If (and only if) you are running RabbitMQ 3 and you need the legacy exporter, enable it via the profile:

```bash
docker compose --profile legacy-rabbitmq3 up -d
```

Then scrape it:

```yaml
scrape_configs:
  - job_name: "rabbitmq_exporter_legacy"
    static_configs:
      - targets: ["rabbitmq_exporter:9419"]
```

## Security notes (do not skip)

- Do **not** expose ports `15672` and `15692` publicly. Keep them internal, firewall them, or put them behind an authenticated reverse proxy.
- Do **not** commit real secrets. This repo includes a `.gitignore` that blocks `secrets/*.txt`.

## Common operations

View logs:

```bash
docker compose logs -f rabbitmq
```

Check health:

```bash
docker inspect --format='{{json .State.Health}}' rabbitmq | jq
```

Stop:

```bash
docker compose down
```

Reset data (destructive):

```bash
docker compose down -v
```

## Files to customize

- `config/rabbitmq/enabled_plugins`: enable/disable RabbitMQ plugins
- `config/rabbitmq/rabbitmq.conf`: RabbitMQ configuration
- `.env`: image tag and published ports

