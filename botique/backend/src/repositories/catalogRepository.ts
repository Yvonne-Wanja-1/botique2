import { randomUUID } from 'node:crypto';
import type { Pool } from 'pg';
import type { Brand, Category } from '../models/index.js';

function mapCategory(row: Record<string, unknown>): Category {
  return {
    id: String(row.id),
    parentId: row.parent_id ? String(row.parent_id) : null,
    name: String(row.name),
    slug: String(row.slug),
    description: row.description ? String(row.description) : null,
    imageUrl: row.image_url ? String(row.image_url) : null,
    isActive: Boolean(row.is_active),
  };
}

function mapBrand(row: Record<string, unknown>): Brand {
  return {
    id: String(row.id),
    name: String(row.name),
    slug: String(row.slug),
    logoUrl: row.logo_url ? String(row.logo_url) : null,
    isActive: Boolean(row.is_active),
  };
}

export class CategoryRepository {
  constructor(private pool: Pool) {}

  async getRootCategories(): Promise<Category[]> {
    const res = await this.pool.query(
      'SELECT * FROM categories WHERE parent_id IS NULL AND is_active = TRUE ORDER BY name',
    );
    return res.rows.map(mapCategory);
  }

  async getSubcategories(parentId: string): Promise<Category[]> {
    const res = await this.pool.query(
      'SELECT * FROM categories WHERE parent_id = $1 AND is_active = TRUE ORDER BY name',
      [parentId],
    );
    return res.rows.map(mapCategory);
  }

  async getById(id: string): Promise<Category | null> {
    const res = await this.pool.query('SELECT * FROM categories WHERE id = $1', [id]);
    return res.rows.length ? mapCategory(res.rows[0]) : null;
  }

  async create(input: {
    name: string;
    slug: string;
    parentId?: string | null;
    description?: string | null;
    imageUrl?: string | null;
  }): Promise<Category> {
    const res = await this.pool.query(
      `INSERT INTO categories (id, parent_id, name, slug, description, image_url)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [randomUUID(), input.parentId ?? null, input.name, input.slug, input.description ?? null, input.imageUrl ?? null],
    );
    return mapCategory(res.rows[0]);
  }
}

export class BrandRepository {
  constructor(private pool: Pool) {}

  async getAll(): Promise<Brand[]> {
    const res = await this.pool.query('SELECT * FROM brands WHERE is_active = TRUE ORDER BY name');
    return res.rows.map(mapBrand);
  }

  async getById(id: string): Promise<Brand | null> {
    const res = await this.pool.query('SELECT * FROM brands WHERE id = $1', [id]);
    return res.rows.length ? mapBrand(res.rows[0]) : null;
  }
}