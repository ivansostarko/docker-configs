const client = require('prom-client');

// Default node metrics
client.collectDefaultMetrics({
  prefix: 'node_',
  // collectDefaultMetrics uses seconds
});

// HTTP metrics
const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status']
});

const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5]
});

function metricsMiddleware(req, res, next) {
  const start = process.hrtime.bigint();

  res.on('finish', () => {
    const route = (req.route && req.route.path) ? req.route.path : (req.baseUrl || req.path || 'unknown');
    const status = String(res.statusCode);
    const method = req.method;

    httpRequestsTotal.labels(method, route, status).inc();

    const end = process.hrtime.bigint();
    const seconds = Number(end - start) / 1e9;
    httpRequestDuration.labels(method, route, status).observe(seconds);
  });

  next();
}

module.exports = {
  client,
  metricsMiddleware
};
