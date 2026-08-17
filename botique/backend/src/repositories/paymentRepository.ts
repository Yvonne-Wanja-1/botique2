import { randomUUID } from 'node:crypto';
import type { Pool, PoolClient } from 'pg';
import type { PaymentMethod, PaymentStatus } from '../models/index.js';
import { ConflictError, NotFoundError } from '../utils/errors.js';

export interface Payment {
  id: string;
  orderId: string;
  customerId: string;
  orderNumber: string | null;
  customerName: string | null;
  amount: number;
  method: PaymentMethod;
  status: PaymentStatus;
  reference: string | null;
  paymentDate: string | null;
  confirmationMessage: string | null;
  note: string | null;
  verifiedAt: string | null;
  verifiedBy: string | null;
  rejectedAt: string | null;
  rejectedBy: string | null;
  rejectReason: string | null;
  duplicateOf: string | null;
  createdAt: string;
  updatedAt: string | null;
}

export interface SubmitPaymentInput {
  orderId: string;
  customerId: string;
  amount: number;
  paymentDate: string;
  reference?: string | null;
  confirmationMessage: string;
  note?: string | null;
}

const DAY_MS = 24 * 60 * 60 * 1000;

function mapPayment(r: Record<string, unknown>): Payment {
  return {
    id: String(r.id),
    orderId: String(r.order_id),
    customerId: String(r.customer_id),
    orderNumber: r.order_number ? String(r.order_number) : null,
    customerName: r.customer_name ? String(r.customer_name) : null,
    amount: Number(r.amount),
    method: r.method as PaymentMethod,
    status: r.status as PaymentStatus,
    reference: r.reference ? String(r.reference) : null,
    paymentDate: r.payment_date ? String(r.payment_date) : null,
    confirmationMessage: r.confirmation_message ? String(r.confirmation_message) : null,
    note: r.note ? String(r.note) : null,
    verifiedAt: r.verified_at ? String(r.verified_at) : null,
    verifiedBy: r.verified_by ? String(r.verified_by) : null,
    rejectedAt: r.rejected_at ? String(r.rejected_at) : null,
    rejectedBy: r.rejected_by ? String(r.rejected_by) : null,
    rejectReason: r.reject_reason ? String(r.reject_reason) : null,
    duplicateOf: r.duplicate_of ? String(r.duplicate_of) : null,
    createdAt: String(r.created_at),
    updatedAt: r.updated_at ? String(r.updated_at) : null,
  };
}

const SELECT_PAYMENT = `SELECT p.*, o.order_number, o.customer_name
  FROM payments p JOIN orders o ON o.id = p.order_id`;

function sameReference(a: string | null | undefined, b: string | null | undefined): boolean {
  if (!a || !b) return false;
  return a.trim().toLowerCase() === b.trim().toLowerCase();
}

function withinDays(a: string, b: string, days: number): boolean {
  const da = new Date(a).getTime();
  const db = new Date(b).getTime();
  return Math.abs(da - db) <= days * DAY_MS;
}

export class PaymentRepository {
  constructor(private pool: Pool) {}

  private async setOrderPaymentStatus(
    q: PoolClient,
    orderId: string,
    orderStatus: 'pending' | 'paid',
    paymentStatus: PaymentStatus,
  ): Promise<void> {
    await q.query(
      'UPDATE orders SET status = $2, payment_status = $3, updated_at = now() WHERE id = $1',
      [orderId, orderStatus, paymentStatus],
    );
  }

  async listForOrder(orderId: string): Promise<Payment[]> {
    const res = await this.pool.query(
      `${SELECT_PAYMENT} WHERE p.order_id = $1 ORDER BY p.created_at DESC`,
      [orderId],
    );
    return res.rows.map(mapPayment);
  }

  async listForCustomer(customerId: string): Promise<Payment[]> {
    const res = await this.pool.query(
      `${SELECT_PAYMENT} WHERE p.customer_id = $1 ORDER BY p.created_at DESC`,
      [customerId],
    );
    return res.rows.map(mapPayment);
  }

