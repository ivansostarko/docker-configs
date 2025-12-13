# MongoDB Replica Set (3 nodes) — Docker Compose

This stack runs a **3-member MongoDB replica set** with:
- Docker networks, named volumes
- Config files (mongod.conf)
- Healthchecks
- Docker secrets (root/app/exporter passwords + replica set keyFile)
- One-shot initializer (`mongo-init`) to **initiate the replica set** and create users
- Optional monitoring profile: **Percona MongoDB Exporter + Prometheus + Grafana**

## Directory layout

- `docker-compose.yml`
- `.env` (non-secret configuration)
- `mongo/` (custom image wrapper to handle keyFile perms)
- `scripts/rs-init.sh` (replica set + users init; idempotent)
- `secrets/` (local secret files; do not commit)
- `monitoring/` (Prometheus and Grafana provisioning)

---

## 1) Create secrets

### Root / app / exporter / Grafana passwords
Edit these files (one line each):

- `secrets/mongo_root_password.txt`
- `secrets/mongo_app_password.txt`
- `secrets/mongo_exporter_password.txt`
- `secrets/grafana_admin_password.txt`

### Replica set keyFile (required)
MongoDB internal authentication for replica set members requires a shared keyfile with strict permissions (the stack enforces 0600 inside containers).

Generate a new keyfile content:

```bash
openssl rand -base64 756 > secrets/mongo_keyfile.txt
chmod 0400 secrets/mongo_keyfile.txt
```

---

## 2) Start MongoDB replica set

```bash
docker compose up -d --build
```

What happens:
1. `mongo1`, `mongo2`, `mongo3` start with `--replSet` and the shared keyFile.
2. `mongo1` creates the **root** user on first boot (official image behavior).
3. `mongo-init` waits for all nodes, then:
   - runs `rs.initiate()` and adds members
   - creates the **app user** (readWrite on `${MONGO_APP_DB}`)
   - creates the **exporter user** (clusterMonitor on admin + read on local)

Check status:

```bash
docker compose logs -f mongo-init
docker compose exec mongo1 mongosh -u "$MONGO_ROOT_USERNAME" -p "$(cat secrets/mongo_root_password.txt)" --authenticationDatabase admin --eval "rs.status()"
```

---

## 3) Connection strings

### From your host (using published port on mongo1)
```text
mongodb://<APP_USER>:<APP_PWD>@localhost:${MONGO_PUBLISHED_PORT}/${MONGO_APP_DB}?replicaSet=${MONGO_REPLICA_SET}&authSource=${MONGO_APP_DB}
```

### From another container on `mongo_net` network
```text
mongodb://<APP_USER>:<APP_PWD>@${MONGO_URI_HOSTS}/${MONGO_APP_DB}?replicaSet=${MONGO_REPLICA_SET}&authSource=${MONGO_APP_DB}
```

Notes:
- Publishing only `mongo1` is convenient, but it is **not** a production-grade ingress pattern by itself. If you need stable ingress, put a TCP load balancer in front and expose **all** members behind it, or run clients within the same Docker network.

---

## 4) Enable monitoring (optional)

Start monitoring services:

```bash
docker compose --profile monitoring up -d
```

Endpoints:
- MongoDB exporter: `http://localhost:${MONGO_EXPORTER_PUBLISHED_PORT}/metrics`
- Prometheus: `http://localhost:${PROMETHEUS_PUBLISHED_PORT}`
- Grafana: `http://localhost:${GRAFANA_PUBLISHED_PORT}` (admin password from `secrets/grafana_admin_password.txt`)

The exporter permissions follow Percona's recommendation:
- `clusterMonitor` on `admin`
- `read` on `local`

(See Percona MongoDB Exporter README for details.)

---

## Operational notes (do not ignore these)

1. **Do not set MONGO_INITDB_ROOT_* on mongo2/mongo3.**
   If you do, you risk creating divergent local users on secondaries before replication is established.

2. **Persistence**:
   Data is stored in named volumes:
   - `mongo1_data`, `mongo2_data`, `mongo3_data`

3. **Re-initialization**:
   If you need to rebuild from scratch:
   ```bash
   docker compose down -v
   ```
   WARNING: `-v` deletes all Mongo data volumes.

4. **TLS**:
   This compose does **not** enable TLS for client traffic by default. For anything beyond local/dev, add:
   - TLS certificates (via secrets)
   - `net.tls` configuration in `mongod.conf`
   - client connection string parameters

5. **Backups**:
   Replica sets are not backups. Add a backup job (mongodump / PBM) if you care about recovery.

---

## Troubleshooting

- Replica set not initiating:
  - `docker compose logs mongo-init`
  - Ensure all nodes are healthy
  - Ensure keyfile is identical on all nodes (`secrets/mongo_keyfile.txt`)

- Auth errors:
  - Ensure you are using `authSource=admin` when logging in as root
  - Ensure volumes are not reusing old state with different credentials
