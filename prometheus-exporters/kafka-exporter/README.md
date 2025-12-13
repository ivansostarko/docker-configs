# Kafka Prometheus Exporter (Docker Compose)

This repository provides a production-oriented Docker Compose setup for running a **Kafka Exporter** for Prometheus using **`danielqsj/kafka_exporter`**.

It includes:
- A wrapper image that keeps the upstream exporter binary but adds **curl** for a **real healthcheck** and supports **Docker secrets**.
- `.env`-driven configuration for brokers, filtering, SASL, and TLS.
- Hardened container defaults (`read_only`, `no-new-privileges`, `cap_drop`).

## What you get

- Exporter endpoint: `http://<host>:9308/metrics`
- Prometheus scrape target (from inside Docker): `kafka_exporter:9308`

## Prerequisites

1. Docker + Docker Compose (plugin) installed.
2. Kafka reachable from the exporter.
3. A Docker network shared with Kafka.

### Required: shared Kafka network

This Compose file expects an **external** network named `kafka` by default.

Create it once:

```bash
docker network create kafka
```

If your Kafka runs in another Compose project, attach that Kafka stack to the same `kafka` network.

## Quick start

1. Edit `.env` and set `KAFKA_BROKERS` to the correct broker addresses.
2. Put your SASL password into `./secrets/kafka_sasl_password.txt` (if using SASL).
3. Start:

```bash
docker compose up -d --build
```

4. Confirm exporter is up:

```bash
curl -fsS http://localhost:9308/metrics | head
```

## Configuration

All configuration is done through `.env`.

### Brokers

Set comma-separated brokers:

```bash
KAFKA_BROKERS=broker-1:9092,broker-2:9092
```

These **must** resolve from inside the `kafka` Docker network.

### Kafka version

Set the Kafka protocol version used by the exporter:

```bash
KAFKA_VERSION=3.9.0
```

If you mis-set this, you can get confusing metadata/offset behavior.

### Topic / group filtering

On large clusters, scrape cost explodes if you export everything. Use filters:

```bash
TOPIC_FILTER=^prod\\.
TOPIC_EXCLUDE=^prod\\.internal\\.
GROUP_FILTER=^prod-
GROUP_EXCLUDE=^$
```

### SASL

Enable SASL and set mechanism:

```bash
SASL_ENABLED=true
SASL_USERNAME=exporter
SASL_MECHANISM=scram-sha512
```

Put the password in `./secrets/kafka_sasl_password.txt`.

Supported mechanisms in `.env` include:
- `plain`
- `scram-sha256`
- `scram-sha512`
- `gssapi`
- `awsiam` (AWS MSK IAM)

### TLS

Enable TLS and mount certs under `kafka_exporter/certs/`:

```bash
TLS_ENABLED=true
TLS_CA_FILE=/etc/kafka-exporter/certs/ca.crt
TLS_CERT_FILE=/etc/kafka-exporter/certs/client.crt
TLS_KEY_FILE=/etc/kafka-exporter/certs/client.key
TLS_INSECURE_SKIP_VERIFY=false
```

If your brokers use hostname verification, set:

```bash
TLS_SERVER_NAME=broker.yourdomain
```

## Prometheus configuration

Add this to `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: "kafka-exporter"
    static_configs:
      - targets: ["kafka_exporter:9308"]
```

If Prometheus runs outside Docker, use your host IP and the published port.

## Common metrics (examples)

Expect metrics in these families:
- Brokers: `kafka_brokers`, `kafka_broker_info`
- Topic/partitions: `kafka_topic_partitions`, `kafka_topic_partition_current_offset`, `kafka_topic_partition_under_replicated_partition`
- Consumer groups: `kafka_consumergroup_lag`, `kafka_consumergroup_current_offset`, `kafka_consumergroup_members`

## Troubleshooting

### No consumer-group metrics

This is typically one of:
- No active consumer groups.
- ACLs prevent describing groups/topics.
- Using the wrong security settings (SASL/TLS mismatch).

Validate connectivity from inside the container:

```bash
docker exec -it kafka_exporter sh
# (No kafka cli tools here.)
# But you can at least check the exporter endpoint:
wget -qO- http://127.0.0.1:9308/metrics | head
```

### Exporter is up, but Kafka is unreachable

- Your `KAFKA_BROKERS` hostnames are not resolvable from inside Docker.
- The exporter is not attached to the same Docker network as Kafka.

Confirm networks:

```bash
docker inspect kafka_exporter --format '{{json .NetworkSettings.Networks}}' | jq
```

## Security notes

- This setup defaults to a hardened container profile.
- Secrets are handled via Docker secrets (file-backed).
- TLS private keys should be stored with least privilege and rotated.

## Files

- `docker-compose.yml` – main stack
- `.env` – configuration
- `secrets/kafka_sasl_password.txt` – SASL password (if used)
- `kafka_exporter/Dockerfile` – wrapper image
- `kafka_exporter/entrypoint.sh` – builds exporter flags from env + secrets
- `kafka_exporter/certs/*` – TLS cert/key placeholders
