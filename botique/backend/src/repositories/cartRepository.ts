import { randomUUID } from 'node:crypto';
import type { Pool } from 'pg';
import { toNumber } from '../models/index.js';
import { ConflictError, NotFoundError } from '../utils/errors.js';

export interface CartItemRow {
  id: string;
  productId: string;
  variantId: string | null;
  name: string;
  size: string | null;
  color: string | null;
  shade: string | null;
  imageUrl: string | null;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}

export interface CartView {
  items: CartItemRow[];
  subtotal: number;
  total: number;
}

export class CartRepository {
  constructor(private pool: Pool) {}

  private async ensureCart(customerId: string): Promise<string> {
    const res = await this.pool.query(
      `INSERT INTO carts (id, user_id) VALUES ($1, $2)
       ON CONFLICT (user_id) DO UPDATE SET updated_at = now()
       RETURNING id`,
      [randomUUID(), customerId],
    );
    return String(res.rows[0].id);
  }

  private async ensureWishlist(customerId: string): Promise<string> {
    const res = await this.pool.query(
      `INSERT INTO wishlists (id, user_id) VALUES ($1, $2)
       ON CONFLICT (user_id) DO UPDATE SET updated_at = now()
       RETURNING id`,
      [randomUUID(), customerId],
    );
    return String(res.rows[0].id);
  }

  async getCart(customerId: string): Promise<CartView> {
    const res = await this.pool.query(
      `SELECT ci.id, ci.product_id, ci.variant_id, ci.quantity,
              p.name, v.size, v.color, v.shade,
              COALESCE(p.discount_price, p.base_price) AS unit_price
       FROM carts c
       JOIN cart_items ci ON ci.cart_id = c.id
       JOIN products p ON p.id = ci.product_id
       LEFT JOIN product_variants v ON v.id = ci.variant_id
       WHERE c.user_id = $1
       ORDER BY ci.created_at`,
      [customerId],
    );
    const items: CartItemRow[] = res.rows.map((r) => {
      const quantity = toNumber(r.quantity);
      const unitPrice = Number(r.unit_price);
      return {
        id: r.id,
        productId: r.product_id,
        variantId: r.variant_id ?? null,
        name: r.name,
        size: r.size ?? null,
        color: r.color ?? null,
        shade: r.shade ?? null,
        imageUrl: null,
        quantity,
        unitPrice,
        totalPrice: quantity * unitPrice,
      };
    });
    if (items.length) {
      const productIds = [...new Set(items.map((i) => i.productId))];
      const imgRes = await this.pool.query(
        `SELECT DISTINCT ON (product_id) product_id, url FROM product_images
         WHERE product_id = ANY($1) ORDER BY product_id, position`,
        [productIds],
      );
      const urlByProduct = new Map(imgRes.rows.map((r) => [r.product_id, r.url]));
      for (const item of items) item.imageUrl = urlByProduct.get(item.productId) ?? null;
    }
    const subtotal = items.reduce((s, i) => s + i.totalPrice, 0);
    return { items, subtotal, total: subtotal };
  }

  async addItem(customerId: string, productId: string, variantId: string | null, quantity: number): Promise<CartView> {
    if (quantity < 1) throw new ConflictError('Quantity must be at least 1');
    const vres = await this.pool.query(
      `SELECT v.stock_qty
       FROM product_variants v JOIN products p ON p.id = v.product_id
       WHERE v.id = $1 AND v.product_id = $2 AND v.is_active = TRUE AND p.status = 'active'`,
      [variantId, productId],
    );
    if (!vres.rows.length) throw new NotFoundError('Variant not found');
    const stock = toNumber(vres.rows[0].stock_qty);
    const cartId = await this.ensureCart(customerId);
    const existing = await this.pool.query(
      'SELECT quantity FROM cart_items WHERE cart_id = $1 AND product_id = $2 AND variant_id = $3',
      [cartId, productId, variantId],
    );
    const newQuantity = quantity + (existing.rows.length ? toNumber(existing.rows[0].quantity) : 0);
    if (newQuantity > stock) throw new ConflictError('Requested quantity exceeds available stock');
    await this.pool.query(
      `INSERT INTO cart_items (id, cart_id, product_id, variant_id, quantity)
       VALUES ($1,$2,$3,$4,$5)
       ON CONFLICT (cart_id, product_id, variant_id)
       DO UPDATE SET quantity = EXCLUDED.quantity, updated_at = now()`,
      [randomUUID(), cartId, productId, variantId, newQuantity],
    );
    return this.getCart(customerId);
  }

