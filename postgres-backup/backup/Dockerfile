FROM postgres:17-alpine

# curl: pushgateway metrics
# bash/coreutils: scripting + date/stat
# ca-certificates: TLS
RUN apk add --no-cache bash curl coreutils ca-certificates tzdata

# supercronic: lightweight cron runner
ADD https://github.com/aptible/supercronic/releases/download/v0.2.29/supercronic-linux-amd64 /usr/local/bin/supercronic
RUN chmod +x /usr/local/bin/supercronic

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY backup.sh /usr/local/bin/backup.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh

RUN chmod +x /usr/local/bin/*.sh

WORKDIR /state

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
