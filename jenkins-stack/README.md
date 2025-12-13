# Jenkins Docker Compose (JCasC + Secrets + Optional Monitoring)

This repository provides a production-oriented Jenkins controller stack using Docker Compose, including:

- Jenkins LTS controller (JDK 17) built with a pinned plugin list
- Docker secrets for admin credentials
- Jenkins Configuration as Code (JCasC) bootstrapping
- Healthcheck
- Optional Prometheus + Grafana monitoring (Compose profile: `monitoring`)
- Optional Docker-in-Docker daemon for builds (Compose profile: `dind`) — high risk

## Quick start

1) Create secrets (do **not** commit real credentials):

- `secrets/jenkins_admin_user.txt`
- `secrets/jenkins_admin_password.txt`

2) Review and edit `.env`:
- Set `JENKINS_URL` to your real public URL (recommended behind TLS reverse proxy).
- If you serve Jenkins under a subpath (e.g., `/jenkins`), set `JENKINS_URL_PREFIX=/jenkins`.

3) Build and start Jenkins:

```bash
docker compose up -d --build
```

4) Open Jenkins:
- `http://localhost:8080` (or your reverse-proxy URL)

## Monitoring (optional)

Start with:

```bash
docker compose --profile monitoring up -d
```

- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000`

Prometheus scrapes Jenkins at `/prometheus` (requires the Prometheus plugin installed via `plugins.txt`).

## Docker-in-Docker (optional, risky)

Enable DinD only if you understand the blast radius:

```bash
docker compose --profile dind up -d
```

**Security reality:** mounting the host Docker socket into Jenkins is effectively “root on the host”. DinD reduces some host coupling but still expands attack surface.

## Files of interest

- `docker-compose.yml` — services, networks, volumes, secrets, healthchecks, profiles
- `docker/jenkins/` — Dockerfile, plugin list, entrypoint (reads secrets into env vars)
- `casc/jenkins.yaml` — JCasC baseline (admin user, URL, auth strategy)
- `monitoring/` — Prometheus + Grafana provisioning (optional)

## Backup (minimum viable)

The Jenkins state is in the named volume `jenkins_home`. Back it up routinely.

Example:

```bash
docker run --rm \
  -v jenkins_home:/data \
  -v "$PWD":/backup \
  alpine:3.20 \
  tar czf /backup/jenkins_home.tgz -C /data .
```

## Hardening notes (non-negotiable)

- Do not expose port 8080 directly to the internet. Put Jenkins behind a TLS reverse proxy.
- Keep controller executors at `0`; run builds on agents.
- Keep plugins minimal; update intentionally.
