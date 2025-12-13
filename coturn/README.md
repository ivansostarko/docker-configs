# Coturn (TURN/STUN) Docker Compose (Hardened)

This package provides a production-oriented Coturn deployment using Docker Compose:
- Correct TURN relay **port range** handling (most broken deployments miss this)
- Docker **configs** and **secrets** separation (TLS private key is a secret, not a bind mount)
- Basic **healthcheck**
- Container hardening (`cap_drop`, `no-new-privileges`, `read_only`, `tmpfs`)
- Clean paths for logs and optional metrics

If you skip the port range and NAT/external IP parts, expect WebRTC “connects but no media” failures. That is not a Coturn bug; it is your infrastructure.

## Repository layout

```
.
├─ docker-compose.yml
├─ .env.example
└─ config/
   └─ coturn/
      ├─ turnserver.conf.example
      └─ certs/
         └─ .gitkeep
```

## 1) Quick start

1. Copy the environment file:
   ```bash
   cp .env.example .env
   ```

2. Put TLS certs (recommended) into:
   - `./config/coturn/certs/fullchain.pem`
   - `./config/coturn/certs/privkey.pem`

   If you do not need TLS on 5349, you can still run TURN on 3478, but many clients/environments prefer TLS.

3. Review and edit the config:
   ```bash
   cp ./config/coturn/turnserver.conf.example ./config/coturn/turnserver.conf
   ```
   Then set:
   - `realm=...`
   - `external-ip=...` (critical if behind NAT)
   - `min-port/max-port` to match your relay range

4. Start:
   ```bash
   docker compose up -d
   ```

5. Validate basics:
   ```bash
   docker compose ps
   docker logs -n 200 coturn
   ```

## 2) Firewall requirements (non-negotiable)

Open these on the **host** firewall and any upstream security groups:

- `3478/udp` and optionally `3478/tcp`
- `5349/tcp` if you use TLS
- **Relay UDP port range**: e.g. `49152-49200/udp` (must match config)

If you do not open the relay range, TURN can authenticate and still fail to relay media. This is the #1 self-inflicted outage.

## 3) NAT / external IP (also non-negotiable)

If the Coturn host is behind NAT (cloud instances often are), you must set `external-ip` correctly or clients will receive unusable candidates.

- Single public IP:
  - `external-ip=203.0.113.10`

In more complex NAT setups, consult Coturn docs for public/private mapping formats.

## 4) Authentication model (pick one; don’t improvise)

You have two sane options:

### A) Static user (simple; fine for small/private use)
In `turnserver.conf`:
```
lt-cred-mech
user=exampleuser:examplepassword
```

### B) TURN REST API secret (recommended for production)
In `turnserver.conf`:
```
lt-cred-mech
use-auth-secret
static-auth-secret=CHANGE_ME_TO_A_LONG_RANDOM_SECRET
```
Your application generates time-limited credentials (HMAC) for clients. This scales and avoids distributing a long-lived password.

## 5) Metrics (honesty section)

Coturn does not magically expose Prometheus metrics just because you want them. If you need metrics, use:
- an exporter you trust (sidecar), or
- log scraping + derived metrics, or
- Coturn’s management/CLI capabilities (but we disable CLI here via `--no-cli` for safety).

A stub sidecar service is included in `docker-compose.yml` as comments.

## 6) Troubleshooting checklist

If WebRTC fails:
1. Check relay range is mapped in Compose AND `min-port/max-port` match.
2. Confirm firewall/security groups allow the relay range UDP.
3. Confirm `external-ip` is correct (especially behind NAT).
4. Confirm your client is actually using TURN (not only STUN).
5. Check logs:
   ```bash
   docker logs -n 300 coturn
   ```

## Files included

- `docker-compose.yml` — hardened Coturn service with configs/secrets
- `.env.example` — environment template
- `config/coturn/turnserver.conf.example` — safe starting config

---

Generated on: 2025-12-13
