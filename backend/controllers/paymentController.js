const Razorpay = require('razorpay');
const crypto = require('crypto');

const PaymentAttempt = require('../models/PaymentAttempt');

const {
  paymentVerificationSuccessTotal,
  paymentVerificationFailuresTotal
} = require('../metrics/metrics');

const createOrder = async (req, res) => {
  try {
    const instance = new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID,
      key_secret: process.env.RAZORPAY_KEY_SECRET,
    });

    // Razorpay accepts amount in paise
    const options = {
      amount: req.body.amount * 100,
      currency: "INR",
    };

    const order = await instance.orders.create(options);

    if (!order) {
      await PaymentAttempt.create({
        amount: req.body.amount,
        status: 'failed'
      });

      return res.status(500).send("Some error occured");
    }

    await PaymentAttempt.create({
      amount: req.body.amount,
      status: 'created',
      paymentId: order.id
    });

    res.json(order);
  } catch (error) {
    await PaymentAttempt.create({
      amount: req.body.amount,
      status: 'failed'
    });

    res.status(500).send(error);
  }
};

// Persist the verification outcome on the attempt it belongs to, so the
// payment success rate survives restarts. The in-memory counters below reset
// whenever the pod restarts, which is why the dashboard used to show 0
// verified payments against dozens of paid orders. Never fails the request:
// the customer's payment outcome must not depend on bookkeeping.
const recordVerification = async (razorpayOrderId, razorpayPaymentId, verified) => {
  if (!razorpayOrderId) return;

  try {
    await PaymentAttempt.updateOne(
      { paymentId: razorpayOrderId },
      {
        status: verified ? 'verified' : 'verification_failed',
        razorpayPaymentId: razorpayPaymentId || null
      }
    );
  } catch (error) {
    console.error('Failed to record payment verification:', error.message);
  }
};

const verifyPayment = async (req, res) => {
  try {
    const {
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature
    } = req.body;

    const sign = razorpay_order_id + "|" + razorpay_payment_id;

    const expectedSign = crypto
      .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET)
      .update(sign.toString())
      .digest("hex");

    if (razorpay_signature === expectedSign) {
      paymentVerificationSuccessTotal.inc();
      await recordVerification(razorpay_order_id, razorpay_payment_id, true);

      return res.status(200).json({
        message: "Payment verified successfully"
      });
    } else {
      paymentVerificationFailuresTotal.inc();
      await recordVerification(razorpay_order_id, razorpay_payment_id, false);

      return res.status(400).json({
        message: "Invalid signature sent!"
      });
    }
  } catch (error) {
    paymentVerificationFailuresTotal.inc();

    res.status(500).send(error);
  }
};

module.exports = { createOrder, verifyPayment };