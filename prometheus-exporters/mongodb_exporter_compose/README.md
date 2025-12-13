# MongoDB Prometheus Exporter (Docker Compose)

This bundle provides a production-oriented Docker Compose deployment of the **Percona MongoDB Exporter** for Prometheus.

Included:
- `docker-compose.yml` (hardening, logging, healthcheck, labels)
- `.env.example`
- `secrets/` placeholders (mounted as Docker secrets)
- Prometheus scrape snippet
- `mongosh` script to create a least-privilege exporter user

## Directory layout

```text
.
├── docker-compose.yml
├── README.md
├── .env.example
├── secrets
│   ├── mongodb_uri.txt
│   ├── mongodb_user.txt
│   └── mongodb_password.txt
└── config
    ├── prometheus
    │   └── prometheus.scrape.mongodb.yml
    └── mongo
        └── create_exporter_user.js
```

## Quick start

1) Create your `.env`:

```bash
cp .env.example .env
```

2) Populate secrets (do **not** commit these to Git):

- `secrets/mongodb_uri.txt` (no credentials in the URI):

```text
mongodb://mongodb:27017/admin
```

- `secrets/mongodb_user.txt`:

```text
exporter
```

- `secrets/mongodb_password.txt`:

```text
<STRONG_PASSWORD>
```

3) Start:

```bash
docker compose up -d
```

4) Verify exporter output:

```bash
curl -s http://localhost:9216/metrics | head
```

If you changed `MONGODB_EXPORTER_PORT`, adjust the port accordingly.

## MongoDB user (least privilege)

Do not use root/admin credentials for scraping.

Edit `config/mongo/create_exporter_user.js` and set a strong password, then run:

```bash
mongosh --host <mongo-host> -u <admin-user> -p <admin-pass> --authenticationDatabase admin < config/mongo/create_exporter_user.js
```

The script assigns:
- `clusterMonitor` on `admin`
- `read` on `local`

## Prometheus scrape config

Add the job from `config/prometheus/prometheus.scrape.mongodb.yml` to your Prometheus config.

Example:

```yaml
- job_name: "mongodb"
  static_configs:
    - targets: ["mongodb_exporter:9216"]
```

If Prometheus runs on the same Docker network (`monitoring`), using the Compose service name (`mongodb_exporter`) is correct.
If Prometheus runs outside Docker, target the host DNS/IP where the exporter port is published.

## Security posture (what this Compose enforces)

- Credentials are injected via secrets (files), not committed in compose or `.env`.
- Container is hardened:
  - `read_only: true`
  - `no-new-privileges`
  - drops all Linux capabilities
  - uses tmpfs for `/tmp`

## Healthcheck note

The Compose healthcheck uses `wget` to validate the `mongodb_up` metric exists.
If the exporter image does not include `wget`, the healthcheck will fail even if scraping works.

Fix options:
- Remove the `healthcheck:` block, or
- Replace with `curl` if available.

## Troubleshooting

### `mongodb_up 0`
- MongoDB host/port wrong in `secrets/mongodb_uri.txt`
- Network ACL/firewall blocks MongoDB
- Bad credentials in secrets
- User missing required roles

### Prometheus cannot scrape the exporter
- Ensure Prometheus can reach `mongodb_exporter:9216` (same Docker network) or `<host>:9216` (host port publishing)
- Check Prometheus Targets UI for the specific error

## Versioning

Image is pinned: `percona/mongodb_exporter:0.40`.

If you upgrade, validate:
- exporter flags
- metric names/labels
- dashboards and alerts
