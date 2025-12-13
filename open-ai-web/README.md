# Open WebUI (Compose Bundle)

This bundle provides a hardened Docker Compose service definition for **Open WebUI** connected to **Ollama**.

## Contents

- `docker-compose.open-webui.yml` — Open WebUI service + networks/volumes/secrets skeleton
- `.env.example` — environment variable template
- `secrets/open_webui_secret_key.txt` — placeholder secret file (do not commit real secrets)

## Why this is “better” than the minimal example

- **Reproducibility:** pins the image tag (`OPEN_WEBUI_TAG`) instead of using a moving `:main`.
- **Persistence:** mounts `/app/backend/data` so users/chats/config survive redeploys.
- **Operational sanity:** includes `healthcheck`, logging rotation, clean stop behavior.
- **Security posture:** drops Linux capabilities and enforces `no-new-privileges`.
- **Config hygiene:** supports `.env` and an optional `secrets/` pattern.

## Quick start

1) Copy the env template and set real values:

```bash
cp .env.example .env
# Edit .env and set OPEN_WEBUI_SECRET_KEY to a strong random value
```

2) (Optional, recommended) Put the secret into a file instead of `.env`:

```bash
mkdir -p secrets
openssl rand -hex 32 > secrets/open_webui_secret_key.txt
```

If you do this, switch from `WEBUI_SECRET_KEY` to the file-based variant supported by your image (commonly `*_FILE` style env vars), or keep using `.env` but protect it.

3) Run:

```bash
docker compose -f docker-compose.open-webui.yml up -d
docker compose -f docker-compose.open-webui.yml ps
```

## Notes on dependencies (Ollama)

This bundle assumes you have an `ollama` service on the same network:

- `OLLAMA_BASE_URL` defaults to `http://ollama:11434`.
- `depends_on: condition: service_healthy` only works if **your ollama service has a healthcheck**.

## Healthcheck

The container is checked via:

- `http://127.0.0.1:8080/health`

If your image lacks `wget`, replace with `curl` if available, or use `python -c` socket checks.

## Optional metrics/tracing

Open WebUI does not typically expose a Prometheus scrape endpoint by default. If you want metrics, use **OpenTelemetry** via OTLP and run an OTLP collector (Grafana Agent/Alloy, OpenTelemetry Collector, etc.). Enable the commented `ENABLE_OTEL*` env vars and point `OTEL_EXPORTER_OTLP_ENDPOINT` to your collector.

## Hard truth / common mistakes

- Using `:main` is how you create **unplanned outages**.
- Not setting `OPEN_WEBUI_SECRET_KEY` is how you get **random session invalidation** after redeploys.
- Binding the port publicly without a proxy/SSO/ACL is how you get **unauthorized access**.

---

Generated: 2025-12-13
