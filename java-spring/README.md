# Spring Boot Docker Compose Stack

This repository provides an opinionated, production-leaning Docker Compose stack for a Spring Boot service, including:

- Spring Boot app (built via multi-stage Dockerfile)
- PostgreSQL
- Redis
- Prometheus scraping Spring Actuator metrics
- Grafana provisioned with Prometheus + Loki datasources
- Loki + Promtail for container log collection
- OpenTelemetry Collector with an optional Jaeger UI (profile `tracing`)
- Optional RabbitMQ (profile `messaging`)

## What you must not ignore

1. **Spring Boot does not automatically map `*_FILE` to the secret value.**
   This stack includes `docker/entrypoint.sh` to read `/run/secrets/*` files and export environment variables before starting Java.
2. **Do not keep optional components “just in case.”**
   If you do not actively use RabbitMQ or tracing today, do not run those profiles.

## Prerequisites

- Docker Engine + Docker Compose plugin
- A Spring Boot project with `pom.xml` and `src/` present in the repository root

## Files

- `compose.yaml` – main stack
- `.env` – non-secret configuration
- `secrets/*.txt` – Docker secrets (replace with real secrets)
- `Dockerfile` – builds and runs the Spring Boot app
- `docker/entrypoint.sh` – loads Docker secrets into env vars
- `config/application.yml` – Spring config used by the container
- `monitoring/*` – Prometheus/Grafana/Loki/Promtail/Otel Collector configs

## Quickstart

1. Create real secrets:

   ```bash
   mkdir -p secrets
   openssl rand -base64 32 > secrets/postgres_password.txt
   openssl rand -base64 64 > secrets/app_jwt_secret.txt
   openssl rand -base64 24 > secrets/app_admin_password.txt
   chmod 600 secrets/*.txt
   ```

2. Build and start the core stack:

   ```bash
   docker compose up -d --build
   ```

3. Access services:

- App: `http://localhost:8080`
- Actuator (management port): `http://localhost:8081/actuator`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000`
- Loki: `http://localhost:3100`

Grafana credentials:
- user: `admin` (default, configurable via `.env`)
- password: read from `secrets/app_admin_password.txt`

## Optional profiles

### RabbitMQ

```bash
docker compose --profile messaging up -d --build
```

### Tracing (Jaeger)

```bash
docker compose --profile tracing up -d --build
```

- Jaeger UI: `http://localhost:16686`

## Metrics

Prometheus scrapes:
- Spring Boot metrics from `http://app:8081/actuator/prometheus`

To expose metrics, ensure your Spring Boot app includes Micrometer + Actuator and Prometheus registry (example Maven deps):

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
  <groupId>io.micrometer</groupId>
  <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

## Logs

Promtail uses Docker service discovery via the Docker socket. This is pragmatic but has security implications (socket access is powerful).
If you cannot tolerate Docker socket access, replace Promtail config with file-based scraping or ship logs another way.

## Healthchecks

Included healthchecks:
- `app`: readiness via `/actuator/health/readiness` on management port
- `postgres`: `pg_isready`
- `redis`: `redis-cli ping`
- `rabbitmq`: `rabbitmq-diagnostics ping`

Note: not all third-party images ship with `curl`/`wget`, so this stack avoids “fake” HTTP healthchecks for those images.

## Hardening notes

- The `app` container is `read_only: true` and drops all Linux capabilities.
- Secrets are mounted from `./secrets/*.txt` using Docker secrets.
- `/.env` is excluded in `.dockerignore` to discourage baking it into images.

## Common failure modes

- App fails to connect to Postgres:
  - Your JDBC settings do not match `DB_HOST=postgres` or you did not mount secrets.
  - Verify `secrets/postgres_password.txt` is correct and readable.

- Actuator returns 404:
  - You did not include `spring-boot-starter-actuator`, or management endpoints are not exposed.

- Prometheus shows target DOWN:
  - Check `http://localhost:8081/actuator/prometheus` from your host.

## Stop / reset

Stop:
```bash
docker compose down
```

Stop and remove volumes (destructive):
```bash
docker compose down -v
```
