jest.mock('../models/Order', () => {
  const Order = jest.fn();
  Order.findById = jest.fn();
  Order.find = jest.fn();
  return Order;
});
jest.mock('../utils/sendEmail', () => jest.fn().mockResolvedValue());

const sendEmail = require('../utils/sendEmail');
const { ordersCreatedTotal, orderCreationFailuresTotal } = require('../metrics/metrics');

const counterValue = async (counter) => (await counter.get()).values[0]?.value ?? 0;

const Order = require('../models/Order');
const {
  addOrderItems,
  updateOrderStatus,
  cancelOrder,
} = require('../controllers/orderController');

const mockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

const makeOrder = (overrides = {}) => ({
  userId: { toString: () => 'owner-1' },
  status: 'Placed',
  save: jest.fn(async function save() { return this; }),
  ...overrides,
});

const asUser = (id) => ({ user: { _id: { toString: () => id } }, params: { id: 'o1' } });

describe('cancelOrder', () => {
  beforeEach(() => jest.clearAllMocks());

  it('404s when the order does not exist', async () => {
    Order.findById.mockResolvedValue(null);
    const res = mockRes();

    await cancelOrder(asUser('owner-1'), res);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  it("403s when the order belongs to someone else, and does not modify it", async () => {
    const order = makeOrder();
    Order.findById.mockResolvedValue(order);
    const res = mockRes();

    await cancelOrder(asUser('intruder'), res);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(order.save).not.toHaveBeenCalled();
    expect(order.status).toBe('Placed');
  });

  it('cancels the owner\'s Placed order', async () => {
    const order = makeOrder();
    Order.findById.mockResolvedValue(order);
    const res = mockRes();

    await cancelOrder(asUser('owner-1'), res);

    expect(order.status).toBe('Cancelled');
    expect(order.save).toHaveBeenCalledTimes(1);
    expect(res.json).toHaveBeenCalledWith(order);
  });

  it('refuses to cancel an already cancelled order', async () => {
    const order = makeOrder({ status: 'Cancelled' });
    Order.findById.mockResolvedValue(order);
    const res = mockRes();

    await cancelOrder(asUser('owner-1'), res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ message: 'This order is already cancelled' });
    expect(order.save).not.toHaveBeenCalled();
  });

  it.each(['Shipped', 'Delivered'])('refuses to cancel a %s order', async (status) => {
    const order = makeOrder({ status });
    Order.findById.mockResolvedValue(order);
    const res = mockRes();

    await cancelOrder(asUser('owner-1'), res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json.mock.calls[0][0].message).toContain(status.toLowerCase());
    expect(order.status).toBe(status);
    expect(order.save).not.toHaveBeenCalled();
  });
});

describe('updateOrderStatus', () => {
  beforeEach(() => jest.clearAllMocks());

  it('updates the status', async () => {
    const order = makeOrder();
    Order.findById.mockResolvedValue(order);
    const res = mockRes();

    await updateOrderStatus({ params: { id: 'o1' }, body: { status: 'Shipped' } }, res);

    expect(order.status).toBe('Shipped');
    expect(res.json).toHaveBeenCalledWith(order);
  });

  it('keeps the current status when none is supplied', async () => {
    const order = makeOrder({ status: 'Shipped' });
    Order.findById.mockResolvedValue(order);

    await updateOrderStatus({ params: { id: 'o1' }, body: {} }, mockRes());

    expect(order.status).toBe('Shipped');
  });

  it('404s for an unknown order', async () => {
    Order.findById.mockResolvedValue(null);
    const res = mockRes();

    await updateOrderStatus({ params: { id: 'nope' }, body: { status: 'Shipped' } }, res);

    expect(res.status).toHaveBeenCalledWith(404);
  });
});

describe('addOrderItems', () => {
  it('rejects an order with no items without touching the database', async () => {
    const res = mockRes();

    await addOrderItems(
      { user: { _id: 'u1' }, body: { items: [], totalAmount: 0, address: {} } },
      res
    );

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ message: 'No order items' });
    expect(Order).not.toHaveBeenCalled();
  });

  describe('order metrics', () => {
    const placeOrder = () => {
      const res = mockRes();
      return addOrderItems(
        {
          user: { _id: 'u1', name: 'Test', email: 't@example.com' },
          body: { items: [{ productId: 'p1', qty: 1 }], totalAmount: 10, address: { street: 's', city: 'c' } },
        },
        res
      ).then(() => res);
    };

    beforeEach(() => {
      jest.clearAllMocks();
      ordersCreatedTotal.reset();
      orderCreationFailuresTotal.reset();
    });

    it('counts a saved order as created', async () => {
      Order.mockImplementation(function Order(doc) { return { ...doc, _id: 'o1', save: async function save() { return this; } }; });

      const res = await placeOrder();

      expect(res.status).toHaveBeenCalledWith(201);
      expect(await counterValue(ordersCreatedTotal)).toBe(1);
      expect(await counterValue(orderCreationFailuresTotal)).toBe(0);
    });

    it('counts a failed save as a failure, not a creation', async () => {
      Order.mockImplementation(function Order() { return { save: async () => { throw new Error('db down'); } }; });

      const res = await placeOrder();

      expect(res.status).toHaveBeenCalledWith(500);
      expect(await counterValue(ordersCreatedTotal)).toBe(0);
      expect(await counterValue(orderCreationFailuresTotal)).toBe(1);
    });

    it('does not count an order as failed when only the confirmation email fails', async () => {
      Order.mockImplementation(function Order(doc) { return { ...doc, _id: 'o1', save: async function save() { return this; } }; });
      sendEmail.mockRejectedValueOnce(new Error('smtp down'));

      await placeOrder();

      expect(await counterValue(ordersCreatedTotal)).toBe(1);
      expect(await counterValue(orderCreationFailuresTotal)).toBe(0);
    });
  });
});
