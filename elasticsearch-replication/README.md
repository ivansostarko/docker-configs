# Elasticsearch Replica (3-node) Docker Compose Stack

This repository provisions a **3-node Elasticsearch cluster** suitable for running indices with **replica shards** (high availability) and includes a minimal **Prometheus + Grafana** monitoring stack.

Be precise about the terminology:
- Elasticsearch **replication** happens at the **index/shard level** via `number_of_replicas`.
- Running *multiple nodes* gives Elasticsearch places to allocate those replicas.

This stack gives you those multiple nodes.

---

## What you get

- `es01`, `es02`, `es03`: Elasticsearch nodes (TLS on HTTP + transport)
- `es-setup`: one-shot cert generator (CA + per-node certs)
- `es-exporter`: exposes Prometheus metrics at `:9114`
- `prometheus`: scrapes exporter
- `grafana`: dashboards (datasource pre-provisioned)

---

## Hard requirements (host OS)

Elasticsearch will refuse to start or behave badly without these OS settings.

### 1) vm.max_map_count
Linux:
```bash
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.d/99-elasticsearch.conf
sudo sysctl --system
```

### 2) File descriptors
Make sure your Docker host permits high `nofile` ulimits (the compose sets them, but the host must allow it).

---

## Setup

### 1) Create secrets

Create the elastic superuser bootstrap password file:

```bash
mkdir -p secrets
openssl rand -base64 32 | tr -d '\n' > secrets/elastic_password.txt
chmod 600 secrets/elastic_password.txt
```

### 2) Create `.env`

```bash
cp .env.example .env
# Edit .env as needed (ports, heap size, Grafana admin password)
```

### 3) Start

```bash
docker compose up -d
docker compose ps
```

---

## Verify cluster

### 1) Get the password
```bash
export ELASTIC_PASSWORD="$(cat secrets/elastic_password.txt)"
```

### 2) Health
```bash
curl --cacert elasticsearch/certs/ca/ca.crt -u "elastic:${ELASTIC_PASSWORD}" https://localhost:9200/_cluster/health?pretty
```

If the cluster is green/yellow and all three nodes show up, the core is working.

> Yellow is normal if you have indices configured with replicas but not enough nodes **or** if initial allocation is still happening.

---

## Create an index with replicas (the actual “replication”)

Example: 1 primary shard and 2 replicas (needs 3 nodes to place them):
```bash
curl --cacert elasticsearch/certs/ca/ca.crt -u "elastic:${ELASTIC_PASSWORD}" -X PUT https://localhost:9200/my_index -H 'Content-Type: application/json' -d '
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 2
  }
}'
```

Check shard allocation:
```bash
curl --cacert elasticsearch/certs/ca/ca.crt -u "elastic:${ELASTIC_PASSWORD}" https://localhost:9200/_cat/shards?v
```

---

## Monitoring

- Exporter: `http://localhost:${ES_EXPORTER_PORT}/metrics`
- Prometheus: `http://localhost:${PROMETHEUS_PORT}`
- Grafana: `http://localhost:${GRAFANA_PORT}`

Grafana datasource is preconfigured to point at Prometheus.

---

## Production warnings (don’t ignore these)

1) **Heap sizing**: `-Xms/-Xmx 1g` is not a serious setup. Size it properly.
2) **Disk IO** matters more than you think. Slow disks = slow cluster.
3) **Snapshots**: this stack does not configure snapshot repositories. If you do not run snapshots, you do not have a backup strategy.
4) **Security**: TLS is enabled, but certificate lifecycle and user management are on you.
5) **Split brain / quorum**: in production, consider dedicated master-eligible nodes and proper placement across failure domains.

If you want “real” HA, you should not run all nodes on one Docker host.

---

## File map

- `docker-compose.yml`: services, networks, volumes, secrets
- `elasticsearch/scripts/es-setup.sh`: generates CA + node certs into a shared volume
- `elasticsearch/config/es0x.yml`: per-node config (TLS paths fixed)
- `prometheus/prometheus.yml`: Prometheus scrape config
- `prometheus/es-exporter.sh`: starts the ES exporter binary (downloads it if missing)
- `grafana/provisioning/datasources/datasource.yml`: Prometheus datasource provisioning
