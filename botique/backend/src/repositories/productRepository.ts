import { randomUUID } from 'node:crypto';
import type { Pool } from 'pg';
import type { Product, ProductRow, ProductVariant, ReviewRow } from '../models/index.js';
import { toNumber } from '../models/index.js';
import { NotFoundError } from '../utils/errors.js';

export interface ProductSearchParams {
  categoryId?: string;
  brandId?: string;
  minPrice?: number;
  maxPrice?: number;
  sizes?: string[];
  colors?: string[];
  availability?: boolean;
  minRating?: number;
  onSaleOnly?: boolean;
  search?: string;
  featured?: boolean;
  newArrival?: boolean;
  bestSeller?: boolean;
  trending?: boolean;
  sort?: 'newest' | 'price_low_high' | 'price_high_low' | 'best_selling' | 'best_rated' | 'discount';
  page?: number;
  pageSize?: number;
}

export interface VariantInput {
  sku: string;
  size?: string | null;
  color?: string | null;
  shade?: string | null;
  price?: number | null;
  stockQty: number;
}

export interface CreateProductInput {
  name: string;
  slug: string;
  description: string;
  categoryId: string;
  brandId: string;
  basePrice: number;
  discountPrice?: number | null;
  stockThreshold: number;
  isFeatured: boolean;
  isNewArrival: boolean;
  isBestSeller: boolean;
  isTrending: boolean;
  specifications: Record<string, string>;
  variants: VariantInput[];
}

const ORDER_BY: Record<NonNullable<ProductSearchParams['sort']>, string> = {
  newest: 'created_at DESC',
  price_low_high: 'COALESCE(discount_price, base_price) ASC',
  price_high_low: 'COALESCE(discount_price, base_price) DESC',
  best_selling: 'sold_count DESC',
  best_rated: 'rating DESC',
  discount: 'CASE WHEN discount_price IS NULL THEN 0 ELSE (base_price - discount_price) END DESC',
};

function mapProductRow(row: ProductRow): Product {
  return {
    id: String(row.id),
    name: String(row.name),
    slug: String(row.slug),
    description: String(row.description),
    categoryId: String(row.category_id),
    brandId: String(row.brand_id),
    basePrice: Number(row.base_price),
    discountPrice: row.discount_price === null ? null : Number(row.discount_price),
    stockThreshold: Number(row.stock_threshold),
    status: row.status as Product['status'],
    rating: Number(row.rating),
    reviewCount: Number(row.review_count),
    soldCount: Number(row.sold_count),
    viewCount: Number(row.view_count),
    isFeatured: Boolean(row.is_featured),
    isNewArrival: Boolean(row.is_new_arrival),
    isBestSeller: Boolean(row.is_best_seller),
    isTrending: Boolean(row.is_trending),
    specifications: typeof row.specifications === 'string' ? JSON.parse(row.specifications) : row.specifications,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    variants: [],
    images: [],
  };
}

export class ProductRepository {
  constructor(private pool: Pool) {}

