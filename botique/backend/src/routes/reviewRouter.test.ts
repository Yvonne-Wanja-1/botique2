import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('reviews API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;
  const customer = { 'x-user-id': '00000000-0000-0000-0000-000000000201', 'x-user-role': 'customer' };
  const manager = { 'x-user-id': '00000000-0000-0000-0000-000000000203', 'x-user-role': 'store_manager' };
  const PID = '00000000-0000-0000-0000-000000000501';
  const VID = '00000000-0000-0000-0000-000000000601';

  async function makeDeliveredOrder(): Promise<string> {
    const orderRes = await request(app).post('/api/orders').set(customer).send({
      customerName: 'Amara Okafor',
      customerPhone: '08011111111',
      customerEmail: 'amara@queenstouch.ng',
      shippingAddress: '12 Broad St, Lagos Island, Lagos',
      paymentMethod: 'cash_on_delivery',
      items: [{ productId: PID, variantId: VID, quantity: 1 }],
    });
    const orderId = orderRes.body.data.id;
    await request(app).patch(`/api/orders/${orderId}/status`).set(manager).send({ status: 'delivered' });
    return orderId;
  }

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool);
  });
  afterAll(async () => {
    await pool.end();
  });

  it('creates a verified purchase review after a delivered order', async () => {
    await makeDeliveredOrder();
    const res = await request(app)
      .post(`/api/reviews/products/${PID}/reviews`)
      .set(customer)
      .send({ rating: 5, comment: 'Love it!' });
    expect(res.status).toBe(201);
    expect(res.body.data.isVerifiedPurchase).toBe(true);
    expect(res.body.data.rating).toBe(5);
  });

  it('lists reviews for a product', async () => {
    const res = await request(app).get(`/api/reviews/products/${PID}/reviews`).set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.length).toBeGreaterThanOrEqual(1);
  });

  it('rejects duplicate reviews', async () => {
    const res = await request(app)
      .post(`/api/reviews/products/${PID}/reviews`)
      .set(customer)
      .send({ rating: 4, comment: 'again' });
    expect(res.status).toBe(409);
  });

  it('reports a review', async () => {
    const list = await request(app).get(`/api/reviews/products/${PID}/reviews`).set(customer);
    const reviewId = list.body.data[0].id;
    const res = await request(app).patch(`/api/reviews/${reviewId}/report`).set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.isReported).toBe(true);
  });

  it('staff can moderate reviews', async () => {
    const list = await request(app).get(`/api/reviews/products/${PID}/reviews`).set(customer);
    const reviewId = list.body.data[0].id;
    const res = await request(app).patch(`/api/reviews/${reviewId}/moderate`).set(manager).send({ approved: false });
    expect(res.status).toBe(200);
    expect(res.body.data.isApproved).toBe(false);
    const hidden = await request(app).get(`/api/reviews/products/${PID}/reviews`).set(customer);
    expect(hidden.body.data.find((r: { id: string }) => r.id === reviewId)).toBeUndefined();
  });
});