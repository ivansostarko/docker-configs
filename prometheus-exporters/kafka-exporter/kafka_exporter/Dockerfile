# Grab the exporter binary from the upstream image
FROM danielqsj/kafka-exporter:v1.9.0 AS exporter

# Minimal runtime with tools for healthcheck + secrets-friendly startup
FROM alpine:3.20

RUN adduser -D -u 10001 exporter \
  && apk add --no-cache ca-certificates curl

COPY --from=exporter /bin/kafka_exporter /usr/local/bin/kafka_exporter
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

USER 10001:10001
EXPOSE 9308
ENTRYPOINT ["/entrypoint.sh"]
