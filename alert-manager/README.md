# Alertmanager (Prometheus) — Hardened Docker Compose Bundle

This bundle provides a production-shaped Docker Compose service for **Prometheus Alertmanager**, including:
- pinned image version
- healthcheck (readiness endpoint)
- persistent volume for state (silences/notification log)
- Docker **configs** for non-secret configuration
- Docker **secrets** for sensitive material (example: SMTP password)
- safe port publishing defaults (localhost-only) and guidance for reverse proxy usage
- Prometheus scrape + alerting integration snippet

## Contents

```
.
├── README.md
├── docker-compose.yml
├── .env.example
├── config/
│   └── alertmanager/
│       ├── alertmanager.yml
│       └── templates/
│           └── .keep
└── secrets/
    └── alertmanager_smtp_password.txt.example
```

## Quick start

1) Copy `.env.example` to `.env` and adjust values:

```bash
cp .env.example .env
```

2) Add your SMTP password to the secret file (single line, no quotes):

```bash
mkdir -p secrets
printf "%s" "YOUR_SMTP_PASSWORD_HERE" > secrets/alertmanager_smtp_password.txt
chmod 600 secrets/alertmanager_smtp_password.txt
```

> Note: The included `docker-compose.yml` references `secrets/alertmanager_smtp_password.txt`.
> The repository-safe example file is `secrets/alertmanager_smtp_password.txt.example`.

3) Start Alertmanager:

```bash
docker compose up -d
```

4) Verify health:

```bash
curl -fsS http://127.0.0.1:${ALERTMANAGER_PORT:-9093}/-/ready
```

## Security posture (non-negotiable)

- **Do not** expose `:9093` directly to the public Internet.
- Default configuration publishes to `127.0.0.1` only:
  - `127.0.0.1:${ALERTMANAGER_PORT}:9093`
- If you need remote access, put Alertmanager behind an authenticated reverse proxy (and ideally VPN).

## Docker Compose (service definition)

See `docker-compose.yml`.

Key decisions:
- **Pinned image**: avoid `latest` to prevent surprise breaking changes.
- **read_only + tmpfs**: reduce writable surface area.
- **cap_drop + no-new-privileges**: reduce container capabilities.
- **configs + secrets**: keep config and secrets out of environment variables.

## Configuration

Alertmanager configuration file location inside container:

- `/etc/alertmanager/alertmanager.yml`

This is mounted via Docker **configs** from:

- `./config/alertmanager/alertmanager.yml`

### Templates (optional)

If you use custom templates, place them under:

- `./config/alertmanager/templates/*.tmpl`

The directory is mounted read-only in the container.

## Secrets

This bundle uses the native Alertmanager setting:

- `smtp_auth_password_file: "/run/secrets/alertmanager_smtp_password"`

Docker secret maps the file at runtime. Create:

- `./secrets/alertmanager_smtp_password.txt`

Do not commit it.

## Prometheus integration (metrics + alerting)

In your `prometheus.yml`:

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ["alertmanager:9093"]

scrape_configs:
  - job_name: "alertmanager"
    static_configs:
      - targets: ["alertmanager:9093"]
```

## Reloading configuration (operational note)

Alertmanager supports configuration reload via:
- SIGHUP
- HTTP `POST /-/reload` (if enabled by your deployment pattern)

For Compose, a simple approach is:

```bash
docker kill -s HUP $(docker ps -q --filter name=alertmanager)
```

## Troubleshooting

### Container is unhealthy
- Check readiness endpoint from inside the container:
  ```bash
  docker exec -it $(docker ps -q --filter name=alertmanager) wget -qO- http://127.0.0.1:9093/-/ready
  ```
- Validate config (requires amtool; you can run it in a temporary container):
  ```bash
  docker run --rm -v "$PWD/config/alertmanager:/etc/alertmanager:ro" prom/alertmanager:latest     amtool check-config /etc/alertmanager/alertmanager.yml
  ```

### Email not sending
- Confirm SMTP settings in `config/alertmanager/alertmanager.yml`.
- Ensure the secret file exists and has correct permissions on the host.
- Review logs:
  ```bash
  docker logs --tail=200 -f $(docker ps -q --filter name=alertmanager)
  ```

## License

Use/adapt freely for your infrastructure needs.
