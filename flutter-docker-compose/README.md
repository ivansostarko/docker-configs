# Flutter Docker Compose (Dev + Prod + Monitoring)

This stack is intentionally opinionated:

- **Dev**: `flutter run -d web-server` inside a container for fast iteration.
- **Prod**: `flutter build web --release` -> served via **NGINX**.
- **Monitoring (optional)**: Prometheus + Grafana + NGINX Prometheus exporter.

If you expected Android/iOS builds in containers, reset that expectation: mobile builds require platform toolchains
(Android SDK / Xcode), licensing, and hardware constraints. This template targets **Flutter Web**, which is the
only Flutter runtime that is operationally sane in Docker.

---

## What you get

### Profiles

- `dev`: Hot-reload web dev server.
- `build`: One-shot web build into a named volume.
- `prod`: NGINX serving the built web files (runs the build as a dependency).
- `monitoring`: Prometheus + Grafana (scrapes NGINX exporter).

### Volumes

- `flutter_pub_cache`: dependency cache to avoid re-downloading packages.
- `web_build`: built web artifacts shared between builder and NGINX.
- `nginx_cache`: nginx cache dir.
- `prometheus_data`, `grafana_data`: persistent monitoring data.

### Secrets (optional)

- `secrets/pub_credentials.json` -> mounted as `pub_credentials_json` secret.
  Use this if you depend on private pub packages / enterprise pub.

---

## Quick start

### 1) Create `.env`

```bash
cp .env.example .env
```

### 2) (Optional) Add pub credentials

If you have private packages, place your pub credentials JSON here:

```
./secrets/pub_credentials.json
```

Common location on a dev machine is:

- `~/.pub-cache/credentials.json`

If you do not have this file, create an **empty** one so Compose doesn't error:

```bash
mkdir -p secrets
echo '{}' > secrets/pub_credentials.json
```

### 3) Dev mode (hot reload)

```bash
docker compose --profile dev up --build
# open http://localhost:8080
```

### 4) Prod mode (NGINX serving release build)

```bash
docker compose --profile prod up --build
# open http://localhost:8081
```

If you want to run the build explicitly:

```bash
docker compose --profile build run --rm flutter_builder
```

### 5) Monitoring (Prometheus + Grafana)

```bash
docker compose --profile prod --profile monitoring up --build
# Prometheus: http://localhost:9090
# Grafana:    http://localhost:3000  (default admin/admin - change it)
```

---

## Operational notes (brutally honest)

- **Flutter in Docker is not “standardized.”** There is no official Flutter SDK Docker image. This stack uses
  `ghcr.io/cirruslabs/flutter:stable`, which is widely used in CI pipelines.
- **Dev container file permissions** can be annoying on Linux hosts. If you hit permission errors, run with
  a matching UID/GID or switch to a dedicated dev user in a custom Dockerfile.
- **Compose `deploy:` limits are not enforced** unless you're running in Swarm. If you want real enforcement
  locally, use Docker Desktop resource settings or run in Kubernetes.
- **Secrets here are runtime secrets**, not build secrets. If you need secrets during image build, use BuildKit
  secrets and a tailored CI pipeline. Don't pretend Compose alone solves supply-chain hygiene.

---

## Typical customization checklist

- Set `FLUTTER_WEB_BASE_HREF` if you're serving under a path (e.g. `/app/`).
- Replace `nginx:1.27-alpine` with a pinned digest for maximum supply-chain control.
- Add TLS termination (Traefik / Caddy / NGINX reverse proxy) if this faces the internet.
- Add CSP headers for your app if you care about real-world security.

---

## File layout

```
.
├── docker-compose.yml
├── .env.example
├── secrets/
│   └── pub_credentials.json
├── docker/
│   └── flutter/
│       ├── Dockerfile.web
│       └── build-web.sh
├── nginx/
│   └── conf.d/
│       └── default.conf
└── monitoring/
    ├── prometheus/
    │   └── prometheus.yml
    └── grafana/
        └── provisioning/
            ├── datasources/
            │   └── prometheus.yml
            └── dashboards/
                └── dashboards.yml
```

---

## Troubleshooting

### `flutter run` can't bind to port

Make sure you're using `--web-hostname 0.0.0.0` (already set in compose) and that your port is not in use.

### Build output is stale

Named volumes persist. Rebuild from scratch:

```bash
docker compose down -v
docker compose --profile prod up --build
```

### I need Android APK / iOS IPA builds

Stop trying to brute-force this into Docker Compose. Use CI runners with the correct toolchains:
- Android: containerized builds *can* work, but you'll need Android SDK + licenses.
- iOS: requires macOS runners. Docker is not your bottleneck; Apple is.
