import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('inventory API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool);
  });
  afterAll(async () => {
    await pool.end();
  });

  const staff = {
    'x-user-id': '00000000-0000-0000-0000-000000000205',
    'x-user-role': 'inventory_staff',
  };

  it('lists variants with stock status', async () => {
    const res = await request(app).get('/api/inventory/variants').set(staff);
    expect(res.status).toBe(200);
    expect(res.body.data.length).toBeGreaterThan(0);
    expect(res.body.data[0]).toHaveProperty('isLowStock');
  });

  it('adjusts stock and records a transaction', async () => {
    const before = await request(app).get('/api/inventory/variants').set(staff);
    const variantId = before.body.data[0].variantId;

    const res = await request(app)
      .post(`/api/inventory/variants/${variantId}/adjust`)
      .set(staff)
      .send({ quantity: -2, reason: 'damaged stock', changeType: 'adjust' });
    expect(res.status).toBe(200);
    expect(res.body.data.newQuantity).toBe(before.body.data[0].stockQty - 2);

    const tx = await pool.query(
      'SELECT count(*)::int AS n FROM inventory_transactions WHERE variant_id = $1',
      [variantId],
    );
    expect(tx.rows[0].n).toBe(1);
  });

  it('rejects reducing below zero', async () => {
    const res = await request(app)
      .post('/api/inventory/variants/00000000-0000-0000-0000-000000000601/adjust')
      .set(staff)
      .send({ quantity: -99999, reason: 'too much', changeType: 'adjust' });
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('CONFLICT');
  });
});