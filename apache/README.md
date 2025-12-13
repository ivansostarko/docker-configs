# Apache + Prometheus Exporter (Docker Compose)

This bundle provides a hardened Apache HTTPD container plus Prometheus metrics via **apache_exporter**.

## What you get

- Apache HTTPD serving content on **http://localhost:${APACHE_HTTP_PORT}/**
- A simple health endpoint: **/healthz.html**
- `mod_status` enabled **only on an internal port** (default **8081**) and **not published to the host**
- `apache_exporter` scraping `mod_status` and exposing Prometheus metrics on **:${APACHE_EXPORTER_PORT}/metrics**

## Why the design is strict (do not “simplify” it)

The single most common misconfiguration is exposing `/server-status` publicly.  
This bundle keeps the status vhost on an internal-only port so it is reachable only from containers on the Docker network.

## Files

```
apache-stack/
  docker-compose.yml
  .env
  apache/
    www/
      index.html
      healthz.html
    conf/
      httpd.conf
      vhosts.conf
      status-vhost.conf
  exporter/
    web-config.yml
  secrets/
    exporter_basic_auth_password.txt
```

## Quick start

```bash
cd apache-stack
docker compose up -d
```

### Verify Apache

```bash
curl -i http://localhost:${APACHE_HTTP_PORT}/
curl -i http://localhost:${APACHE_HTTP_PORT}/healthz.html
```

Expected:
- `200 OK` for both
- `OK` body for `/healthz.html`

### Verify exporter

```bash
curl -i http://localhost:${APACHE_EXPORTER_PORT}/metrics
```

If you keep exporter auth enabled, you will need to provide basic auth. The sample `exporter/web-config.yml` is a template and may require you to wire the password into the exporter config. The robust pattern is to have Prometheus scrape with `basic_auth` and `password_file`.

## Prometheus scrape config (example)

If Prometheus runs on the same Docker network:

```yaml
scrape_configs:
  - job_name: "apache"
    static_configs:
      - targets: ["apache_exporter:9117"]
    basic_auth:
      username: "prometheus"
      password_file: "/run/secrets/exporter_basic_auth_password"
```

If Prometheus runs outside Docker, scrape `localhost:${APACHE_EXPORTER_PORT}`.

## Environment variables

Edit `.env`:

- `APACHE_HTTP_PORT`: host port mapped to container port 80
- `APACHE_STATUS_PORT_INTERNAL`: internal-only port used for `mod_status` (not published)
- `APACHE_EXPORTER_PORT`: host port mapped to exporter 9117

## Secrets

`./secrets/exporter_basic_auth_password.txt` contains a generated password:
- **79of12m6fk23_mmFK8zQ_Hrf2V97iIEicUsYo3rQSaY**

Change it before committing anything.

## Metrics

Typical metrics exposed by `apache_exporter` include counters and gauges such as:

- `apache_up`
- `apache_accesses_total`
- `apache_sent_kilobytes_total`
- `apache_cpu_load`
- `apache_workers`

Exact names depend on exporter version and Apache `mod_status` output.

## Operational notes

- Do not publish port `8081` (or whatever you set as `APACHE_STATUS_PORT_INTERNAL`). It exists solely for the exporter to scrape.
- Pin image versions in real environments (avoid `:latest`).
- If you need TLS, put a reverse proxy (Traefik/Caddy/Nginx) in front of Apache; do not terminate TLS inside the Apache container unless you have a strong operational reason.

## Troubleshooting

### Apache won’t start
Run config test:

```bash
docker compose logs apache --tail=200
docker compose exec apache httpd -t
```

### Exporter shows `apache_up 0`
- Confirm Apache is healthy: `docker compose ps`
- Confirm the scrape URI is reachable from exporter:
  - The exporter scrapes: `http://apache:${APACHE_STATUS_PORT_INTERNAL}/server-status?auto`
- Confirm `status-vhost.conf` is mounted and included in `httpd.conf`

---

## License / usage

Use freely in internal infrastructure. Review security posture before exposing anything to the internet.
