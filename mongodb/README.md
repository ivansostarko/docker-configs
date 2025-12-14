# MongoDB Docker Compose (MongoDB + Exporter + Optional UI)

This repository provides a production-leaning Docker Compose stack for:

- **MongoDB** (auth enabled, persisted volumes, healthcheck)
- **Prometheus metrics** via **Percona MongoDB Exporter**
- Optional **mongo-express** UI (profile `ui`, loopback-only)

## What this is (and what it is not)

- This is a **single-node MongoDB** setup. It is not high-availability.
- It is hardened against the most common self-inflicted failures: no public bind, secrets not in env vars, explicit healthchecks.
- If you publish MongoDB to the internet, you are choosing to get compromised.

## Prerequisites

- Docker Engine + Docker Compose v2
- `openssl` installed (for secret generation)

## Quick start

1) Copy environment file

```bash
cp .env.example .env
```

2) Generate secrets

```bash
bash ./scripts/generate-secrets.sh
```

3) Start

```bash
docker compose up -d
```

4) Verify

```bash
docker compose ps
# MongoDB healthcheck will go healthy after initialization.
docker compose logs -f mongodb
```

## Connecting

### From the host (recommended default)

MongoDB is bound to **127.0.0.1** by default.

```bash
mongosh "mongodb://root:$(cat secrets/mongo_root_password.txt)@127.0.0.1:27017/admin"
```

### From other containers on the same Docker network

Use the service name `mongodb`:

```text
mongodb://<user>:<pass>@mongodb:27017/<db>?authSource=admin
```

## Metrics (Prometheus)

Exporter is exposed on **127.0.0.1:${MONGO_EXPORTER_PORT}** by default.

Example Prometheus scrape job:

```yaml
scrape_configs:
  - job_name: "mongodb"
    static_configs:
      - targets: ["host.docker.internal:9216"]
```

Notes:
- On Linux, `host.docker.internal` may require Docker 20.10+ or custom configuration. If Prometheus runs in the same Compose network, scrape `mongodb-exporter:9216` instead.

## Optional: mongo-express UI

This is **not** a security boundary. Treat it as a convenience tool and keep it private.

Start with the `ui` profile:

```bash
docker compose --profile ui up -d
```

Then open:

- `http://127.0.0.1:${MONGO_EXPRESS_PORT}`

## Backups

Create a backup:

```bash
bash ./scripts/backup.sh
```

Restore from a backup directory:

```bash
bash ./scripts/restore.sh ./backups/<timestamp>/backup
```

Hard truth: if you do not test restores, you do not have backups.

## Security posture (non-negotiable defaults)

- **Loopback-only host exposure** for MongoDB and exporter
- **Docker secrets** via files, not plaintext env vars
- **Auth enabled** in `mongod.conf`
- **Internal Docker networks** (services talk internally; host exposure is explicit)

If you want TLS, replica sets, or external access, you need to make explicit architectural decisions (and accept the operational overhead).

## Troubleshooting

- If users are not created, you probably reused an existing volume. Init scripts run only when the DB is initialized the first time.
  - Fix: `docker compose down -v` (destructive) or create users manually.

- Check health:

```bash
docker inspect --format='{{json .State.Health}}' mongodb | jq
```

- Logs:

```bash
docker compose logs -f mongodb
```

## Files

- `docker-compose.yml` – main stack
- `config/mongod.conf` – MongoDB configuration
- `initdb/01-users.js` – first-run user creation
- `scripts/generate-secrets.sh` – create secret files
- `scripts/backup.sh` / `scripts/restore.sh` – basic backup/restore helpers
