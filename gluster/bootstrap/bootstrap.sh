#!/usr/bin/env bash
set -euo pipefail

: "${GLUSTER_PEERS:?Set GLUSTER_PEERS (space-separated)}"
: "${GLUSTER_VOLUME_NAME:?Set GLUSTER_VOLUME_NAME}"
: "${GLUSTER_VOLUME_TYPE:?Set GLUSTER_VOLUME_TYPE}"
: "${GLUSTER_BRICKS:?Set GLUSTER_BRICKS}"

REPLICA_COUNT="${GLUSTER_REPLICA_COUNT:-3}"
AUTH_ALLOW="${GLUSTER_AUTH_ALLOW:-}"

echo "[bootstrap] Waiting for glusterd..."
for i in {1..30}; do
  if gluster --mode=script peer status >/dev/null 2>&1; then break; fi
  sleep 2
done

echo "[bootstrap] Probing peers: ${GLUSTER_PEERS}"
for p in ${GLUSTER_PEERS}; do
  gluster --mode=script peer probe "${p}" || true
done

echo "[bootstrap] Current peer status:"
gluster --mode=script peer status || true

if gluster --mode=script volume info "${GLUSTER_VOLUME_NAME}" >/dev/null 2>&1; then
  echo "[bootstrap] Volume ${GLUSTER_VOLUME_NAME} already exists. Nothing to do."
  exit 0
fi

case "${GLUSTER_VOLUME_TYPE}" in
  replica)
    echo "[bootstrap] Creating replica volume (${REPLICA_COUNT}): ${GLUSTER_VOLUME_NAME}"
    gluster --mode=script volume create "${GLUSTER_VOLUME_NAME}" replica "${REPLICA_COUNT}" ${GLUSTER_BRICKS} force
    ;;
  distribute)
    echo "[bootstrap] Creating distributed volume: ${GLUSTER_VOLUME_NAME}"
    gluster --mode=script volume create "${GLUSTER_VOLUME_NAME}" ${GLUSTER_BRICKS} force
    ;;
  disperse)
    echo "[bootstrap] Disperse not wired in this template; implement your disperse/redundancy args explicitly."
    exit 2
    ;;
  *)
    echo "[bootstrap] Unknown GLUSTER_VOLUME_TYPE=${GLUSTER_VOLUME_TYPE}"
    exit 2
    ;;
esac

gluster --mode=script volume start "${GLUSTER_VOLUME_NAME}"

if [[ -n "${AUTH_ALLOW}" ]]; then
  echo "[bootstrap] Setting auth.allow=${AUTH_ALLOW}"
  gluster --mode=script volume set "${GLUSTER_VOLUME_NAME}" auth.allow "${AUTH_ALLOW}"
fi

echo "[bootstrap] Done. Volume info:"
gluster --mode=script volume info "${GLUSTER_VOLUME_NAME}"
