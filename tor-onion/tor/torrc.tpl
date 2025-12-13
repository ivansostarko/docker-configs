RunAsDaemon 0
DataDirectory /var/lib/tor

# Do NOT run a SOCKS proxy in this stack.
SocksPort 0

Log notice stdout

# ----- Onion service: web -----
HiddenServiceDir /var/lib/tor/hs_web
HiddenServicePort 80 ${HS_WEB_TARGET}

# ----- Add more onion domains/services by duplicating blocks -----
# HiddenServiceDir /var/lib/tor/hs_api
# HiddenServicePort 80 api:8080

# ----- Prometheus metrics (internal-only) -----
MetricsPort 0.0.0.0:${TOR_METRICS_PORT}
MetricsPortPolicy accept ${PROMETHEUS_STATIC_IP}
MetricsPortPolicy reject *
