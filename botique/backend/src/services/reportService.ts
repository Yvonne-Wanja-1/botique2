import type { Pool } from 'pg';
import { toNumber } from '../models/index.js';

export interface DateRange {
  from?: string;
  to?: string;
}

function buildRange(from?: string, to?: string): { where: string; values: unknown[] } {
  return buildRangeWithPrefix('', from, to);
}

function buildRangeWithPrefix(
  prefix: string,
  from?: string,
  to?: string,
): { where: string; values: unknown[] } {
  const conditions: string[] = [];
  const values: unknown[] = [];
  const column = prefix ? `${prefix}.created_at` : 'created_at';
  if (from) {
    values.push(from);
    conditions.push(`${column} >= $${values.length}`);
  }
  if (to) {
    values.push(to);
    conditions.push(`${column} < $${values.length}`);
  }
  return { where: conditions.length ? `WHERE ${conditions.join(' AND ')}` : '', values };
}

export class ReportService {
  constructor(private pool: Pool) {}

  async salesSummary(from?: string, to?: string) {
    const range = buildRange(from, to);
    const total = await this.pool.query(
      `SELECT count(*)::int AS total_orders,
              COALESCE(sum(total), 0) AS total_revenue,
              COALESCE(avg(total), 0) AS avg_order_value,
              SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END)::int AS pending_orders
       FROM orders ${range.where}`,
      range.values,
    );
    const verifiedRange = buildRangeWithPrefix('o', from, to);
    const verified = await this.pool.query(
      `SELECT COALESCE(SUM(p.amount), 0) AS verified_revenue
       FROM payments p
       JOIN orders o ON o.id = p.order_id
       WHERE p.status = 'successful'
       ${verifiedRange.where ? `AND ${verifiedRange.where.slice('WHERE '.length)}` : ''}`,
      verifiedRange.values,
    );
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const today = await this.pool.query(
      `SELECT COALESCE(SUM(total), 0) AS today_revenue,
              count(*)::int AS today_orders
       FROM orders
       WHERE created_at >= $1`,
      [todayStart.toISOString()],
    );
    const byMethod = await this.pool.query(
      `SELECT payment_method, count(*)::int AS orders, COALESCE(sum(total), 0) AS revenue
       FROM orders ${range.where} GROUP BY payment_method`,
      range.values,
    );
    const byPaymentStatus = await this.pool.query(
      `SELECT payment_status, count(*)::int AS orders
       FROM orders ${range.where} GROUP BY payment_status`,
      range.values,
    );
    const daily = await this.pool.query(
      `SELECT created_at::date AS day,
              count(*)::int AS orders,
              COALESCE(sum(total), 0) AS revenue
       FROM orders ${range.where} GROUP BY day ORDER BY day DESC`,
      range.values,
    );
    const totalRevenue = Number(total.rows[0].total_revenue);
    const verifiedRevenue = Number(verified.rows[0].verified_revenue);
    return {
      totalOrders: toNumber(total.rows[0].total_orders),
      totalRevenue,
      verifiedRevenue,
      outstandingBalance: Math.max(0, Math.round((totalRevenue - verifiedRevenue) * 100) / 100),
      avgOrderValue: Number(total.rows[0].avg_order_value),
      pendingOrders: toNumber(total.rows[0].pending_orders),
      todayRevenue: Number(today.rows[0].today_revenue),
      todayOrders: toNumber(today.rows[0].today_orders),
      byPaymentMethod: byMethod.rows.map((r) => ({
        paymentMethod: String(r.payment_method),
        orders: toNumber(r.orders),
        revenue: Number(r.revenue),
      })),
      ordersByPaymentStatus: byPaymentStatus.rows.map((r) => ({
        paymentStatus: String(r.payment_status),
        orders: toNumber(r.orders),
      })),
      daily: daily.rows.map((r) => ({
        day: String(r.day),
        orders: toNumber(r.orders),
        revenue: Number(r.revenue),
      })),
    };
  }

  async salesReport(from?: string, to?: string, limit = 500) {
    const conditions: string[] = [];
    const values: unknown[] = [];
    if (from) {
      values.push(from);
      conditions.push(`o.created_at >= $${values.length}`);
    }
    if (to) {
      values.push(to);
      conditions.push(`o.created_at < $${values.length}`);
    }
    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    values.push(limit);
    const res = await this.pool.query(
      `SELECT o.id, o.order_number, o.created_at, o.customer_name, o.total,
              o.status AS order_status, o.payment_status,
              COALESCE(SUM(CASE WHEN p.status = 'successful' THEN p.amount ELSE 0 END), 0) AS verified
       FROM orders o
       LEFT JOIN payments p ON p.order_id = o.id
       ${where}
       GROUP BY o.id, o.order_number, o.created_at, o.customer_name, o.total, o.status, o.payment_status
       ORDER BY o.created_at DESC
       LIMIT $${values.length}`,
      values,
    );
    return res.rows.map((r) => {
      const total = Number(r.total);
      const verified = Number(r.verified);
      return {
        id: String(r.id),
        orderNumber: String(r.order_number),
        date: String(r.created_at),
        customerName: String(r.customer_name),
        total,
        verified,
        remainingBalance: Math.max(0, Math.round((total - verified) * 100) / 100),
        orderStatus: String(r.order_status),
        paymentStatus: String(r.payment_status),
      };
    });
  }

