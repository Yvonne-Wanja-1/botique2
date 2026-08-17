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

export class PaymentRepository {
  constructor(private pool: Pool) {}

  async getByOrder(orderId: string): Promise<Payment | null> {
    const res = await this.pool.query(
      `SELECT * FROM payments WHERE order_id = $1`,
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