const mongoose = require('mongoose');

const paymentAttemptSchema = new mongoose.Schema(
  {
    amount: {
      type: Number,
      required: true
    },

    // created             - Razorpay order opened; the customer has not
    //                       (yet) completed payment
    // failed              - the Razorpay order could not be created
    // verified            - payment completed and its signature checked
    // verification_failed - a payment came back with a bad signature
    // legacy              - written by an older version that recorded no
    //                       Razorpay ID, so the outcome is unknown
    status: {
      type: String,
      enum: ['created', 'failed', 'verified', 'verification_failed', 'legacy'],
      required: true
    },

    // The Razorpay ORDER id (order_...). verifyPayment uses it to find the
    // attempt a payment belongs to.
    paymentId: {
      type: String,
      default: null
    },

    // The Razorpay PAYMENT id (pay_...), set once the payment is verified.
    // It is what the saved Order stores as its paymentId.
    razorpayPaymentId: {
      type: String,
      default: null
    }
  },
  {
    timestamps: true
  }
);

module.exports = mongoose.model('PaymentAttempt', paymentAttemptSchema);