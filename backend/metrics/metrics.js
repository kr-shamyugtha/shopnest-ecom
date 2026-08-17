const client = require('prom-client');

client.collectDefaultMetrics();

const httpRequestsTotal = new client.Counter({
  name: 'shopnest_http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const httpRequestDuration = new client.Histogram({
  name: 'shopnest_http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.05, 0.1, 0.25, 0.5, 1, 2, 5]
});

const ordersCreatedTotal = new client.Counter({
  name: 'shopnest_orders_created_total',
  help: 'Total number of successfully created orders'
});

const orderCreationFailuresTotal = new client.Counter({
  name: 'shopnest_order_creation_failures_total',
  help: 'Total number of failed order creation attempts'
});

const paymentAttemptsTotal = new client.Counter({
  name: 'shopnest_payment_attempts_total',
  help: 'Total number of payment order creation attempts'
});

const paymentVerificationSuccessTotal = new client.Counter({
  name: 'shopnest_payment_verification_success_total',
  help: 'Total number of successfully verified payments'
});

const paymentVerificationFailuresTotal = new client.Counter({
  name: 'shopnest_payment_verification_failures_total',
  help: 'Total number of failed payment verifications'
});

const ordersTotal = new client.Gauge({
  name: 'shopnest_orders_total',
  help: 'Current total number of orders'
});

const ordersByStatus = new client.Gauge({
  name: 'shopnest_orders_by_status',
  help: 'Current number of orders by status',
  labelNames: ['status']
});

const updateOrderStatusMetrics = async (Order) => {
  const statuses = ['Pending', 'Shipped', 'Delivered'];

  const counts = await Order.aggregate([
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 }
      }
    }
  ]);

  const countMap = Object.fromEntries(
    counts.map(item => [item._id, item.count])
  );

  let totalOrders = 0;

  for (const status of statuses) {
    const count = countMap[status] || 0;

    ordersByStatus.set(
      { status },
      count
    );

    totalOrders += count;
  }

  ordersTotal.set(totalOrders);
};

module.exports = {
  client,
  httpRequestsTotal,
  httpRequestDuration,
  ordersCreatedTotal,
  orderCreationFailuresTotal,
  paymentAttemptsTotal,
  paymentVerificationSuccessTotal,
  paymentVerificationFailuresTotal,
  ordersTotal,
  ordersByStatus,
  updateOrderStatusMetrics
};