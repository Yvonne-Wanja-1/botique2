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
  const stranger = { 'x-user-id': '00000000-0000-0000-0000-000000000205', 'x-user-role': 'inventory_staff' };

  const PID = '00000000-0000-0000-0000-000000000501';
  const VID = '00000000-0000-0000-0000-000000000601';
  const PID2 = '00000000-0000-0000-0000-000000000502';
  const VID2 = '00000000-0000-0000-0000-000000000606';
  const PID3 = '00000000-0000-0000-0000-000000000503';
  const VID3 = '00000000-0000-0000-0000-000000000610';

  async function makeDeliveredOrder(productId = PID, variantId = VID): Promise<string> {
    const orderRes = await request(app).post('/api/orders').set(customer).send({
      customerName: 'Amara Okafor',
      customerPhone: '08011111111',
      customerEmail: 'amara@queenstouch.ng',
      shippingAddress: '12 Broad St, Lagos Island, Lagos',
      paymentMethod: 'cash_on_delivery',
      items: [{ productId, variantId, quantity: 1 }],
    });
    const orderId = orderRes.body.data.id;
    await request(app).patch(`/api/orders/${orderId}/status`).set(manager).send({ status: 'delivered' });
    return orderId;
  }

  async function createReview(productId = PID, rating = 5, comment = 'Love it!') {
    return request(app)
      .post(`/api/reviews/products/${productId}/reviews`)
      .set(customer)
      .send({ rating, comment });
  }

  function reviewIdFor(pending: any, productId: string): string {
    const review = pending.body.data.find((r: { productId: string }) => r.productId === productId);
    expect(review).toBeDefined();
    return review.id;
  }

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool);
  });
  afterAll(async () => {
    await pool.end();
  });

  it('creates a pending verified purchase review after a delivered order', async () => {
    await makeDeliveredOrder();
    const res = await createReview();
    expect(res.status).toBe(201);
    expect(res.body.data.isVerifiedPurchase).toBe(true);
    expect(res.body.data.rating).toBe(5);
    expect(res.body.data.isApproved).toBe(false);
    expect(res.body.data.isRejected).toBe(false);
    expect(res.body.data.customerName).toBe('Amara Okafor');
    expect(res.body.data.productName).toBe('Rosé Midi Wrap Dress');
  });

  it('does not expose pending reviews on the product', async () => {
    const res = await request(app).get(`/api/reviews/products/${PID}/reviews`).set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(0);
  });

  it('lists pending reviews for moderators', async () => {
    const res = await request(app).get('/api/reviews/pending').set(manager);
    expect(res.status).toBe(200);
    expect(res.body.data.length).toBeGreaterThanOrEqual(1);
    expect(res.body.data[0].customerName).toBe('Amara Okafor');
  });

  it('blocks non-moderators from the pending list', async () => {
    const res = await request(app).get('/api/reviews/pending').set(customer);
    expect(res.status).toBe(403);
  });

  it('rejects reviews without a delivered order', async () => {
    const res = await request(app)
      .post(`/api/reviews/products/${PID2}/reviews`)
      .set(customer)
      .send({ rating: 5, comment: 'I did not buy this' });
    expect(res.status).toBe(403);
  });

  it('rejects a user reviewing a purchase made by another customer', async () => {
    const res = await request(app)
      .post(`/api/reviews/products/${PID}/reviews`)
      .set(stranger)
      .send({ rating: 4, comment: 'Not mine' });
    expect(res.status).toBe(403);
  });

  it('rejects invalid ratings and empty text', async () => {
    await makeDeliveredOrder(PID2, VID2);
    const low = await request(app)
      .post(`/api/reviews/products/${PID2}/reviews`)
      .set(customer)
      .send({ rating: 0, comment: 'bad' });
    expect(low.status).toBe(422);
    const high = await request(app)
      .post(`/api/reviews/products/${PID2}/reviews`)
      .set(customer)
      .send({ rating: 6, comment: 'bad' });
    expect(high.status).toBe(422);
    const noText = await request(app)
      .post(`/api/reviews/products/${PID2}/reviews`)
      .set(customer)
      .send({ rating: 4, comment: '' });
    expect(noText.status).toBe(422);
  });

  it('rejects duplicate reviews for the same product', async () => {
    const first = await createReview(PID2, 4, 'nice');
    expect(first.status).toBe(201);
    const res = await createReview(PID2, 4, 'again');
    expect(res.status).toBe(409);
  });

  it('reports eligibility with the customers own review status', async () => {
    const res = await request(app)
      .get(`/api/reviews/products/${PID2}/eligibility`)
      .set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.purchased).toBe(true);
    expect(res.body.data.canReview).toBe(false);
    expect(res.body.data.review.rating).toBe(4);
  });

  it('approves a pending review so it becomes public', async () => {
    const pending = await request(app).get('/api/reviews/pending').set(manager);
    const id = reviewIdFor(pending, PID2);
    const res = await request(app)
      .patch(`/api/reviews/${id}/moderate`)
      .set(manager)
      .send({ approved: true });
    expect(res.status).toBe(200);
    expect(res.body.data.isApproved).toBe(true);
    expect(res.body.data.isRejected).toBe(false);
    const listed = await request(app).get(`/api/reviews/products/${PID2}/reviews`).set(customer);
    expect(listed.body.data.find((r: { id: string }) => r.id === id)).toBeDefined();
  });

  it('rejects a review so it stays hidden and leaves the pending queue', async () => {
    const pending = await request(app).get('/api/reviews/pending').set(manager);
    const id = reviewIdFor(pending, PID);
    const res = await request(app)
      .patch(`/api/reviews/${id}/moderate`)
      .set(manager)
      .send({ approved: false });
    expect(res.status).toBe(200);
    expect(res.body.data.isApproved).toBe(false);
    expect(res.body.data.isRejected).toBe(true);
    const listed = await request(app).get(`/api/reviews/products/${PID}/reviews`).set(customer);
    expect(listed.body.data.find((r: { id: string }) => r.id === id)).toBeUndefined();
    const queue = await request(app).get('/api/reviews/pending').set(manager);
    expect(queue.body.data.find((r: { id: string }) => r.id === id)).toBeUndefined();
  });

  it('reports a review', async () => {
    await makeDeliveredOrder(PID3, VID3);
    const created = await createReview(PID3, 3, 'so so');
    expect(created.status).toBe(201);
    const res = await request(app).patch(`/api/reviews/${created.body.data.id}/report`).set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.isReported).toBe(true);
  });

  it('lets a customer see the status of their own rejected review', async () => {
    const res = await request(app)
      .get(`/api/reviews/products/${PID}/eligibility`)
      .set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.purchased).toBe(true);
    expect(res.body.data.canReview).toBe(false);
    expect(res.body.data.review.isRejected).toBe(true);
  });
});