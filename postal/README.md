# Postal (Docker Compose) Stack

This folder contains a hardened-ish Docker Compose stack for **Postal** (mail platform), backed by **MariaDB** and **RabbitMQ**, with optional **Prometheus metrics**.

## What this gives you

- Postal + MariaDB + RabbitMQ on a dedicated bridge network
- Healthchecks and dependency gating (Postal waits for DB/RabbitMQ)
- Conservative security defaults (`no-new-privileges`, `init: true`, tmpfs `/tmp`)
- RabbitMQ Prometheus plugin enabled, plus optional MariaDB exporter (`profiles: ["metrics"]`)
- Clear separation of config and persistent volumes

## What this does *not* do for you (and will hurt if you ignore it)

Running a mail platform is not a “docker-compose up” toy.

If you skip these, you will waste time and still fail deliverability:
- Correct **SPF**, **DKIM**, **DMARC** records
- Correct **rDNS/PTR** for your server IP that matches your mail hostname
- Outbound port 25 availability (many providers block or rate-limit it)
- IP reputation / warming / complaint handling

## Folder layout

```text
postal-stack/
  docker-compose.yml
  .env.example
  config/
    postal/                 # Postal runtime config/state (image uses /config)
    postal-mariadb/
      my.cnf                # MariaDB override
  secrets/                  # placeholders (do not commit real secrets)
```

## Quick start

1. Copy env file and fill values:

```bash
cp .env.example .env
```

2. Create the directories:

```bash
mkdir -p config/postal config/postal-mariadb secrets
```

3. Start the stack:

```bash
docker compose up -d
```

4. Optional: start with metrics profile (MariaDB exporter enabled):

```bash
docker compose --profile metrics up -d
```

## Port bindings

By default this stack **does not bind host port 25** directly. It maps:
- host `2525` -> container `25` (SMTP)
- host `8088` -> container `80` (Postal web)
- host `8089` -> container `8080` (tracking)

If you insist on binding 25 publicly, do it via firewall/NAT rules and lock it down. Do not casually publish 25 on a random host without controls.

## Security posture (minimums)

- Restrict management UIs (RabbitMQ 15672) to localhost, VPN, or firewall allowlists.
- Put Postal web behind a reverse proxy with TLS (Traefik/Nginx/NPM) and authentication as appropriate.
- Back up **MariaDB volume**, **RabbitMQ volume**, and **Postal config**. “It’s in a Docker volume” is not a backup.

## Metrics

- RabbitMQ exposes Prometheus metrics on `15692` (plugin enabled).
- MariaDB exporter is enabled only under the `metrics` profile and exposes `9104`.

## Notes on secrets

A `secrets/` directory is included as scaffolding. This compose file defines secrets, but the service images may not automatically consume `*_FILE` variables unless you wire them in. If you want real secret handling, either:
- Update services to use `*_FILE` environment variables (where supported), or
- Use Docker Swarm/Kubernetes secret stores, or
- Use an external secret manager (e.g., Vault) and templating.

## License

Use at your own risk. Mail infra is operationally expensive; test in a sandbox before you expose anything to the internet.
