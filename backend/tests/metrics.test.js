// /metrics runs the Atlas-backed gauges' queries; stub them so the scrape
// answers immediately without a database.
jest.mock('../models/Order', () => ({
  countDocuments: jest.fn().mockResolvedValue(0),
  aggregate: jest.fn().mockResolvedValue([]),
  schema: { path: () => ({ enumValues: ['Placed'] }) },
}));
jest.mock('../models/PaymentAttempt', () => ({
  countDocuments: jest.fn().mockResolvedValue(0),
}));

const request = require('supertest');
const app = require('../app');
const { client } = require('../metrics/metrics');

// The dashboard groups every HTTP panel by these labels, so these tests pin
// the label values themselves rather than just "a metric was recorded".
const routeCounts = async () => {
  const metric = await client.register.getSingleMetric('shopnest_http_requests_total').get();
  const counts = {};
  for (const { labels, value } of metric.values) {
    counts[`${labels.method} ${labels.route} ${labels.status_code}`] = value;
  }
  return counts;
};

describe('HTTP request metrics', () => {
  beforeEach(() => client.register.resetMetrics());

  it('labels a sub-router route with its mount prefix, not just "/"', async () => {
    // No token, so `protect` answers 401 without touching the database.
    await request(app).get('/api/orders');
    await request(app).get('/api/orders/myorders');

    const counts = await routeCounts();
    expect(counts['GET /api/orders 401']).toBe(1);
    expect(counts['GET /api/orders/myorders 401']).toBe(1);
    expect(Object.keys(counts).some((k) => k.startsWith('GET / '))).toBe(false);
  });

  it('keeps the route template for parameterised paths', async () => {
    await request(app).put('/api/orders/abc123/cancel');

    expect((await routeCounts())['PUT /api/orders/:id/cancel 401']).toBe(1);
  });

  it('groups unknown paths as "unmatched" instead of one series per URL', async () => {
    await request(app).get('/wp-login.php');
    await request(app).get('/some/random/path');

    const counts = await routeCounts();
    expect(Object.keys(counts)).toEqual(['GET unmatched 404']);
    expect(counts['GET unmatched 404']).toBe(2);
  });

  it('does not count health probes or metric scrapes as traffic', async () => {
    await request(app).get('/health');
    await request(app).get('/metrics');

    expect(await routeCounts()).toEqual({});
  });
});
