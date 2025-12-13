# CoreDNS on Docker Compose (Hardened Baseline)

This package provides a production-grade CoreDNS Docker Compose configuration with:
- Pinned image version (no `latest` surprises)
- Explicit networks and static IP (optional, but predictable)
- `configs` for `Corefile` and bind mount for zone directory
- Optional secrets mounting (for TLS/DoT use cases)
- Security hardening (read-only rootfs, dropped capabilities, `no-new-privileges`)

## Contents

```text
coredns-docker-compose/
  docker-compose.yml
  .env.example
  config/
    coredns/
      Corefile
      zones/
        db.example.internal
        db.home.arpa
      secrets/
        tls_cert.pem        (placeholder, create your own)
        tls_key.pem         (placeholder, create your own)
```

## Quick start

1. Copy `.env.example` to `.env` and adjust values:

```bash
cp .env.example .env
```

2. Ensure the host directory exists:

```bash
sudo mkdir -p /config/coredns/zones /config/coredns/secrets
```

3. Copy the provided config into place (or change `COREDNS_CONFIG_DIR` in `.env` to use this repo directory):

```bash
sudo cp -r ./config/coredns/* /config/coredns/
```

4. Start CoreDNS:

```bash
docker compose up -d
```

5. Verify ports are listening (UDP/TCP 53, metrics 9153):

```bash
docker ps
docker logs -f coredns
```

## Host port 53 conflict (common failure)

If your host runs `systemd-resolved` or another DNS daemon, port 53 may already be in use.
Fix that before starting CoreDNS. Otherwise Docker will fail to bind the port.

Typical checks:

```bash
sudo ss -ltnup | grep ':53 '
```

## Using CoreDNS as DNS for other containers

Attach other services to the same `dns_net` network and point DNS to CoreDNS:

```yaml
services:
  app:
    image: alpine
    command: ["sleep","infinity"]
    networks:
      - dns_net
    dns:
      - 172.28.0.53

networks:
  dns_net:
    external: true
    name: dns_net
```

## Notes on secrets

Compose secrets here are file-backed and mounted into the container. They keep secrets out of environment variables,
but they do not encrypt your filesystem. Protect host permissions and backups accordingly.

If you do not use TLS features in your Corefile, remove the `secrets:` section entirely.

## Files

- `docker-compose.yml`: main compose file
- `.env.example`: environment variables you should copy to `.env`
- `config/coredns/Corefile`: baseline CoreDNS config (edit to your needs)
- `config/coredns/zones/*`: example authoritative zones (optional)

## Hardening choices (why they exist)

- `read_only: true` + `tmpfs`: reduces writable surface area.
- `cap_drop: [ALL]` + `cap_add: [NET_BIND_SERVICE]`: CoreDNS can bind to 53 without running as root.
- `no-new-privileges`: blocks privilege escalation.

If you do not understand a hardening knob, do not remove it casually. Remove it only when you can articulate the failure mode you’re fixing.