  async listAll(params: { status?: string; page?: number; pageSize?: number }) {
    const conditions: string[] = [];
    const values: unknown[] = [];
    if (params.status) {
      values.push(params.status);
      conditions.push(`p.status = $${values.length}`);
    }
    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const page = Math.max(1, params.page ?? 1);
    const pageSize = Math.min(100, Math.max(1, params.pageSize ?? 20));
    const offset = (page - 1) * pageSize;
    const countRes = await this.pool.query(`SELECT count(*)::int AS n FROM payments p ${where}`, values);
    const res = await this.pool.query(
      `${SELECT_PAYMENT} ${where} ORDER BY p.created_at DESC LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, offset],
    );
    return { rows: res.rows.map(mapPayment), total: Number(countRes.rows[0]?.n ?? 0) };
  }

  async getById(id: string): Promise<Payment | null> {
    const res = await this.pool.query(`${SELECT_PAYMENT} WHERE p.id = $1`, [id]);
    return res.rows.length ? mapPayment(res.rows[0]) : null;
  }

  async submit(input: SubmitPaymentInput): Promise<Payment> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const orderRes = await client.query(
        'SELECT id, customer_id, total, status, payment_status FROM orders WHERE id = $1 FOR UPDATE',
        [input.orderId],
      );
      if (!orderRes.rows.length) throw new NotFoundError('Order not found');
      const order = orderRes.rows[0];
      if (String(order.customer_id) !== input.customerId) {
        throw new ConflictError('Order does not belong to this customer');
      }
      if (String(order.status) === 'cancelled') {
        throw new ConflictError('Cancelled orders cannot accept payments');
      }

      const total = Number(order.total);
      const existing = await client.query(
        "SELECT id, amount, reference, payment_date, status FROM payments WHERE order_id = $1 AND status != 'rejected'",
        [input.orderId],
      );
      const nonRejectedSum = existing.rows.reduce((s, r) => s + Number(r.amount), 0);
      if (nonRejectedSum + input.amount > total) {
        throw new ConflictError('Payment would exceed the order balance');
      }

      let duplicateId: string | null = null;
      for (const r of existing.rows) {
        if (Number(r.amount) !== input.amount) continue;
        if (sameReference(r.reference, input.reference)) {
          duplicateId = String(r.id);
          break;
        }
        if (r.payment_date && withinDays(String(r.payment_date), input.paymentDate, 2)) {
          duplicateId = String(r.id);
          break;
        }
      }

      const paymentId = randomUUID();
      await client.query(
        `INSERT INTO payments (id, order_id, customer_id, amount, method, status, reference,
            payment_date, confirmation_message, note, duplicate_of)
         VALUES ($1,$2,$3,$4,'paybill','pending_verification',$5,$6,$7,$8,$9)`,
        [
          paymentId,
          input.orderId,
          input.customerId,
          input.amount,
          input.reference ?? null,
          input.paymentDate,
          input.confirmationMessage,
          input.note ?? null,
          duplicateId,
        ],
      );

      if (String(order.payment_status) === 'pending') {
        await client.query(
          "UPDATE orders SET payment_status = 'pending_verification', updated_at = now() WHERE id = $1",
          [input.orderId],
        );
      }

      await client.query('COMMIT');
      const payment = await this.getById(paymentId);
      if (!payment) throw new NotFoundError('Payment was not created');
      return payment;
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }

  async verify(id: string, staffUserId: string): Promise<Payment> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const payRes = await client.query(
        'SELECT * FROM payments WHERE id = $1 FOR UPDATE',
        [id],
      );
      if (!payRes.rows.length) throw new NotFoundError('Payment not found');
      const pay = payRes.rows[0];
      if (String(pay.status) !== 'pending_verification') {
        throw new ConflictError('Only pending_verification payments can be verified');
      }

      await client.query(
        "UPDATE payments SET status = 'successful', verified_at = now(), verified_by = $2, updated_at = now() WHERE id = $1",
        [id, staffUserId],
      );

      const orderRes = await client.query(
        'SELECT id, total, status FROM orders WHERE id = $1 FOR UPDATE',
        [pay.order_id],
      );
      const order = orderRes.rows[0];
      const total = Number(order.total);
      const sums = await client.query(
        "SELECT COALESCE(SUM(amount),0) AS verified FROM payments WHERE order_id = $1 AND status = 'successful'",
        [pay.order_id],
      );
      const verified = Number(sums.rows[0].verified);

      if (verified >= total) {
        await this.setOrderPaymentStatus(client, String(pay.order_id), 'paid', 'successful');
      } else {
        await this.setOrderPaymentStatus(client, String(pay.order_id), 'pending', 'partially_paid');
      }

      await client.query('COMMIT');
      const payment = await this.getById(id);
      if (!payment) throw new NotFoundError('Payment not found');
      return payment;
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }

  async reject(id: string, staffUserId: string, reason: string): Promise<Payment> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const payRes = await client.query(
        'SELECT * FROM payments WHERE id = $1 FOR UPDATE',
        [id],
      );
      if (!payRes.rows.length) throw new NotFoundError('Payment not found');
      const pay = payRes.rows[0];
      if (String(pay.status) !== 'pending_verification') {
        throw new ConflictError('Only pending_verification payments can be rejected');
      }

      await client.query(
        "UPDATE payments SET status = 'rejected', rejected_at = now(), rejected_by = $2, reject_reason = $3, updated_at = now() WHERE id = $1",
        [id, staffUserId, reason],
      );

      const pending = await client.query(
        "SELECT COALESCE(SUM(amount),0) AS n FROM payments WHERE order_id = $1 AND status = 'pending_verification'",
        [pay.order_id],
      );
      const verified = await client.query(
        "SELECT COALESCE(SUM(amount),0) AS n FROM payments WHERE order_id = $1 AND status = 'successful'",
        [pay.order_id],
      );
      let paymentStatus: PaymentStatus = 'pending';
      if (Number(verified.rows[0].n) > 0) paymentStatus = 'partially_paid';
      else if (Number(pending.rows[0].n) > 0) paymentStatus = 'pending_verification';
      await this.setOrderPaymentStatus(client, String(pay.order_id), 'pending', paymentStatus);

      await client.query('COMMIT');
      const payment = await this.getById(id);
      if (!payment) throw new NotFoundError('Payment not found');
      return payment;
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }

  transferDetails() {
    return {
      bankName: 'Family Bank',
      paybillNumber: '222111',
      accountNumber: '65727',
    };
  }
}