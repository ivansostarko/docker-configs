# Adds minimal troubleshooting tools needed for healthchecks and ops.
# Official image keeps HAProxy itself up-to-date.
FROM haproxy:2.9-alpine

RUN set -eux; \
    apk add --no-cache \
      bash \
      ca-certificates \
      curl \
      openssl \
      socat \
      tzdata \
      gettext \
    ; \
    addgroup -g 99 -S haproxy || true; \
    adduser  -u 99 -S -D -H -G haproxy haproxy || true; \
    mkdir -p /var/run/haproxy /var/lib/haproxy; \
    chown -R 99:99 /var/run/haproxy /var/lib/haproxy

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["haproxy", "-W", "-db", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
