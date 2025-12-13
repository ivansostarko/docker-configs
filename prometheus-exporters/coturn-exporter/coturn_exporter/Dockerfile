# This is a generic wrapper Dockerfile that:
# - includes wget + envsubst for healthcheck + templating
# - renders a config from a template + Docker secret at container start
#
# IMPORTANT:
# - Replace `COPY coturn_exporter ...` with the correct binary/artifact for your exporter,
#   or paste/merge your existing build steps here.

FROM alpine:3.20

RUN apk add --no-cache ca-certificates wget gettext

# Copy your exporter binary (adjust to your actual build output).
COPY coturn_exporter /usr/local/bin/coturn_exporter

# Ensure config directory exists.
RUN mkdir -p /coturn_exporter_files /etc/coturn_exporter

# Run as non-root
USER 65534:65534

# Render config from template + secret, then start exporter
ENTRYPOINT ["/bin/sh", "-lc", "\
  export COTURN_STATIC_AUTH_SECRET=\"$(cat /run/secrets/coturn_static_auth_secret 2>/dev/null)\" && \
  envsubst < /etc/coturn_exporter/config.yml.tmpl > /coturn_exporter_files/config && \
  exec /usr/local/bin/coturn_exporter \
"]
