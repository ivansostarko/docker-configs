'use strict';

const fs = require('fs');
const express = require('express');
const client = require('prom-client');

function readSecretFile(path) {
  try {
    if (!path) return null;
    return fs.readFileSync(path, 'utf8').trim();
  } catch (e) {
    return null;
  }
}

const app = express();
const port = Number(process.env.PORT || 3000);

// Metrics
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// Example: demonstrate reading secrets from file paths
// (In real apps, you should use these values for DB auth, JWT signing, etc.)
const jwtSecret = readSecretFile(process.env.JWT_SECRET_FILE);
if (!jwtSecret) {
  // Not fatal for the demo app; fatal for real auth systems.
  console.warn('JWT secret not found via JWT_SECRET_FILE; demo continues.');
}

app.get('/healthz', (_req, res) => {
  // Real readiness should validate required dependencies.
  res.status(200).send('ok');
});

app.get('/metrics', async (_req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.get('/', (_req, res) => {
  res.status(200).json({
    service: 'nodejs-stack-sample',
    status: 'running',
    health: '/healthz',
    metrics: '/metrics'
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Listening on :${port}`);
});
