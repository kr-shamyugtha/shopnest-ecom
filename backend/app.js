const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');

const {
  client,
  httpRequestsTotal,
  httpRequestDuration
} = require('./metrics/metrics');

dotenv.config();

const app = express();

app.use(cors({
  origin: [
    'http://localhost:3000',
    'http://127.0.0.1:3000',
    process.env.FRONTEND_URL
  ].filter(Boolean),
  credentials: true
}));

app.use(express.json());

// Endpoints that exist for the platform, not for users. Kubernetes probes
// /health every few seconds and Prometheus scrapes /metrics every 15s; counted
// as traffic they added ~0.2 req/s per pod with nobody on the site, inflating
// the request rate, diluting the error percentage, and (since every /metrics
// call runs three Atlas queries) dominating the latency percentiles.
const UNMETERED_PATHS = new Set(['/health', '/metrics']);

app.use((req, res, next) => {
  if (UNMETERED_PATHS.has(req.path)) {
    return next();
  }

  const start = process.hrtime();

  res.on('finish', () => {
    const diff = process.hrtime(start);
    const durationSeconds = diff[0] + diff[1] / 1e9;

    // The route TEMPLATE, mount prefix included. req.route.path alone is the
    // path inside the sub-router, so /api/products, /api/orders and every
    // other router's index all reported as "/" and were merged on the
    // dashboard. Requests that matched no route are grouped as "unmatched"
    // rather than labelled with their raw path, so scanners probing random
    // URLs can't create a new series per URL.
    const route = req.route
      ? (`${req.baseUrl}${req.route.path}`.replace(/\/$/, '') || '/')
      : 'unmatched';

    httpRequestsTotal.inc({
      method: req.method,
      route,
      status_code: res.statusCode
    });

    httpRequestDuration.observe(
      {
        method: req.method,
        route,
        status_code: res.statusCode
      },
      durationSeconds
    );
  });

  next();
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', client.register.contentType);
    res.end(await client.register.metrics());
  } catch (error) {
    res.status(500).end(error.message);
  }
});

app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/products', require('./routes/productRoutes'));
app.use('/api/orders', require('./routes/orderRoutes'));
app.use('/api/payment', require('./routes/paymentRoutes'));
app.use('/api/analytics', require('./routes/analyticsRoutes'));

if (process.env.NODE_ENV === 'production') {
  app.get('/', (req, res) => {
    res.send('ShopNest API is running in Production mode...');
  });
} else {
  app.get('/', (req, res) => {
    res.send('ShopNest API is running in Development mode...');
  });
}

module.exports = app;