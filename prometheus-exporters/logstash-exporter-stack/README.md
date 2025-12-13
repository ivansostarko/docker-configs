# Logstash Prometheus Exporter (Docker Compose)

This stack runs:
- **Logstash** (example workload) with the **Monitoring API** enabled on port `9600` (Docker-internal)
- **wing924/logstash-exporter** exposing Prometheus metrics on port `9649`

## Why this design (and what not to do)

- **Do not expose Logstash’s Monitoring API (9600) publicly.** It is often unsecured by default and is meant to be internal.
- Export **metrics** via the exporter (`9649`) instead.

If you enable authentication/TLS on the Logstash API, validate that your exporter supports it first. Many do not.

---

## Quick start

1. Copy `.env.example` to `.env` and edit values:
   ```bash
   cp .env.example .env
   ```

2. Start services:
   ```bash
   docker compose up -d
   ```

3. Verify exporter metrics:
   ```bash
   curl -fsS http://localhost:9649/metrics | head
   ```

4. Add the Prometheus scrape job:
   - Merge `prometheus/prometheus.scrape.job.yml` into your Prometheus `prometheus.yml`,
   - or include it via your existing Prometheus configuration management.

---

## Files

- `docker-compose.yml` – Logstash + exporter with healthchecks, hardened exporter container, persistent volume.
- `.env.example` – required variables (copy to `.env`).
- `logstash/config/logstash.yml` – minimal config (pipeline + log level).
- `logstash/pipeline/logstash.conf` – example pipeline (Beats input on 5044).
- `prometheus/prometheus.scrape.job.yml` – Prometheus scrape job for the exporter.

---

## Ports

- `5044/tcp` – optional Logstash Beats input (published)
- `9600/tcp` – Logstash Monitoring API (**NOT published**, internal only)
- `9649/tcp` – exporter `/metrics` endpoint (published)

---

## Metrics (what to sanity-check)

At minimum you should see:
- `logstash_up` – exporter connectivity/health (should be `1`)
- JVM and process metrics (heap, GC, etc.)
- Pipeline/event counters (throughput, queue stats if enabled)

If `logstash_up` is missing or `0`, treat your monitoring as broken, not “fine.”

---

## Hardening checklist (recommended)

1. Keep `9600` internal-only (current compose does this).
2. If you must expose metrics beyond localhost, put the exporter behind:
   - reverse proxy auth (basic auth / mTLS), or
   - network policy / firewall rules.
3. Pin images (avoid `latest`) for repeatable rollouts.
4. Monitor for restarts and scrape failures in Prometheus.

---

## Troubleshooting

### Exporter is up but `logstash_up` is 0
- Confirm Logstash healthcheck is passing:
  ```bash
  docker ps --format "table {{.Names}}\t{{.Status}}"
  ```
- From inside exporter container, test connectivity:
  ```bash
  docker exec -it logstash_exporter sh -lc 'wget -qO- http://logstash:9600/ | head'
  ```
- Confirm `.env` has:
  - `LOGSTASH_SCRAPE_URI=http://logstash:9600`

### Logstash won’t start (memory issues)
- Increase heap:
  - set `LOGSTASH_HEAP=2g` (or more) in `.env`

### Healthcheck failing early
- Increase `start_period` in `docker-compose.yml` for slower hosts.

---

## Notes for external Logstash targets

If Logstash runs outside this Compose:
- Remove or disable the `logstash` service,
- Set `LOGSTASH_SCRAPE_URI=http://<your-logstash-host>:9600`
- Ensure network access from exporter to Logstash API.
