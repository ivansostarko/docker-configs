# Wrapper to support Docker secrets + HTTP healthcheck tooling
# Upstream image is often distroless, so we add a tiny Alpine runtime.

FROM ghcr.io/lablabs/cloudflare_exporter:0.2.3 as upstream

FROM alpine:3.20

RUN adduser -D -u 65532 exporter \
  && apk add --no-cache ca-certificates wget

# ko-built images commonly place the binary in /ko-app/
COPY --from=upstream /ko-app/cloudflare_exporter /usr/local/bin/cloudflare_exporter
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER 65532:65532
ENTRYPOINT ["/entrypoint.sh"]
