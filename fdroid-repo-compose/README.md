# F-Droid Repository (Docker Compose)

This repository provides a Docker Compose stack for hosting a **binary F-Droid repository**:
you build APKs elsewhere, then publish them through an F-Droid-compatible repo endpoint.

It is intentionally opinionated:
- separate **repo generation** (`fdroid update`) from **serving** (NGINX)
- default to a conventional URL: `/fdroid/repo/`
- include optional scheduling and metrics profiles

## What this is (and is not)

- ✅ Good for internal distribution, staging repos, small private repos, or “I already have APKs and want F-Droid clients to consume them”.
- ❌ Not a high-assurance build-server architecture.
- ❌ Not a “secure signing” design if you keep signing keys on the same public host.

If you care about repo integrity under compromise, the correct approach is:
1) run `fdroid update` + signing on a restricted builder
2) publish only the resulting `/repo/repo` artifacts to the web host

## Components

- `fdroid` service:
  - runs `scripts/update.sh` which executes `fdroid update`
  - writes repo output to the `fdroid_repo` volume
- `web` service:
  - NGINX serving `/fdroid/repo/` from `fdroid_repo`
  - has `/healthz` for healthchecks
- Optional profiles:
  - `scheduler`: Ofelia running `fdroid update` every 6 hours (requires docker.sock)
  - `metrics`: NGINX Prometheus exporter + Prometheus

## Files

- `docker-compose.yml`
- `.env` (ports, image tag, update flags)
- `config/config.yml` (your F-Droid repo config)
- `config/metadata/` (metadata YAMLs)
- `nginx/conf.d/fdroid.conf`
- `scripts/update.sh`
- `secrets/` (local secret files; ignored by git)
- `config/systemd-example.txt` (host-side systemd timer alternative)

## Quick start

1) Edit `.env` if needed (ports, image tag).

2) Edit `config/config.yml`:
- set `repo_url` to your public URL, e.g. `https://example.com/fdroid/repo`
- set `repo_name`, `repo_description`

3) Start NGINX:
```bash
docker compose up -d web
```

4) Run a repo update (generates indexes):
```bash
docker compose run --rm fdroid
```

5) Check:
- `http://localhost:8080/fdroid/repo/`

## Adding APKs

The simplest approach is to copy APKs into the `fdroid_repo` volume via the `fdroid` container:

```bash
docker compose run --rm fdroid bash
# inside container:
cp /path/to/your.apk /repo/repo/
fdroid update
```

For automated flows, mount a host directory into `/repo/repo` instead of (or in addition to) the named volume.

## Signing / secrets

This compose defines Docker secrets as **local files** under `./secrets/`.

Expected files:
- `secrets/keystore.p12`
- `secrets/keystore.pass`
- `secrets/keypass.pass`
- `secrets/keyalias.txt`

Hard truth:
- Docker “secrets” in non-Swarm Compose are still files on the host.
- If the host is compromised, your signing keys are compromised.
- If you cannot accept that, do not sign on this box.

### If fdroidserver requires plaintext passwords in config.yml

Some fdroidserver versions expect `keystorepass` / `keypass` in `config.yml`.
Do not commit them. Your defensible options:

1) Best: sign on a separate builder, publish artifacts to the web server.
2) Acceptable: generate a runtime-only config in the container from secrets:
   - write a small wrapper that copies `config.yml` to a temp file and injects the passwords
   - keep the resulting file inside the container or tmpfs, never in git

## Scheduling updates

### Option A (included, higher risk): scheduler profile

Enables Ofelia with docker.sock mounted (root-equivalent).

```bash
docker compose --profile scheduler up -d
```

Change schedule in `docker-compose.yml` (label `ofelia.job-run.fdroid-update.schedule`).

### Option B (recommended): host systemd timer

See `config/systemd-example.txt` for a working template.

## Metrics

Enable:

```bash
docker compose --profile metrics up -d
```

- exporter: `http://localhost:9113/metrics`
- prometheus: `http://localhost:9090`

## Backups

Back up these Docker volumes:
- `fdroid_state`
- `fdroid_repo`

Example:
```bash
docker run --rm -v fdroid-repo_fdroid_repo:/data -v "$PWD":/backup alpine   tar czf /backup/fdroid_repo.tar.gz -C /data .
```

## Production hardening checklist

- Put `web` behind TLS (reverse proxy recommended).
- Restrict who can publish APKs and modify metadata.
- Keep signing keys off the public host if integrity matters.
- Pin image digests (not tags) for reproducibility.
- Monitor access logs; rate-limit if internet-facing.
