# Poste.io (PosteIO) Docker Compose

This repository contains a production-oriented Docker Compose setup for **Poste.io** (all‑in‑one mail server), based on the Poste.io container image (`analogic/poste.io`).

It includes:
- Recommended **host-network** deployment for Linux
- Optional **bridge-mode** profile (only if you cannot use host networking)
- Persistent storage (`./data`) for mail, config, certificates, logs
- Healthchecks, log rotation, ulimits
- Optional **Elasticsearch** integration (profile `elastic`)
- Optional **Prometheus + Blackbox Exporter** availability probes (profile `monitoring`)

## 1) Hard prerequisites (do not skip)

If any of the items below are missing, expect major issues (delivery failures, rejection, blacklisting, or time-wasting troubleshooting):

- Static public IPv4 (IPv6 recommended but not enough)
- Provider allows **inbound and outbound TCP/25**
- You control **rDNS/PTR** for the server’s public IP and it matches your mail hostname
- Proper DNS for:
  - `MX` record
  - `A/AAAA` records for your mail hostname
  - SPF
  - DKIM (generated in Poste UI)
  - DMARC

If you don’t have rDNS control, your outbound mail deliverability will be poor or non-existent.

## 2) Files

- `docker-compose.yml` — main compose file (host mode default)
- `.env.example` — copy to `.env` and adjust values
- `configs/blackbox.yml` — blackbox exporter modules (optional)
- `configs/prometheus.yml` — Prometheus config (optional)

## 3) Quick start (recommended: host networking)

### 3.1 Prepare

```bash
cp .env.example .env
mkdir -p data
```

Edit `.env`:
- Set `POSTE_HOSTNAME=mail.example.com`
- Keep `POSTE_DATA_DIR=./data` unless you want an absolute host path

### 3.2 Start

```bash
docker compose up -d
docker compose ps
docker logs -f poste
```

### 3.3 Access the admin UI

Open:

- `https://mail.example.com/admin`

Poste.io will guide you through initial setup.

## 4) Bridge-mode (not recommended)

Bridge mode is provided under a profile for environments where host networking is impossible.

Start it with:

```bash
docker compose --profile bridge up -d
```

If you terminate TLS in a reverse proxy, set:

```bash
POSTE_HTTPS_REDIRECT_MODE=OFF
```

And ensure your reverse proxy forwards correct headers and does not break ACME HTTP challenges.

## 5) Ports you must allow (host mode)

At minimum, typical Poste deployments expose:

- 25 (SMTP)
- 80 (HTTP)
- 443 (HTTPS)
- 587 (Submission)
- 993 (IMAPS)

Common extras:

- 110/995 (POP3/POP3S)
- 143 (IMAP)
- 465 (SMTPS legacy)
- 4190 (Sieve)

Make sure host firewall and cloud security groups allow what you intend.

## 6) Optional: Elasticsearch integration

Enable the Elasticsearch service:

```bash
docker compose --profile elastic up -d
```

Then set in `.env`:

```bash
POSTE_ELASTICSEARCH=elasticsearch:9200
```

This offloads certain search/log features from the container to Elasticsearch.

## 7) Optional: Monitoring (Prometheus + Blackbox)

This setup provides **availability checks** (HTTP/TCP probes). It is not deep mail system telemetry.

Enable:

```bash
docker compose --profile monitoring up -d
```

Prometheus will be available at:

- `http://<host>:9090`

Blackbox exporter uses host networking to probe the host-network Poste instance locally.

## 8) Backups (what actually matters)

Back up the entire `./data` directory. That is your system of record (mailboxes, config, certs, keys).

Example (offline tarball):

```bash
tar -czf poste-data-$(date +%F).tar.gz data/
```

Store backups off-host.

## 9) Upgrades

```bash
docker compose pull
docker compose up -d
docker image prune -f
```

If you are running a production mail system, test upgrades in a staging environment first.

## 10) Common failure modes you should expect (and prevent)

- No rDNS: outbound mail rejected or spam-foldered.
- Port 25 blocked: you cannot reliably send mail.
- Wrong DNS / missing SPF/DKIM/DMARC: spam classification and rejection.
- Putting Poste behind a generic reverse proxy without understanding mail protocols: broken ACME, redirects, or client auth issues.
- Not backing up `./data`: you will lose mail and keys, full stop.

---

## Commands reference

Start (host mode):

```bash
docker compose up -d
```

Stop:

```bash
docker compose down
```

View logs:

```bash
docker logs -f poste
```

Health status:

```bash
docker inspect --format='{{json .State.Health}}' poste | jq
```
