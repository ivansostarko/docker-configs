# Secrets directory

Do not commit real secret files.

Create these files before running the stack:

- `mysql_root_password.txt`
- `mysql_app_password.txt`
- `mysql_exporter_password.txt`
- `grafana_admin_password.txt` (only needed if you enable the `monitoring` profile)

Use the `*.example` files as templates.
