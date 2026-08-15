import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('users API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;
  const customer = { 'x-user-id': '00000000-0000-0000-0000-000000000201', 'x-user-role': 'customer' };
  const admin = { 'x-user-id': '00000000-0000-0000-0000-000000000202', 'x-user-role': 'super_admin' };

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool);
  });
  afterAll(async () => {
    await pool.end();
  });

  it('lists users for admins', async () => {
    const res = await request(app).get('/api/users').set(admin);
    expect(res.status).toBe(200);
    expect(res.body.data.total).toBeGreaterThanOrEqual(5);
  });

  it('denies non-admins', async () => {
    const res = await request(app).get('/api/users').set(customer);
    expect(res.status).toBe(403);
  });

  it('creates a staff user', async () => {
    const res = await request(app).post('/api/users').set(admin).send({
      email: 'new.staff@queenstouch.ng',
      password: 'Secret123!',
      fullName: 'New Staff',
      phone: '08099999999',
      role: 'inventory_staff',
    });
    expect(res.status).toBe(201);
    expect(res.body.data.role).toBe('inventory_staff');
  });

  it('rejects duplicate emails', async () => {
    const res = await request(app).post('/api/users').set(admin).send({
      email: 'new.staff@queenstouch.ng',
      password: 'Secret123!',
      fullName: 'Dup',
      phone: '08088888888',
      role: 'store_manager',
    });
    expect(res.status).toBe(409);
  });
});