process.env.JWT_SECRET = 'test-secret';

const jwt = require('jsonwebtoken');

jest.mock('../models/User', () => ({ findById: jest.fn() }));

const User = require('../models/User');
const { protect } = require('../middleware/authMiddleware');
const { admin } = require('../middleware/adminMiddleware');

const mockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

describe('protect middleware', () => {
  beforeEach(() => jest.clearAllMocks());

  it('rejects a request with no Authorization header', async () => {
    const res = mockRes();
    const next = jest.fn();

    await protect({ headers: {} }, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ message: 'Not authorized, no token' });
    expect(next).not.toHaveBeenCalled();
  });

  it('rejects a token signed with the wrong secret', async () => {
    const token = jwt.sign({ id: 'u1' }, 'some-other-secret');
    const res = mockRes();
    const next = jest.fn();

    await protect({ headers: { authorization: `Bearer ${token}` } }, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ message: 'Not authorized, token failed' });
    expect(next).not.toHaveBeenCalled();
  });

  it('rejects an expired token', async () => {
    const token = jwt.sign({ id: 'u1' }, 'test-secret', { expiresIn: -10 });
    const res = mockRes();
    const next = jest.fn();

    await protect({ headers: { authorization: `Bearer ${token}` } }, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('attaches the user (without password) and calls next for a valid token', async () => {
    const user = { _id: 'u1', name: 'Asha', role: 'user' };
    const select = jest.fn().mockResolvedValue(user);
    User.findById.mockReturnValue({ select });

    const token = jwt.sign({ id: 'u1' }, 'test-secret');
    const req = { headers: { authorization: `Bearer ${token}` } };
    const res = mockRes();
    const next = jest.fn();

    await protect(req, res, next);

    expect(User.findById).toHaveBeenCalledWith('u1');
    expect(select).toHaveBeenCalledWith('-password');
    expect(req.user).toBe(user);
    expect(next).toHaveBeenCalledTimes(1);
    expect(res.status).not.toHaveBeenCalled();
  });
});

describe('admin middleware', () => {
  it('lets an admin through', () => {
    const next = jest.fn();
    admin({ user: { role: 'admin' } }, mockRes(), next);
    expect(next).toHaveBeenCalledTimes(1);
  });

  it('blocks a normal user', () => {
    const res = mockRes();
    const next = jest.fn();
    admin({ user: { role: 'user' } }, res, next);
    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('blocks a request with no user attached', () => {
    const res = mockRes();
    const next = jest.fn();
    admin({}, res, next);
    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });
});
