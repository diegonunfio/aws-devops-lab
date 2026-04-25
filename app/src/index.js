'use strict';

const express = require('express');
const promClient = require('prom-client');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.APP_VERSION || '1.0.0';
const ENV = process.env.NODE_ENV || 'development';

const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.3, 0.5, 1, 2, 5],
});
register.registerMetric(httpRequestDuration);

const httpRequestTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
});
register.registerMetric(httpRequestTotal);

app.use(express.json());
app.use(morgan(ENV === 'production' ? 'combined' : 'dev'));

app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer();
  res.on('finish', () => {
    const labels = {
      method: req.method,
      route: req.route?.path || req.path,
      status_code: res.statusCode,
    };
    end(labels);
    httpRequestTotal.inc(labels);
  });
  next();
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    version: VERSION,
    environment: ENV,
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

app.get('/ready', (req, res) => {
  res.status(200).json({ status: 'ready' });
});

app.get('/metrics', async (req, res) => {
  res.setHeader('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.get('/api/v1/info', (req, res) => {
  res.json({
    name: 'aws-devops-lab-api',
    version: VERSION,
    environment: ENV,
    author: 'Diego Nunfio',
    repository: 'https://github.com/diegonunfio/aws-devops-lab',
  });
});

app.get('/api/v1/items', (req, res) => {
  const items = [
    { id: 1, name: 'CI/CD Pipeline',        status: 'active' },
    { id: 2, name: 'Docker Container',       status: 'active' },
    { id: 3, name: 'Terraform IaC',          status: 'active' },
    { id: 4, name: 'Kubernetes Deployment',  status: 'active' },
    { id: 5, name: 'Prometheus Monitoring',  status: 'active' },
  ];
  res.json({ items, total: items.length });
});

app.use((req, res) => {
  res.status(404).json({ error: 'Not Found', path: req.path });
});

app.use((err, req, res) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal Server Error' });
});

const server = app.listen(PORT, () => {
  console.log(`[${ENV}] aws-devops-lab-api listening on :${PORT} — v${VERSION}`);
});

const shutdown = (signal) => {
  console.log(`${signal} received — shutting down gracefully`);
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 10_000); 
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT',  () => shutdown('SIGINT'));

module.exports = app; 