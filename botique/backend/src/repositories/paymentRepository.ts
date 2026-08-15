import type { Pool } from 'pg';
import type { PaymentMethod, PaymentStatus } from '../models/index.js';

export interface Payment {
  id: string;
  orderId: string;
  customerId: string;
  amount: number;
  method: PaymentMethod;
  status: PaymentStatus;
  reference: string | null;
  createdAt: string;
}

export class PaymentRepository {
  constructor(private pool: Pool) {}

  async getByOrder(orderId: string): Promise<Payment | null> {
    const res = await this.pool.query(
      `SELECT id, order_id, customer_id, amount, method, status, reference, created_at
       FROM payments WHERE order_id = $1`,
      [orderId],
    );
    if (!res.rows.length) return null;
    const r = res.rows[0];
    return {
      id: String(r.id),
      orderId: String(r.order_id),
      customerId: String(r.customer_id),
      amount: Number(r.amount),
      method: r.method as PaymentMethod,
      status: r.status as PaymentStatus,
      reference: r.reference ? String(r.reference) : null,
      createdAt: String(r.created_at),
    };
  }

  async verify(orderId: string, reference: string): Promise<Payment | null> {
    const res = await this.pool.query(
      `UPDATE payments SET status = 'successful', reference = $2, updated_at = now()
       WHERE order_id = $1 AND status = 'pending'
       RETURNING id`,
      [orderId, reference],
    );
    if (!res.rows.length) return null;
    await this.pool.query(
      `UPDATE orders SET status = 'paid', payment_status = 'successful', updated_at = now()
       WHERE id = $1 AND status = 'pending'`,
      [orderId],
    );
    return this.getByOrder(orderId);
  }

  transferDetails() {
    return {
      bankName: 'GTBank',
      accountName: 'QUEENS TOUCH BOUTIQUE',
      accountNumber: '0123456789',
    };
  }
}