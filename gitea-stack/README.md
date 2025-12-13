# Gitea Docker Compose Stack (Production-Leaning)

This repository contains a complete Docker Compose deployment for **Gitea** with:
- **PostgreSQL** backend (recommended for serious use)
- Docker **secrets** for DB password, admin password, and metrics token
- **Healthchecks** for both DB and Gitea
- Optional **Prometheus + Grafana** (Compose profile: `observability`)
- Optional **Gitea Actions runner** (Compose profile: `actions`)

If you expose this to the internet without TLS + a reverse proxy and without backups, that is not “minimal”; it is negligent.

---

## 1) Prerequisites

- Docker Engine + Docker Compose v2
- A DNS name for Gitea (if you plan to expose it)
- Optional: a reverse proxy (Traefik/Nginx/Caddy) providing TLS

---

## 2) Files and folders

```
.
├─ compose.yaml
├─ .env
├─ gitea/
│  └─ conf/
│     └─ app.ini
├─ prometheus/
│  └─ prometheus.yml
├─ scripts/
│  ├─ gitea-entrypoint-with-secrets.sh
│  └─ gitea-init-admin.sh
└─ secrets/
   ├─ postgres_password.txt
   ├─ gitea_admin_password.txt
   ├─ gitea_metrics_token.txt
   └─ gitea_runner_token.txt        # optional (only if you enable Actions runner)
```

---

## 3) Configure environment

Edit `.env` and set (at minimum):

- `GITEA_DOMAIN`
- `GITEA_ROOT_URL` (must be the external URL users will access, usually https)
- `GITEA_SSH_DOMAIN`
- `GITEA_HTTP_PORT` and `GITEA_SSH_PORT`

If you are behind a reverse proxy, ensure `GITEA_ROOT_URL` is **https** and matches the proxy public URL.

---

## 4) Create secrets

The stack expects 3 required secrets, plus an optional runner token.

### Linux/macOS

```bash
cd gitea-stack

mkdir -p secrets
openssl rand -base64 32 > secrets/postgres_password.txt
openssl rand -base64 24 > secrets/gitea_admin_password.txt
openssl rand -hex 32 > secrets/gitea_metrics_token.txt

chmod -R go-rwx secrets
```

### Actions runner token (optional)

If you plan to run Actions, create a runner registration token in the Gitea UI and save it:

```bash
echo "PASTE_RUNNER_TOKEN_HERE" > secrets/gitea_runner_token.txt
chmod go-rwx secrets/gitea_runner_token.txt
```

---

## 5) Start the stack

### Core stack

```bash
docker compose up -d
```

### With Prometheus + Grafana

```bash
docker compose --profile observability up -d
```

- Prometheus: `http://localhost:${PROMETHEUS_PORT}`
- Grafana: `http://localhost:${GRAFANA_PORT}`

### With Actions runner

```bash
docker compose --profile actions up -d
```

### With both profiles enabled

```bash
docker compose --profile observability --profile actions up -d
```

---

## 6) First login and admin bootstrap

This stack includes a one-shot container `gitea-init-admin` that runs after Gitea is healthy and creates an admin user from:
- `GITEA_ADMIN_USER`
- `GITEA_ADMIN_EMAIL`
- `secrets/gitea_admin_password.txt`

If the user already exists, it safely exits.

---

## 7) Security posture you should not ignore

### Reverse proxy + TLS (recommended)
You should not expose port 3000 directly on the internet. Put a reverse proxy in front and terminate TLS there.

### Registration and anonymous access
Defaults are conservative:
- `GITEA_DISABLE_REGISTRATION=true`
- `GITEA_REQUIRE_SIGNIN_VIEW=true`

If you turn these off, you are opting into additional abuse and credential-stuffing risk.

### Actions runner and docker.sock
If you enable the runner **and** mount `/var/run/docker.sock`, workflows can control the host Docker daemon.
That is effectively host-level privilege. Do not do this in an untrusted environment.

If you need safer isolation, use a dedicated VM for runners, or a DinD strategy with strict constraints.

---

## 8) Backups (do this, or accept data loss)

You must back up:
- PostgreSQL database (`postgres_data` volume)
- Gitea data (`gitea_data` volume)

A practical approach:
- Nightly `pg_dump` (or physical volume snapshot)
- File-level backup of `/data` (repos, LFS objects, attachments, etc.)

If you want this automated inside Compose, add a `restic` or `borg` backup service and store backups off-host.

---

## 9) Troubleshooting

### Check container health
```bash
docker compose ps
docker compose logs -f gitea
docker compose logs -f gitea-db
```

### Verify health endpoint
```bash
curl -fsS http://localhost:${GITEA_HTTP_PORT}/api/healthz
```

### Confirm clone URL correctness
If clone URLs are wrong, your `GITEA_ROOT_URL` and `GITEA_DOMAIN` are wrong. Fix `.env`, then restart:

```bash
docker compose up -d --force-recreate gitea
```

---

## 10) What you may want to add next (sensible upgrades)

- Reverse proxy (Traefik/Nginx) + TLS + HSTS
- SMTP configuration for notifications
- Object storage for attachments/LFS (S3-compatible) if you scale
- Automated backups (restic/borg) + alerting on failure
- SSO (OIDC) integration for enterprise usage

