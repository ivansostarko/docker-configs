# HAProxy Docker Compose (Production-leaning)

This stack gives you:
- HAProxy reverse proxy/load balancer
- Built-in health endpoint
- Stats UI (basic auth)
- Prometheus metrics endpoint (built-in exporter)
- Optional Prometheus + Grafana via Compose profiles

## What you actually get (ports)

- **HTTP**: `:${HAPROXY_HTTP_PORT:-8080}` -> HAProxy `:80`
- **Health**: `:${HAPROXY_HEALTH_PORT:-8406}/healthz` -> HAProxy `:8406` (no auth)
- **Metrics**: `:${HAPROXY_METRICS_PORT:-8404}/metrics` -> HAProxy `:8404` (Prometheus format)
- **Stats UI**: `:${HAPROXY_STATS_PORT:-8405}/stats` -> HAProxy `:8405` (basic auth)

## Files

- `docker-compose.yml` – full stack (HAProxy + demo upstreams + optional observability)
- `haproxy/haproxy.cfg.tmpl` – HAProxy config template (rendered at container start)
- `haproxy/docker-entrypoint.sh` – renders config + validates it
- `haproxy/Dockerfile` – extends official HAProxy image with minimal ops tooling
- `prometheus/prometheus.yml` – scrapes HAProxy metrics
- `grafana/provisioning/*` – auto-provisions Prometheus datasource and a minimal dashboard

## 1) Secrets (do this first)

Create the secrets directory contents:

```bash
cp .env.example .env

# Strong password for stats UI + Grafana admin (shared in this example)
mkdir -p secrets
# Optional: start from the example file
# cp secrets/haproxy_stats_password.txt.example secrets/haproxy_stats_password.txt
openssl rand -base64 32 > secrets/haproxy_stats_password.txt

# OPTIONAL TLS (PEM bundle = cert + key). If you don't need TLS, ignore this file.
# cat fullchain.pem privkey.pem > secrets/haproxy_tls.pem
```

If you do **not** create `secrets/haproxy_tls.pem`, Compose will still work; the TLS section is commented out in the config.

## 2) Start the base stack

```bash
docker compose up -d --build
```

Validate:

```bash
curl -fsS http://localhost:${HAPROXY_HEALTH_PORT:-8406}/healthz
curl -fsS http://localhost:${HAPROXY_METRICS_PORT:-8404}/metrics | head
curl -fsS http://localhost:${HAPROXY_HTTP_PORT:-8080}
```

Stats UI:
- Open `http://localhost:${HAPROXY_STATS_PORT:-8405}/stats`
- Username: `${HAPROXY_STATS_USER:-admin}`
- Password: from `secrets/haproxy_stats_password.txt`

## 3) Optional: bring up Prometheus + Grafana

```bash
docker compose --profile observability up -d
```

- Prometheus: `http://localhost:${PROMETHEUS_PORT:-9090}`
- Grafana: `http://localhost:${GRAFANA_PORT:-3000}`

Grafana credentials:
- user: `${GRAFANA_ADMIN_USER:-admin}`
- password: `secrets/haproxy_stats_password.txt` (same secret in this reference setup)

## 4) Replace the demo upstreams with your real services

Right now, `haproxy.cfg.tmpl` points to `whoami1` and `whoami2` for a deterministic test.

In real use you will do one of these:

### Option A — Keep everything in this compose
- Add your app containers to `docker-compose.yml`
- Put them on the `app` network
- Replace `server whoami1 ...` lines with your real service names/ports

### Option B — HAProxy in its own compose (recommended for modular stacks)
- Attach HAProxy to an **external** Docker network shared with other stacks.
- Example:

```yaml
networks:
  app:
    external: true
    name: shared_app_net
```

Then connect your app services to `shared_app_net` and reference them by container name or service DNS.

## 5) Hard truths (operational)

- **You don’t have “production” because you wrote a compose file.** You have a dev-friendly deployment descriptor.
- If you want production, add: host firewalling, automated backups for Grafana/Prometheus (if you care), log shipping, TLS lifecycle (ACME), and real alerting.
- Exposing `:8405` and `:8404` publicly is a common mistake. Put them behind VPN, bind to localhost only, or restrict via firewall.

## Troubleshooting

Check HAProxy config rendering:

```bash
docker logs ${COMPOSE_PROJECT_NAME:-haproxy_stack}_haproxy
```

Check admin socket:

```bash
docker exec -it ${COMPOSE_PROJECT_NAME:-haproxy_stack}_haproxy \
  sh -lc "echo 'show info' | socat stdio /var/run/haproxy/admin.sock"
```