  async topProducts(from?: string, to?: string, limit = 10) {
    const conditions: string[] = [];
    const values: unknown[] = [];
    if (from) {
      values.push(from);
      conditions.push(`o.created_at >= $${values.length}`);
    }
    if (to) {
      values.push(to);
      conditions.push(`o.created_at < $${values.length}`);
    }
    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    values.push(limit);
    const res = await this.pool.query(
      `SELECT p.id, p.name, sum(oi.quantity)::int AS quantity_sold,
              sum(oi.line_total) AS revenue
       FROM order_items oi
       JOIN products p ON p.id = oi.product_id
       JOIN orders o ON o.id = oi.order_id
       ${where}${where ? ' AND' : ' WHERE'} o.status <> 'cancelled'
       GROUP BY p.id, p.name
       ORDER BY revenue DESC NULLS LAST LIMIT $${values.length}`,
      values,
    );
    return res.rows.map((r) => ({
      id: String(r.id),
      name: String(r.name),
      quantitySold: toNumber(r.quantity_sold),
      revenue: Number(r.revenue),
    }));
  }

  async inventoryReport() {
    const res = await this.pool.query(
      `SELECT v.id AS variant_id, v.sku, v.size, v.color, v.shade, v.stock_qty,
              p.id AS product_id, p.name AS product_name, p.stock_threshold
       FROM product_variants v
       JOIN products p ON p.id = v.product_id
       ORDER BY p.name ASC, v.sku ASC`,
    );
    return res.rows.map((r) => {
      const stockQty = toNumber(r.stock_qty);
      const threshold = toNumber(r.stock_threshold);
      const status = stockQty === 0 ? 'out' : stockQty < threshold ? 'low' : 'ok';
      return {
        variantId: String(r.variant_id),
        productId: String(r.product_id),
        productName: String(r.product_name),
        sku: String(r.sku),
        variantLabel: [r.size, r.color, r.shade].filter((v) => v != null).join(' / '),
        stockQty,
        stockThreshold: threshold,
        stockStatus: status,
      };
    });
  }

  async inventorySummary() {
    const res = await this.pool.query(
      `SELECT COUNT(*)::int AS total_variants,
              SUM(CASE WHEN v.stock_qty = 0 THEN 1 ELSE 0 END)::int AS out_of_stock,
              SUM(CASE WHEN v.stock_qty > 0 AND v.stock_qty < p.stock_threshold THEN 1 ELSE 0 END)::int AS low_stock,
              SUM(CASE WHEN v.stock_qty >= p.stock_threshold THEN 1 ELSE 0 END)::int AS in_stock,
              COALESCE(SUM(v.stock_qty), 0)::int AS total_units,
              COUNT(DISTINCT p.id)::int AS total_products
       FROM product_variants v
       JOIN products p ON p.id = v.product_id`,
    );
    const r = res.rows[0];
    return {
      totalVariants: toNumber(r.total_variants),
      outOfStock: toNumber(r.out_of_stock),
      lowStock: toNumber(r.low_stock),
      inStock: toNumber(r.in_stock),
      totalUnits: toNumber(r.total_units),
      totalProducts: toNumber(r.total_products),
    };
  }

