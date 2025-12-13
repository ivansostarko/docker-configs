# Apache Prometheus Exporter (Docker Compose)

This stack runs:

- **Apache httpd** with `mod_status` enabled and a **locked down** `/server-status?auto` endpoint.
- **apache_exporter** scraping Apache status and exposing Prometheus metrics at `/metrics`.

## Why this design

The exporter is not magic: it only works if Apache exposes the machine-readable status endpoint:

- `http://<apache>/server-status?auto`

If you skip `mod_status` or expose the wrong endpoint, you will get `apache_up 0` or no meaningful metrics.

Security note: `/server-status` leaks operational details. This stack **restricts** it to the exporter container IP on a dedicated monitoring network.

---

## Directory layout

```
apache-exporter-stack/
├─ docker-compose.yml
├─ .env
├─ apache/
│  ├─ Dockerfile
│  └─ conf/extra/httpd-info.conf
├─ apache_exporter/
│  └─ web.yml
└─ secrets/
   └─ exporter_users.yml
```

---

## Quick start

From the folder containing `docker-compose.yml`:

```bash
docker compose up -d --build
```

Verify:

- Apache: `http://localhost:${APACHE_HTTP_PORT}/`
- Exporter metrics: `http://localhost:${APACHE_EXPORTER_PORT}/metrics`

---

## Configuration

### `.env`

Key variables:

- `APACHE_HTTP_PORT` – Host port mapped to Apache port 80
- `APACHE_EXPORTER_PORT` – Host port mapped to exporter port 9117
- `MONITORING_SUBNET` – Subnet for the monitoring network
- `APACHE_IP`, `EXPORTER_IP` – Static IPs used for least-privilege allowlisting

Important: if you change `EXPORTER_IP`, update `apache/conf/extra/httpd-info.conf` accordingly.

### Apache `mod_status` hardening

`apache/conf/extra/httpd-info.conf` enables `ExtendedStatus On` and exposes:

- `/server-status?auto`

It restricts access:

```apache
Require ip 172.20.0.10
```

That IP matches `EXPORTER_IP` in `.env`.

### Exporter hardening (optional)

The exporter supports `--web.config.file=/etc/apache_exporter/web.yml`, which can enable basic auth/TLS for `/metrics`.

This repository includes:

- `apache_exporter/web.yml`
- `secrets/exporter_users.yml`

They are **examples**. You must replace the bcrypt hash.

Generate a bcrypt hash (example):

```bash
htpasswd -nBC 10 "" | tr -d ':
'
```

Then set:

```yaml
basic_auth_users:
  prometheus: "$2y$10$YOUR_HASH_HERE..."
```

If you do not want auth on `/metrics`:

1. Remove the `--web.config.file` flag from `docker-compose.yml`
2. Remove the `secrets:` section from the exporter service
3. Remove the volume mount for `web.yml`

---

## Prometheus scrape config

If Prometheus is on the same Docker network, you can scrape by service name:

```yaml
scrape_configs:
  - job_name: "apache"
    static_configs:
      - targets: ["apache_exporter:9117"]
    metrics_path: /metrics
    # If you enabled exporter basic auth:
    # basic_auth:
    #   username: prometheus
    #   password: "CLEAR_TEXT_PASSWORD"  # prefer secret management where available
```

---

## Metrics you should see

At minimum:

- `apache_up`
- `apache_accesses_total`
- `apache_sent_kilobytes_total`
- `apache_cpu_load`
- `apache_workers`
- `apache_scoreboard`
- `apache_uptime_seconds_total`

If `apache_up` is missing or stuck at 0, your Apache status endpoint is not reachable from the exporter.

---

## Troubleshooting

### 1) Exporter is up, but `apache_up 0`

Common causes:

- `mod_status` not enabled (you removed the Dockerfile changes or use a different image)
- `/server-status` blocked (IP allowlist mismatch)
- Wrong scrape URI (must include `?auto`)

Check from inside the exporter container:

```bash
docker exec -it apache_exporter sh
wget -qO- http://apache:80/server-status?auto
```

If that fails, fix connectivity/access first.

### 2) `/server-status` is reachable from your laptop

That means you accidentally exposed it. Re-check:

- Apache is not publishing `/server-status` separately
- The `<Location "/server-status">` stanza includes `Require ip <EXPORTER_IP>`

### 3) Healthchecks failing

- Apache healthcheck runs `httpd -t` (config syntax).
- Exporter healthcheck checks for an `apache_up` metric.

If Apache healthcheck fails, the container logs will show config errors:

```bash
docker logs apache
```

---

## Operational notes (don’t ignore)

- Pin exporter versions; do not use `:latest` for monitoring components.
- Restrict `/server-status` to the exporter only; treat it as sensitive.
- Prefer terminating TLS upstream (ingress/reverse proxy) and keep internal monitoring traffic private.

---

## License

This is an example stack. Adapt to your environment and security requirements.