  async updateItemQuantity(customerId: string, itemId: string, quantity: number): Promise<CartView> {
    if (quantity < 1) throw new ConflictError('Quantity must be at least 1');
    const found = await this.pool.query(
      'SELECT ci.id FROM cart_items ci JOIN carts c ON c.id = ci.cart_id WHERE ci.id = $1 AND c.user_id = $2',
      [itemId, customerId],
    );
    if (!found.rows.length) throw new NotFoundError('Cart item not found');
    const stockRes = await this.pool.query(
      'SELECT v.stock_qty FROM cart_items ci JOIN carts c ON c.id = ci.cart_id JOIN product_variants v ON v.id = ci.variant_id WHERE ci.id = $1 AND c.user_id = $2',
      [itemId, customerId],
    );
    const stock = stockRes.rows.length ? toNumber(stockRes.rows[0].stock_qty) : 0;
    if (quantity > stock) throw new ConflictError('Requested quantity exceeds available stock');
    await this.pool.query(
      'UPDATE cart_items SET quantity = $2, updated_at = now() WHERE id = $1',
      [itemId, quantity],
    );
    return this.getCart(customerId);
  }

  async removeItem(customerId: string, itemId: string): Promise<CartView> {
    const res = await this.pool.query(
      'DELETE FROM cart_items WHERE id = $1 AND cart_id = (SELECT id FROM carts WHERE user_id = $2)',
      [itemId, customerId],
    );
    if (!res.rowCount) throw new NotFoundError('Cart item not found');
    return this.getCart(customerId);
  }

  async clearCart(customerId: string): Promise<void> {
    await this.pool.query(
      'DELETE FROM cart_items WHERE cart_id = (SELECT id FROM carts WHERE user_id = $1)',
      [customerId],
    );
  }

  async getWishlist(customerId: string) {
    const res = await this.pool.query(
      `SELECT wi.product_id, p.name, p.base_price, p.discount_price, p.rating
       FROM wishlists w
       JOIN wishlist_items wi ON wi.wishlist_id = w.id
       JOIN products p ON p.id = wi.product_id
       WHERE w.user_id = $1 AND p.status = 'active'
       ORDER BY wi.added_at DESC`,
      [customerId],
    );
    return res.rows.map((r) => ({
      productId: r.product_id,
      name: r.name,
      basePrice: Number(r.base_price),
      discountPrice: r.discount_price === null ? null : Number(r.discount_price),
      rating: Number(r.rating),
    }));
  }

  async toggleWishlist(customerId: string, productId: string): Promise<{ added: boolean }> {
    const wishlistId = await this.ensureWishlist(customerId);
    const existing = await this.pool.query(
      'SELECT 1 FROM wishlist_items WHERE wishlist_id = $1 AND product_id = $2',
      [wishlistId, productId],
    );
    if (existing.rows.length) {
      await this.pool.query('DELETE FROM wishlist_items WHERE wishlist_id = $1 AND product_id = $2', [wishlistId, productId]);
      return { added: false };
    }
    await this.pool.query(
      'INSERT INTO wishlist_items (id, wishlist_id, product_id) VALUES ($1,$2,$3)',
      [randomUUID(), wishlistId, productId],
    );
    return { added: true };
  }
}