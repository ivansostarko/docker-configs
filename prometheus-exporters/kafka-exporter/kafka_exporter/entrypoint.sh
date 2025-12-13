#!/bin/sh
set -eu

# Build repeated --kafka.server flags from comma-separated env
KAFKA_SERVER_ARGS=""
IFS=','
for b in ${KAFKA_BROKERS:-kafka:9092}; do
  b_trimmed="$(echo "$b" | xargs)"
  [ -n "$b_trimmed" ] && KAFKA_SERVER_ARGS="$KAFKA_SERVER_ARGS --kafka.server=$b_trimmed"
done
unset IFS

# Optional SASL password from Docker secret
SASL_PASSWORD=""
if [ -f /run/secrets/kafka_sasl_password ]; then
  SASL_PASSWORD="$(cat /run/secrets/kafka_sasl_password)"
fi

# Core args
ARGS="
  $KAFKA_SERVER_ARGS
  --kafka.version=${KAFKA_VERSION:-2.0.0}
  --kafka.labels=${KAFKA_LABELS:-kafka}
  --web.listen-address=:9308
  --web.telemetry-path=/metrics
  --topic.filter=${TOPIC_FILTER:-.*}
  --topic.exclude=${TOPIC_EXCLUDE:-^$}
  --group.filter=${GROUP_FILTER:-.*}
  --group.exclude=${GROUP_EXCLUDE:-^$}
  --refresh.metadata=${REFRESH_METADATA:-30s}
  --offset.show-all=${OFFSET_SHOW_ALL:-true}
  --concurrent.enable=${CONCURRENT_ENABLE:-false}
  --topic.workers=${TOPIC_WORKERS:-100}
"

# SASL
if [ "${SASL_ENABLED:-false}" = "true" ]; then
  ARGS="$ARGS
    --sasl.enabled=true
    --sasl.username=${SASL_USERNAME:-}
    --sasl.password=$SASL_PASSWORD
    --sasl.mechanism=${SASL_MECHANISM:-plain}
    --sasl.handshake=${SASL_HANDSHAKE:-true}
  "
fi

# TLS to Kafka
if [ "${TLS_ENABLED:-false}" = "true" ]; then
  ARGS="$ARGS
    --tls.enabled=true
    --tls.server-name=${TLS_SERVER_NAME:-}
    --tls.insecure-skip-tls-verify=${TLS_INSECURE_SKIP_VERIFY:-false}
    --tls.ca-file=${TLS_CA_FILE:-}
    --tls.cert-file=${TLS_CERT_FILE:-}
    --tls.key-file=${TLS_KEY_FILE:-}
  "
fi

exec /usr/local/bin/kafka_exporter $ARGS
