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
  // Most API calls finish well under 50ms. With 0.05 as the first bucket,
  // p50 (and often p95) came out as a straight-line guess inside 0-50ms -
  // about 25ms whatever the real latency was - and anything slower than 5s
  // was capped at 5. Finer low buckets and a 10s top bucket fix both.
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
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
 * Whether each Atlas-backed gauge below was refreshed on the last scrape
 * (1) or its query failed (0). On a failed query prom-client keeps
 * exporting the previous value, so without this an Atlas outage would show
 * as order counts that simply stop changing, indistinguishable from a quiet
 * shop.
 */
const dbMetricsUp = new client.Gauge({
  name: 'shopnest_db_metrics_up',
  help: 'Whether the Atlas-backed gauge was refreshed on the last scrape (1) or its query failed (0)',
  labelNames: ['metric']
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
      dbMetricsUp.set({ metric: 'shopnest_payment_attempts_total' }, 1);
    } catch (error) {
      dbMetricsUp.set({ metric: 'shopnest_payment_attempts_total' }, 0);
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
 * Payment attempts by outcome, read from MongoDB on every scrape.
 *
 * The success rate on the dashboard is built from this rather than from the
 * verification counters below: those live in process memory and reset to 0
 * on every restart, while the attempts and orders they were compared with are
 * database totals. Every status in the schema is exported (0 when empty) so a
 * status with no attempts reads 0 instead of disappearing from the panels.
 */
const paymentAttemptsByStatus = new client.Gauge({
  name: 'shopnest_payment_attempts_by_status',
  help: 'Payment attempts in MongoDB by status (created = opened but not completed)',
  labelNames: ['status'],

  async collect() {
    try {
      const PaymentAttempt = require('../models/PaymentAttempt');

      const statuses = PaymentAttempt.schema.path('status').enumValues;

      const counts = await PaymentAttempt.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } }
      ]);

      const countMap = Object.fromEntries(counts.map(item => [item._id, item.count]));

      for (const status of statuses) {
        this.set({ status }, countMap[status] || 0);
      }

      dbMetricsUp.set({ metric: 'shopnest_payment_attempts_by_status' }, 1);
    } catch (error) {
      dbMetricsUp.set({ metric: 'shopnest_payment_attempts_by_status' }, 0);
      console.error('Failed to collect shopnest_payment_attempts_by_status:', error);
    }
  }
});

/*
 * Orders by how they were paid, read from MongoDB on every scrape.
 *
 * Checkout saves an order only after Razorpay verification succeeds, with the
 * Razorpay payment id (pay_...). The "Student Bypass" path saves orders with a
 * bypass_txn_... id and no payment at all. Without this split, half the orders
 * looked like payments that had never been verified.
 */
const ordersByPaymentMethod = new client.Gauge({
  name: 'shopnest_orders_by_payment_method',
  help: 'Orders in MongoDB by payment method (razorpay, bypass, other)',
  labelNames: ['method'],

  async collect() {
    try {
      const Order = require('../models/Order');

      const [razorpay, bypass, total] = await Promise.all([
        Order.countDocuments({ paymentId: /^pay_/ }),
        Order.countDocuments({ paymentId: /^bypass_/ }),
        Order.countDocuments()
      ]);

      this.set({ method: 'razorpay' }, razorpay);
      this.set({ method: 'bypass' }, bypass);
      this.set({ method: 'other' }, total - razorpay - bypass);

      dbMetricsUp.set({ metric: 'shopnest_orders_by_payment_method' }, 1);
    } catch (error) {
      dbMetricsUp.set({ metric: 'shopnest_orders_by_payment_method' }, 0);
      console.error('Failed to collect shopnest_orders_by_payment_method:', error);
    }
  }
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
      dbMetricsUp.set({ metric: 'shopnest_orders_total' }, 1);
    } catch (error) {
      dbMetricsUp.set({ metric: 'shopnest_orders_total' }, 0);
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

      dbMetricsUp.set({ metric: 'shopnest_orders_by_status' }, 1);
    } catch (error) {
      dbMetricsUp.set({ metric: 'shopnest_orders_by_status' }, 0);
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
  ordersByStatus,
  paymentAttemptsByStatus,
  ordersByPaymentMethod,
  dbMetricsUp
};