import { randomUUID } from 'node:crypto';
import type { Pool } from 'pg';
import { toNumber } from '../models/index.js';
import { ConflictError, NotFoundError, ValidationError } from '../utils/errors.js';
import type { OrderItemRow, OrderRow, PaymentMethod, PaymentStatus, OrderStatus } from '../models/index.js';
import type { Payment } from './paymentRepository.js';

export interface CheckoutItemInput {
  productId: string;
  variantId: string | null;
  quantity: number;
}

export interface CheckoutInput {
  items: CheckoutItemInput[];
  customerName: string;
  customerPhone: string;
  customerEmail: string;
  shippingAddress: string;
  promotionCode?: string | null;
  paymentMethod: PaymentMethod;
  installmentRequested: boolean;
}

export interface PaymentSummary {
  total: number;
  verified: number;
  pending: number;
  remaining: number;
}

export interface Order extends OrderRow {
  items: OrderItemRow[];
  payments: Payment[];
  paymentSummary: PaymentSummary;
}

const DELIVERY_FEE = 2500;
const FREE_DELIVERY_THRESHOLD = 100000;

function makeOrderNumber(): string {
  return `QT-${Date.now()}-${randomUUID().slice(0, 4).toUpperCase()}`;
}

function mapOrder(row: Record<string, unknown>): Order {
  return {
    id: String(row.id),
    orderNumber: String(row.order_number),
    customerId: String(row.customer_id),
    customerName: String(row.customer_name),
    customerPhone: String(row.customer_phone),
    customerEmail: String(row.customer_email),
    shippingAddress: String(row.shipping_address),
    subtotal: Number(row.subtotal),
    discount: Number(row.discount),
    shippingFee: Number(row.shipping_fee),
    total: Number(row.total),
    status: row.status as OrderStatus,
    paymentStatus: row.payment_status as PaymentStatus,
    paymentMethod: row.payment_method as PaymentMethod,
    installmentRequested: Boolean(row.installment_requested),
    promotionCode: row.promotion_code ? String(row.promotion_code) : null,
    createdAt: String(row.created_at),
    items: [],
    payments: [],
    paymentSummary: { total: Number(row.total), verified: 0, pending: 0, remaining: Number(row.total) },
  };
}

export class OrderRepository {
  constructor(private pool: Pool) {}

  async findById(id: string): Promise<Order | null> {
    const res = await this.pool.query('SELECT * FROM orders WHERE id = $1', [id]);
    if (!res.rows.length) return null;
    const order = mapOrder(res.rows[0]);
    const items = await this.pool.query(
      `SELECT oi.id, oi.order_id, oi.product_id, oi.variant_id, oi.product_name, oi.variant_label,
              oi.unit_price, oi.quantity, oi.line_total
       FROM order_items oi
       WHERE oi.order_id = $1`,
      [id],
    );
    order.items = items.rows.map((r) => ({
      id: String(r.id),
      orderId: String(r.order_id),
      productId: String(r.product_id),
      variantId: r.variant_id ? String(r.variant_id) : null,
      productName: String(r.product_name),
      variantLabel: r.variant_label ? String(r.variant_label) : null,
      unitPrice: Number(r.unit_price),
      quantity: toNumber(r.quantity),
      lineTotal: Number(r.line_total),
    }));
    const pays = await this.pool.query(
      'SELECT * FROM payments WHERE order_id = $1 ORDER BY created_at DESC',
      [id],
    );
    const payments: Payment[] = pays.rows.map((r) => ({
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
    }));
    order.payments = payments;
    const verified = payments.filter((p) => p.status === 'successful').reduce((s, p) => s + p.amount, 0);
    const pending = payments.filter((p) => p.status === 'pending_verification').reduce((s, p) => s + p.amount, 0);
    order.paymentSummary = {
      total: order.total,
      verified,
      pending,
      remaining: order.total - verified,
    };
    return order;
  }

  async create(customerId: string, input: CheckoutInput): Promise<Order> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const variantIds = input.items.map((i) => i.variantId).filter((v): v is string => v !== null);
      const placeholders = variantIds.map((_, i) => `$${i + 1}`).join(', ');
      const vres = await client.query(
        `SELECT v.id, v.product_id, v.stock_qty, v.size, v.color, v.shade, p.name,
                COALESCE(p.discount_price, p.base_price) AS unit_price
         FROM product_variants v JOIN products p ON p.id = v.product_id
         WHERE v.id IN (${placeholders}) AND v.is_active = TRUE AND p.status = 'active'
         FOR UPDATE`,
        variantIds,
      );
      const variantMap = new Map(vres.rows.map((r) => [r.id, r]));
      let subtotal = 0;
      for (const item of input.items) {
        const v = variantMap.get(item.variantId ?? '');
        if (!v) throw new NotFoundError(`Variant ${item.variantId ?? '?'} not found`);
        if (toNumber(v.stock_qty) < item.quantity) throw new ConflictError('Insufficient stock for one or more items');
        subtotal += Number(v.unit_price) * item.quantity;
      }

