/**
 * Create a least-privilege MongoDB user for Prometheus exporter.
 *
 * Run inside mongosh (or via kubectl exec / docker exec):
 *   mongosh --host <mongo-host> -u <admin> -p <password> --authenticationDatabase admin < thisfile.js
 *
 * Replace password below before running.
 */
use admin;

db.createUser({
  user: "exporter",
  pwd: "CHANGE_ME_TO_A_STRONG_PASSWORD",
  roles: [
    { role: "clusterMonitor", db: "admin" },
    { role: "read", db: "local" }
  ]
});
