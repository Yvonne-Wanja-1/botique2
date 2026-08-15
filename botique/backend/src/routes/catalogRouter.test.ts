import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('catalog API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool);
  });
  afterAll(async () => {
    await pool.end();
  });

  it('lists root categories', async () => {
    const res = await request(app)
      .get('/api/categories')
      .set('x-user-id', '00000000-0000-0000-0000-000000000201');
    expect(res.status).toBe(200);
    const names = res.body.data.map((c: { name: string }) => c.name);
    expect(names).toContain('Clothing');
    expect(names).toContain('Cosmetics & Beauty');
  });

  it('lists subcategories', async () => {
    const res = await request(app)
      .get('/api/categories/00000000-0000-0000-0000-000000000401/subcategories')
      .set('x-user-id', '00000000-0000-0000-0000-000000000201');
    expect(res.status).toBe(200);
    expect(res.body.data.length).toBeGreaterThan(0);
  });

  it('lists brands', async () => {
    const res = await request(app)
      .get('/api/brands')
      .set('x-user-id', '00000000-0000-0000-0000-000000000201');
    expect(res.status).toBe(200);
    expect(res.body.data.length).toBe(6);
  });
});