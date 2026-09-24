const Order = require('../models/Order');
const sendEmail = require('../utils/sendEmail');
const {
  ordersCreatedTotal,
  orderCreationFailuresTotal
} = require('../metrics/metrics');

const addOrderItems = async (req, res) => {
  try {
    const { items, totalAmount, address, paymentId } = req.body;

    if (items && items.length === 0) {
      return res.status(400).json({ message: 'No order items' });
    } else {
      const order = new Order({
        userId: req.user._id,
        items,
        totalAmount,
        address,
        paymentId
      });

      const createdOrder = await order.save();
     

      // Send Order Confirmation Email
      const message = `
        <h2>Order Confirmation</h2>
        <p>Hello ${req.user.name},</p>
        <p>Your order has been successfully placed! Order ID: <strong>${createdOrder._id}</strong></p>
        <p>Total Amount Paid: $${totalAmount.toFixed(2)}</p>
        <p>It will be shipped to: ${address.street}, ${address.city}</p>
        <p>Thank you for shopping with ShopNest!</p>
      `;

      await sendEmail({
        email: req.user.email,
        subject: 'ShopNest - Order Confirmation',
        message
      });

      res.status(201).json(createdOrder);
    }
  } catch (error) {
    orderCreationFailuresTotal.inc();

    res.status(500).json({
      message: error.message
    });
  }
};

const getMyOrders = async (req, res) => {
  try {
    const orders = await Order.find({ userId: req.user._id });
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getOrders = async (req, res) => {
  try {
    const orders = await Order.find({}).populate('userId', 'id name');
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateOrderStatus = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);

    if (order) {
      order.status = req.body.status || order.status;

      const updatedOrder = await order.save();


      res.json(updatedOrder);
    } else {
      res.status(404).json({ message: 'Order not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};


// A customer may withdraw their own order, but only while it is still
// Placed — once it ships, cancelling is a returns problem, not an order
// problem. Ownership is checked explicitly so one account cannot cancel
// another's order by guessing an id.
const cancelOrder = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    if (order.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'You cannot cancel an order that is not yours' });
    }

    if (order.status === 'Cancelled') {
      return res.status(400).json({ message: 'This order is already cancelled' });
    }

    if (order.status !== 'Placed') {
      return res.status(400).json({
        message: `An order that has been ${order.status.toLowerCase()} can no longer be cancelled`
      });
    }

    order.status = 'Cancelled';
    const updatedOrder = await order.save();

    res.json(updatedOrder);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  addOrderItems,
  getMyOrders,
  getOrders,
  updateOrderStatus,
  cancelOrder
};