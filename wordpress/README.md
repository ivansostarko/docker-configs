# Store WordPress (Docker Compose)

Production-leaning Docker Compose stack for:
- WordPress (Apache/PHP)
- MySQL 8

This bundle includes pinned images, healthchecks, basic hardening, and Docker secrets.

## Contents

- `docker-compose.yml`
- `.env.example` (copy to `.env`)
- `config/wordpress/php.ini`
- `config/mysql/my.cnf`
- `secrets/` (placeholders + instructions)
- `.gitignore`

## Quick start

1) Create the environment file:

```bash
cp .env.example .env
```

2) Create secrets (required):

```bash
mkdir -p secrets
# Use strong random values (examples below use openssl)
openssl rand -base64 32 > secrets/wordpress_db_password.txt
openssl rand -base64 32 > secrets/mysql_root_password.txt
```

3) Start:

```bash
docker compose up -d
docker compose ps
```

4) Open WordPress:

- http://localhost:${WORDPRESS_PORT} (default: http://localhost:8080)

## Operational notes (read this or regret it)

### 1) Backups are not optional
You need BOTH:
- DB backups (logical dumps)
- WordPress content backups (the `wordpress_data` volume)

Example DB dump:

```bash
docker exec -i wordpress-mysql sh -lc 'exec mysqldump -uroot -p"$(cat /run/secrets/mysql_root_password)" --single-transaction --routines --events ${WORDPRESS_DB_NAME}' \
  > backup-wordpress-db.sql
```

### 2) Do not expose MySQL publicly
The DB service is intentionally not published to the host. If you must access it from the host, bind to localhost only (see commented `ports:` block in `docker-compose.yml`).

### 3) Stop using `:latest`
Images are pinned on purpose. You upgrade intentionally, not accidentally.

### 4) Reverse proxy + TLS
If this is a real store, run WordPress behind a reverse proxy (Caddy / Nginx / Traefik) with TLS and basic WAF/rate limiting. Otherwise you are depending on luck.

## Repo layout

```text
.
├── docker-compose.yml
├── .env.example
├── config/
│   ├── wordpress/
│   │   └── php.ini
│   └── mysql/
│       └── my.cnf
└── secrets/
    └── README.txt
```

## Commands

```bash
# Start
docker compose up -d

# Logs
docker compose logs -f

# Stop
docker compose down

# Stop + remove volumes (THIS DELETES DATA)
docker compose down -v
```
