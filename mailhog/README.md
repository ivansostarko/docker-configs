# MailHog Docker Compose Bundle

This bundle provides a hardened, more operationally complete MailHog service definition for dev/test SMTP capture, including:
- A MailHog service with sensible defaults and security posture (bind to localhost by default)
- Optional outgoing SMTP “Release” configuration
- Optional HTTP Basic Auth via a Docker secret
- Healthcheck
- Compose-level `networks`, `volumes`, `configs`, `secrets`
- Example `.env`

## What you get

```
.
├── docker-compose.mailhog.yml
├── .env.example
├── config
│   └── mailhog
│       └── outgoing-smtp.json
└── secrets
    └── mailhog
        └── auth.txt
```

## Quick start

1. Copy the environment file:

```bash
cp .env.example .env
```

2. (Optional) Configure outgoing SMTP servers for the “Release” action:

Edit:
- `config/mailhog/outgoing-smtp.json`

3. (Optional) Protect the UI and API with HTTP Basic Auth:

- Put `username:bcrypt_hash` into:
  - `secrets/mailhog/auth.txt`

**Important:** This protects **HTTP (UI + API)** only. SMTP remains open to the network you expose it to.

4. Start:

```bash
docker compose -f docker-compose.mailhog.yml up -d
```

## Access

- SMTP: `127.0.0.1:${MAILHOG_SMTP_PORT:-1025}`
- UI/API: `http://127.0.0.1:${MAILHOG_UI_PORT:-8025}`

## Operational notes (do not ignore)

- **Do not expose MailHog publicly.** It is a dev tool, not a secure mail gateway.
- If you need LAN access, remove `127.0.0.1:` from the `ports:` mappings and put it behind a reverse proxy + auth.
- If you need persistence, set `MAILHOG_STORAGE=maildir` and MailHog will store data under the `mailhog_maildir` volume.
- “Metrics”: MailHog does not provide a native Prometheus `/metrics` endpoint in this bundle. Monitor it with blackbox checks against HTTP and SMTP instead.

## Files

### `docker-compose.mailhog.yml`
Contains the MailHog service plus required `networks`, `volumes`, `configs`, and `secrets`.

### `config/mailhog/outgoing-smtp.json`
Outgoing SMTP targets used by the UI “Release” functionality.

### `secrets/mailhog/auth.txt`
HTTP Basic Auth file (one line per user): `username:bcrypt_hash`

### `.env.example`
Minimal environment variables for ports, hostname, and storage selection.
