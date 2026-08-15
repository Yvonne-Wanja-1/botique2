import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('notifications API', () => {
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

  it('sends a notification to a customer', async () => {
    const res = await request(app).post('/api/notifications').set(manager).send({
      userId: '00000000-0000-0000-0000-000000000201',
      title: 'Order update',
      body: 'Your order is being packed.',
      type: 'order',
    });
    expect(res.status).toBe(201);
  });

  it('lists notifications for the customer', async () => {
    const res = await request(app).get('/api/notifications').set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.length).toBeGreaterThanOrEqual(1);
    expect(res.body.data[0].isRead).toBe(false);
  });

  it('marks a notification read', async () => {
    const list = await request(app).get('/api/notifications').set(customer);
    const id = list.body.data[0].id;
    const res = await request(app).patch(`/api/notifications/${id}/read`).set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.isRead).toBe(true);
  });

  it('marks all notifications read', async () => {
    await request(app).post('/api/notifications').set(manager).send({
      userId: '00000000-0000-0000-0000-000000000201',
      title: 'Another',
      body: 'A second update.',
      type: 'announcement',
    });
    await request(app).patch('/api/notifications/read-all').set(customer);
    const res = await request(app).get('/api/notifications').set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.every((n: { isRead: boolean }) => n.isRead)).toBe(true);
  });

  it('denies customers from sending notifications', async () => {
    const res = await request(app).post('/api/notifications').set(customer).send({
      title: 'Nope',
      body: 'Should be denied.',
      type: 'announcement',
    });
    expect(res.status).toBe(403);
  });
});