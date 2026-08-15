import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('products API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool);
  });

  afterAll(async () => {
    await pool.end();
  });

  it('lists featured products', async () => {
    const res = await request(app)
      .get('/api/products?featured=true')
      .set('x-user-id', '00000000-0000-0000-0000-000000000201');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.products.length).toBeGreaterThan(0);
  });

  it('gets a product by id with variants', async () => {
    const res = await request(app)
      .get('/api/products/00000000-0000-0000-0000-000000000501')
      .set('x-user-id', '00000000-0000-0000-0000-000000000201');
    expect(res.status).toBe(200);
    expect(res.body.data.name).toBe('Rosé Midi Wrap Dress');
    expect(res.body.data.variants.length).toBe(5);
  });

  it('rejects creating a product without staff role', async () => {
    const res = await request(app)
      .post('/api/products')
      .set('x-user-id', '00000000-0000-0000-0000-000000000201')
      .send({ name: 'X', slug: 'x', categoryId: '00000000-0000-0000-0000-000000000402', brandId: '00000000-0000-0000-0000-000000000301', basePrice: 5 });
    expect(res.status).toBe(403);
  });

  it('creates a product as store_manager', async () => {
    const res = await request(app)
      .post('/api/products')
      .set('x-user-id', '00000000-0000-0000-0000-000000000203')
      .set('x-user-role', 'store_manager')
      .send({
        name: 'Test Gown', slug: 'test-gown', description: 'd',
        categoryId: '00000000-0000-0000-0000-000000000402',
        brandId: '00000000-0000-0000-0000-000000000301',
        basePrice: 55, discountPrice: 45, stockThreshold: 5,
        variants: [{ sku: 'TG-1', size: 'M', stockQty: 4 }],
      });
    expect(res.status).toBe(201);
    expect(res.body.data.variants[0].stockQty).toBe(4);
  });
});