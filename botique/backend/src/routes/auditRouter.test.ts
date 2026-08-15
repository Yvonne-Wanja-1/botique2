import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('audit API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;
  const manager = { 'x-user-id': '00000000-0000-0000-0000-000000000203', 'x-user-role': 'store_manager' };
  const staff = { 'x-user-id': '00000000-0000-0000-0000-000000000205', 'x-user-role': 'inventory_staff' };

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool);
  });
  afterAll(async () => {
    await pool.end();
  });

  it('records an audit entry when inventory is adjusted', async () => {
    const list = await request(app).get('/api/inventory/variants').set(staff);
    const variantId = list.body.data[0].variantId;
    await request(app)
      .post(`/api/inventory/variants/${variantId}/adjust`)
      .set(staff)
      .send({ quantity: -1, reason: 'damaged', changeType: 'adjust' });

    const res = await request(app)
      .get('/api/audit-logs?action=adjust&resource=inventory.variant')
      .set(manager);
    expect(res.status).toBe(200);
    expect(res.body.data.rows.length).toBeGreaterThanOrEqual(1);
    expect(res.body.data.rows[0].action).toBe('adjust');
    expect(res.body.data.rows[0].actorName).toBe('Chidi Nwosu');
  });

  it('denies non-staff', async () => {
    const res = await request(app)
      .get('/api/audit-logs')
      .set({ 'x-user-id': '00000000-0000-0000-0000-000000000201', 'x-user-role': 'customer' });
    expect(res.status).toBe(403);
  });
});