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

      return res.status(200).json({
        message: "Payment verified successfully"
      });
    } else {
      paymentVerificationFailuresTotal.inc();

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