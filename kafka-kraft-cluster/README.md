# Kafka KRaft Cluster (3-node) — Docker Compose

This repository provides a **3-node Kafka cluster** running in **KRaft mode** (no ZooKeeper), with:
- Replication defaults set for a 3-broker cluster (RF=3, min ISR=2).
- Optional **Kafka UI** (`--profile ui`).
- Optional **Prometheus + Grafana + kafka-exporter** (`--profile observability`).
- Optional **topic bootstrap job** (`--profile init`) to create topics after the cluster is healthy.

## What you are actually getting

- **3 brokers** that are also **controllers** (`broker,controller`) using a 3-node controller quorum.
- Separate listeners for internal vs external traffic:
  - `PLAINTEXT://kafkaN:29092` for container-to-container (recommended for apps in the same Docker network)
  - `PLAINTEXT_HOST://<host>:<mapped-port>` for host clients (your laptop, CI runner, etc.)

If you want a production-grade security posture (TLS/SASL/ACLs), do **not** deploy this as-is.

---

## Requirements

- Docker Engine + Docker Compose v2
- ~2–4 GB RAM available (Kafka + metrics stack can be heavy)
- Open host ports (by default): `19092`, `29092`, `39092`, plus optional UI/metrics ports

---

## Quickstart

1) Create your `.env`:

```bash
cp .env.example .env
```

2) Generate and set `KAFKA_CLUSTER_ID` in `.env`:

```bash
docker run --rm confluentinc/cp-kafka:8.1.1 kafka-storage random-uuid
```

Paste the UUID into `.env` as `KAFKA_CLUSTER_ID=...`.

3) Start the cluster:

```bash
docker compose up -d
```

4) Confirm health:

```bash
docker compose ps
docker logs kafka1 --tail 100
```

---

## Optional profiles

### Kafka UI

```bash
docker compose --profile ui up -d
```

Open: `http://localhost:${KAFKA_UI_PORT}`

### Observability (Prometheus + Grafana + kafka-exporter)

```bash
docker compose --profile observability up -d
```

- Prometheus: `http://localhost:${PROMETHEUS_PORT}`
- Grafana: `http://localhost:${GRAFANA_PORT}` (default user/pass from `.env`)

Grafana is provisioned with:
- Prometheus datasource
- A small “Kafka Exporter Overview” dashboard

### Topic initialization

This runs **once** and exits. Configure `.env`:

```bash
KAFKA_INIT_TOPICS=orders,payments,users
KAFKA_INIT_PARTITIONS=6
KAFKA_INIT_RF=3
```

Run:

```bash
docker compose --profile init up kafka-init --abort-on-container-exit
```

---

## Connecting clients

### From your host machine

Use mapped ports (defaults):

- Broker 1: `localhost:19092`
- Broker 2: `localhost:29092`
- Broker 3: `localhost:39092`

Example:

```bash
kafka-topics --bootstrap-server localhost:19092 --list
```

### From another container on the same `kafka-net`

Use internal listeners:

```text
kafka1:29092,kafka2:29092,kafka3:29092
```

---

## Data persistence

Each broker has its own named volume:

- `kafka1_data`
- `kafka2_data`
- `kafka3_data`

Prometheus and Grafana also persist to named volumes when the observability profile is used.

---

## Critical operational constraints (do not ignore)

### 1) `KAFKA_CLUSTER_ID` must not change

Kafka KRaft storage is bound to the cluster ID. If you change it after writing data, the cluster will not boot cleanly.

If you must change it, you must **wipe volumes**:

```bash
docker compose down -v
```

### 2) Don’t expose PLAINTEXT to the internet

This compose uses PLAINTEXT listeners for simplicity. If you bind this to a public interface without TLS/SASL/ACLs, assume compromise.

If you need secure external access, you should implement:
- TLS encryption
- SASL auth (SCRAM/OAuth)
- ACL authorization
- Separate controller listener isolation
- Proper secrets management (Docker secrets / vault)

---

## Monitoring

### Prometheus

Scrapes:
- Prometheus itself
- kafka-exporter at `kafka-exporter:9308`

Config: `config/prometheus/prometheus.yml`

### Grafana

Provisioning:
- Datasource: `config/grafana/provisioning/datasources/datasource.yml`
- Dashboard provider: `config/grafana/provisioning/dashboards/provider.yml`
- Dashboards: `config/grafana/dashboards/*.json`

---

## Common admin commands

List topics (from host):

```bash
kafka-topics --bootstrap-server localhost:19092 --list
```

Describe a topic:

```bash
kafka-topics --bootstrap-server localhost:19092 --describe --topic orders
```

Create a topic (manual):

```bash
kafka-topics --bootstrap-server localhost:19092 --create --topic orders --partitions 6 --replication-factor 3
```

---

## Troubleshooting

### Cluster won’t form / controller quorum issues
- Ensure all three services are running and healthy.
- Check logs:

```bash
docker logs kafka1 --tail 200
docker logs kafka2 --tail 200
docker logs kafka3 --tail 200
```

### “Cluster ID mismatch” or storage errors
- You changed `KAFKA_CLUSTER_ID` or have dirty volumes.
- Fix: stop and wipe volumes (destructive):

```bash
docker compose down -v
```

### Host clients can’t connect
- Ensure `KAFKA_EXTERNAL_HOST` is correct:
  - `localhost` for local-only usage
  - LAN IP or DNS name if connecting from other machines
- Ensure ports are open and not already in use.

---

## Layout

```text
.
├── docker-compose.yml
├── .env.example
├── config
│   ├── prometheus
│   │   └── prometheus.yml
│   └── grafana
│       ├── dashboards
│       │   └── kafka-exporter-overview.json
│       └── provisioning
│           ├── datasources
│           │   └── datasource.yml
│           └── dashboards
│               └── provider.yml
└── scripts
    └── create-topics.sh
```

---

## Next hardening steps (recommended)

If you intend to run this beyond local dev, the next rational increment is:
1) TLS everywhere (including inter-broker and controller traffic)
2) SASL/SCRAM for clients
3) Kafka ACLs + superuser configuration
4) Move credentials to Docker secrets (or a secret manager)
5) Add broker-level metrics via JMX exporter (not just kafka-exporter)

If you want, I can deliver a **secure** variant (TLS/SASL/ACLs) with keystore/truststore generation and Docker secrets wired correctly.