  async search(params: ProductSearchParams): Promise<{ rows: Product[]; total: number }> {
    const conditions: string[] = ["p.status = 'active'"];
    const values: unknown[] = [];

    if (params.featured) conditions.push('p.is_featured = TRUE');
    if (params.newArrival) conditions.push('p.is_new_arrival = TRUE');
    if (params.bestSeller) conditions.push('p.is_best_seller = TRUE');
    if (params.trending) conditions.push('p.is_trending = TRUE');
    if (params.onSaleOnly) conditions.push('p.discount_price IS NOT NULL');
    if (params.categoryId) {
      values.push(params.categoryId);
      conditions.push(
        `(p.category_id = $${values.length} OR p.category_id IN (SELECT id FROM categories WHERE parent_id = $${values.length}))`,
      );
    }
    if (params.brandId) {
      values.push(params.brandId);
      conditions.push(`p.brand_id = $${values.length}`);
    }
    if (params.minPrice !== undefined) {
      values.push(params.minPrice);
      conditions.push(`COALESCE(p.discount_price, p.base_price) >= $${values.length}`);
    }
    if (params.maxPrice !== undefined) {
      values.push(params.maxPrice);
      conditions.push(`COALESCE(p.discount_price, p.base_price) <= $${values.length}`);
    }
    if (params.minRating !== undefined) {
      values.push(params.minRating);
      conditions.push(`p.rating >= $${values.length}`);
    }
    if (params.availability === true) {
      conditions.push(`EXISTS (SELECT 1 FROM product_variants v WHERE v.product_id = p.id AND v.stock_qty > 0 AND v.is_active)`);
    }
    if (params.availability === false) {
      conditions.push(`NOT EXISTS (SELECT 1 FROM product_variants v WHERE v.product_id = p.id AND v.stock_qty > 0 AND v.is_active)`);
    }
    if (params.sizes?.length) {
      values.push(params.sizes);
      conditions.push(`EXISTS (SELECT 1 FROM product_variants v WHERE v.product_id = p.id AND v.size = ANY($${values.length}))`);
    }
    if (params.colors?.length) {
      values.push(params.colors);
      conditions.push(`EXISTS (SELECT 1 FROM product_variants v WHERE v.product_id = p.id AND v.color = ANY($${values.length}))`);
    }
    if (params.search) {
      values.push(`%${params.search.toLowerCase()}%`);
      conditions.push(`(LOWER(p.name) LIKE $${values.length} OR LOWER(p.description) LIKE $${values.length})`);
    }

    const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const sort = params.sort ?? 'newest';
    const page = Math.max(1, params.page ?? 1);
    const pageSize = Math.min(100, Math.max(1, params.pageSize ?? 20));
    const offset = (page - 1) * pageSize;

    const countRes = await this.pool.query(
      `SELECT count(*)::int AS n FROM products p ${whereClause}`,
      values,
    );
    const dataRes = await this.pool.query(
      `SELECT p.* FROM products p ${whereClause} ORDER BY ${ORDER_BY[sort]} LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, offset],
    );

    const products = dataRes.rows.map(mapProductRow);
    if (products.length) {
      const ids = products.map((p) => p.id);
      const varRes = await this.pool.query(
        'SELECT * FROM product_variants WHERE product_id = ANY($1) ORDER BY created_at',
        [ids],
      );
      const imgRes = await this.pool.query(
        'SELECT product_id, url FROM product_images WHERE product_id = ANY($1) ORDER BY position',
        [ids],
      );
      const variantsByProduct = new Map<string, ProductVariant[]>();
      for (const row of varRes.rows) {
        const list = variantsByProduct.get(row.product_id) ?? [];
        list.push({
          id: row.id,
          productId: row.product_id,
          sku: row.sku,
          size: row.size,
          color: row.color,
          shade: row.shade,
          price: row.price === null ? null : Number(row.price),
          stockQty: Number(row.stock_qty),
          isActive: row.is_active,
        });
        variantsByProduct.set(row.product_id, list);
      }
      const imagesByProduct = new Map<string, string[]>();
      for (const row of imgRes.rows) {
        const list = imagesByProduct.get(row.product_id) ?? [];
        list.push(row.url);
        imagesByProduct.set(row.product_id, list);
      }
      for (const p of products) {
        p.variants = variantsByProduct.get(p.id) ?? [];
        p.images = imagesByProduct.get(p.id) ?? [];
      }
    }

    return { rows: products, total: toNumber(countRes.rows[0]?.n ?? 0) };
  }

  async findById(id: string): Promise<Product | null> {
    const res = await this.pool.query('SELECT * FROM products WHERE id = $1', [id]);
    if (!res.rows.length) return null;
    const product = mapProductRow(res.rows[0]);
    const varRes = await this.pool.query(
      'SELECT * FROM product_variants WHERE product_id = $1 ORDER BY created_at',
      [id],
    );
    product.variants = varRes.rows.map((r) => ({
      id: r.id,
      productId: r.product_id,
      sku: r.sku,
      size: r.size,
      color: r.color,
      shade: r.shade,
      price: r.price === null ? null : Number(r.price),
      stockQty: Number(r.stock_qty),
      isActive: r.is_active,
    }));
    const imgRes = await this.pool.query(
      'SELECT url FROM product_images WHERE product_id = $1 ORDER BY position',
      [id],
    );
    product.images = imgRes.rows.map((r) => r.url);
    return product;
  }

  async create(input: CreateProductInput): Promise<Product> {
    const productId = randomUUID();
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(
        `INSERT INTO products (id, name, slug, description, category_id, brand_id, base_price,
           discount_price, stock_threshold, is_featured, is_new_arrival, is_best_seller, is_trending, specifications)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)`,
        [
          productId, input.name, input.slug, input.description, input.categoryId, input.brandId,
          input.basePrice, input.discountPrice ?? null, input.stockThreshold,
          input.isFeatured, input.isNewArrival, input.isBestSeller, input.isTrending,
          JSON.stringify(input.specifications),
        ],
      );
      for (const v of input.variants) {
        await client.query(
          `INSERT INTO product_variants (id, product_id, sku, size, color, shade, price, stock_qty)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
          [randomUUID(), productId, v.sku, v.size ?? null, v.color ?? null, v.shade ?? null, v.price ?? null, v.stockQty],
        );
      }
      await client.query('COMMIT');
      const created = await this.findById(productId);
      if (!created) throw new NotFoundError('Product was not created');
      return created;
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }

  async update(id: string, input: Partial<CreateProductInput>): Promise<Product | null> {
    await this.pool.query(
      `UPDATE products SET
         name = COALESCE($2, name),
         slug = COALESCE($3, slug),
         description = COALESCE($4, description),
         category_id = COALESCE($5, category_id),
         brand_id = COALESCE($6, brand_id),
         base_price = COALESCE($7, base_price),
         discount_price = $8,
         stock_threshold = COALESCE($9, stock_threshold),
         is_featured = COALESCE($10, is_featured),
         is_new_arrival = COALESCE($11, is_new_arrival),
         is_best_seller = COALESCE($12, is_best_seller),
         is_trending = COALESCE($13, is_trending),
         updated_at = now()
       WHERE id = $1`,
      [
        id, input.name ?? null, input.slug ?? null, input.description ?? null,
        input.categoryId ?? null, input.brandId ?? null, input.basePrice ?? null,
        input.discountPrice === undefined ? null : input.discountPrice,
        input.stockThreshold ?? null, input.isFeatured ?? null, input.isNewArrival ?? null,
        input.isBestSeller ?? null, input.isTrending ?? null,
      ],
    );
    return this.findById(id);
  }

  async setStatus(id: string, status: 'active' | 'inactive' | 'discontinued'): Promise<boolean> {
    const res = await this.pool.query(
      'UPDATE products SET status = $2, updated_at = now() WHERE id = $1',
      [id, status],
    );
    return (res.rowCount ?? 0) > 0;
  }

  async getReviews(productId: string): Promise<ReviewRow[]> {
    const res = await this.pool.query(
      `SELECT id, product_id, customer_id, rating, comment, is_verified_purchase, is_approved, is_reported, created_at
       FROM reviews WHERE product_id = $1 AND is_approved = TRUE ORDER BY created_at DESC`,
      [productId],
    );
    return res.rows.map((r) => ({
      id: r.id,
      productId: r.product_id,
      customerId: r.customer_id,
      rating: Number(r.rating),
      comment: r.comment,
      isVerifiedPurchase: r.is_verified_purchase,
      isApproved: r.is_approved,
      isReported: r.is_reported,
      createdAt: r.created_at,
    }));
  }
}