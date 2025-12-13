# Docker Compose configurations

A small, opinionated collection of Docker and Docker Compose configurations intended to be copied into projects (or used as a starting point) for local development environments.

## What this repo is:

- [php Apache](/php-apache/README.md)
- Portainer


## Prerequisites

- Docker Engine + Docker Compose v2 (`docker compose ...`)
- Git

## Repository layout

Each stack should be self-contained in its own folder, typically including:
- `docker-compose.yml`
- optional `Dockerfile` / `docker/` config
- optional `.env.example`
- stack-specific notes

## Quick start

1. Clone:
   ```bash
   git clone https://github.com/ivansostarko/docker-configs.git
   cd docker-configs
   ```

2. Pick a stack folder and run:
   ```bash
   cd <stack-folder>
   docker compose up -d --build
   ```

3. Stop:
   ```bash
   docker compose down
   ```


## Contributing

If you add new stacks:
1. Create a new folder at the repo root (e.g., `laravel/`, `mysql/`).
2. Include a short stack-specific README (or document it here).
3. Keep defaults safe for local dev (no open admin tools without a note)

## License

MIT.
