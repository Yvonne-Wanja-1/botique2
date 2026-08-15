import { randomUUID } from 'node:crypto';
import type { Pool } from 'pg';
import { toNumber } from '../models/index.js';
import { ConflictError, NotFoundError } from '../utils/errors.js';

export interface InstallmentPaymentRow {
  id: string;
  installmentId: string;
  amount: number;
  dueDate: string;
  paidAt: string | null;
  isPaid: boolean;
}

export interface Installment {
  id: string;
  orderId: string;
  customerId: string;
  totalAmount: number;
  amountPaid: number;
  termMonths: number;
  status: string;
  approvedBy: string | null;
  approvedAt: string | null;
  payments: InstallmentPaymentRow[];
}

function addMonths(date: Date, months: number): Date {
  const d = new Date(date);
  d.setMonth(d.getMonth() + months);
  return d;
}

function mapPayment(row: Record<string, unknown>): InstallmentPaymentRow {
  return {
    id: String(row.id),
    installmentId: String(row.installment_id),
    amount: Number(row.amount),
    dueDate: String(row.due_date),
    paidAt: row.paid_at ? String(row.paid_at) : null,
    isPaid: Boolean(row.is_paid),
  };
}

export class InstallmentRepository {
  constructor(private pool: Pool) {}

  async getByOrder(orderId: string): Promise<Installment | null> {
    const res = await this.pool.query(
      'SELECT * FROM installments WHERE order_id = $1 ORDER BY created_at DESC LIMIT 1',
      [orderId],
    );
    if (!res.rows.length) return null;
    const r = res.rows[0];
    const payments = await this.pool.query(
      'SELECT * FROM installment_payments WHERE installment_id = $1 ORDER BY due_date ASC',
      [r.id],
    );
    return {
      id: String(r.id),
      orderId: String(r.order_id),
      customerId: String(r.customer_id),
      totalAmount: Number(r.total_amount),
      amountPaid: Number(r.amount_paid),
      termMonths: toNumber(r.term_months),
      status: String(r.status),
      approvedBy: r.approved_by ? String(r.approved_by) : null,
      approvedAt: r.approved_at ? String(r.approved_at) : null,
      payments: payments.rows.map(mapPayment),
    };
  }

  async createPlan(orderId: string, customerId: string, planCount: number): Promise<Installment> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const orderRes = await client.query(
        'SELECT id, customer_id, total, status FROM orders WHERE id = $1',
        [orderId],
      );
      if (!orderRes.rows.length) throw new NotFoundError('Order not found');
      const order = orderRes.rows[0];
      if (String(order.customer_id) !== customerId) {
        throw new ConflictError('Order does not belong to this customer');
      }
      if (String(order.status) !== 'paid') {
        throw new ConflictError('Only paid orders can have installment plans');
      }

      const existing = await client.query('SELECT id FROM installments WHERE order_id = $1', [orderId]);
      if (existing.rows.length) throw new ConflictError('An installment plan already exists for this order');

      const total = Number(order.total);
      const installmentId = randomUUID();
      await client.query(
        `INSERT INTO installments (id, order_id, customer_id, total_amount, amount_paid, term_months, status)
         VALUES ($1,$2,$3,$4,0,$5,'active')`,
        [installmentId, orderId, customerId, total, planCount],
      );

      const base = Math.floor((total * 100) / planCount) / 100;
      const first = Math.round((total - base * (planCount - 1)) * 100) / 100;
      const due = new Date();
      for (let i = 0; i < planCount; i++) {
        const amount = i === 0 ? first : base;
        await client.query(
          `INSERT INTO installment_payments (id, installment_id, amount, due_date, is_paid)
           VALUES ($1,$2,$3,$4,FALSE)`,
          [randomUUID(), installmentId, amount, addMonths(due, i + 1)],
        );
      }

      await client.query('COMMIT');
      const plan = await this.getByOrder(orderId);
      if (!plan) throw new NotFoundError('Installment plan was not created');
      return plan;
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }

  async payPayment(paymentId: string, customerId: string, amount: number): Promise<InstallmentPaymentRow> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const payRes = await client.query(
        `SELECT ip.id, ip.amount, ip.is_paid, ip.installment_id, i.customer_id, i.total_amount, i.status
         FROM installment_payments ip
         JOIN installments i ON i.id = ip.installment_id
         WHERE ip.id = $1
         FOR UPDATE`,
        [paymentId],
      );
      if (!payRes.rows.length) throw new NotFoundError('Installment payment not found');
      const p = payRes.rows[0];
      if (String(p.customer_id) !== customerId) {
        throw new ConflictError('Installment plan does not belong to this customer');
      }
      if (String(p.status) === 'completed') throw new ConflictError('Installment plan is already completed');
      if (Boolean(p.is_paid)) throw new ConflictError('This installment payment has already been paid');
      if (amount < Number(p.amount)) {
        throw new ConflictError('Payment amount is less than the due amount');
      }

      await client.query(
        'UPDATE installment_payments SET is_paid = TRUE, paid_at = now() WHERE id = $1',
        [paymentId],
      );
      await client.query(
        'UPDATE installments SET amount_paid = amount_paid + $2 WHERE id = $1',
        [p.installment_id, amount],
      );

      const remaining = await client.query(
        `SELECT count(*)::int AS n FROM installment_payments
         WHERE installment_id = $1 AND is_paid = FALSE`,
        [p.installment_id],
      );
      if (toNumber(remaining.rows[0]?.n ?? 0) === 0) {
        await client.query(
          "UPDATE installments SET status = 'completed', amount_paid = total_amount, updated_at = now() WHERE id = $1",
          [p.installment_id],
        );
      }

      await client.query('COMMIT');
      const res = await client.query('SELECT * FROM installment_payments WHERE id = $1', [paymentId]);
      return mapPayment(res.rows[0]);
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }
}