import { randomUUID } from 'node:crypto';
import type { Pool } from 'pg';
import { toNumber } from '../models/index.js';
import { ConflictError, NotFoundError } from '../utils/errors.js';

export interface PromotionRow {
  id: string;
  code: string;
  title: string;
  description: string | null;
  type: string;
  value: number;
  categoryId: string | null;
  productId: string | null;
  minimumOrderAmount: number | null;
  maximumDiscount: number | null;
  usageLimit: number | null;
  usageCount: number;
  startDate: string | null;
  endDate: string | null;
  isActive: boolean;
}

export class PromotionRepository {
  constructor(private pool: Pool) {}

  private map(r: Record<string, unknown>): PromotionRow {
    return {
      id: String(r.id),
      code: String(r.code),
      title: String(r.title),
      description: r.description ? String(r.description) : null,
      type: String(r.type),
      value: toNumber(r.value),
      categoryId: r.category_id ? String(r.category_id) : null,
      productId: r.product_id ? String(r.product_id) : null,
      minimumOrderAmount: r.minimum_order_amount != null ? toNumber(r.minimum_order_amount) : null,
      maximumDiscount: r.maximum_discount != null ? toNumber(r.maximum_discount) : null,
      usageLimit: r.usage_limit != null ? toNumber(r.usage_limit) : null,
      usageCount: toNumber(r.usage_count),
      startDate: r.start_date ? String(r.start_date) : null,
      endDate: r.end_date ? String(r.end_date) : null,
      isActive: Boolean(r.is_active),
    };
  }

  async listAll(): Promise<PromotionRow[]> {
    const res = await this.pool.query('SELECT * FROM promotions ORDER BY created_at DESC');
    return res.rows.map((r) => this.map(r));
  }

  async listActive(): Promise<PromotionRow[]> {
    const res = await this.pool.query(
      `SELECT * FROM promotions WHERE is_active = TRUE
       AND (start_date IS NULL OR start_date <= now())
       AND (end_date IS NULL OR end_date >= now())
       ORDER BY created_at DESC`,
    );
    return res.rows.map((r) => this.map(r));
  }

  async getById(id: string): Promise<PromotionRow | null> {
    const res = await this.pool.query('SELECT * FROM promotions WHERE id = $1', [id]);
    return res.rows.length ? this.map(res.rows[0]) : null;
  }

  async getByCode(code: string): Promise<PromotionRow | null> {
    const res = await this.pool.query('SELECT * FROM promotions WHERE code = $1', [code.toUpperCase()]);
    return res.rows.length ? this.map(res.rows[0]) : null;
  }

  async create(input: {
    code: string;
    title: string;
    description?: string | null;
    type: string;
    value: number;
    categoryId?: string | null;
    productId?: string | null;
    minimumOrderAmount?: number | null;
    maximumDiscount?: number | null;
    usageLimit?: number | null;
    startDate?: string | null;
    endDate?: string | null;
    isActive?: boolean;
  }): Promise<PromotionRow> {
    const existing = await this.getByCode(input.code);
    if (existing) throw new ConflictError('A promotion with this code already exists');

    const id = randomUUID();
    await this.pool.query(
      `INSERT INTO promotions (id, code, title, description, type, value, category_id, product_id, minimum_order_amount, maximum_discount, usage_limit, start_date, end_date, is_active)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)`,
      [
        id,
        input.code.toUpperCase(),
        input.title,
        input.description ?? null,
        input.type,
        input.value,
        input.categoryId ?? null,
        input.productId ?? null,
        input.minimumOrderAmount ?? null,
        input.maximumDiscount ?? null,
        input.usageLimit ?? null,
        input.startDate ?? null,
        input.endDate ?? null,
        input.isActive ?? true,
      ],
    );
    const promo = await this.getById(id);
    if (!promo) throw new NotFoundError('Promotion was not created');
    return promo;
  }

  async update(id: string, input: {
    code?: string;
    title?: string;
    description?: string | null;
    type?: string;
    value?: number;
    categoryId?: string | null;
    productId?: string | null;
    minimumOrderAmount?: number | null;
    maximumDiscount?: number | null;
    usageLimit?: number | null;
    startDate?: string | null;
    endDate?: string | null;
    isActive?: boolean;
  }): Promise<PromotionRow> {
    const existing = await this.getById(id);
    if (!existing) throw new NotFoundError('Promotion not found');

    if (input.code && input.code.toUpperCase() !== existing.code) {
      const dup = await this.getByCode(input.code);
      if (dup) throw new ConflictError('A promotion with this code already exists');
    }

    await this.pool.query(
      `UPDATE promotions SET
        code = $2, title = $3, description = $4, type = $5, value = $6,
        category_id = $7, product_id = $8,
        minimum_order_amount = $9, maximum_discount = $10, usage_limit = $11,
        start_date = $12, end_date = $13, is_active = $14, updated_at = now()
       WHERE id = $1`,
      [
        id,
        (input.code ?? existing.code).toUpperCase(),
        input.title ?? existing.title,
        input.description !== undefined ? input.description : existing.description,
        input.type ?? existing.type,
        input.value ?? existing.value,
        input.categoryId !== undefined ? input.categoryId : existing.categoryId,
        input.productId !== undefined ? input.productId : existing.productId,
        input.minimumOrderAmount !== undefined ? input.minimumOrderAmount : existing.minimumOrderAmount,
        input.maximumDiscount !== undefined ? input.maximumDiscount : existing.maximumDiscount,
        input.usageLimit !== undefined ? input.usageLimit : existing.usageLimit,
        input.startDate !== undefined ? input.startDate : existing.startDate,
        input.endDate !== undefined ? input.endDate : existing.endDate,
        input.isActive !== undefined ? input.isActive : existing.isActive,
      ],
    );
    return (await this.getById(id))!;
  }

  async incrementUsage(id: string): Promise<void> {
    await this.pool.query(
      'UPDATE promotions SET usage_count = usage_count + 1, updated_at = now() WHERE id = $1',
      [id],
    );
  }

  async delete(id: string): Promise<void> {
    const res = await this.pool.query('DELETE FROM promotions WHERE id = $1 RETURNING id', [id]);
    if (!res.rows.length) throw new NotFoundError('Promotion not found');
  }
}
