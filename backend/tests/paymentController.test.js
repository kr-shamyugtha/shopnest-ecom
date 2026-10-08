jest.mock('../models/PaymentAttempt', () => ({
  create: jest.fn(),
  updateOne: jest.fn().mockResolvedValue({}),
}));

const crypto = require('crypto');
const PaymentAttempt = require('../models/PaymentAttempt');
const { verifyPayment } = require('../controllers/paymentController');

const SECRET = 'test-secret';

const mockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  res.send = jest.fn().mockReturnValue(res);
  return res;
};

const sign = (orderId, paymentId) =>
  crypto.createHmac('sha256', SECRET).update(`${orderId}|${paymentId}`).digest('hex');

describe('verifyPayment', () => {
  beforeAll(() => { process.env.RAZORPAY_KEY_SECRET = SECRET; });
  beforeEach(() => jest.clearAllMocks());

  it('marks the attempt verified, keyed by the Razorpay order id', async () => {
    const res = mockRes();

    await verifyPayment({ body: {
      razorpay_order_id: 'order_1',
      razorpay_payment_id: 'pay_1',
      razorpay_signature: sign('order_1', 'pay_1'),
    } }, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(PaymentAttempt.updateOne).toHaveBeenCalledWith(
      { paymentId: 'order_1' },
      { status: 'verified', razorpayPaymentId: 'pay_1' }
    );
  });

  it('marks the attempt verification_failed on a bad signature', async () => {
    const res = mockRes();

    await verifyPayment({ body: {
      razorpay_order_id: 'order_2',
      razorpay_payment_id: 'pay_2',
      razorpay_signature: 'forged',
    } }, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(PaymentAttempt.updateOne).toHaveBeenCalledWith(
      { paymentId: 'order_2' },
      { status: 'verification_failed', razorpayPaymentId: 'pay_2' }
    );
  });

  it('still confirms a valid payment when recording it fails', async () => {
    PaymentAttempt.updateOne.mockRejectedValueOnce(new Error('db down'));
    jest.spyOn(console, 'error').mockImplementation(() => {});
    const res = mockRes();

    await verifyPayment({ body: {
      razorpay_order_id: 'order_3',
      razorpay_payment_id: 'pay_3',
      razorpay_signature: sign('order_3', 'pay_3'),
    } }, res);

    expect(res.status).toHaveBeenCalledWith(200);
    console.error.mockRestore();
  });
});
