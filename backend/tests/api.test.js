process.env.JWT_SECRET = 'test-secret';

const request = require('supertest');
const jwt = require('jsonwebtoken');

jest.mock('../models/User', () => ({
  findById: jest.fn(),
  findOne: jest.fn(),
  find: jest.fn(),
  create: jest.fn(),
}));

const User = require('../models/User');
const app = require('../app');

const tokenFor = (id) => jwt.sign({ id }, 'test-secret');
const loggedInAs = (user) => User.findById.mockReturnValue({ select: jest.fn().mockResolvedValue(user) });

// These go through the real Express app, routing and middleware chain;
// only the database layer is replaced.
describe('API access control', () => {
  beforeEach(() => jest.clearAllMocks());

  it('GET /api/auth/users requires a token', async () => {
    const res = await request(app).get('/api/auth/users');
    expect(res.statusCode).toBe(401);
  });

  it('GET /api/auth/users is forbidden for a normal user', async () => {
    loggedInAs({ _id: 'u1', role: 'user' });
    const res = await request(app)
      .get('/api/auth/users')
      .set('Authorization', `Bearer ${tokenFor('u1')}`);
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Not authorized as an admin');
    expect(User.find).not.toHaveBeenCalled();
  });

  it('GET /api/auth/users works for an admin', async () => {
    loggedInAs({ _id: 'a1', role: 'admin' });
    User.find.mockReturnValue({ select: jest.fn().mockResolvedValue([{ _id: 'u1', name: 'Asha' }]) });
    const res = await request(app)
      .get('/api/auth/users')
      .set('Authorization', `Bearer ${tokenFor('a1')}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toEqual([{ _id: 'u1', name: 'Asha' }]);
  });

  it('POST /api/auth/login rejects unknown credentials with 401', async () => {
    User.findOne.mockResolvedValue(null);
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'nobody@x.com', password: 'pw' });
    expect(res.statusCode).toBe(401);
    expect(res.body.message).toBe('Invalid email or password');
  });

  it('GET /api/orders is not open to anonymous callers', async () => {
    const res = await request(app).get('/api/orders');
    expect([401, 403, 404]).toContain(res.statusCode);
  });
});
