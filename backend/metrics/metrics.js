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

/*
 * Total number of payment attempts recorded in MongoDB.
 *
 * This is a point-in-time value, so we calculate it
 * directly from MongoDB whenever Prometheus scrapes /metrics.
 */
const paymentAttemptsTotal = new client.Gauge({
  name: 'shopnest_payment_attempts_total',
  help: 'Total number of payment order creation attempts',

  async collect() {
    try {
      const PaymentAttempt = require('../models/PaymentAttempt');

      const count = await PaymentAttempt.countDocuments();

      this.set(count);
    } catch (error) {
      console.error(
        'Failed to collect shopnest_payment_attempts_total:',
        error
      );
    }
  }
});

const paymentVerificationSuccessTotal = new client.Counter({
  name: 'shopnest_payment_verification_success_total',
  help: 'Total number of successfully verified payments'
});

const paymentVerificationFailuresTotal = new client.Counter({
  name: 'shopnest_payment_verification_failures_total',
  help: 'Total number of failed payment verifications'
});


/*
 * Current total number of orders.
 *
 * This is a point-in-time value, so we calculate it
 * directly from MongoDB whenever Prometheus scrapes /metrics.
 */
const ordersTotal = new client.Gauge({
  name: 'shopnest_orders_total',
  help: 'Current total number of orders',

  async collect() {
    try {
      const Order = require('../models/Order');

      const count = await Order.countDocuments();

      this.set(count);
    } catch (error) {
      console.error('Failed to collect shopnest_orders_total:', error);
    }
  }
});


/*
 * Current number of orders by status.
 *
 * Values are read directly from MongoDB whenever
 * Prometheus scrapes /metrics.
 */
const ordersByStatus = new client.Gauge({
  name: 'shopnest_orders_by_status',
  help: 'Current number of orders by status',
  labelNames: ['status'],

  async collect() {
    try {
      const Order = require('../models/Order');

      /*
       * Read the status list off the schema rather than repeating it here.
       *
       * This was previously hardcoded as ['Pending', 'Shipped',
       * 'Delivered'], and when the model renamed Pending -> Placed and
       * added Cancelled, this copy was missed. The result was silent and
       * wrong rather than broken: the Pending series reported 0 forever,
       * Placed and Cancelled were never emitted at all, and the statuses
       * stopped adding up to shopnest_orders_total - five orders simply
       * unaccounted for on the dashboard.
       *
       * Deriving from enumValues means a future status is exported the
       * moment it is added to the model, with no second place to update.
       */
      const statuses = Order.schema.path('status').enumValues;

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

      for (const status of statuses) {
        this.set(
          { status },
          countMap[status] || 0
        );
      }

    } catch (error) {
      console.error('Failed to collect shopnest_orders_by_status:', error);
    }
  }
});


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
  ordersByStatus
};