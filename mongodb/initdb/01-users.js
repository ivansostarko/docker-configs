// Runs only on first container initialization (when /data/db is empty).
// Creates:
// - Application DB user (readWrite on app DB)
// - Metrics/exporter user (clusterMonitor + read on local)

function readFile(path) {
  return cat(path).trim();
}

const appDb = process.env.MONGO_APP_DB || "appdb";
const appUser = process.env.MONGO_APP_USER || "appuser";
const appPassFile = process.env.MONGO_APP_PASSWORD_FILE || "/run/secrets/mongo_app_password";

const exporterUser = process.env.MONGO_EXPORTER_USER || "mongometrics";
const exporterPassFile =
  process.env.MONGO_EXPORTER_PASSWORD_FILE || "/run/secrets/mongo_exporter_password";

const appPass = readFile(appPassFile);
const exporterPass = readFile(exporterPassFile);

const app = db.getSiblingDB(appDb);
app.createUser({
  user: appUser,
  pwd: appPass,
  roles: [{ role: "readWrite", db: appDb }],
});

const admin = db.getSiblingDB("admin");
admin.createUser({
  user: exporterUser,
  pwd: exporterPass,
  roles: [
    { role: "clusterMonitor", db: "admin" },
    { role: "read", db: "local" },
  ],
});

print("MongoDB users created: app + exporter");
