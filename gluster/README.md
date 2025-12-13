# GlusterFS Docker Compose (Single Peer per Host)

This repository provides a production-oriented Docker Compose template to run a **GlusterFS peer**
on a host, plus optional **cluster bootstrap** and **Prometheus metrics**.

## Hard reality check (do not ignore)

- **One Gluster peer per host.** Running multiple peers on the same Docker host is a lab trick that
  produces misleading results (port collisions, unrealistic failure domains, performance artifacts).
- **Bricks must be real storage.** If you put bricks on Docker overlay storage, you are taking
  durability risks for no gain.
- **Host networking and privileged mode are intentional.** Gluster containers often expect this
  for performance and operational simplicity.

## Contents

- `docker-compose.yml`  
  - `gluster` (peer)
  - `gluster-bootstrap` (one-time cluster formation + volume creation)
  - `gluster-exporter` (Prometheus metrics)
  - `node-exporter` (optional host metrics)

- `.env.example`  
  Copy to `.env` per node and customize.

- `bootstrap/bootstrap.sh`  
  Idempotent bootstrap: probes peers and creates/starts a volume if it does not exist.

- `metrics/gluster-exporter/`  
  Builds the `gluster-exporter` from the upstream `gluster-prometheus` repo.

## Prerequisites

- Linux host with Docker Engine + Docker Compose v2
- Storage mounted on the host for bricks (recommended: separate disks/partitions)
- **Time synchronization on every node** (chronyd/ntpd). If node clocks drift, you will suffer.

## Quick start (per host)

### 1) Create host directories

Create the host paths you specify in `.env`:

```bash
sudo mkdir -p /srv/gluster/etc-glusterfs
sudo mkdir -p /srv/gluster/var-lib-glusterd
sudo mkdir -p /srv/gluster/var-log-glusterfs
sudo mkdir -p /srv/gluster/bricks
```

If SELinux is enabled, the compose uses `:z` labeling for shared volumes.

### 2) Configure `.env`

```bash
cp .env.example .env
nano .env
```

Set at minimum:

- `NODE_NAME` (unique per host)
- `GLUSTER_*_DIR` paths
- `GLUSTER_BRICKS_DIR` (your brick storage mount)

### 3) Start the Gluster peer

```bash
docker compose up -d
docker compose ps
```

### 4) Bootstrap the cluster (only on the first node)

On the first node only, set the bootstrap variables in `.env`:

- `GLUSTER_PEERS`
- `GLUSTER_VOLUME_NAME`
- `GLUSTER_VOLUME_TYPE`
- `GLUSTER_REPLICA_COUNT`
- `GLUSTER_BRICKS`

Then run:

```bash
chmod +x bootstrap/bootstrap.sh
docker compose --profile bootstrap up --abort-on-container-exit
```

Re-running bootstrap is safe; it exits if the volume already exists.

### 5) Enable metrics (optional)

```bash
docker compose --profile metrics up -d
```

Endpoints:

- Gluster exporter: `http://<node-ip>:9713/metrics`
- Node exporter: `http://<node-ip>:9100/metrics`

## Firewall and ports (host networking)

Because the services use `network_mode: host`, you must allow Gluster ports on the **host firewall**.

At a minimum, plan for:
- Gluster management ports (commonly `24007`, `24008`)
- Brick ports (Gluster allocates a range depending on config)

Exact port requirements depend on your Gluster version/config; lock this down explicitly for your environment.

## Secrets handling

This stack does not embed secrets in Compose. Treat `.env` as sensitive.

If you add features that require credentials (e.g., NFS-Ganesha, TLS, object gateways), use:
- Docker secrets (Swarm/compose-compatible patterns), or
- Host-provisioned files with strict permissions, mounted read-only.

Do not paste credentials into `docker-compose.yml`.

## Operational checks

Peer status:

```bash
docker exec -it ${NODE_NAME} gluster peer status
```

Volume status:

```bash
docker exec -it ${NODE_NAME} gluster volume status
docker exec -it ${NODE_NAME} gluster volume info
```

## Troubleshooting

- **Healthcheck failing:** confirm `glusterd` is running in the container and `gluster` CLI exists.
- **Peers not connecting:** verify DNS/IP reachability between hosts and firewall rules.
- **SELinux denial:** verify the `:z` labels are applied and check audit logs.
- **Performance issues:** confirm bricks are on real disks, not overlay storage; check MTU and NIC offloads.

## What you should do next (if you’re serious)

- Document your **volume topology** (replica/disperse counts, brick mapping to disks).
- Add backup/restore strategy for metadata and configuration.
- Add alerting rules for exporter metrics (split-brain indicators, heal backlog, brick down, etc.).
- Pin image tags (avoid `:latest`) for repeatable deployments.
