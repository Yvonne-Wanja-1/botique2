import { describe, expect, it } from 'vitest';
import { loadPgMem, schemaPath } from './pgMem.js';

describe('schema', () => {
  it('runs the full schema against an in-memory Postgres', async () => {
    const pool = loadPgMem(schemaPath());
    const tables = await pool.query(
      "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'",
    );
    const names = tables.rows.map((r: { table_name: string }) => r.table_name);
    for (const t of [
      'roles', 'users', 'categories', 'brands', 'products', 'product_variants', 'inventory_transactions',
      'carts', 'cart_items', 'wishlists', 'wishlist_items', 'addresses', 'promotions',
      'orders', 'order_items', 'payments', 'installments', 'installment_payments',
      'reviews', 'notifications', 'audit_logs',
    ]) {
      expect(names).toContain(t);
    }
    await pool.end();
  });

  it('seeds reference data', async () => {
    const pool = loadPgMem(schemaPath());
    const { rows } = await pool.query('SELECT count(*)::int AS n FROM roles');
    expect(rows[0].n).toBeGreaterThanOrEqual(5);
    const prod = await pool.query('SELECT count(*)::int AS n FROM products');
    expect(prod.rows[0].n).toBe(16);
    const cats = await pool.query('SELECT count(*)::int AS n FROM categories');
    expect(cats.rows[0].n).toBe(23);
    await pool.end();
  });
});