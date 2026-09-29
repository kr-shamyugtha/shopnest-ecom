process.env.JWT_SECRET = 'test-secret';

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

jest.mock('../models/User', () => ({
  findOne: jest.fn(),
  create: jest.fn(),
  find: jest.fn(),
}));
jest.mock('../utils/sendEmail', () => jest.fn().mockResolvedValue());

const User = require('../models/User');
const sendEmail = require('../utils/sendEmail');
const { registerUser, loginUser, getUsers } = require('../controllers/authController');

const mockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

describe('registerUser', () => {
  beforeEach(() => jest.clearAllMocks());

  it('rejects an email that is already registered', async () => {
    User.findOne.mockResolvedValue({ _id: 'existing' });
    const res = mockRes();

    await registerUser({ body: { name: 'A', email: 'a@x.com', password: 'pw' } }, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ message: 'User already exists' });
    expect(User.create).not.toHaveBeenCalled();
  });

  it('stores a bcrypt hash, never the plain password, and returns a usable token', async () => {
    User.findOne.mockResolvedValue(null);
    User.create.mockImplementation(async (data) => ({ _id: 'u1', role: 'user', ...data }));
    const res = mockRes();

    await registerUser({ body: { name: 'Asha', email: 'asha@x.com', password: 'secret123' } }, res);

    const saved = User.create.mock.calls[0][0];
    expect(saved.password).not.toBe('secret123');
    expect(await bcrypt.compare('secret123', saved.password)).toBe(true);

    expect(res.status).toHaveBeenCalledWith(201);
    const body = res.json.mock.calls[0][0];
    expect(body).toMatchObject({ _id: 'u1', name: 'Asha', email: 'asha@x.com', role: 'user' });
    expect(body).not.toHaveProperty('password');
    expect(jwt.verify(body.token, 'test-secret').id).toBe('u1');
    expect(sendEmail).toHaveBeenCalledWith(expect.objectContaining({ email: 'asha@x.com' }));
  });

  it('returns 500 with the error message when the database fails', async () => {
    User.findOne.mockRejectedValue(new Error('db down'));
    const res = mockRes();

    await registerUser({ body: { name: 'A', email: 'a@x.com', password: 'pw' } }, res);

    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith({ message: 'db down' });
  });
});

describe('loginUser', () => {
  beforeEach(() => jest.clearAllMocks());

  it('logs in with the correct password', async () => {
    const hash = await bcrypt.hash('secret123', 4);
    User.findOne.mockResolvedValue({
      _id: 'u1', name: 'Asha', email: 'asha@x.com', role: 'admin', password: hash,
    });
    const res = mockRes();

    await loginUser({ body: { email: 'asha@x.com', password: 'secret123' } }, res);

    const body = res.json.mock.calls[0][0];
    expect(body.role).toBe('admin');
    expect(body).not.toHaveProperty('password');
    expect(jwt.verify(body.token, 'test-secret').id).toBe('u1');
  });

  it('rejects a wrong password', async () => {
    const hash = await bcrypt.hash('secret123', 4);
    User.findOne.mockResolvedValue({ _id: 'u1', password: hash });
    const res = mockRes();

    await loginUser({ body: { email: 'asha@x.com', password: 'wrong' } }, res);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ message: 'Invalid email or password' });
  });

  it('gives the same error for an unknown email (no account enumeration)', async () => {
    User.findOne.mockResolvedValue(null);
    const res = mockRes();

    await loginUser({ body: { email: 'nobody@x.com', password: 'pw' } }, res);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ message: 'Invalid email or password' });
  });
});

describe('getUsers', () => {
  it('excludes the password field from the query', async () => {
    const select = jest.fn().mockResolvedValue([{ _id: 'u1' }]);
    User.find.mockReturnValue({ select });
    const res = mockRes();

    await getUsers({}, res);

    expect(select).toHaveBeenCalledWith('-password');
    expect(res.json).toHaveBeenCalledWith([{ _id: 'u1' }]);
  });
});
