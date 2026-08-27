import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('auth API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;
  const jwtSecret = 'test-secret-at-least-16-chars';

  const newCustomer = {
    fullName: 'Zainab Bello',
    email: 'zainab@example.com',
    phone: '+234 809 555 1234',
    password: 'Secret123!',
  };

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool, { jwtSecret });
  });
  afterAll(async () => {
    await pool.end();
  });

  it('registers a customer with role customer and returns a token', async () => {
    const res = await request(app).post('/api/auth/register').send(newCustomer);
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeTruthy();
    expect(res.body.data.user.role).toBe('customer');
    expect(res.body.data.user.email).toBe('zainab@example.com');
    expect(JSON.stringify(res.body)).not.toContain('password');
  });

  it('never stores a plaintext password', async () => {
    const rows = await pool.query('SELECT password_hash FROM users WHERE email = $1', [newCustomer.email]);
    expect(rows.rowCount).toBe(1);
    const hash = String(rows.rows[0].password_hash);
    expect(hash).not.toBe(newCustomer.password);
    expect(hash).toMatch(/^\$argon2/);
  });

  it('rejects a duplicate email', async () => {
    const res = await request(app).post('/api/auth/register').send({
      ...newCustomer,
      phone: '+234 809 555 9999',
    });
    expect(res.status).toBe(409);
    expect(res.body.error.message).toContain('already exists');
  });

  it('rejects invalid input', async () => {
    const res = await request(app).post('/api/auth/register').send({
      fullName: '',
      email: 'not-an-email',
      phone: '',
      password: 'short',
    });
    expect(res.status).toBe(422);
  });

  it('rejects a client-supplied privileged role', async () => {
    const res = await request(app).post('/api/auth/register').send({
      fullName: 'Role Sneak',
      email: 'sneak@example.com',
      phone: '08000000000',
      password: 'Secret123!',
      role: 'super_admin',
    });
    expect(res.status).toBe(422);
    const rows = await pool.query('SELECT count(*)::int AS n FROM users WHERE email = $1', ['sneak@example.com']);
    expect(rows.rows[0].n).toBe(0);
  });

  it('logs in with correct credentials', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: newCustomer.email,
      password: newCustomer.password,
    });
    expect(res.status).toBe(200);
    expect(res.body.data.token).toBeTruthy();
    expect(res.body.data.user.role).toBe('customer');
    expect(JSON.stringify(res.body)).not.toContain('password');
  });

  it('rejects a wrong password', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: newCustomer.email,
      password: 'wrong-password',
    });
    expect(res.status).toBe(401);
    expect(res.body.error.message).toBe('Incorrect email or password');
  });

  it('rejects an unknown email the same way', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: 'ghost@example.com',
      password: 'whatever1',
    });
    expect(res.status).toBe(401);
    expect(res.body.error.message).toBe('Incorrect email or password');
  });

  it('rejects login for a deactivated account', async () => {
    const registered = await request(app).post('/api/auth/register').send({
      fullName: 'Deactivated User',
      email: 'deactivated@example.com',
      phone: '08011111111',
      password: 'Secret123!',
    });
    const userId = registered.body.data.user.id;
    await pool.query('UPDATE users SET is_active = FALSE WHERE id = $1', [userId]);
    const res = await request(app).post('/api/auth/login').send({
      email: 'deactivated@example.com',
      password: 'Secret123!',
    });
    expect(res.status).toBe(401);
    expect(res.body.error.message).toContain('deactivated');
  });

  it('returns the current user for a valid token', async () => {
    const login = await request(app).post('/api/auth/login').send({
      email: newCustomer.email,
      password: newCustomer.password,
    });
    const res = await request(app).get('/api/auth/me').set('Authorization', `Bearer ${login.body.data.token}`);
    expect(res.status).toBe(200);
    expect(res.body.data.email).toBe(newCustomer.email);
    expect(res.body.data.role).toBe('customer');
  });

  it('rejects /auth/me without a token', async () => {
    const res = await request(app).get('/api/auth/me');
    expect(res.status).toBe(401);
  });

  it('rejects a tampered token', async () => {
    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', 'Bearer not.a.real.token');
    expect(res.status).toBe(401);
  });

  it('logs out', async () => {
    const login = await request(app).post('/api/auth/login').send({
      email: newCustomer.email,
      password: newCustomer.password,
    });
    const res = await request(app).post('/api/auth/logout').set('Authorization', `Bearer ${login.body.data.token}`);
    expect(res.status).toBe(200);
    expect(res.body.data.loggedOut).toBe(true);
  });

  it('updates the authenticated user avatar', async () => {
    const login = await request(app).post('/api/auth/login').send({
      email: newCustomer.email,
      password: newCustomer.password,
    });
    const png = Buffer.from(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      'base64',
    );
    const res = await request(app)
      .post('/api/auth/avatar')
      .set('Authorization', `Bearer ${login.body.data.token}`)
      .attach('avatar', png, 'avatar.png');
    expect(res.status).toBe(200);
    expect(res.body.data.avatarUrl).toMatch(/^\/images\/avatar-/);
    const me = await request(app).get('/api/auth/me').set('Authorization', `Bearer ${login.body.data.token}`);
    expect(me.body.data.avatarUrl).toMatch(/^\/images\/avatar-/);
  });

  it('rejects avatar upload without a file', async () => {
    const login = await request(app).post('/api/auth/login').send({
      email: newCustomer.email,
      password: newCustomer.password,
    });
    const res = await request(app)
      .post('/api/auth/avatar')
      .set('Authorization', `Bearer ${login.body.data.token}`);
    expect(res.status).toBe(422);
  });
});

