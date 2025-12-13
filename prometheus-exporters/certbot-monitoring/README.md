# Certbot + Prometheus Exporter (Certificate Expiry Monitoring)

This stack runs:
- **Certbot** in a safe “renew loop” (it periodically runs `certbot renew`).
- **ssl_exporter** configured to **read Certbot certificate files** from `/etc/letsencrypt/live/**/fullchain.pem` and expose Prometheus metrics.

## Why this exists (no fluff)

Certbot does **not** expose Prometheus metrics. Monitoring is done by reading certificate files and exposing their **expiry timestamps** as metrics. If you only monitor Certbot logs, you will miss the most common failure mode: certificates renew, but your reverse proxy never reloads and continues serving the old certificate.

## Contents

```text
certbot-monitoring/
├─ docker-compose.yml
├─ .env
├─ config/
│  └─ ssl_exporter/
│     └─ ssl_exporter.yml
├─ scripts/
│  ├─ certbot-renew.sh
│  └─ deploy-hook.sh
└─ secrets/
   └─ cloudflare.ini   # optional (DNS-01); do not commit real tokens
```

## Quick start

1. Review and edit `.env` as needed.
2. (Optional DNS-01) Put real credentials in `secrets/cloudflare.ini` and lock permissions:
   ```bash
   chmod 600 secrets/cloudflare.ini
   ```
3. Start the stack:
   ```bash
   docker compose up -d
   ```

### Important: initial certificate issuance

This compose file covers **renewal**. You still need to issue the initial certificate at least once (otherwise there are no cert files to monitor).

Typical patterns:
- **HTTP-01 (webroot)**: mount `certbot_webroot` into your reverse proxy and serve `/.well-known/acme-challenge/` from it.
- **DNS-01**: use the relevant DNS plugin and credentials (example provided for Cloudflare).

After initial issuance, Certbot stores renewal config and `certbot renew` will manage future renewals.

## Prometheus scraping

### Scrape cert file expiries (this stack)

Because `ssl_exporter.yml` sets the `target:` inside the module, you can scrape `/probe` directly:

```yaml
scrape_configs:
  - job_name: "certbot-certs"
    metrics_path: /probe
    static_configs:
      - targets: ["ssl_exporter:9219"]
```

## Key metrics you will get

- `ssl_file_cert_not_after` — certificate "Not After" timestamp (Unix epoch)
- `ssl_file_cert_not_before` — certificate "Not Before" timestamp (Unix epoch)
- `ssl_probe_success` — whether probing succeeded

## PromQL examples

Expiring within 7 days:
```promql
ssl_file_cert_not_after - time() < 86400 * 7
```

Probe failures:
```promql
ssl_probe_success == 0
```

## Operational hard truths (do not ignore)

1. **Renewed certs are useless until your proxy reloads.** Implement `scripts/deploy-hook.sh` to reload your webserver or trigger your proxy to re-read certs.
2. **Do not mount Docker socket** into Certbot unless you have a compelling reason and understand the risk. It turns this into a host-control container.
3. For “renewal succeeded/failed” counters, add a separate log-to-metrics component (mtail/vector/grok exporter). Expiry monitoring alone is necessary but not sufficient.

## Security posture

- `ssl_exporter` is `read_only: true`, has `no-new-privileges`, and drops all Linux capabilities.
- Certbot drops all capabilities and uses `no-new-privileges`, but must write to its certificate volumes.

## Troubleshooting

- `certbot` healthcheck stays unhealthy:
  - That’s expected until at least one cert exists under `/etc/letsencrypt/live/**/fullchain.pem`.
- `ssl_exporter` has no cert metrics:
  - Confirm the certificates exist inside the volume:
    ```bash
    docker exec -it certbot sh -lc 'find /etc/letsencrypt/live -name fullchain.pem -maxdepth 3 -print'
    ```

## License

Use at your own risk. This repo provides infrastructure scaffolding, not a compliance guarantee.
