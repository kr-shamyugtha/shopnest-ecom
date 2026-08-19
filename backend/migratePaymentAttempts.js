const mongoose = require('mongoose');
const dotenv = require('dotenv');

const Order = require('./models/Order');
const PaymentAttempt = require('./models/PaymentAttempt');

dotenv.config();

const migrate = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);

    const orders = await Order.find({
      paymentId: { $exists: true, $ne: null }
    }).select('paymentId totalAmount createdAt');

    console.log('Orders with payment IDs:', orders.length);

    let created = 0;
    let skipped = 0;

    for (const order of orders) {
      const existing = await PaymentAttempt.findOne({
        paymentId: order.paymentId
      });

      if (existing) {
        skipped++;
        continue;
      }

      await PaymentAttempt.create({
        amount: order.totalAmount,
        status: 'created',
        paymentId: order.paymentId,
        createdAt: order.createdAt
      });

      created++;
    }

    console.log('Created:', created);
    console.log('Skipped:', skipped);
    console.log(
      'Total PaymentAttempt documents:',
      await PaymentAttempt.countDocuments()
    );

    await mongoose.disconnect();
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
};

migrate();