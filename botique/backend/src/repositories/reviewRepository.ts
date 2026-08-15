import { randomUUID } from 'node:crypto';
import type { Pool } from 'pg';
import { ConflictError, NotFoundError } from '../utils/errors.js';

export interface Review {
  id: string;
  productId: string;
  customerId: string;
  orderId: string | null;
  rating: number;
  comment: string;
  isVerifiedPurchase: boolean;
  isApproved: boolean;
  isReported: boolean;
  createdAt: string;
}

export class ReviewRepository {
  constructor(private pool: Pool) {}

  private map(r: Record<string, unknown>): Review {
    return {
      id: String(r.id),
      productId: String(r.product_id),
      customerId: String(r.customer_id),
      orderId: r.order_id ? String(r.order_id) : null,
      rating: Number(r.rating),
      comment: String(r.comment),
      isVerifiedPurchase: Boolean(r.is_verified_purchase),
      isApproved: Boolean(r.is_approved),
      isReported: Boolean(r.is_reported),
      createdAt: String(r.created_at),
    };
  }

  private getById(id: string): Promise<Review | null> {
    return this.pool.query('SELECT * FROM reviews WHERE id = $1', [id]).then((res) =>
      res.rows.length ? this.map(res.rows[0]) : null,
    );
  }

  async add(customerId: string, productId: string, input: { rating: number; comment: string }): Promise<Review> {
    const product = await this.pool.query('SELECT id FROM products WHERE id = $1', [productId]);
    if (!product.rows.length) throw new NotFoundError('Product not found');

    const orderRes = await this.pool.query(
      `SELECT o.id FROM order_items oi
       JOIN orders o ON o.id = oi.order_id
       WHERE oi.product_id = $1 AND o.customer_id = $2 AND o.status = 'delivered'
       ORDER BY o.created_at DESC LIMIT 1`,
      [productId, customerId],
    );
    const orderId = orderRes.rows.length ? String(orderRes.rows[0].id) : null;
    const verified = orderId !== null;

    const existing = await this.pool.query(
      'SELECT id FROM reviews WHERE product_id = $1 AND customer_id = $2',
      [productId, customerId],
    );
    if (existing.rows.length) throw new ConflictError('You already reviewed this product');

    const res = await this.pool.query(
      `INSERT INTO reviews (id, product_id, customer_id, order_id, rating, comment, is_verified_purchase, is_approved)
       VALUES ($1,$2,$3,$4,$5,$6,$7, TRUE)
       RETURNING id`,
      [randomUUID(), productId, customerId, orderId, input.rating, input.comment, verified],
    );
    if (!res.rows.length) throw new ConflictError('You already reviewed this product');
    const review = await this.getById(res.rows[0].id);
    if (!review) throw new NotFoundError('Review was not created');
    return review;
  }

  async listForProduct(productId: string): Promise<Review[]> {
    const res = await this.pool.query(
      'SELECT * FROM reviews WHERE product_id = $1 AND is_approved = TRUE ORDER BY created_at DESC',
      [productId],
    );
    return res.rows.map((r) => this.map(r));
  }

  async listPending(): Promise<Review[]> {
    const res = await this.pool.query(
      'SELECT * FROM reviews WHERE is_approved = FALSE ORDER BY created_at ASC',
    );
    return res.rows.map((r) => this.map(r));
  }

  async moderate(id: string, approved: boolean): Promise<Review> {
    const res = await this.pool.query(
      'UPDATE reviews SET is_approved = $2, updated_at = now() WHERE id = $1 RETURNING id',
      [id, approved],
    );
    if (!res.rows.length) throw new NotFoundError('Review not found');
    const review = await this.getById(id);
    if (!review) throw new NotFoundError('Review not found');
    return review;
  }

  async report(id: string): Promise<Review> {
    const res = await this.pool.query(
      'UPDATE reviews SET is_reported = TRUE, updated_at = now() WHERE id = $1 RETURNING id',
      [id],
    );
    if (!res.rows.length) throw new NotFoundError('Review not found');
    const review = await this.getById(id);
    if (!review) throw new NotFoundError('Review not found');
    return review;
  }
}