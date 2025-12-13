'use strict';

require('dotenv').config();

const express = require('express');
const helmet = require('helmet');
const morgan = require('morgan');
const cors = require('cors');
const { client, metricsMiddleware } = require('./metrics');

const app = express();

const PORT = parseInt(process.env.PORT || '3000', 10);
const NODE_ENV = process.env.NODE_ENV || 'production';

// Basic middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(morgan(NODE_ENV === 'production' ? 'combined' : 'dev'));

// Metrics
app.use(metricsMiddleware);

// Health
app.get('/health', async (req, res) => {
  // Keep it simple: container-level health.
  // If you want deeper checks, test DB/Redis connectivity here.
  res.status(200).json({ status: 'ok' });
});

// Sample route
app.get('/', (req, res) => {
  res.json({ service: 'express-api', status: 'running' });
});

// Prometheus scrape endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

// Graceful shutdown
const server = app.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`Express API listening on :${PORT}`);
});

function shutdown(signal) {
  // eslint-disable-next-line no-console
  console.log(`Received ${signal}. Shutting down...`);
  server.close(() => process.exit(0));

  // Force exit if hung
  setTimeout(() => process.exit(1), 10_000).unref();
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
