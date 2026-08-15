import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('installments API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;
  const customer = { 'x-user-id': '00000000-0000-0000-0000-000000000201', 'x-user-role': 'customer' };
  const otherCustomer = { 'x-user-id': '00000000-0000-0000-0000-000000000202', 'x-user-role': 'customer' };
  const PID = '00000000-0000-0000-0000-000000000501';
  const VID = '00000000-0000-0000-0000-000000000601';

  async function makePaidOrder(): Promise<string> {
    const orderRes = await request(app).post('/api/orders').set(customer).send({
      customerName: 'Amara Okafor',
      customerPhone: '08011111111',
      customerEmail: 'amara@queenstouch.ng',
      shippingAddress: '12 Broad St, Lagos Island, Lagos',
      paymentMethod: 'bank_transfer',
      items: [{ productId: PID, variantId: VID, quantity: 1 }],
    });
    const orderId = orderRes.body.data.id;
    await request(app).post(`/api/payments/${orderId}/verify`).set(customer).send({ reference: `REF-${orderId}` });
    return orderId;
  }

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool);
  });
  afterAll(async () => {
    await pool.end();
  });

  it('creates a 2-payment installment plan', async () => {
    const orderId = await makePaidOrder();
    const res = await request(app).post(`/api/installments/orders/${orderId}/plans`).set(customer).send({ plans: 2 });
    expect(res.status).toBe(201);
    expect(res.body.data.payments).toHaveLength(2);
    expect(res.body.data.termMonths).toBe(2);
  });

  it('lists the plan for the order', async () => {
    const orderId = await makePaidOrder();
    await request(app).post(`/api/installments/orders/${orderId}/plans`).set(customer).send({ plans: 2 });
    const res = await request(app).get(`/api/installments/orders/${orderId}/plans`).set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.termMonths).toBe(2);
  });

  it('rejects a second plan on the same order', async () => {
    const orderId = await makePaidOrder();
    await request(app).post(`/api/installments/orders/${orderId}/plans`).set(customer).send({ plans: 2 });
    const res = await request(app).post(`/api/installments/orders/${orderId}/plans`).set(customer).send({ plans: 3 });
    expect(res.status).toBe(409);
  });

  it('pays off both payments and marks the plan completed', async () => {
    const orderId = await makePaidOrder();
    await request(app).post(`/api/installments/orders/${orderId}/plans`).set(customer).send({ plans: 2 });
    const plan = await request(app).get(`/api/installments/orders/${orderId}/plans`).set(customer);
    for (const payment of plan.body.data.payments) {
      const pay = await request(app).post(`/api/installments/payments/${payment.id}/pay`).set(customer).send({ amount: payment.amount });
      expect(pay.status).toBe(200);
      expect(pay.body.data.isPaid).toBe(true);
    }
    const planAfter = await request(app).get(`/api/installments/orders/${orderId}/plans`).set(customer);
    expect(planAfter.body.data.status).toBe('completed');
  });

  it('prevents a customer from reading another user\'s plan', async () => {
    const orderRes = await request(app).post('/api/orders').set(otherCustomer).send({
      customerName: 'Bola Adeyemi',
      customerPhone: '08022222222',
      customerEmail: 'bola@queenstouch.ng',
      shippingAddress: '3 Marina Rd, Lagos Island, Lagos',
      paymentMethod: 'bank_transfer',
      items: [{ productId: PID, variantId: VID, quantity: 1 }],
    });
    const orderId = orderRes.body.data.id;
    await request(app).post(`/api/payments/${orderId}/verify`).set(otherCustomer).send({ reference: `REF-${orderId}` });
    await request(app).post(`/api/installments/orders/${orderId}/plans`).set(otherCustomer).send({ plans: 2 });
    const res = await request(app).get(`/api/installments/orders/${orderId}/plans`).set(customer);
    expect(res.status).toBe(403);
  });
});