  async customerSummary(from?: string, to?: string) {
    const newRange = buildRangeWithPrefix('u', from, to);
    const newCondition = newRange.where ? newRange.where.slice('WHERE '.length) : 'TRUE';
    const counts = await this.pool.query(
      `SELECT
         COUNT(DISTINCT u.id)::int AS total_customers,
         SUM(CASE WHEN ${newCondition} THEN 1 ELSE 0 END)::int AS new_customers,
         COALESCE(AVG(order_counts.cnt), 0) AS avg_orders_per_customer
       FROM users u
       JOIN roles r ON r.id = u.role_id AND r.name = 'customer'
       LEFT JOIN (SELECT customer_id, count(*)::int AS cnt FROM orders GROUP BY customer_id) AS order_counts
         ON order_counts.customer_id = u.id`,
      newRange.values,
    );
    const withOrdersRange = buildRange(from, to);
    const withOrders = await this.pool.query(
      `SELECT COUNT(DISTINCT customer_id)::int AS customers_with_orders
       FROM orders
       WHERE customer_id IS NOT NULL
       ${withOrdersRange.where ? `AND ${withOrdersRange.where.slice('WHERE '.length)}` : ''}`,
      withOrdersRange.values,
    );
    const conditions: string[] = [];
    const values: unknown[] = [];
    if (from) {
      values.push(from);
      conditions.push(`o.created_at >= $${values.length}`);
    }
    if (to) {
      values.push(to);
      conditions.push(`o.created_at < $${values.length}`);
    }
    const where = conditions.length ? `AND ${conditions.join(' AND ')}` : '';
    const top = await this.pool.query(
      `SELECT u.id, u.full_name, u.email,
              count(o.id)::int AS orders,
              COALESCE(sum(o.total), 0) AS spend
       FROM users u
       JOIN roles r ON r.id = u.role_id AND r.name = 'customer'
       LEFT JOIN orders o ON o.customer_id = u.id AND o.status <> 'cancelled' ${where}
       GROUP BY u.id, u.full_name, u.email
       ORDER BY spend DESC LIMIT 10`,
      values,
    );
    const r = counts.rows[0];
    return {
      totalCustomers: toNumber(r.total_customers),
      newCustomers: toNumber(r.new_customers),
      customersWithOrders: toNumber(withOrders.rows[0].customers_with_orders),
      avgOrdersPerCustomer: Number(r.avg_orders_per_customer),
      topCustomers: top.rows.map((t) => ({
        id: String(t.id),
        fullName: String(t.full_name),
        email: String(t.email),
        orders: toNumber(t.orders),
        spend: Number(t.spend),
      })),
    };
  }

  async ordersSummary(from?: string, to?: string) {
    const range = buildRange(from, to);
    const byStatus = await this.pool.query(
      `SELECT status, count(*)::int AS count, COALESCE(sum(total), 0) AS revenue
       FROM orders ${range.where} GROUP BY status`,
      range.values,
    );
    const byPaymentStatus = await this.pool.query(
      `SELECT payment_status, count(*)::int AS count
       FROM orders ${range.where} GROUP BY payment_status`,
      range.values,
    );
    const total = byStatus.rows.reduce((s, r) => s + toNumber(r.count), 0);
    const revenue = byStatus.rows.reduce((s, r) => s + Number(r.revenue), 0);
    return {
      totalOrders: total,
      totalRevenue: revenue,
      byStatus: byStatus.rows.map((r) => ({
        status: String(r.status),
        count: toNumber(r.count),
        revenue: Number(r.revenue),
      })),
      byPaymentStatus: byPaymentStatus.rows.map((r) => ({
        paymentStatus: String(r.payment_status),
        count: toNumber(r.count),
      })),
    };
  }

  async paymentsSummary(from?: string, to?: string) {
    const conditions: string[] = [];
    const values: unknown[] = [];
    if (from) {
      values.push(from);
      conditions.push(`created_at >= $${values.length}`);
    }
    if (to) {
      values.push(to);
      conditions.push(`created_at < $${values.length}`);
    }
    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const res = await this.pool.query(
      `SELECT status, count(*)::int AS count, COALESCE(sum(amount), 0) AS amount
       FROM payments ${where}
       GROUP BY status`,
      values,
    );
    const pick = (status: string) =>
      res.rows.find((r) => r.status === status) ?? { count: 0, amount: 0 };
    const successful = pick('successful');
    return {
      successful: toNumber(successful.count),
      totalProcessed: Number(successful.amount),
      pendingVerification: toNumber(pick('pending_verification').count),
      pendingVerificationAmount: Number(pick('pending_verification').amount),
      rejected: toNumber(pick('rejected').count),
      rejectedAmount: Number(pick('rejected').amount),
      failed: toNumber(pick('failed').count),
      refunded: toNumber(pick('refunded').count),
      refundedAmount: Number(pick('refunded').amount),
    };
  }

  async installmentsSummary() {
    const byStatus = await this.pool.query(
      `SELECT status, count(*)::int AS count FROM installments GROUP BY status`,
    );
    const totals = await this.pool.query(
      `SELECT COALESCE(SUM(total_amount), 0) AS total_value,
              COALESCE(SUM(amount_paid), 0) AS total_paid,
              COALESCE(SUM(total_amount - amount_paid), 0) AS outstanding
       FROM installments
       WHERE status <> 'rejected'`,
    );
    const pick = (status: string) =>
      byStatus.rows.find((r) => r.status === status) ?? { count: 0 };
    return {
      active: toNumber(pick('active').count),
      completed: toNumber(pick('completed').count),
      pendingApproval: toNumber(pick('pending_approval').count),
      approved: toNumber(pick('approved').count),
      rejected: toNumber(pick('rejected').count),
      overdue: toNumber(pick('overdue').count),
      totalValue: Number(totals.rows[0].total_value),
      totalPaid: Number(totals.rows[0].total_paid),
      outstandingBalance: Number(totals.rows[0].outstanding),
    };
  }
}