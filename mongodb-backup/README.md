# MongoDB Backup (Docker Compose)

A production-oriented MongoDB backup stack that runs scheduled `mongodump` jobs, applies retention, and can optionally:
- Encrypt backups at rest (OpenSSL)
- Upload backups to S3 (AWS S3 or S3-compatible endpoints)
- Emit backup metrics to Prometheus via Pushgateway

## What this is (and what it isn't)

- This container **does not run MongoDB**. It backs up an existing MongoDB instance you already operate.
- This is **file-level backup output from `mongodump`** (logical backup). It is not a snapshot/volume backup.

If you are backing up a replica set under write load, **use `--oplog`** (enabled by default via `USE_OPLOG=true`) or you are accepting inconsistent backups.

## Prerequisites

- Docker + Docker Compose v2
- Network reachability from the backup container to your MongoDB endpoint
- If S3 uploads are enabled: valid credentials and a bucket

## Quick start

1) Create secrets (do not commit them):

```bash
mkdir -p secrets
printf '%s' 'mongodb://user:pass@mongo:27017/admin' > secrets/mongo_uri.txt
printf '%s' 'CHANGEME' > secrets/aws_access_key_id.txt
printf '%s' 'CHANGEME' > secrets/aws_secret_access_key.txt
printf '%s' 'CHANGEME' > secrets/backup_encryption_passphrase.txt
```

2) Configure environment:

```bash
cp .env.example .env
```

3) Start:

```bash
docker compose up -d --build
```

4) Optional metrics (Pushgateway):

```bash
docker compose --profile metrics up -d
```

## Configuration

### Core scheduling / retention

- `BACKUP_CRON`: cron expression (container local time, see `TZ`)
- `RETENTION_DAYS`: local retention period
- `MAX_BACKUP_AGE_HOURS`: healthcheck fails if last successful backup exceeds this age

### Consistency

- `USE_OPLOG=true` enables `mongodump --oplog` (recommended for replica sets)

### Encryption (optional)

Set in `.env`:
- `ENCRYPTION_ENABLED=true`
- Provide passphrase in `secrets/backup_encryption_passphrase.txt`

Result: backups are stored as encrypted files on the backup volume. The plaintext archive is removed.

### S3 upload (optional)

Set in `.env`:
- `S3_ENABLED=true`
- `S3_BUCKET=your-bucket`
- Optionally `S3_ENDPOINT=http://minio:9000` for S3-compatible storage

Provide credentials via:
- `secrets/aws_access_key_id.txt`
- `secrets/aws_secret_access_key.txt`

## Volumes

- `mongo_backups`: backup artifacts
- `mongo_backup_state`: state (last success timestamp/file) for healthchecks

## Healthcheck semantics (strict by design)

The service is considered healthy only if:
- `cron` is running
- A successful backup has been recorded
- The last successful backup is not older than `MAX_BACKUP_AGE_HOURS`

If you want “green” even when no backup has run yet, you are optimizing for appearances, not operations.

## Restore drills (do this or stop pretending you have backups)

A backup you have not restored is not a backup.

Example restore into a temporary MongoDB (use an isolated environment):

1) Start a disposable MongoDB somewhere safe.
2) Restore:

```bash
docker exec -it mongo_backup /usr/local/bin/restore.sh   /backups/<your_backup_file>.archive.gz   "mongodb://user:pass@your-restore-mongo:27017/admin"
```

Validate application-level integrity, not just that `mongorestore` completes.

## Notes / security

- Secrets are mounted as Docker secrets (`/run/secrets/*`) rather than env vars.
- The container root filesystem is read-only; required runtime paths are tmpfs mounts.
- Local-only backups are not resilient to host compromise or ransomware. If you care about recovery, use S3 or an immutable/off-host target.

## Troubleshooting

- Check logs:
  ```bash
  docker logs -f mongo_backup
  ```
- Verify last success markers:
  ```bash
  docker exec -it mongo_backup sh -lc 'ls -l /state && cat /state/last_success_epoch /state/last_success_file'
  ```
- Force a manual run:
  ```bash
  docker exec -it mongo_backup /usr/local/bin/backup.sh
  ```

## File layout

- `docker-compose.yml` - stack definition
- `backup/` - backup container image + scripts
- `secrets/` - secret files (do not commit)
