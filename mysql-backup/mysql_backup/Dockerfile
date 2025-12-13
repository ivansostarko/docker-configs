FROM alpine:3.20

# Tools:
# - mysql-client: mysqldump + mysql CLI
# - bash: scripting
# - gzip: compression
# - curl: pushgateway metrics
# - coreutils/findutils: retention logic
RUN apk add --no-cache \
      bash \
      mysql-client \
      gzip \
      tzdata \
      ca-certificates \
      curl \
      coreutils \
      findutils \
      util-linux \
    && update-ca-certificates

# Create directories
RUN mkdir -p /backups /state /etc/mysql-backup

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY backup.sh /usr/local/bin/backup.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
COPY config/backup.defaults.env /etc/mysql-backup/backup.defaults.env

RUN chmod +x /usr/local/bin/*.sh

VOLUME ["/backups", "/state"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
