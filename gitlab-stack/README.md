# GitLab (Self-Managed) Docker Compose Stack

This repository contains a production-leaning Docker Compose stack for **GitLab (Omnibus)** with:
- External **Postgres** and **Redis**
- Docker Compose **secrets** (file-mounted) for passwords
- Dedicated Docker **network** with fixed subnet/IPs (useful for metrics allowlists)
- Persistent **volumes** for all state
- Healthchecks
- Optional **monitoring profile** (Prometheus + Grafana + Redis/Postgres exporters)

## What this is (and what it is not)

- This stack is designed for **self-managed GitLab** (Community Edition by default).
- If you meant **Gitea** (you wrote “gitab”), this stack is the wrong choice; GitLab is significantly heavier.

## Prerequisites

- Docker Engine + Docker Compose v2+
- A DNS record (or /etc/hosts entry) for the hostname you choose, e.g. `gitlab.example.com`
- Sufficient resources (GitLab is not lightweight; plan accordingly)

## Quickstart

### 1) Configure environment

```bash
cp .env.example .env
# Edit .env to match your hostname, external URL, and ports
```

### 2) Create secrets (required)

```bash
mkdir -p secrets
openssl rand -base64 32 > secrets/gitlab_root_password.txt
openssl rand -base64 32 > secrets/postgres_password.txt
openssl rand -base64 32 > secrets/redis_password.txt
chmod 600 secrets/*.txt
```

### 3) Start GitLab

```bash
docker compose up -d
```

Initial bootstrap can take several minutes.

### 4) Optional monitoring

```bash
docker compose --profile monitoring up -d
```

Prometheus: `http://localhost:${PROMETHEUS_PORT}`
Grafana: `http://localhost:${GRAFANA_PORT}`

## Files

- `compose.yaml` — main Compose stack
- `.env.example` — environment template
- `secrets/` — secret files (NOT included with values; you must create them)
- `postgres/initdb/01-extensions.sql` — initial DB extensions
- `prometheus/prometheus.yml` — Prometheus scrape config for optional monitoring

## Operational notes you should not ignore

1. **Pin GitLab versions**: running `latest` is operational negligence. Pin to a tested GitLab tag and upgrade intentionally.
2. **Backups**: GitLab data is stateful. Use GitLab backup tooling and/or volume snapshots; test restores.
3. **SMTP**: If you want password resets/notifications, configure SMTP in GitLab (Omnibus config). GitLab does not magically send email.
4. **TLS**: This stack configures GitLab to listen on HTTP internally. Terminate TLS at a reverse proxy (recommended) or adjust Omnibus config to enable HTTPS.
5. **Runner**: GitLab Runner is not included. Add it if you need CI.

## Common commands

```bash
# View logs
docker compose logs -f gitlab

# Check health
docker inspect --format='{{json .State.Health}}' gitlab | jq

# Stop
docker compose down

# Stop + delete volumes (DANGEROUS: destroys data)
docker compose down -v
```

## Security posture (baseline)

- Passwords are provided via Docker secrets (file mounts under `/run/secrets`).
- Metrics endpoint is allowlisted to the Docker subnet and localhost (adjust as needed).
- Do not expose Postgres/Redis ports publicly.

## License

Internal / use at your discretion.
