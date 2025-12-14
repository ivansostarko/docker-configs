#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP_SERVERS="${BOOTSTRAP_SERVERS:-kafka1:29092,kafka2:29092,kafka3:29092}"
TOPICS="${TOPICS:-}"
PARTITIONS="${TOPIC_PARTITIONS:-6}"
RF="${TOPIC_RF:-3}"

if [[ -z "$TOPICS" ]]; then
  echo "[kafka-init] No TOPICS set; exiting."
  exit 0
fi

IFS=',' read -ra TOPIC_ARR <<< "$TOPICS"

echo "[kafka-init] Bootstrap: $BOOTSTRAP_SERVERS"
echo "[kafka-init] Partitions: $PARTITIONS  Replication: $RF"
echo "[kafka-init] Topics: ${TOPIC_ARR[*]}"

for t in "${TOPIC_ARR[@]}"; do
  topic="$(echo "$t" | xargs)"
  if [[ -z "$topic" ]]; then
    continue
  fi

  # Check topic existence
  if kafka-topics --bootstrap-server "$BOOTSTRAP_SERVERS" --list | grep -qx "$topic"; then
    echo "[kafka-init] Topic exists: $topic (skipping)"
    continue
  fi

  echo "[kafka-init] Creating topic: $topic"
  kafka-topics     --bootstrap-server "$BOOTSTRAP_SERVERS"     --create     --topic "$topic"     --partitions "$PARTITIONS"     --replication-factor "$RF"

done

echo "[kafka-init] Done."
