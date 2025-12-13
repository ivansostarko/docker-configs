# Docker Registry Repository (Private Container Registry)

This project provides a production-leaning **private Docker Registry (Distribution v2)** deployment with:
- TLS termination via **Nginx**
- Authentication via **htpasswd**
- A lightweight **registry UI**
- Internal-only **debug/metrics** endpoints
- Optional **Prometheus + Grafana + cAdvisor** observability profile

## Contents

- `docker-compose.yml` – main stack
- `.env` – environment configuration (edit before running)
- `secrets/` – htpasswd and registry http secret (you must generate/replace)
- `registry/` – registry config and entrypoint
- `nginx/` – nginx config
- `certs/` – TLS certs (you must provide real certs)
- `prometheus/` + `grafana/` – optional observability profile

## Security / Operational Warnings (Read This)

If you expose this to the public internet without hardening, you are taking unnecessary risk.

- Use **real TLS certificates** (Let’s Encrypt or enterprise PKI).
- Keep the registry **debug endpoint** on internal networks only (this compose does).
- Plan for **stateful storage** and **backups**. `registry_data` is your critical asset.
- Registry deletes do not automatically reclaim blobs; garbage collection is an operational action.

## Prerequisites

- Docker Engine + Docker Compose plugin
- TLS certificates (recommended)
- Strong passwords (do not use defaults)

## Quick Start

1. Edit `.env`:
   - Set `REGISTRY_EXTERNAL_URL`
   - Set ports if needed
   - Set Grafana credentials if using observability

2. Provide TLS certs:
   - Place `fullchain.pem` and `privkey.pem` in `./certs/`

3. Create secrets:

   **Create htpasswd** (bcrypt):

   ```bash
   mkdir -p secrets
   docker run --rm httpd:2.4-alpine htpasswd -Bbn registryuser 'REPLACE_WITH_STRONG_PASSWORD' > secrets/htpasswd
   ```

   **Create registry HTTP secret**:

   ```bash
   openssl rand -hex 64 > secrets/http_secret
   chmod 600 secrets/http_secret secrets/htpasswd
   ```

4. Start the base stack:

   ```bash
   docker compose up -d
   ```

5. (Optional) Start with observability:

   ```bash
   docker compose --profile observability up -d
   ```

## Usage (Docker CLI)

Login:

```bash
docker login registry.example.com
```

Push an image:

```bash
docker pull alpine:latest
docker tag alpine:latest registry.example.com/library/alpine:latest
docker push registry.example.com/library/alpine:latest
```

## Endpoints

- Registry API: `https://<host>/v2/`
- UI: `https://<host>/`
- Health check: `https://<host>/healthz`
- Prometheus (observability profile): internal network only
- Grafana (observability profile): internal network only

## Common Troubleshooting

- **Client errors pushing large layers**: ensure `client_max_body_size 0;` is set (already done).
- **401 Unauthorized**: verify `secrets/htpasswd` exists and contains correct user/password hash.
- **TLS errors**: confirm your certs are valid for the hostname used in `REGISTRY_EXTERNAL_URL`.
- **Disk growth**: registry blob storage will grow; implement lifecycle policies or a regular GC process.

## Notes on Garbage Collection

Registry deletion removes manifests, but blobs remain until garbage collection runs.
A safe GC procedure typically requires the registry to be stopped or placed in read-only mode.
Plan this as a maintenance operation.

## License

You are responsible for compliance with the licenses of the upstream images used.
