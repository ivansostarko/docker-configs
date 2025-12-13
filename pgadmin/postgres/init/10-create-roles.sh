#!/bin/sh
set -eu

# NOTE: These init scripts only run when the data directory is empty
# (i.e., the first time the postgres_data volume is created).

PGADMIN_DB_USER="${PGADMIN_DB_USER:-pgadmin}"
PGADMIN_DB_PASSWORD="$(cat /run/secrets/pgadmin_db_password)"

EXPORTER_USER="${EXPORTER_USER:-postgres_exporter}"
EXPORTER_PASSWORD="$(cat /run/secrets/postgres_exporter_password)"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${PGADMIN_DB_USER}') THEN
    CREATE ROLE ${PGADMIN_DB_USER} LOGIN PASSWORD '${PGADMIN_DB_PASSWORD}';
  END IF;
END
\$\$;

GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO ${PGADMIN_DB_USER};
GRANT USAGE ON SCHEMA public TO ${PGADMIN_DB_USER};

-- CRUD on public schema tables (adjust to your policy; this is convenient but not strict)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${PGADMIN_DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${PGADMIN_DB_USER};

-- Monitoring without superuser
GRANT pg_monitor TO ${PGADMIN_DB_USER};

-- Exporter role for Prometheus metrics
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${EXPORTER_USER}') THEN
    CREATE ROLE ${EXPORTER_USER} LOGIN PASSWORD '${EXPORTER_PASSWORD}';
  ELSE
    ALTER ROLE ${EXPORTER_USER} WITH PASSWORD '${EXPORTER_PASSWORD}';
  END IF;
END
\$\$;

GRANT pg_monitor TO ${EXPORTER_USER};

-- Enable pg_stat_statements in the target DB (requires shared_preload_libraries and restart; safe if already enabled)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
SQL
