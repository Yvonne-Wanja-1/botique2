import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('cart & wishlist API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;
  const customer = { 'x-user-id': '00000000-0000-0000-0000-000000000201', 'x-user-role': 'customer' };
  const PID = '00000000-0000-0000-0000-000000000501';
  const VID = '00000000-0000-0000-0000-000000000601';

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool);
  });
  afterAll(async () => {
    await pool.end();
  });

  it('adds an item to the cart', async () => {
    const res = await request(app).post('/api/cart/items').set(customer).send({ productId: PID, variantId: VID, quantity: 2 });
    expect(res.status).toBe(201);
    expect(res.body.data.items).toHaveLength(1);
    expect(res.body.data.items[0].quantity).toBe(2);
    expect(res.body.data.subtotal).toBeCloseTo(res.body.data.items[0].totalPrice, 2);
  });

  it('lists the cart', async () => {
    const res = await request(app).get('/api/cart').set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.items).toHaveLength(1);
    expect(res.body.data.items[0].name).toBe('Rosé Midi Wrap Dress');
  });

  it('rejects quantity above stock', async () => {
    const res = await request(app).post('/api/cart/items').set(customer).send({ productId: PID, variantId: VID, quantity: 99999 });
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('CONFLICT');
  });

  it('updates item quantity', async () => {
    const cart = await request(app).get('/api/cart').set(customer);
    const itemId = cart.body.data.items[0].id;
    const res = await request(app).patch(`/api/cart/items/${itemId}`).set(customer).send({ quantity: 3 });
    expect(res.status).toBe(200);
    expect(res.body.data.items[0].quantity).toBe(3);
  });

  it('removes an item', async () => {
    const cart = await request(app).get('/api/cart').set(customer);
    const itemId = cart.body.data.items[0].id;
    const res = await request(app).delete(`/api/cart/items/${itemId}`).set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.items).toHaveLength(0);
  });

  it('toggles the wishlist', async () => {
    const add = await request(app).post(`/api/cart/wishlist/${PID}`).set(customer);
    expect(add.body.data.added).toBe(true);
    const list = await request(app).get('/api/cart/wishlist').set(customer);
    expect(list.body.data.map((i: { productId: string }) => i.productId)).toContain(PID);
    const remove = await request(app).delete(`/api/cart/wishlist/${PID}`).set(customer);
    expect(remove.body.data.added).toBe(false);
  });
});