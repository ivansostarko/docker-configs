# Angular 21 — Docker Compose Bundle (Dev + Prod + Monitoring)

This repository is a ready-to-run Docker Compose setup for an Angular workspace (Angular 21 assumed) with:

- **Dev profile**: `ng serve` inside a Node container (hot reload, stable file watching via polling)
- **Prod profile**: multi-stage build + **Nginx** serving static assets
- **Monitoring profile (optional)**: **Prometheus + Grafana + cAdvisor + Nginx Prometheus exporter**

## Why this exists

Angular versions are not the hard part. The hard part is:
1) reliable file watching in containers, and  
2) **serving the correct build output directory** (Angular dist output differs across configurations).

This bundle addresses both.

---

## Prerequisites

- Docker Engine + Docker Compose v2
- Your Angular workspace checked out into `./app` (or generate one; see below)

---

## Repository layout

```
.
├─ docker-compose.yml
├─ .env.example
├─ app/                          # your Angular project goes here (bind-mounted in dev)
├─ angular/
│  ├─ Dockerfile.dev
│  ├─ Dockerfile
│  ├─ nginx/default.conf
│  └─ scripts/dev-entrypoint.sh
├─ prometheus/prometheus.yml
├─ grafana/provisioning/datasources/datasource.yml
├─ grafana/provisioning/dashboards/provider.yml
└─ secrets/
   ├─ npm_token.txt              # optional (private npm registry)
   └─ grafana_admin_password.txt # required if you run monitoring
```

---

## Quick start

### 1) Configure env + secrets

```bash
cp .env.example .env
mkdir -p secrets
echo "change-me" > secrets/grafana_admin_password.txt
# Optional: for private npm packages
echo "" > secrets/npm_token.txt
```

### 2) Put your Angular workspace into `./app`

If you already have a repo:
- Copy/clone it into `./app`

If you want to generate a new one:
```bash
docker compose --profile dev run --rm angular_dev ng new app --directory .
```

---

## Run modes

### Dev (ng serve)
```bash
docker compose --profile dev up -d --build
```

Open: `http://localhost:4200`

Notes:
- `node_modules` is a named volume (prevents host/OS mismatch issues).
- Polling watchers are enabled by default because bind-mount file events are unreliable in many Docker environments.

### Prod (static Nginx)
```bash
docker compose --profile prod up -d --build
```

Open: `http://localhost:8080`

**Important**: The production Dockerfile normalizes your build output by locating `dist/**/index.html` and copying that directory into the Nginx web root. This avoids the most common “wrong dist path” failure.

### Prod + monitoring (Prometheus + Grafana)
```bash
docker compose --profile prod --profile monitoring up -d --build
```

- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000`
  - User: `admin` (default in `.env`)
  - Password: from `secrets/grafana_admin_password.txt`

---

## Environment variables

See `.env.example`. Most commonly changed:

- `ANGULAR_DEV_PORT` — dev server port (default 4200)
- `ANGULAR_WEB_PORT` — prod Nginx port (default 8080)
- `ANGULAR_BUILD_CONFIGURATION` — `production` or your custom config
- `BASE_HREF` — deploy under a subpath (e.g. `/app/`)
- `CHOKIDAR_INTERVAL` — file watcher polling interval

---

## Healthchecks

- Dev: checks `http://localhost:4200/`
- Prod: checks `http://localhost/healthz`
- Exporter: checks `/metrics`
- Prometheus: checks `/-/healthy`
- Grafana: checks `/api/health`

If you see “unhealthy”:
- check logs: `docker compose logs -f <service>`
- verify your Angular app actually starts and serves content

---

## Security / production notes (read this, or you’ll regret it)

- **Do not use `:latest` in production.** Pin versions once you stabilize.
- Nginx exposes `/nginx_status` but restricts it to private ranges + localhost.
- Grafana admin password is loaded from a Docker secret file; don’t bake credentials into images.

---

## Troubleshooting

### Dev server doesn’t hot reload
Increase polling:
- Set `CHOKIDAR_INTERVAL=500` in `.env`, restart dev container.

### Prod build fails with “Cannot find dist/**/index.html”
Your build may not be producing output where expected. Common causes:
- Build errors (check logs)
- Nonstandard outputPath in `angular.json`
- SSR / prerender outputs (different structure)

Run a local build inside the builder stage by temporarily adding:
- `RUN find dist -maxdepth 4 -type f | head -n 200`

---

## Common commands

```bash
docker compose --profile dev down
docker compose --profile prod down
docker compose --profile prod --profile monitoring down -v
```

---

## What you should do next

If you’re serious about production:
1) pin all images to explicit versions,
2) add a CI build that runs `docker build` and smoke-tests `/healthz`,
3) put Grafana/Prometheus behind auth or a private network, not open ports.
