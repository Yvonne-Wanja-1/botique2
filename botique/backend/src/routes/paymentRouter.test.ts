import request from 'supertest';
import { afterAll, afterEach, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('payments API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;
  const customer = { 'x-user-id': '00000000-0000-0000-0000-000000000201', 'x-user-role': 'customer' };
  const otherCustomer = { 'x-user-id': '00000000-0000-0000-0000-000000000202', 'x-user-role': 'customer' };
  const manager = { 'x-user-id': '00000000-0000-0000-0000-000000000203', 'x-user-role': 'store_manager' };
  const PID = '00000000-0000-0000-0000-000000000501';
  const VID = '00000000-0000-0000-0000-000000000601';

  afterEach(async () => {
    await pool.query('UPDATE payments SET duplicate_of = NULL');
    await pool.query('DELETE FROM payments');
    await pool.query('DELETE FROM orders');
    await pool.query('UPDATE product_variants SET stock_qty = 8 WHERE id = $1', [VID]);
  });

  async function makeOrder(principal: Record<string, string>, qty = 1): Promise<string> {
    const res = await request(app).post('/api/orders').set(principal).send({
      customerName: 'Amara Okafor',
      customerPhone: '08011111111',
      customerEmail: 'amara@queenstouch.ng',
      shippingAddress: '12 Broad St, Lagos Island, Lagos',
      paymentMethod: 'paybill',
      items: [{ productId: PID, variantId: VID, quantity: qty }],
    });
    return res.body.data.id;
  }

  function submitBody(overrides: Record<string, unknown> = {}) {
    return {
      orderId: 'ignored', // replaced below
      amount: 100,
      paymentDate: '2026-08-17',
      confirmationMessage: 'Confirmed via M-Pesa, balance is fine',
      ...overrides,
    };
  }

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool);
  });
  afterAll(async () => {
    await pool.end();
  });

  it('submits a payment proof as pending_verification', async () => {
    const orderId = await makeOrder(customer);
    const res = await request(app)
      .post('/api/payments')
      .set(customer)
      .send({ ...submitBody({ orderId, amount: 100 }) });
    expect(res.status).toBe(201);
    expect(res.body.data.status).toBe('pending_verification');
    expect(res.body.data.amount).toBe(100);
    expect(res.body.data.confirmationMessage).toBe('Confirmed via M-Pesa, balance is fine');
    const order = await request(app).get(`/api/orders/${orderId}`).set(customer);
    expect(order.body.data.paymentStatus).toBe('pending_verification');
    expect(order.body.data.paymentSummary.pending).toBe(100);
    expect(order.body.data.paymentSummary.remaining).toBe(order.body.data.total);
  });

  it('rejects a submission that exceeds the order balance', async () => {
    const orderId = await makeOrder(customer);
    const res = await request(app)
      .post('/api/payments')
      .set(customer)
      .send({ ...submitBody({ orderId, amount: 999999 }) });
    expect(res.status).toBe(409);
  });

  it('flags duplicate submissions with duplicateOf instead of rejecting', async () => {
    const orderId = await makeOrder(customer);
    await request(app).post('/api/payments').set(customer).send({ ...submitBody({ orderId, amount: 100, reference: 'MP-111' }) });
    const dup = await request(app).post('/api/payments').set(customer).send({ ...submitBody({ orderId, amount: 100, reference: 'MP-111' }) });
    expect(dup.status).toBe(201);
    expect(dup.body.data.duplicateOf).toBeTruthy();
  });

  it('staff verifies a payment and advances the order to paid when fully paid', async () => {
    const orderId = await makeOrder(customer);
    const orderRes = await request(app).get(`/api/orders/${orderId}`).set(customer);
    const total = orderRes.body.data.total;
    const sub = await request(app).post('/api/payments').set(customer).send({ ...submitBody({ orderId, amount: total }) });
    expect(sub.status).toBe(201);
    const verify = await request(app).post(`/api/payments/${sub.body.data.id}/verify`).set(manager);
    expect(verify.status).toBe(200);
    expect(verify.body.data.status).toBe('successful');
    expect(verify.body.data.verifiedBy).toBe('00000000-0000-0000-0000-000000000203');
    const order = await request(app).get(`/api/orders/${orderId}`).set(customer);
    expect(order.body.data.status).toBe('paid');
    expect(order.body.data.paymentStatus).toBe('successful');
    expect(order.body.data.paymentSummary.verified).toBe(total);
  });

  it('keeps an order partially_paid when only part is verified', async () => {
    const orderId = await makeOrder(customer, 2); // subtotal 2 * unit price -> total > 100
    const sub = await request(app).post('/api/payments').set(customer).send({ ...submitBody({ orderId, amount: 100 }) });
    await request(app).post(`/api/payments/${sub.body.data.id}/verify`).set(manager);
    const order = await request(app).get(`/api/orders/${orderId}`).set(customer);
    expect(order.body.data.paymentStatus).toBe('partially_paid');
    expect(order.body.data.status).toBe('pending');
  });

  it('staff rejects a payment with a reason', async () => {
    const orderId = await makeOrder(customer);
    const sub = await request(app).post('/api/payments').set(customer).send({ ...submitBody({ orderId, amount: 100 }) });
    const reject = await request(app).post(`/api/payments/${sub.body.data.id}/reject`).set(manager).send({ reason: 'Transaction not found' });
    expect(reject.status).toBe(200);
    expect(reject.body.data.status).toBe('rejected');
    expect(reject.body.data.rejectReason).toBe('Transaction not found');
  });

  it('does not let a customer verify or reject', async () => {
    const orderId = await makeOrder(customer);
    const sub = await request(app).post('/api/payments').set(customer).send({ ...submitBody({ orderId, amount: 100 }) });
    const verify = await request(app).post(`/api/payments/${sub.body.data.id}/verify`).set(customer);
    const reject = await request(app).post(`/api/payments/${sub.body.data.id}/reject`).set(customer).send({ reason: 'x' });
    expect(verify.status).toBe(403);
    expect(reject.status).toBe(403);
  });

  it('lists payments for an order; staff see all, customers only their own', async () => {
    const myOrder = await makeOrder(customer);
    await request(app).post('/api/payments').set(customer).send({ ...submitBody({ orderId: myOrder, amount: 100 }) });
    const otherOrder = await makeOrder(otherCustomer);
    await request(app).post('/api/payments').set(otherCustomer).send({ ...submitBody({ orderId: otherOrder, amount: 100 }) });

    const staff = await request(app).get('/api/payments').set(manager);
    expect(staff.status).toBe(200);
    expect(staff.body.data.rows.length).toBeGreaterThanOrEqual(2);
    expect(staff.body.data.rows[0].orderNumber).toMatch(/^QT-/);
    expect(staff.body.data.rows[0].customerName).toBeTruthy();

    const own = await request(app).get('/api/payments').set(customer);
    expect(own.status).toBe(200);
    expect(own.body.data.rows.length).toBe(1);
  });

  it('returns Family Bank paybill transfer details', async () => {
    const res = await request(app).get('/api/payments/transfer-details').set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.bankName).toBe('Family Bank');
    expect(res.body.data.paybillNumber).toBe('222111');
    expect(res.body.data.accountNumber).toBe('65727');
  });

  it('prevents a customer from reading another user\'s payment list', async () => {
    const orderId = await makeOrder(otherCustomer);
    const res = await request(app).get(`/api/payments/orders/${orderId}`).set(customer);
    expect(res.status).toBe(403);
  });
});
