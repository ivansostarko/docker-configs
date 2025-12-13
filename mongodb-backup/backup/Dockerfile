FROM mongo:7.0

RUN apt-get update && apt-get install -y --no-install-recommends \
      cron ca-certificates curl jq openssl wget \
      python3 python3-pip \
    && pip3 install --no-cache-dir awscli \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY backup.sh /usr/local/bin/backup.sh
COPY restore.sh /usr/local/bin/restore.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh

RUN chmod +x /usr/local/bin/*.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
