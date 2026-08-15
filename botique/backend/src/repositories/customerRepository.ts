import { randomUUID } from 'node:crypto';
import type { Pool } from 'pg';
import { toNumber } from '../models/index.js';
import { NotFoundError } from '../utils/errors.js';

export interface Address {
  id: string;
  label: string;
  fullName: string;
  phone: string;
  street: string;
  city: string;
  state: string;
  isDefault: boolean;
}

export interface CustomerProfile {
  id: string;
  email: string;
  phone: string;
  fullName: string;
  avatarUrl: string | null;
  isActive: boolean;
  createdAt: string;
  addresses: Address[];
  orderCount: number;
  totalSpent: number;
}

export class CustomerRepository {
  constructor(private pool: Pool) {}

  private mapAddress(r: Record<string, unknown>): Address {
    return {
      id: String(r.id),
      label: String(r.label),
      fullName: String(r.full_name),
      phone: String(r.phone),
      street: String(r.street),
      city: String(r.city),
      state: String(r.state),
      isDefault: Boolean(r.is_default),
    };
  }

  async getProfile(customerId: string): Promise<CustomerProfile> {
    const user = await this.pool.query(
      'SELECT id, email, phone, full_name, avatar_url, is_active, created_at FROM users WHERE id = $1',
      [customerId],
    );
    if (!user.rows.length) throw new NotFoundError('Customer not found');
    const u = user.rows[0];

    const addresses = await this.pool.query(
      `SELECT id, label, full_name, phone, street, city, state, is_default
       FROM addresses WHERE user_id = $1 ORDER BY is_default DESC, created_at DESC`,
      [customerId],
    );
    const stats = await this.pool.query(
      `SELECT count(*)::int AS order_count, COALESCE(sum(total), 0) AS total_spent
       FROM orders WHERE customer_id = $1`,
      [customerId],
    );

    return {
      id: String(u.id),
      email: String(u.email),
      phone: String(u.phone),
      fullName: String(u.full_name),
      avatarUrl: u.avatar_url ? String(u.avatar_url) : null,
      isActive: Boolean(u.is_active),
      createdAt: String(u.created_at),
      addresses: addresses.rows.map((r) => this.mapAddress(r)),
      orderCount: toNumber(stats.rows[0]?.order_count ?? 0),
      totalSpent: Number(stats.rows[0]?.total_spent ?? 0),
    };
  }

  async listStaff(params: { search?: string; page?: number; pageSize?: number }) {
    const conditions: string[] = [];
    const values: unknown[] = [];
    if (params.search) {
      values.push(`%${params.search}%`);
      conditions.push(`(u.full_name ILIKE $${values.length} OR u.email ILIKE $${values.length} OR u.phone ILIKE $${values.length})`);
    }
    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const page = Math.max(1, params.page ?? 1);
    const pageSize = Math.min(100, Math.max(1, params.pageSize ?? 20));
    const offset = (page - 1) * pageSize;
    const countRes = await this.pool.query(`SELECT count(*)::int AS n FROM users u ${where}`, values);
    const res = await this.pool.query(
      `SELECT u.id, u.email, u.phone, u.full_name, u.is_active, u.created_at, r.name AS role
       FROM users u JOIN roles r ON r.id = u.role_id
       ${where}
       ORDER BY u.created_at DESC LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, offset],
    );
    const userIds = res.rows.map((r) => String(r.id));
    const orderCounts = new Map<string, number>();
    if (userIds.length) {
      const ph = userIds.map((_, i) => `$${i + 1}`).join(', ');
      const counts = await this.pool.query(
        `SELECT customer_id, count(*)::int AS n FROM orders WHERE customer_id IN (${ph}) GROUP BY customer_id`,
        userIds,
      );
      for (const c of counts.rows) orderCounts.set(String(c.customer_id), c.n);
    }
    const rows = res.rows.map((r) => ({ ...r, orderCount: orderCounts.get(String(r.id)) ?? 0 }));
    return { rows, total: toNumber(countRes.rows[0]?.n ?? 0) };
  }

  async addAddress(customerId: string, input: Omit<Address, 'id'>): Promise<Address> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      if (input.isDefault) {
        await client.query('UPDATE addresses SET is_default = FALSE WHERE user_id = $1', [customerId]);
      }
      const id = randomUUID();
      await client.query(
        `INSERT INTO addresses (id, user_id, label, full_name, phone, street, city, state, is_default)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
        [id, customerId, input.label, input.fullName, input.phone, input.street, input.city, input.state, input.isDefault],
      );
      await client.query('COMMIT');
      const res = await client.query(
        `SELECT id, label, full_name, phone, street, city, state, is_default
         FROM addresses WHERE id = $1`,
        [id],
      );
      return this.mapAddress(res.rows[0]);
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }

  async getAddresses(customerId: string): Promise<Address[]> {
    const res = await this.pool.query(
      `SELECT id, label, full_name, phone, street, city, state, is_default
       FROM addresses WHERE user_id = $1 ORDER BY is_default DESC, created_at DESC`,
      [customerId],
    );
    return res.rows.map((r) => this.mapAddress(r));
  }

  async setDefaultAddress(customerId: string, addressId: string): Promise<Address> {
    const owner = await this.pool.query(
      'SELECT id FROM addresses WHERE id = $1 AND user_id = $2',
      [addressId, customerId],
    );
    if (!owner.rows.length) throw new NotFoundError('Address not found');
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      await client.query('UPDATE addresses SET is_default = FALSE WHERE user_id = $1', [customerId]);
      await client.query('UPDATE addresses SET is_default = TRUE WHERE id = $1', [addressId]);
      await client.query('COMMIT');
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
    const res = await this.pool.query(
      `SELECT id, label, full_name, phone, street, city, state, is_default
       FROM addresses WHERE id = $1`,
      [addressId],
    );
    return this.mapAddress(res.rows[0]);
  }
}