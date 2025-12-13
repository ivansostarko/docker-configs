FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl \
      glusterfs-client \
    && rm -rf /var/lib/apt/lists/*

# Install exporter (script installs the binary on the image)
# Note: If your environment blocks outbound GitHub during builds, this will fail.
RUN curl -fsSL https://github.com/kadalu/gluster-metrics-exporter/releases/latest/download/install.sh \
    | bash -x

# Ensure binary is in PATH (script typically installs into /usr/sbin/)
RUN test -x /usr/sbin/gluster-metrics-exporter || test -x /usr/local/bin/gluster-metrics-exporter

EXPOSE 9713
ENTRYPOINT ["/usr/sbin/gluster-metrics-exporter"]
