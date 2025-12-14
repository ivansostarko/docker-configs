# Secrets

This stack uses **file-based Docker secrets**.

You must create the following files **before** `docker compose up -d`:

- `secrets/mongo_root_password.txt`
- `secrets/mongo_app_password.txt`
- `secrets/mongo_exporter_password.txt`
- `secrets/mongo_express_password.txt` (only needed if you enable the `ui` profile)

Use the provided script:

```bash
bash ./scripts/generate-secrets.sh
```

Do not commit secrets to git.
