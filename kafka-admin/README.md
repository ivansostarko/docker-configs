# Kafka + AKHQ Admin GUI (Docker Compose)

This stack deploys:

- **Kafka (3-node KRaft cluster)** using Bitnami Kafka containers
- **AKHQ** as the Kafka admin GUI
- **Prometheus + Grafana** for monitoring
- **Kafka Exporter** (consumer group lag + protocol-level metrics)
- **JMX Exporter javaagent** on each broker (broker/JVM metrics)

## What this is (and isn’t)

- This is **good for local/dev/lab environments** and basic internal demos.
- This is **not** a serious production control plane. If Kafka is business-critical, stop pretending Compose is a platform. Use Kubernetes/Strimzi or a managed Kafka offering.

## Quick start

1) Copy env file and set values:

```bash
cp .env.example .env
```

You **must** set:

- `KAFKA_KRAFT_CLUSTER_ID`
- `AKHQ_ADMIN_PASSWORD_SHA256`
- `AKHQ_READER_PASSWORD_SHA256`
- `AKHQ_JWT_SECRET` (recommended; required if you want RBAC enforced properly)

Generate a KRaft cluster id:

```bash
uuidgen | tr -d '-' | head -c 22
```

Generate SHA256 password hashes:

```bash
echo -n "your-password" | sha256sum | awk '{print $1}'
```

Generate JWT secret:

```bash
openssl rand -hex 32
```

2) Set Grafana admin password secret:

Edit:

- `./secrets/grafana_admin_password.txt`

3) Start the stack:

```bash
docker compose up -d
```

## Access

- AKHQ: `http://localhost:8080`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000`

## Networks

- `edge`: exposed services (AKHQ/Grafana/Prometheus)
- `kafka`: internal Kafka network
- `monitoring`: internal monitoring network

Kafka is only reachable from within the compose networks unless you add extra listeners/ports.

## Monitoring endpoints

- Kafka JMX exporter (per broker): `kafka1:7071`, `kafka2:7072`, `kafka3:7073`
- Kafka Exporter: `kafka-exporter:9308`
- AKHQ metrics: `akhq:28081/prometheus`

## AKHQ authentication / RBAC

- Basic auth users are configured in `config/akhq/application.yml`.
- The `AKHQ_JWT_SECRET` is used by Micronaut’s JWT signing generator.

### About Docker secrets for AKHQ JWT
Docker Compose does **not** natively inject a secret file into an environment variable.
This repo includes `secrets/akhq_jwt_secret.txt` for completeness, but this compose file expects
`AKHQ_JWT_SECRET` in `.env`.

If you want to strictly avoid env vars, you’ll need to implement a custom entrypoint/wrapper
that reads `/run/secrets/akhq_jwt_secret` and exports `AKHQ_JWT_SECRET` before launching AKHQ.

## Security warnings (don’t ignore these)

- Kafka runs with **PLAINTEXT listeners**. That is fine for local/dev only.
- For any shared environment: configure **SASL_SSL and ACLs** (or mTLS), and put the UI behind a reverse proxy with TLS and proper auth.

## Common operations

Create a topic:

```bash
docker exec -it ${COMPOSE_PROJECT_NAME:-kafka-akhq}-kafka1   kafka-topics.sh --create --topic test --bootstrap-server localhost:9092 --partitions 3 --replication-factor 3
```

List topics:

```bash
docker exec -it ${COMPOSE_PROJECT_NAME:-kafka-akhq}-kafka1   kafka-topics.sh --list --bootstrap-server localhost:9092
```

Tail logs:

```bash
docker compose logs -f --tail=200
```

Stop:

```bash
docker compose down
```

Wipe all data (destructive):

```bash
docker compose down -v
```

## Files

- `docker-compose.yml` — full stack definition
- `.env.example` — env template
- `config/akhq/application.yml` — AKHQ config (connections + auth)
- `config/prometheus/prometheus.yml` — Prometheus scrape config
- `config/jmx-exporter/kafka-broker.yml` — JMX exporter rules
- `config/grafana/provisioning/**` — Grafana datasource + dashboard provider

