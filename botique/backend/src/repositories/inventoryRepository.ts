import { randomUUID } from 'node:crypto';
import type { Pool } from 'pg';
import { toNumber } from '../models/index.js';

export interface VariantStockRow {
  variantId: string;
  productId: string;
  productName: string;
  sku: string;
  size: string | null;
  color: string | null;
  shade: string | null;
  stockQty: number;
  stockThreshold: number;
  isLowStock: boolean;
  isOutOfStock: boolean;
}

export class InventoryRepository {
  constructor(private pool: Pool) {}

  async listVariantInventory(stock?: 'low' | 'out' | 'all'): Promise<VariantStockRow[]> {
    const filter = {
      low: 'AND v.stock_qty > 0 AND v.stock_qty <= p.stock_threshold',
      out: 'AND v.stock_qty = 0',
      all: '',
    }[stock ?? 'all'];

    const res = await this.pool.query(
      `SELECT v.id AS variant_id, p.id AS product_id, p.name AS product_name, v.sku, v.size, v.color, v.shade,
              v.stock_qty, p.stock_threshold,
              (v.stock_qty > 0 AND v.stock_qty <= p.stock_threshold) AS is_low_stock,
              (v.stock_qty = 0) AS is_out_of_stock
       FROM product_variants v
       JOIN products p ON p.id = v.product_id
       WHERE v.is_active = TRUE ${filter}
       ORDER BY p.name, v.sku`,
    );
    return res.rows.map((r) => ({
      variantId: r.variant_id,
      productId: r.product_id,
      productName: r.product_name,
      sku: r.sku,
      size: r.size,
      color: r.color,
      shade: r.shade,
      stockQty: toNumber(r.stock_qty),
      stockThreshold: toNumber(r.stock_threshold),
      isLowStock: Boolean(r.is_low_stock),
      isOutOfStock: Boolean(r.is_out_of_stock),
    }));
  }

  async adjust(
    variantId: string,
    quantity: number,
    reason: string,
    changeType: 'add' | 'reduce' | 'adjust' | 'purchase',
    staffUserId: string | null,
  ): Promise<{ newQuantity: number; previousQuantity: number } | null> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const res = await client.query(
        `UPDATE product_variants SET stock_qty = stock_qty + $2, updated_at = now()
         WHERE id = $1 AND stock_qty + $2 >= 0
         RETURNING stock_qty`,
        [variantId, quantity],
      );
      if (!res.rows.length) {
        await client.query('ROLLBACK');
        return null;
      }
      const newQuantity = Number(res.rows[0].stock_qty);
      const previousQuantity = newQuantity - quantity;
      const prod = await client.query('SELECT product_id FROM product_variants WHERE id = $1', [variantId]);
      await client.query(
        `INSERT INTO inventory_transactions
           (id, variant_id, product_id, change_type, quantity_change, previous_quantity, new_quantity, reason, staff_user_id)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
        [
          randomUUID(),
          variantId,
          prod.rows[0]?.product_id ?? null,
          changeType,
          quantity,
          previousQuantity,
          newQuantity,
          reason,
          staffUserId,
        ],
      );
      await client.query('COMMIT');
      return { newQuantity, previousQuantity };
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }
}