describe('auth enforcement', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;
  const jwtSecret = 'test-secret-at-least-16-chars';
  const adminStub = { 'x-user-id': '00000000-0000-0000-0000-000000000202', 'x-user-role': 'super_admin' };

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool, { jwtSecret });
  });
  afterAll(async () => {
    await pool.end();
  });

  async function registerCustomer(email: string) {
    const res = await request(app).post('/api/auth/register').send({
      fullName: `Customer ${email}`,
      email,
      phone: '08022222222',
      password: 'Secret123!',
    });
    return res.body.data as { token: string; user: { id: string; role: string } };
  }

  it('rejects unauthenticated requests to protected endpoints', async () => {
    const res = await request(app).get('/api/orders');
    expect(res.status).toBe(401);
  });

  it('denies a customer admin access via a real token', async () => {
    const customer = await registerCustomer('denied@example.com');
    const res = await request(app).get('/api/users').set('Authorization', `Bearer ${customer.token}`);
    expect(res.status).toBe(403);
  });

  it('allows an admin (created via staff endpoint) through a real token', async () => {
    const created = await request(app).post('/api/users').set(adminStub).send({
      email: 'tokenadmin@queenstouch.com',
      password: 'Secret123!',
      fullName: 'Token Admin',
      phone: '08033333333',
      role: 'store_manager',
    });
    expect(created.status).toBe(201);
    const login = await request(app).post('/api/auth/login').send({
      email: 'tokenadmin@queenstouch.com',
      password: 'Secret123!',
    });
    expect(login.status).toBe(200);
    const res = await request(app).get('/api/users').set('Authorization', `Bearer ${login.body.data.token}`);
    expect(res.status).toBe(200);
  });

  it('scopes orders to the authenticated customer', async () => {
    const [a, b] = await Promise.all([
      registerCustomer('owner@example.com'),
      registerCustomer('intruder@example.com'),
    ]);

    const order = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${a.token}`)
      .send({
        customerName: 'Owner',
        customerPhone: '08044444444',
        customerEmail: 'owner@example.com',
        shippingAddress: '1 Test St',
        paymentMethod: 'cash_on_delivery',
        items: [{ productId: '00000000-0000-0000-0000-000000000501', variantId: '00000000-0000-0000-0000-000000000601', quantity: 1 }],
      });
    expect(order.status).toBe(201);
    const orderId = order.body.data.id;

    const ownerView = await request(app)
      .get(`/api/orders/${orderId}`)
      .set('Authorization', `Bearer ${a.token}`);
    expect(ownerView.status).toBe(200);

    const intruderView = await request(app)
      .get(`/api/orders/${orderId}`)
      .set('Authorization', `Bearer ${b.token}`);
    expect(intruderView.status).toBe(403);
  });
});