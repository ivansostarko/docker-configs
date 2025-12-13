# Gluster Prometheus Exporter (Docker Compose)

This bundle runs a **Gluster metrics exporter** on a Gluster node and exposes metrics in a Prometheus-friendly format.

## Non-negotiable reality (read this)
Gluster exporters are **not** self-contained. They rely on **node-local Gluster state** (e.g., `/var/lib/glusterd`) and the **Gluster CLI**.
That makes the container **host-coupled** to the Gluster node it runs on. If you need “portable monitoring,” Gluster is not that.

## What you get
- `gluster_metrics_exporter`: Exposes metrics at `http://127.0.0.1:9713/metrics` by default.
- `gluster_exporter_proxy` (optional but enabled here): Exposes metrics externally with **Basic Auth** at `http://<node>:9714/metrics`.

## Folder layout
```text
gluster-exporter/
├─ docker-compose.yml
├─ .env
├─ gluster-metrics-exporter/
│  └─ Dockerfile
├─ config/
│  └─ nginx/
│     └─ nginx.conf
└─ secrets/
   └─ gluster_exporter_htpasswd   # you must create this locally
```

## Prerequisites
- Docker Engine + Docker Compose v2
- Gluster installed and running on the host (this is assumed; the exporter is not a Gluster installer)
- Host has directories:
  - `/var/lib/glusterd`
  - `/etc/glusterfs`
  - `/run/gluster`

## Configure
Edit `.env` if needed.

### Create the Basic Auth secret (required when proxy is enabled)
Create the file locally (do **not** commit it):

```bash
mkdir -p secrets
printf "admin:$(openssl passwd -apr1 'CHANGE_ME_STRONG_PASSWORD')\n" > secrets/gluster_exporter_htpasswd
chmod 600 secrets/gluster_exporter_htpasswd
```

If you want to disable the proxy entirely, remove/comment the `gluster_exporter_proxy` service in `docker-compose.yml` and scrape
`127.0.0.1:9713` from the node itself (not recommended in most real environments).

## Run
```bash
docker compose up -d --build
```

## Validate
Exporter locally:
```bash
curl -fsS http://127.0.0.1:9713/metrics | head
```

Proxy with auth:
```bash
curl -u admin:CHANGE_ME_STRONG_PASSWORD -fsS http://127.0.0.1:9714/metrics | head
```

## Prometheus scrape config example
```yaml
scrape_configs:
  - job_name: gluster
    metrics_path: /metrics
    scheme: http
    basic_auth:
      username: admin
      password: CHANGE_ME_STRONG_PASSWORD
    static_configs:
      - targets:
          - gluster-node-1.example.com:9714
          - gluster-node-2.example.com:9714
          - gluster-node-3.example.com:9714
```

## Security posture (what this does and does not do)
- Exporter binds to **localhost** by default (`GLUSTER_EXPORTER_BIND=127.0.0.1`) so it is not directly exposed.
- Nginx proxy is the only externally reachable endpoint and requires Basic Auth.
- Containers are configured with:
  - `read_only: true`
  - `cap_drop: [ALL]`
  - `no-new-privileges`

### Your biggest risk
If you expose port 9713 publicly, you are leaking operational storage information. Don’t.

## Troubleshooting
- **Healthcheck failing**: confirm Gluster is up and the exporter can read `/var/lib/glusterd` and execute `/usr/sbin/gluster`.
- **Build fails downloading install.sh**: your build environment blocks GitHub. Fix your egress policy or vendor the binary.
- **Duplicate “cluster-level” metrics**: expected if scraping every node. Use labels/recording rules to aggregate.
