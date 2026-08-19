const mongoose = require('mongoose');

const paymentAttemptSchema = new mongoose.Schema(
  {
    amount: {
      type: Number,
      required: true
    },

    status: {
      type: String,
      enum: ['created', 'failed'],
      required: true
    },

    paymentId: {
      type: String,
      default: null
    }
  },
  {
    timestamps: true
  }
);

module.exports = mongoose.model('PaymentAttempt', paymentAttemptSchema);