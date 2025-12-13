#!/usr/bin/env bash
set -euo pipefail

# Runs only on first init of the primary data directory

REPL_USER="${REPL_USER:-repl_user}"
REPL_PASS="$(cat /run/secrets/repl_password)"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-SQL
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${REPL_USER}') THEN
    CREATE ROLE ${REPL_USER} WITH REPLICATION LOGIN PASSWORD '${REPL_PASS}';
  END IF;
END
$$;

-- Helpful privileges for monitoring (optional)
GRANT pg_read_all_stats TO ${POSTGRES_USER};
SQL

# Create replication slot for replica1 (safe if re-run; it won't create duplicates)
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-SQL
SELECT * FROM pg_create_physical_replication_slot('${REPL_SLOT:-replica1_slot}')
WHERE NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name='${REPL_SLOT:-replica1_slot}');
SQL
