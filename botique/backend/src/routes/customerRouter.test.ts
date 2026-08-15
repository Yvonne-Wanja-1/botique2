import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('customers API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;
  const customer = { 'x-user-id': '00000000-0000-0000-0000-000000000201', 'x-user-role': 'customer' };
  const manager = { 'x-user-id': '00000000-0000-0000-0000-000000000203', 'x-user-role': 'store_manager' };

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool);
  });
  afterAll(async () => {
    await pool.end();
  });

  it('returns the profile for the authenticated customer', async () => {
    const res = await request(app).get('/api/customers/me').set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.fullName).toBe('Amara Okafor');
    expect(Array.isArray(res.body.data.addresses)).toBe(true);
  });

  it('adds and lists an address', async () => {
    const add = await request(app).post('/api/customers/me/addresses').set(customer).send({
      label: 'Home',
      fullName: 'Amara Okafor',
      phone: '08011111111',
      street: '14 Marina Rd',
      city: 'Lagos',
      state: 'Lagos',
      isDefault: true,
    });
    expect(add.status).toBe(201);
    expect(add.body.data.street).toBe('14 Marina Rd');
    const list = await request(app).get('/api/customers/me/addresses').set(customer);
    expect(list.status).toBe(200);
    expect(list.body.data.length).toBeGreaterThanOrEqual(1);
    expect(list.body.data[0].isDefault).toBe(true);
  });

  it('sets a default address', async () => {
    const first = await request(app).post('/api/customers/me/addresses').set(customer).send({
      label: 'Work',
      fullName: 'Amara Okafor',
      phone: '08011111111',
      street: '5 Broad St',
      city: 'Lagos',
      state: 'Lagos',
    });
    expect(first.status).toBe(201);
    const second = await request(app).post('/api/customers/me/addresses').set(customer).send({
      label: 'Office',
      fullName: 'Amara Okafor',
      phone: '08011111111',
      street: '9 Broad St',
      city: 'Lagos',
      state: 'Lagos',
    });
    expect(second.status).toBe(201);
    const res = await request(app).patch(`/api/customers/me/addresses/${second.body.data.id}/default`).set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.isDefault).toBe(true);
    const list = await request(app).get('/api/customers/me/addresses').set(customer);
    const defaults = list.body.data.filter((a: { isDefault: boolean }) => a.isDefault);
    expect(defaults).toHaveLength(1);
    expect(defaults[0].id).toBe(second.body.data.id);
  });

  it('lists customers for staff only', async () => {
    const denied = await request(app).get('/api/customers').set(customer);
    expect(denied.status).toBe(403);
    const res = await request(app).get('/api/customers').set(manager);
    expect(res.status).toBe(200);
    expect(res.body.data.rows.length).toBeGreaterThanOrEqual(1);
  });
});