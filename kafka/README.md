# Kafka (KRaft) Docker Compose Stack

This repository provides a practical, production-minded Docker Compose stack for:
- Apache Kafka **KRaft mode** (no ZooKeeper)
- JMX-based broker metrics via **Prometheus JMX exporter**
- Optional **kafka-exporter** for consumer-group/topic/lag style metrics
- Optional **Prometheus** + **Grafana**
- Optional **Kafka UI**
- Optional security override using **Docker secrets** and **SASL/PLAIN**

## Contents

- `docker-compose.yml` – core stack (Kafka + JMX exporter agent + kafka-exporter + optional UI/monitoring)
- `docker-compose.secure.yml` – optional override enabling **SASL_PLAINTEXT** using Docker secrets
- `.env.example` – environment template
- `monitoring/jmx/kafka-jmx.yml` – JMX exporter rules
- `monitoring/prometheus/prometheus.yml` – Prometheus scrape config
- `secrets/*` – templates for the secure override

## Quick start (plaintext)

1) Copy env template:
```bash
cp .env.example .env
```

2) Generate a stable KRaft cluster id and put it into `.env`:
```bash
docker run --rm apache/kafka:4.1.1 /opt/kafka/bin/kafka-storage.sh random-uuid
```

3) Start:
```bash
docker compose up -d
```

Kafka will be reachable on:
- Host: `localhost:${KAFKA_EXTERNAL_PORT}` (default `9092`)
- Docker network: `kafka:29092`

## Enable UI / Monitoring profiles

Start with Kafka UI and Prometheus+Grafana:
```bash
docker compose --profile ui --profile monitoring up -d
```

- Kafka UI: `http://localhost:${KAFKA_UI_PORT}` (default `8080`)
- Prometheus: `http://localhost:${PROMETHEUS_PORT}` (default `9090`)
- Grafana: `http://localhost:${GRAFANA_PORT}` (default `3000`)

## Metrics

This stack exposes:
- Kafka broker JMX-exporter metrics: `kafka:9404/metrics` (internal)
- Kafka exporter metrics: `kafka-exporter:9308/metrics` and optionally host port `9308`

Prometheus scrape config lives at:
- `monitoring/prometheus/prometheus.yml`

## Security (SASL/PLAIN with Docker secrets)

This is **not encryption**. It adds authentication, but traffic is still plaintext.
If you expose Kafka beyond a trusted network, you should implement TLS and tighten ACLs.

1) Create secrets (templates exist under `secrets/`):
- `secrets/kafka_server_jaas.conf`
- `secrets/kafka_client_username.txt`
- `secrets/kafka_client_password.txt`

2) Start with the security override:
```bash
docker compose -f docker-compose.yml -f docker-compose.secure.yml up -d
```

### Rotate credentials
- Update the secret files
- Restart Kafka and exporters

## Operational notes

- This stack runs Kafka as **single node combined broker+controller**. That’s suitable for dev and small internal workloads.
- For real production, use **separate controllers** (usually 3) and multiple brokers.
- Do not set `KAFKA_ADVERTISED_HOST=localhost` if your clients run on other machines. Set it to the host’s routable DNS/IP.

## Troubleshooting

### Kafka not healthy
Check logs:
```bash
docker logs -f kafka
```

Ensure `.env` has a valid `KAFKA_CLUSTER_ID`.

### Clients cannot connect
Verify:
- `KAFKA_ADVERTISED_HOST`
- Port mapping `KAFKA_EXTERNAL_PORT`
- Firewalls / security groups

## License
Use at your own risk.
