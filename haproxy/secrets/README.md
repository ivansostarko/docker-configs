# Secrets

This directory is **intentionally** treated as sensitive.

## Required

- `haproxy_stats_password.txt` — password for HAProxy stats UI (and Grafana admin password in this reference stack).

Create it like:

```bash
openssl rand -base64 32 > secrets/haproxy_stats_password.txt
```

## Optional

- `haproxy_tls.pem` — PEM bundle containing **certificate + private key** (for TLS termination in HAProxy).

Example:

```bash
cat fullchain.pem privkey.pem > secrets/haproxy_tls.pem
```

## Notes

- If you commit this repo to Git, add `secrets/*` to `.gitignore` (already included).
- Docker Swarm secrets are supported by Compose, but **plain Docker Compose stores secrets on the local filesystem**. Treat them accordingly.
