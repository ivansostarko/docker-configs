# phpMyAdmin Docker Compose (Hardened Baseline)

This bundle provides a more production-grade `phpmyadmin` service definition for Docker Compose:
- Pinned image version (no `latest`)
- Uses Docker **secrets** for the database password (avoid plaintext in `.env`)
- Adds `healthcheck`, `configs`, `tmpfs`, and basic container hardening
- Includes optional **cAdvisor** for container-level metrics scraping

## File layout

```
.
├── docker-compose.yml
├── .env.example
├── config/
│   └── phpmyadmin/
│       └── config.user.inc.php
├── secrets/
│   └── mysql_app_password.txt
└── .gitignore
```

## What you must change (non-negotiable)

1. **Do not use MySQL `root` in phpMyAdmin** for anything except break-glass work.
   Create a dedicated DB user (least privilege) and use that as `PMA_USER`.

2. **Do not expose phpMyAdmin to the public internet** without an authentication gate, IP allowlisting, and TLS.
   If you need remote access, prefer VPN or a bastion + reverse proxy with strong auth.

3. Replace placeholders:
   - `.env.example` → copy to `.env` and set real values
   - `secrets/mysql_app_password.txt` → set the real password for `PMA_USER`
   - `PMA_BLOWFISH_SECRET` → set a long random string

## Quick start

1. Create `.env`:
   ```bash
   cp .env.example .env
   ```

2. Set the password secret:
   ```bash
   # Put ONLY the password (single line) in this file
   echo "YOUR_STRONG_PASSWORD" > secrets/mysql_app_password.txt
   chmod 600 secrets/mysql_app_password.txt
   ```

3. Start phpMyAdmin (profiled):
   ```bash
   docker compose --profile admin up -d
   ```

4. Open:
   - http://localhost:${PHPMYADMIN_PORT}

## Notes about `depends_on`

This compose file expects your MySQL service to be named `wordpress-db` and to implement a `healthcheck`.
If your database service does **not** have a healthcheck, `condition: service_healthy` will not behave as intended.

## Metrics (optional)

Start cAdvisor (profiled):
```bash
docker compose --profile metrics up -d
```

Then scrape:
- http://localhost:8080/metrics

This is container-level telemetry. phpMyAdmin does not offer meaningful first-class application metrics.

## Compatibility

- Docker Compose v2+
- Works as part of a larger stack (WordPress/MySQL/etc.) as long as:
  - both services share the same Docker network, and
  - `PMA_HOST` matches the DB service name

Generated on: 2025-12-13
