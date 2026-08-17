import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('orders API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;
  const customer = { 'x-user-id': '00000000-0000-0000-0000-000000000201', 'x-user-role': 'customer' };
  const manager = { 'x-user-id': '00000000-0000-0000-0000-000000000203', 'x-user-role': 'store_manager' };
  const PID = '00000000-0000-0000-0000-000000000501';
  const VID = '00000000-0000-0000-0000-000000000601';
  const payload = {
    customerName: 'Amara Okafor',
    customerPhone: '08011111111',
    customerEmail: 'amara@queenstouch.ng',
    shippingAddress: '12 Broad St, Lagos Island, Lagos',
    paymentMethod: 'bank_transfer',
    items: [{ productId: PID, variantId: VID, quantity: 1 }],
  };

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool);
  });
  afterAll(async () => {
    await pool.end();
  });

  it('creates an order and decrements stock', async () => {
    const seed = await pool.query('SELECT stock_qty FROM product_variants WHERE id = $1', [VID]);
    const res = await request(app).post('/api/orders').set(customer).send(payload);
    expect(res.status).toBe(201);
    expect(res.body.data.orderNumber).toMatch(/^QT-/);
    expect(res.body.data.status).toBe('pending');
    expect(res.body.data.shippingFee).toBeGreaterThan(0);
    expect(res.body.data.items).toHaveLength(1);
    const after = await pool.query('SELECT stock_qty FROM product_variants WHERE id = $1', [VID]);
    expect(Number(after.rows[0].stock_qty)).toBe(Number(seed.rows[0].stock_qty) - 1);
  });

  it('rejects insufficient stock', async () => {
    const res = await request(app).post('/api/orders').set(customer).send({
      ...payload,
      items: [{ productId: PID, variantId: VID, quantity: 999999 }],
    });
    expect(res.status).toBe(409);
  });

  it('rejects an invalid promo code', async () => {
    const res = await request(app).post('/api/orders').set(customer).send({ ...payload, promotionCode: 'NOPE' });
    expect(res.status).toBe(422);
  });

  it('applies the FLAT15 promo discount', async () => {
    const res = await request(app)
      .post('/api/orders')
      .set(customer)
      .send({ ...payload, promotionCode: 'FLAT15', items: [{ productId: PID, variantId: VID, quantity: 2 }] });
    expect(res.status).toBe(201);
    expect(res.body.data.discount).toBe(15);
  });

  it('lists the customer\'s own orders', async () => {
    const res = await request(app).get('/api/orders').set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.length).toBeGreaterThanOrEqual(2);
  });

  it('prevents a customer from reading another user\'s order', async () => {
    const otherCustomer = { 'x-user-id': '00000000-0000-0000-0000-000000000202', 'x-user-role': 'customer' };
    const otherOrder = await request(app).post('/api/orders').set(otherCustomer).send(payload);
    expect(otherOrder.status).toBe(201);
    const res = await request(app).get(`/api/orders/${otherOrder.body.data.id}`).set(customer);
    expect(res.status).toBe(403);
  });

  it('staff can update order status to delivered', async () => {
    const list = await request(app).get('/api/orders').set(manager);
    const orderId = list.body.data.rows[0].id;
    const res = await request(app).patch(`/api/orders/${orderId}/status`).set(manager).send({ status: 'delivered' });
    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe('delivered');
  });

  it('does not auto-create a payment row for a new order', async () => {
    const res = await request(app).post('/api/orders').set(customer).send(payload);
    expect(res.status).toBe(201);
    const pays = await pool.query('SELECT * FROM payments WHERE order_id = $1', [res.body.data.id]);
    expect(pays.rows).toHaveLength(0);
  });

  it('includes an empty payments list and summary on order detail', async () => {
    const res = await request(app).post('/api/orders').set(customer).send(payload);
    const orderId = res.body.data.id;
    const detail = await request(app).get(`/api/orders/${orderId}`).set(customer);
    expect(detail.status).toBe(200);
    expect(detail.body.data.payments).toEqual([]);
    expect(detail.body.data.paymentSummary).toEqual({
      total: detail.body.data.total,
      verified: 0,
      pending: 0,
      remaining: detail.body.data.total,
    });
  });

  it('auto-creates an installment plan when installmentRequested is true', async () => {
    const res = await request(app)
      .post('/api/orders')
      .set(customer)
      .send({ ...payload, paymentMethod: 'installment', installmentRequested: true });
    expect(res.status).toBe(201);
    const plans = await pool.query('SELECT * FROM installments WHERE order_id = $1', [res.body.data.id]);
    expect(plans.rows).toHaveLength(1);
    expect(plans.rows[0].term_months).toBe(3);
  });
});