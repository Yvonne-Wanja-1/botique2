import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('reports API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;
  const manager = { 'x-user-id': '00000000-0000-0000-0000-000000000203', 'x-user-role': 'store_manager' };
  const customer = { 'x-user-id': '00000000-0000-0000-0000-000000000201', 'x-user-role': 'customer' };

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool);
  });
  afterAll(async () => {
    await pool.end();
  });

  it('returns sales summary with totals', async () => {
    const res = await request(app).get('/api/reports/sales-summary').set(manager);
    expect(res.status).toBe(200);
    expect(res.body.data.totalOrders).toBeGreaterThanOrEqual(0);
    expect(res.body.data).toHaveProperty('totalRevenue');
  });

  it('returns top products', async () => {
    const res = await request(app).get('/api/reports/top-products?limit=5').set(manager);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  it('returns inventory summary', async () => {
    const res = await request(app).get('/api/reports/inventory-summary').set(manager);
    expect(res.status).toBe(200);
    expect(res.body.data).toHaveProperty('outOfStock');
  });

  it('returns customer summary', async () => {
    const res = await request(app).get('/api/reports/customer-summary').set(manager);
    expect(res.status).toBe(200);
    expect(res.body.data).toHaveProperty('totalCustomers');
  });

  it('denies customers', async () => {
    const res = await request(app).get('/api/reports/sales-summary').set(customer);
    expect(res.status).toBe(403);
  });
});