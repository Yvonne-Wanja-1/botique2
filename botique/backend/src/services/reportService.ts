import type { Pool } from 'pg';
import { toNumber } from '../models/index.js';

const LOW_STOCK_THRESHOLD = 10;

export class ReportService {
  constructor(private pool: Pool) {}

  async salesSummary(from?: string, to?: string) {
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
    const total = await this.pool.query(
      `SELECT count(*)::int AS total_orders,
              COALESCE(sum(total), 0) AS total_revenue,
              COALESCE(avg(total), 0) AS avg_order_value
       FROM orders ${where}`,
      values,
    );
    const byMethod = await this.pool.query(
      `SELECT payment_method, count(*)::int AS orders, COALESCE(sum(total), 0) AS revenue
       FROM orders ${where} GROUP BY payment_method`,
      values,
    );
    const daily = await this.pool.query(
      `SELECT created_at::date AS day,
              count(*)::int AS orders,
              COALESCE(sum(total), 0) AS revenue
       FROM orders ${where} GROUP BY day ORDER BY day DESC`,
      values,
    );
    return {
      totalOrders: toNumber(total.rows[0].total_orders),
      totalRevenue: Number(total.rows[0].total_revenue),
      avgOrderValue: Number(total.rows[0].avg_order_value),
      byPaymentMethod: byMethod.rows.map((r) => ({
        paymentMethod: String(r.payment_method),
        orders: toNumber(r.orders),
        revenue: Number(r.revenue),
      })),
      daily: daily.rows.map((r) => ({
        day: String(r.day),
        orders: toNumber(r.orders),
        revenue: Number(r.revenue),
      })),
    };
  }

  async topProducts(limit = 10) {
    const res = await this.pool.query(
      `SELECT p.id, p.name, sum(oi.quantity)::int AS quantity_sold,
              sum(oi.line_total) AS revenue
       FROM order_items oi
       JOIN products p ON p.id = oi.product_id
       JOIN orders o ON o.id = oi.order_id
       WHERE o.status <> 'cancelled'
       GROUP BY p.id, p.name
       ORDER BY revenue DESC NULLS LAST LIMIT $1`,
      [limit],
    );
    return res.rows.map((r) => ({
      id: String(r.id),
      name: String(r.name),
      quantitySold: toNumber(r.quantity_sold),
      revenue: Number(r.revenue),
    }));
  }

  async inventorySummary() {
    const res = await this.pool.query(
      `SELECT
         COUNT(*) FILTER (WHERE stock_qty = 0) AS out_of_stock,
         COUNT(*) FILTER (WHERE stock_qty > 0 AND stock_qty < $1) AS low_stock,
         COUNT(*) FILTER (WHERE stock_qty >= $1) AS in_stock,
         COALESCE(SUM(stock_qty), 0)::int AS total_units
       FROM product_variants`,
      [LOW_STOCK_THRESHOLD],
    );
    const r = res.rows[0];
    return {
      outOfStock: toNumber(r.out_of_stock),
      lowStock: toNumber(r.low_stock),
      inStock: toNumber(r.in_stock),
      totalUnits: toNumber(r.total_units),
    };
  }

  async customerSummary() {
    const counts = await this.pool.query(
      `SELECT
         COUNT(DISTINCT u.id)::int AS total_customers,
         COALESCE(AVG(order_counts.cnt), 0) AS avg_orders_per_customer
       FROM users u
       JOIN roles r ON r.id = u.role_id AND r.name = 'customer'
       LEFT JOIN (SELECT customer_id, count(*)::int AS cnt FROM orders GROUP BY customer_id) AS order_counts
         ON order_counts.customer_id = u.id`,
    );
    const top = await this.pool.query(
      `SELECT u.id, u.full_name, u.email,
              count(o.id)::int AS orders,
              COALESCE(sum(o.total), 0) AS spend
       FROM users u
       JOIN roles r ON r.id = u.role_id AND r.name = 'customer'
       LEFT JOIN orders o ON o.customer_id = u.id AND o.status <> 'cancelled'
       GROUP BY u.id, u.full_name, u.email
       ORDER BY spend DESC LIMIT 10`,
    );
    const r = counts.rows[0];
    return {
      totalCustomers: toNumber(r.total_customers),
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
}