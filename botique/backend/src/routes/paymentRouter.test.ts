import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('payments API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;
  const customer = { 'x-user-id': '00000000-0000-0000-0000-000000000201', 'x-user-role': 'customer' };
  const otherCustomer = { 'x-user-id': '00000000-0000-0000-0000-000000000202', 'x-user-role': 'customer' };
  const PID = '00000000-0000-0000-0000-000000000501';
  const VID = '00000000-0000-0000-0000-000000000601';

  async function makeOrder(principal: Record<string, string>): Promise<string> {
    const res = await request(app).post('/api/orders').set(principal).send({
      customerName: 'Amara Okafor',
      customerPhone: '08011111111',
      customerEmail: 'amara@queenstouch.ng',
      shippingAddress: '12 Broad St, Lagos Island, Lagos',
      paymentMethod: 'bank_transfer',
      items: [{ productId: PID, variantId: VID, quantity: 1 }],
    });
    return res.body.data.id;
  }

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool);
  });
  afterAll(async () => {
    await pool.end();
  });

  it('returns a pending payment for an order', async () => {
    const orderId = await makeOrder(customer);
    const res = await request(app).get(`/api/payments/${orderId}`).set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe('pending');
    expect(res.body.data.reference).toMatch(/^PAY-/);
    expect(res.body.data.orderId).toBe(orderId);
  });

  it('verifies payment and advances the order to paid', async () => {
    const orderId = await makeOrder(customer);
    const res = await request(app).post(`/api/payments/${orderId}/verify`).set(customer).send({ reference: 'REF-123' });
    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe('successful');
    expect(res.body.data.reference).toBe('REF-123');
    const order = await request(app).get(`/api/orders/${orderId}`).set(customer);
    expect(order.body.data.status).toBe('paid');
    expect(order.body.data.paymentStatus).toBe('successful');
  });

  it('prevents a customer from reading another user\'s payment', async () => {
    const orderId = await makeOrder(otherCustomer);
    const res = await request(app).get(`/api/payments/${orderId}`).set(customer);
    expect(res.status).toBe(403);
  });

  it('returns transfer details', async () => {
    const res = await request(app).get('/api/payments/transfer-details').set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.bankName).toBeTruthy();
    expect(res.body.data.accountNumber).toBeTruthy();
  });
});