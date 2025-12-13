# syntax=docker/dockerfile:1.6

ARG EXPORTER_UPSTREAM_IMAGE
FROM ${EXPORTER_UPSTREAM_IMAGE} AS exporter

FROM alpine:3.20
RUN apk add --no-cache ca-certificates curl && update-ca-certificates

# Copy everything from upstream stage; then detect and copy an executable.
COPY --from=exporter / /opt/exporter/

RUN set -eux;     bin="$(find /opt/exporter -maxdepth 3 -type f -perm /111 | head -n 1)";     test -n "$bin";     cp "$bin" /usr/local/bin/kibana-exporter;     chmod +x /usr/local/bin/kibana-exporter

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# nonroot
USER 65532:65532
EXPOSE 9684
ENTRYPOINT ["/entrypoint.sh"]
