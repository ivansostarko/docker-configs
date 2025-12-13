# MySQL Primary/Replica Replication (Docker Compose)

This stack provisions:
- 1 MySQL **primary** (`mysql-primary`)
- 1 MySQL **replica** (`mysql-replica1`)
- A one-shot **replication configurer** that sets up GTID auto-position (`replica1-configurer`)
- **mysqld_exporter** for each MySQL node + **Prometheus** + **Grafana**

## What you get (and what you do not)

You get working asynchronous replication with sane defaults and metrics.  
You do **not** get automatic failover or split-brain protection; if you want that, add MySQL InnoDB Cluster, Orchestrator, ProxySQL, or similar. Replication without a failover plan is a liability, not an HA strategy.

## Folder structure

- `compose.yaml` — main stack
- `config/mysql/*.cnf` — MySQL config files (base, primary, replica)
- `initdb/primary/01-primary-init.sh` — creates replication + exporter users on first primary init
- `scripts/configure-replication.sh` — idempotently configures replica to replicate from primary (GTID)
- `monitoring/prometheus/prometheus.yml` — Prometheus scrape config
- `secrets/*.txt` — local Docker secrets (DO NOT commit real credentials)

## First-time setup

1) Copy env file:
```bash
cp .env.example .env
```

2) Create secrets (edit the values):
```bash
mkdir -p secrets
printf '%s' 'CHANGE_ME_ROOT'      > secrets/mysql_root_password.txt
printf '%s' 'CHANGE_ME_APP'       > secrets/mysql_app_password.txt
printf '%s' 'CHANGE_ME_REPL'      > secrets/mysql_repl_password.txt
printf '%s' 'CHANGE_ME_EXPORTER'  > secrets/mysql_exporter_password.txt
printf '%s' 'CHANGE_ME_GRAFANA'   > secrets/grafana_admin_password.txt
```

3) Create exporter DSNs (must match the `exporter` user created by `01-primary-init.sh`):
```bash
# DSN format: user:password@(host:port)/
printf '%s' 'exporter:CHANGE_ME_EXPORTER@(mysql-primary:3306)/'  > secrets/mysql_exporter_primary_dsn.txt
printf '%s' 'exporter:CHANGE_ME_EXPORTER@(mysql-replica1:3306)/' > secrets/mysql_exporter_replica1_dsn.txt
```

4) Start:
```bash
docker compose up -d
```

## Validate replication

Check replica status:
```bash
docker compose exec -T mysql-replica1 mysql -uroot -p"$(cat secrets/mysql_root_password.txt)" -e 'SHOW REPLICA STATUS\G'
```

Look for:
- `Replica_IO_Running: Yes`
- `Replica_SQL_Running: Yes`
- `Seconds_Behind_Source` (not NULL)

## Common operational notes (read this; it will save you pain)

- **Writes must go to primary only.** If your app can write to the replica, your architecture is broken.
- **Backups:** take them from the replica to reduce primary load; but validate lag first.
- **Promotion / failover:** if primary dies, you need a playbook:
  - stop writes
  - verify replica caught up
  - disable `super_read_only` on replica
  - repoint clients
  - rebuild former primary as a replica
- **Durability vs performance:** this example uses `sync_binlog=1` and `innodb_flush_log_at_trx_commit=1` on primary for durability. If you relax these, you are explicitly accepting possible data loss on crash.

## Endpoints

- MySQL primary: `localhost:${MYSQL_PRIMARY_PORT:-3306}`
- MySQL replica: `localhost:${MYSQL_REPLICA1_PORT:-3307}`
- Prometheus: `http://localhost:${PROMETHEUS_PORT:-9090}`
- Grafana: `http://localhost:${GRAFANA_PORT:-3000}`

## Teardown

Remove containers:
```bash
docker compose down
```

Remove containers + volumes (DESTROYS DATA):
```bash
docker compose down -v
```
