# Elasticsearch (single-node) + TLS + Prometheus Exporter (Docker Compose)

This repo contains a production-leaning **single-node** Elasticsearch setup with:

- Persistent storage (`esdata`)
- Auto-generated **TLS certificates** (HTTPS for HTTP, TLS for transport) via a one-time init service (`es-certs`)
- Security enabled (`xpack.security.enabled=true`) with the `elastic` password provided via **Docker secrets**
- Healthcheck that validates HTTPS + auth
- Prometheus metrics via `prometheuscommunity/elasticsearch-exporter` exposed on `:9114`
- Dedicated bridge network (`elastic`)

## Contents

```text
.
├─ docker-compose.yml
├─ .env
├─ config/
│  ├─ elasticsearch.yml
│  └─ instances.yml
└─ secrets/
   └─ elastic_password.txt
```

## Prerequisites

- Docker Engine + Docker Compose v2
- **Linux hosts:** Elasticsearch requires:

```bash
sudo sysctl -w vm.max_map_count=262144
```

To make it persistent (recommended), add to `/etc/sysctl.conf` or a drop-in:

```bash
echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.d/99-elasticsearch.conf
sudo sysctl --system
```

## Quick start

1) Set the `elastic` superuser password:

- Edit `./secrets/elastic_password.txt` and replace the placeholder with a strong password (single line).

2) Optionally tune JVM heap in `.env`:

- Keep `-Xms` equal to `-Xmx`
- Do not exceed ~50% of system RAM (leave headroom for OS page cache)

3) Start the stack:

```bash
docker compose up -d
```

4) Validate health:

```bash
docker compose ps
docker logs es01 --tail=200
```

5) Test HTTPS + authentication from host:

```bash
PASS="$(cat ./secrets/elastic_password.txt)"
CA="$(docker run --rm -v escerts:/certs alpine:3.20 cat /certs/ca/ca.crt)"
printf "%s" "$CA" > /tmp/es-ca.crt

curl -sS --cacert /tmp/es-ca.crt -u "elastic:${PASS}" https://localhost:9200
curl -sS --cacert /tmp/es-ca.crt -u "elastic:${PASS}" https://localhost:9200/_cluster/health?pretty
```

## Metrics (Prometheus)

Exporter is exposed on:

- `http://localhost:9114/metrics` (or `ES_EXPORTER_PORT` from `.env`)

Example Prometheus scrape config:

```yaml
scrape_configs:
  - job_name: "elasticsearch"
    static_configs:
      - targets: ["localhost:9114"]
```

## Security notes (what not to do)

- Do **not** put the `elastic` password into environment variables. It leaks via `docker inspect`.
- Treat the `escerts` volume as sensitive; it contains the CA key and node private key material.
- If you expose `9200` beyond localhost, put a reverse proxy with strict ACLs in front, or restrict with firewall rules.

## Operational guidance

### Upgrade Elasticsearch

1) Update `ELASTIC_VERSION` in `.env` to the desired version.
2) Read Elastic’s breaking changes for that target version.
3) Restart:

```bash
docker compose pull
docker compose up -d
```

### Backups (Snapshots)

This compose does **not** configure a snapshot repository by default, because the correct target is environment-specific
(S3, GCS, NFS, etc.). If you tell me your target repository type, I’ll add the cleanest implementation.

### Reset certificates

If you need to regenerate certs (e.g., changed hostnames), you must remove the `escerts` volume:

```bash
docker compose down
docker volume rm escerts
docker compose up -d
```

### Troubleshooting

- `vm.max_map_count` too low (Linux): container may exit or log bootstrap checks failures.
- Heap too small: GC thrash, instability, slow queries. Increase `ES_JAVA_OPTS`.
- Permission issues on certs: remove `escerts` volume and restart (see reset certificates).
- Healthcheck failing: verify `elastic_password.txt` has no trailing spaces/newlines beyond the single line.

## Ports

- Elasticsearch HTTPS: `9200` (mapped from `ES_HTTP_PORT`)
- Exporter metrics: `9114` (mapped from `ES_EXPORTER_PORT`)

## License

Use/adapt freely for internal deployments. You are responsible for compliance with Elastic licensing in your environment.
