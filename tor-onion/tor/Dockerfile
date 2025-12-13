FROM debian:12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates gnupg wget procps gettext-base \
 && rm -rf /var/lib/apt/lists/*

# Add Tor Project repo key + repository
RUN wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc \
    | gpg --dearmor -o /usr/share/keyrings/tor-archive-keyring.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org bookworm main" \
    > /etc/apt/sources.list.d/tor.list

RUN apt-get update \
 && apt-get install -y --no-install-recommends tor \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/tor /run/tor \
 && chown -R debian-tor:debian-tor /var/lib/tor /run/tor \
 && chmod 700 /var/lib/tor

USER debian-tor
VOLUME ["/var/lib/tor"]

ENTRYPOINT ["/entrypoint.sh"]