      let discountAmount = 0;
      let promoCode: string | null = null;
      if (input.promotionCode) {
        const pres = await client.query(
          `SELECT * FROM promotions WHERE code = $1 AND is_active = TRUE
             AND (start_date IS NULL OR start_date <= now())
             AND (end_date IS NULL OR end_date >= now())`,
          [input.promotionCode],
        );
        if (!pres.rows.length) throw new ValidationError('Promotion code is invalid or expired');
        const promo = pres.rows[0];
        if (promo.minimum_order_amount !== null && subtotal < Number(promo.minimum_order_amount)) {
          throw new ValidationError('Subtotal is below the promotion minimum');
        }
        promoCode = String(promo.code);
        if (promo.type === 'percentage') discountAmount = (subtotal * Number(promo.value)) / 100;
        else discountAmount = Number(promo.value);
        if (promo.maximum_discount !== null && discountAmount > Number(promo.maximum_discount)) {
          discountAmount = Number(promo.maximum_discount);
        }
        if (discountAmount > subtotal) discountAmount = subtotal;
      }

      const shippingFee = subtotal - discountAmount >= FREE_DELIVERY_THRESHOLD ? 0 : DELIVERY_FEE;
      const total = subtotal - discountAmount + shippingFee;
      const orderId = randomUUID();
      const orderNumber = makeOrderNumber();

      await client.query(
        `INSERT INTO orders (id, order_number, customer_id, customer_name, customer_phone, customer_email,
           shipping_address, subtotal, discount, shipping_fee, total, status, payment_status, payment_method,
           installment_requested, promotion_code)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,'pending','pending',$12,$13,$14)`,
        [
          orderId, orderNumber, customerId, input.customerName, input.customerPhone, input.customerEmail,
          input.shippingAddress, subtotal, discountAmount, shippingFee, total,
          input.paymentMethod, input.installmentRequested, promoCode,
        ],
      );

      for (const item of input.items) {
        const v = variantMap.get(item.variantId ?? '')!;
        const unitPrice = Number(v.unit_price);
        const variantLabel = [v.size, v.color, v.shade].filter((x) => x).join(' / ') || null;
        await client.query(
          `INSERT INTO order_items (id, order_id, product_id, variant_id, product_name, variant_label, unit_price, quantity, line_total)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
          [randomUUID(), orderId, item.productId, item.variantId, v.name, variantLabel, unitPrice, item.quantity, unitPrice * item.quantity],
        );
        await client.query(
          'UPDATE product_variants SET stock_qty = stock_qty - $2::int, updated_at = now() WHERE id = $1',
          [item.variantId, item.quantity],
        );
      }

      await client.query(
        `DELETE FROM cart_items WHERE variant_id IN (${placeholders}) AND cart_id IN (SELECT id FROM carts WHERE user_id = $${variantIds.length + 1})`,
        [...variantIds, customerId],
      );
      await client.query('COMMIT');

      const order = await this.findById(orderId);
      if (!order) throw new NotFoundError('Order was not created');
      return order;
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }

  async listByCustomer(customerId: string, status?: string) {
    const params: unknown[] = [customerId];
    let where = 'WHERE customer_id = $1';
    if (status) {
      params.push(status);
      where += ` AND status = $${params.length}`;
    }
    const res = await this.pool.query(`SELECT * FROM orders ${where} ORDER BY created_at DESC`, params);
    return res.rows.map(mapOrder);
  }

  async listAll(params: { status?: string; page?: number; pageSize?: number }) {
    const conditions: string[] = [];
    const values: unknown[] = [];
    if (params.status) {
      values.push(params.status);
      conditions.push(`status = $${values.length}`);
    }
    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const page = Math.max(1, params.page ?? 1);
    const pageSize = Math.min(100, Math.max(1, params.pageSize ?? 20));
    const offset = (page - 1) * pageSize;
    const countRes = await this.pool.query(`SELECT count(*)::int AS n FROM orders ${where}`, values);
    const res = await this.pool.query(
      `SELECT * FROM orders ${where} ORDER BY created_at DESC LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, offset],
    );
    return { rows: res.rows.map(mapOrder), total: toNumber(countRes.rows[0]?.n ?? 0) };
  }

  async setStatus(orderId: string, status: OrderStatus): Promise<Order | null> {
    const res = await this.pool.query(
      'UPDATE orders SET status = $2, updated_at = now() WHERE id = $1 RETURNING id',
      [orderId, status],
    );
    if (!res.rows.length) throw new NotFoundError('Order not found');
    return this.findById(orderId);
  }

  async cancel(customerId: string, orderId: string): Promise<Order | null> {
    const res = await this.pool.query(
      `UPDATE orders SET status = 'cancelled', updated_at = now()
       WHERE id = $2 AND customer_id = $1 AND status = 'pending'
       RETURNING id`,
      [customerId, orderId],
    );
    if (!res.rows.length) {
      const exists = await this.pool.query('SELECT status FROM orders WHERE id = $1 AND customer_id = $2', [orderId, customerId]);
      if (!exists.rows.length) throw new NotFoundError('Order not found');
      throw new ConflictError('Only pending orders can be cancelled');
    }
    return this.findById(orderId);
  }

  async logAudit(
    resource: string,
    resourceId: string,
    action: 'create' | 'update' | 'delete' | 'approve' | 'reject' | 'adjust' | 'login' | 'logout',
    actorUserId: string | null,
    description: string,
    newValue?: unknown,
  ): Promise<void> {
    const actorRes = actorUserId
      ? await this.pool.query('SELECT full_name FROM users WHERE id = $1', [actorUserId])
      : { rows: [] as { full_name: string }[] };
    const actorName = actorRes.rows.length ? String(actorRes.rows[0].full_name) : 'system';
    await this.pool.query(
      `INSERT INTO audit_logs (id, actor_user_id, actor_name, action, resource, resource_id, description, new_value)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
      [randomUUID(), actorUserId, actorName, action, resource, resourceId, description, newValue !== undefined ? JSON.stringify(newValue) : null],
    );
  }
}