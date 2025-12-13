#!/usr/bin/env bash
set -euo pipefail

RS_NAME="${MONGO_REPLICA_SET:-rs0}"
ROOT_USER="${MONGO_ROOT_USERNAME:-root}"
ROOT_PWD="$(cat /run/secrets/mongo_root_password)"
APP_DB="${MONGO_APP_DB:-appdb}"
APP_USER="${MONGO_APP_USERNAME:-appuser}"
APP_PWD="$(cat /run/secrets/mongo_app_password)"
EXP_USER="${MONGO_EXPORTER_USERNAME:-exporter}"
EXP_PWD="$(cat /run/secrets/mongo_exporter_password)"

PRIMARY_HOST="mongo1:27017"
MEMBERS=("mongo1:27017" "mongo2:27017" "mongo3:27017")

mongo_eval() {
  mongosh --quiet --host "${PRIMARY_HOST}"     -u "${ROOT_USER}" -p "${ROOT_PWD}" --authenticationDatabase "admin"     --eval "$1"
}

echo "[mongo-init] Waiting for ${PRIMARY_HOST} to accept authenticated connections..."
until mongo_eval "db.adminCommand({ ping: 1 }).ok" | grep -q "1"; do
  sleep 2
done

echo "[mongo-init] Checking replica set status..."
if mongo_eval "try { rs.status().ok } catch(e) { 0 }" | grep -q "1"; then
  echo "[mongo-init] Replica set already initiated."
else
  echo "[mongo-init] Initiating replica set: ${RS_NAME}"
  mongo_eval "rs.initiate({ _id: '${RS_NAME}', members: [
    { _id: 0, host: '${MEMBERS[0]}' },
    { _id: 1, host: '${MEMBERS[1]}' },
    { _id: 2, host: '${MEMBERS[2]}' }
  ]})"
fi

echo "[mongo-init] Waiting for a PRIMARY to be elected..."
until mongo_eval "db.hello().isWritablePrimary ? 1 : 0" | grep -q "1"; do
  sleep 2
done

echo "[mongo-init] Ensuring application user exists on db='${APP_DB}'..."
mongo_eval "
  const appDb = db.getSiblingDB('${APP_DB}');
  const user = appDb.getUser('${APP_USER}');
  if (!user) {
    appDb.createUser({
      user: '${APP_USER}',
      pwd:  '${APP_PWD}',
      roles: [ { role: 'readWrite', db: '${APP_DB}' } ]
    });
    print('created app user');
  } else {
    print('app user exists');
  }
"

echo "[mongo-init] Ensuring exporter user exists (clusterMonitor + read on local)..."
mongo_eval "
  const adminDb = db.getSiblingDB('admin');
  const user = adminDb.getUser('${EXP_USER}');
  if (!user) {
    adminDb.createUser({
      user: '${EXP_USER}',
      pwd:  '${EXP_PWD}',
      roles: [
        { role: 'clusterMonitor', db: 'admin' },
        { role: 'read', db: 'local' }
      ]
    });
    print('created exporter user');
  } else {
    print('exporter user exists');
  }
"

echo "[mongo-init] Done."
