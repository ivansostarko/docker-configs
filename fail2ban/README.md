# Fail2Ban (Docker Compose)

This repository deploys Fail2Ban in a way that can **actually ban traffic on the host**, plus an optional Prometheus exporter for observability.

## What this setup does (and what it does not)

- Protects **host services** (e.g., SSH) by banning IPs at the host firewall level.
- Optionally monitors **application logs** mounted into `/remotelogs/<app>/` (recommended pattern).
- Exposes **metrics** (jails, bans, failures) via an exporter on port `9191` (default).

It does **not** magically protect anything if:
- Fail2Ban cannot read the right log files.
- You run without host networking / NET_ADMIN capabilities.
- Your services only log to journald and you do not write logs to files.

## Requirements

- Linux host with either `iptables` or `nftables` in use.
- Docker + Docker Compose plugin.
- Log files available under `/var/log` (or mounted into `/remotelogs`).

## Quick start

1. Create secrets (do not keep the placeholder password):

   ```bash
   ./scripts/generate-secrets.sh
   ```

2. Review `.env` (PUID/PGID/TZ, exporter port, optional `REMOTELOGS_ROOT`).

3. Review Fail2Ban jail configuration:

   - `config/fail2ban/jail.local` (global defaults)
   - `config/fail2ban/jail.d/sshd.local` (enabled by default)

4. Start:

   ```bash
   docker compose up -d
   ```

5. Validate:

   ```bash
   docker compose exec fail2ban fail2ban-client ping
   docker compose exec fail2ban fail2ban-client status
   docker compose exec fail2ban fail2ban-client status sshd
   ```

If `sshd` shows a missing/empty `File list`, you are not monitoring the SSH log path correctly.

## Key design choices (non-negotiable if you want host banning)

- `network_mode: host`
  - Required so firewall changes apply to the host network namespace.

- `cap_add: NET_ADMIN, NET_RAW`
  - Required for manipulating firewall rules and networking primitives.

- Mount `/var/log` read-only
  - Fail2Ban needs access to real log files.

## Remote logs pattern

LinuxServer recommends mounting each application's **log directory** under `/remotelogs/<app>/`.

Example:

- Host: `/srv/logs/nginx/` containing `access.log` and `error.log`
- Container: `/remotelogs/nginx/`

Then configure a jail to read:

```ini
logpath = /remotelogs/nginx/error.log
```

Avoid mounting individual log files where possible (rotation and inode changes often break monitoring).

## iptables vs nftables

In `config/fail2ban/jail.local`, choose the correct `banaction`:

- `iptables-multiport` for iptables environments
- `nftables-multiport` for nftables environments

If you pick the wrong one, bans may “succeed” in logs but not affect real traffic.

## Docker-published ports and reverse proxies

If the service you want to protect is exposed via Docker port publishing (or sits behind a reverse proxy), you may need:

- A jail that reads the reverse proxy logs (Traefik/Nginx/Caddy)
- A ban action targeting `DOCKER-USER` (common approach)

This template defaults to `chain = INPUT` because it is the correct starting point for **host services** like SSH.

## Metrics (Prometheus)

The optional exporter exposes metrics at:

- `http://<host>:9191/metrics`

Basic auth is enabled via Docker secrets.

See `docs/prometheus-scrape-example.yml` for a scrape snippet.

## Security notes

This container is intentionally granted elevated capabilities to modify firewall rules on your host.

Do not deploy this on hosts where:

- You do not fully control who can run containers.
- Your image supply chain is untrusted.
- You do not have an “out-of-band” access path (console/VPN) in case you lock yourself out.

## Troubleshooting

### 1) “Fail2Ban runs but nothing gets banned”

- Confirm logs are readable and paths are correct.
- Confirm the jail is enabled.
- Confirm the jail filter matches your log format.
- Confirm `banaction` matches your firewall backend.

### 2) “sshd jail shows no file list / no matches”

- Debian/Ubuntu default is `/var/log/auth.log`
- RHEL/CentOS default is `/var/log/secure`

### 3) Exporter is up but shows no metrics

- Confirm `/var/run/fail2ban/fail2ban.sock` exists in the fail2ban container.
- Confirm the exporter mounts `f2b_run` volume and can read the socket.

## Files

- `docker-compose.yml` – services + healthchecks + secrets
- `.env` – environment variables
- `config/` – Fail2Ban config (persistent)
- `scripts/generate-secrets.sh` – generates exporter basic auth secrets
- `docs/prometheus-scrape-example.yml` – scrape config example
