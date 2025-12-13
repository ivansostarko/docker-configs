# Docker Compose configurations

A small, opinionated collection of Docker and Docker Compose configurations intended to be copied into projects (or used as a starting point) for local development environments.

## What this repo is:


### Apps
- [Wordpress](/wordpress/README.md)

### Web servers
- [Apache](/apache/README.md)
- [Nginx](/nginx/README.md)
- [Nginx Proxy](/nginx-proxy/README.md)


### Databases
- [MySql](/mysql/README.md)
- [Postgres](/postgres/README.md)
- [MariaDB](/mariadb/README.md)
- [MongoDB](/mongodb/README.md)
- [Redis](/redis/README.md)

### Status Page
- [CachetHq](/cachethq/README.md)


### Admin Tools
- [Portainer](/portainer/README.md)
- [PhpMyAdmin](/phpmyadmin/README.md)
- [Adminer](/adminer/README.md)
- Kafka Admin
- Redis Admin
- Postgres Admin
- RabbitMq Admin


### Collaboration Tools
- [Mattermost](/mattermost/README.md)

### Error Management
- [Glitchtip](/glitchtip/README.md)


### Monitoring
- [Prometheus](/prometheus/README.md)
- [Grafana](/grafana/README.md)
- [Alert Manager](/alert-manager/README.md)


### Networks and VPN
- [CoreDNS](/coredns/README.md)

### Email
- [Postal](/postal/README.md)
- [Mailhog](/mailhog/README.md)

### AI
- [Ollama](/ollama/README.md)
- [Open AI Web](/open-ai-web/README.md)

### Automation Tools
- [N8N](/n8n/README.md)

### Storage
- [Minio](/minio/README.md)

### queue
- [Kafka](/kafka/README.md)
- [Beanstalkd](/beanstalkd/README.md)
- [RabbitMq](/rabbitmq/README.md)

### Security
- [Infisical](/infisical/README.md)

### Backup
- [MySql Backup](/mysql-backup/README.md)
- [Postgres Backup](/postgres-backup/README.md)
- [MongoDB Backup](/mongodb-backup/README.md)

### Metrics / Prometheus Exporters
- [Coturn Exporter](/prometheus-exporters/coturn-exporter/README.md)
- [MySql Exporter](/prometheus-exporters/mysqld-exporter/README.md)
- [Node Exporter](/prometheus-exporters/node-exporter/README.md)
- [Ollama Exporter](/prometheus-exporters/ollama-exporter/README.md)
- [Postgres Exporter](/prometheus-exporters/postgres-exporter/README.md)
- [Wireguard Exporter](/prometheus-exporters/wireguard-exporter/README.md)
- [Cloudflare Exporter](/prometheus-exporters/wireguard-exporter/README.md)
- [Gluster Exporter](/prometheus-exporters/gluster-exporter/README.md)
- [Elasticsearch Exporter](/prometheus-exporters/elasticsearch-exporter/README.md)
- [Cloudflare Exporter](/prometheus-exporters/cloudflare-exporter/README.md)
- [Redis Exporter](/prometheus-exporters/redis-exporter/README.md)
- [Rabbitmq Exporter](/prometheus-exporters/rabbitmq-exporter/README.md)
- [Nginx Exporter](/prometheus-exporters/nginx-exporter/README.md)
- [Mysqld Exporter](/prometheus-exporters/mysqld-exporter/README.md)
- [MongoDB Exporter](/prometheus-exporters/mongodb-exporter/README.md)
- [Logstash Exporter](/prometheus-exporters/logstash-exporter/README.md)
- [Kibana Exporter](/prometheus-exporters/kibana-exporter/README.md)
- [Kafka Exporter](/prometheus-exporters/kafka-exporter/README.md)
- [Certbot Exporter](/prometheus-exporters/certbot-exporter/README.md)
- [Apache Exporter](/prometheus-exporters/apache-exporter/README.md)


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
