import request from 'supertest';
import { afterAll, afterEach, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('reports API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;
  const customer = { 'x-user-id': '00000000-0000-0000-0000-000000000201', 'x-user-role': 'customer' };
  const manager = { 'x-user-id': '00000000-0000-0000-0000-000000000203', 'x-user-role': 'store_manager' };
  const salesStaff = { 'x-user-id': '00000000-0000-0000-0000-000000000204', 'x-user-role': 'sales_staff' };
  const inventoryStaff = { 'x-user-id': '00000000-0000-0000-0000-000000000205', 'x-user-role': 'inventory_staff' };
  const PID = '00000000-0000-0000-0000-000000000501';
  const PID2 = '00000000-0000-0000-0000-000000000502';
  const VID = '00000000-0000-0000-0000-000000000601';
  const VID2 = '00000000-0000-0000-0000-000000000606';

  const PAYLOAD = {
    customerName: 'Amara Okafor',
    customerPhone: '08011111111',
    customerEmail: 'amara@queenstouch.ng',
    shippingAddress: '12 Broad St, Lagos Island, Lagos',
    paymentMethod: 'bank_transfer',
  };

  async function makeOrder(
    principal: Record<string, string>,
    overrides: Partial<Record<string, unknown>> = {},
  ): Promise<{ id: string; total: number; orderNumber: string }> {
    const res = await request(app).post('/api/orders').set(principal).send({
      ...PAYLOAD,
      items: [{ productId: PID, variantId: VID, quantity: 1 }],
      ...overrides,
    });
    expect(res.status).toBe(201);
    return { id: res.body.data.id, total: Number(res.body.data.total), orderNumber: res.body.data.orderNumber };
  }

  async function submitPayment(orderId: string, amount: number, reference?: string) {
    const res = await request(app).post('/api/payments').set(customer).send({
      orderId,
      amount,
      paymentDate: '2026-08-17',
      confirmationMessage: 'Confirmed',
      ...(reference ? { reference } : {}),
    });
    return res.body.data;
  }

  async function setOrderDate(orderId: string, date: string) {
    await pool.query('UPDATE orders SET created_at = $1 WHERE id = $2', [date, orderId]);
  }

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool);
  });
  afterAll(async () => {
    await pool.end();
  });

  afterEach(async () => {
    await pool.query('UPDATE payments SET duplicate_of = NULL');
    await pool.query('DELETE FROM payments');
    await pool.query('DELETE FROM orders');
    await pool.query("UPDATE product_variants SET stock_qty = 8 WHERE id IN ($1, $2)", [VID, VID2]);
  });

  it('computes sales totals from real order data', async () => {
    const a = await makeOrder(customer);
    const b = await makeOrder(customer, { items: [{ productId: PID2, variantId: VID2, quantity: 2 }] });
    const res = await request(app).get('/api/reports/sales-summary').set(manager);
    expect(res.status).toBe(200);
    expect(res.body.data.totalOrders).toBe(2);
    expect(res.body.data.totalRevenue).toBeCloseTo(a.total + b.total, 2);
    expect(res.body.data.avgOrderValue).toBeCloseTo((a.total + b.total) / 2, 2);
    expect(res.body.data.byPaymentMethod.length).toBeGreaterThan(0);
    expect(res.body.data.daily.length).toBeGreaterThan(0);
  });

  it('applies date filters to sales summary and sales report', async () => {
    const o1 = await makeOrder(customer);
    const o2 = await makeOrder(customer);
    const o3 = await makeOrder(customer);
    await setOrderDate(o1.id, '2026-08-01T10:00:00Z');
    await setOrderDate(o2.id, '2026-08-10T10:00:00Z');
    await setOrderDate(o3.id, '2026-08-20T10:00:00Z');

    const summary = await request(app)
      .get('/api/reports/sales-summary?from=2026-08-09&to=2026-08-11')
      .set(manager);
    expect(summary.status).toBe(200);
    expect(summary.body.data.totalOrders).toBe(1);

    const report = await request(app)
      .get('/api/reports/sales?from=2026-08-19&to=2026-08-21')
      .set(manager);
    expect(report.status).toBe(200);
    expect(report.body.data).toHaveLength(1);
    expect(report.body.data[0].orderNumber).toBe(o3.orderNumber);
    expect(report.body.data[0].customerName).toBe('Amara Okafor');
  });

  it('does not count unverified payments as verified revenue', async () => {
    const order = await makeOrder(customer);
    const payment = await submitPayment(order.id, order.total);

    const before = await request(app).get('/api/reports/sales-summary').set(manager);
    expect(before.body.data.verifiedRevenue).toBe(0);
    expect(before.body.data.outstandingBalance).toBeCloseTo(order.total, 2);

    const verified = await request(app).post(`/api/payments/${payment.id}/verify`).set(manager);
    expect(verified.status).toBe(200);

    const after = await request(app).get('/api/reports/sales-summary').set(manager);
    expect(after.body.data.verifiedRevenue).toBeCloseTo(order.total, 2);
    expect(after.body.data.outstandingBalance).toBe(0);
  });

  it('computes outstanding balances and payment statuses per order', async () => {
    const order = await makeOrder(customer, { items: [{ productId: PID, variantId: VID, quantity: 2 }] });
    const payment = await submitPayment(order.id, 100);
    await request(app).post(`/api/payments/${payment.id}/verify`).set(manager);

    const res = await request(app).get('/api/reports/sales').set(manager);
    expect(res.status).toBe(200);
    const row = res.body.data.find((r: { orderNumber: string }) => r.orderNumber === order.orderNumber);
    expect(row).toBeTruthy();
    expect(Number(row.verified)).toBe(100);
    expect(Number(row.remainingBalance)).toBeCloseTo(order.total - 100, 2);
    expect(row.paymentStatus).toBe('partially_paid');
    expect(row.orderStatus).toBe('pending');

    const summary = await request(app).get('/api/reports/sales-summary').set(manager);
    const partial = summary.body.data.ordersByPaymentStatus.find(
      (r: { paymentStatus: string }) => r.paymentStatus === 'partially_paid',
    );
    expect(partial.orders).toBe(1);
  });

  it('reports best-selling products from real order data', async () => {
    await makeOrder(customer, { items: [{ productId: PID, variantId: VID, quantity: 3 }] });
    await makeOrder(customer, { items: [{ productId: PID2, variantId: VID2, quantity: 1 }] });

    const res = await request(app).get('/api/reports/top-products').set(manager);
    expect(res.status).toBe(200);
    expect(res.body.data[0].name).toBe('Rosé Midi Wrap Dress');
    expect(res.body.data[0].quantitySold).toBe(3);
    expect(res.body.data[0].revenue).toBeGreaterThan(0);
    expect(res.body.data[1].name).toBe('Velvet Blush Blazer');
  });

  it('filters best sellers by date range', async () => {
    const o1 = await makeOrder(customer);
    await setOrderDate(o1.id, '2026-08-01T10:00:00Z');

    const inRange = await request(app)
      .get('/api/reports/top-products?from=2026-08-01&to=2026-08-02')
      .set(manager);
    expect(inRange.body.data.find((r: { name: string }) => r.name === 'Rosé Midi Wrap Dress')).toBeTruthy();

    const outRange = await request(app)
      .get('/api/reports/top-products?from=2026-09-01&to=2026-09-02')
      .set(manager);
    expect(outRange.body.data).toEqual([]);
  });

  it('inventory report uses real stock and thresholds', async () => {
    await pool.query('UPDATE product_variants SET stock_qty = 0 WHERE id = $1', [VID]);
    await pool.query('UPDATE product_variants SET stock_qty = 3 WHERE id = $1', [VID2]);

    const res = await request(app).get('/api/reports/inventory').set(manager);
    expect(res.status).toBe(200);
    const out = res.body.data.find((r: { sku: string }) => r.sku === 'QT-501-XS');
    expect(out.stockQty).toBe(0);
    expect(out.stockStatus).toBe('out');
    expect(out.productName).toBe('Rosé Midi Wrap Dress');
    const low = res.body.data.find((r: { sku: string }) => r.sku === 'QT-502-S');
    expect(low.stockQty).toBe(3);
    expect(low.stockThreshold).toBe(5);
    expect(low.stockStatus).toBe('low');

    const summary = await request(app).get('/api/reports/inventory-summary').set(manager);
    expect(summary.status).toBe(200);
    const expOut = await pool.query('SELECT COUNT(*)::int AS c FROM product_variants WHERE stock_qty = 0');
    const expLow = await pool.query(
      `SELECT COUNT(*)::int AS c FROM product_variants v
       JOIN products p ON p.id = v.product_id
       WHERE v.stock_qty > 0 AND v.stock_qty < p.stock_threshold`,
    );
    expect(summary.body.data.outOfStock).toBe(expOut.rows[0].c);
    expect(summary.body.data.lowStock).toBe(expLow.rows[0].c);
    expect(summary.body.data.totalProducts).toBe(16);
  });

  it('customer statistics use real data', async () => {
    const noOrders = await request(app).get('/api/reports/customer-summary').set(manager);
    expect(noOrders.status).toBe(200);
    expect(noOrders.body.data.totalCustomers).toBe(1);
    expect(noOrders.body.data.customersWithOrders).toBe(0);

    await makeOrder(customer);
    const res = await request(app).get('/api/reports/customer-summary').set(manager);
    expect(res.body.data.customersWithOrders).toBe(1);
    expect(res.body.data.topCustomers[0].fullName).toBe('Amara Okafor');
    expect(res.body.data.topCustomers[0].orders).toBe(1);
    expect(res.body.data.topCustomers[0].spend).toBeGreaterThan(0);
  });

  it('orders summary reflects real statuses', async () => {
    const order = await makeOrder(customer);
    await request(app).patch(`/api/orders/${order.id}/status`).set(manager).send({ status: 'delivered' });
    const res = await request(app).get('/api/reports/orders').set(manager);
    expect(res.status).toBe(200);
    expect(res.body.data.totalOrders).toBe(1);
    const delivered = res.body.data.byStatus.find((r: { status: string }) => r.status === 'delivered');
    expect(delivered.count).toBe(1);
    expect(delivered.revenue).toBeCloseTo(order.total, 2);
  });

  it('payments summary respects verification status', async () => {
    const order = await makeOrder(customer);
    const pending = await submitPayment(order.id, 100, 'MP-PENDING-1');
    const res = await request(app).get('/api/reports/payments').set(manager);
    expect(res.status).toBe(200);
    expect(res.body.data.pendingVerification).toBe(1);
    expect(res.body.data.successful).toBe(0);
    expect(res.body.data.totalProcessed).toBe(0);

    await request(app).post(`/api/payments/${pending.id}/verify`).set(manager);
    const after = await request(app).get('/api/reports/payments').set(manager);
    expect(after.body.data.successful).toBe(1);
    expect(after.body.data.totalProcessed).toBeCloseTo(100, 2);
    expect(after.body.data.pendingVerification).toBe(0);
  });

  it('installments summary computes outstanding balance', async () => {
    const order = await makeOrder(customer, {
      paymentMethod: 'installment',
      installmentRequested: true,
    });
    const plan = await pool.query('SELECT * FROM installments WHERE order_id = $1', [order.id]);
    expect(plan.rows).toHaveLength(1);
    const res = await request(app).get('/api/reports/installments').set(manager);
    expect(res.status).toBe(200);
    expect(res.body.data.active).toBe(1);
    expect(res.body.data.outstandingBalance).toBeCloseTo(order.total, 2);
    expect(res.body.data.totalPaid).toBe(0);
  });

  it('handles empty report results', async () => {
    const res = await request(app)
      .get('/api/reports/sales-summary?from=2020-01-01&to=2020-01-02')
      .set(manager);
    expect(res.status).toBe(200);
    expect(res.body.data.totalOrders).toBe(0);
    expect(res.body.data.totalRevenue).toBe(0);

    const report = await request(app).get('/api/reports/sales?from=2020-01-01&to=2020-01-02').set(manager);
    expect(report.body.data).toEqual([]);
    const top = await request(app).get('/api/reports/top-products?from=2020-01-01&to=2020-01-02').set(manager);
    expect(top.body.data).toEqual([]);
  });

  it('allows all staff roles and denies customers', async () => {
    for (const role of [manager, salesStaff, inventoryStaff]) {
      const res = await request(app).get('/api/reports/sales-summary').set(role);
      expect(res.status).toBe(200);
      const inv = await request(app).get('/api/reports/inventory').set(role);
      expect(inv.status).toBe(200);
    }
    for (const path of [
      '/api/reports/sales-summary',
      '/api/reports/sales',
      '/api/reports/top-products',
      '/api/reports/inventory',
      '/api/reports/inventory-summary',
      '/api/reports/customer-summary',
      '/api/reports/orders',
      '/api/reports/payments',
      '/api/reports/installments',
    ]) {
      const res = await request(app).get(path).set(customer);
      expect(res.status).toBe(403);
    }
  });
});