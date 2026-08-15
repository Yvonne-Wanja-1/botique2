import { randomUUID } from 'node:crypto';
import type { Pool } from 'pg';
import { toNumber } from '../models/index.js';
import { ConflictError, NotFoundError } from '../utils/errors.js';

export interface UserRow {
  id: string;
  email: string;
  phone: string;
  fullName: string;
  role: string;
  isActive: boolean;
  createdAt: string;
}

export class UserRepository {
  constructor(private pool: Pool) {}

  private map(r: Record<string, unknown>): UserRow {
    return {
      id: String(r.id),
      email: String(r.email),
      phone: String(r.phone),
      fullName: String(r.full_name),
      role: String(r.role),
      isActive: Boolean(r.is_active),
      createdAt: String(r.created_at),
    };
  }

  async getById(id: string): Promise<UserRow | null> {
    const res = await this.pool.query(
      'SELECT u.id, u.email, u.phone, u.full_name, u.is_active, u.created_at, r.name AS role FROM users u JOIN roles r ON r.id = u.role_id WHERE u.id = $1',
      [id],
    );
    return res.rows.length ? this.map(res.rows[0]) : null;
  }

  async list(params: { role?: string; search?: string; page?: number; pageSize?: number }) {
    const conditions: string[] = [];
    const values: unknown[] = [];
    if (params.role) {
      values.push(params.role);
      conditions.push(`r.name = $${values.length}`);
    }
    if (params.search) {
      values.push(`%${params.search}%`);
      conditions.push(`(u.full_name ILIKE $${values.length} OR u.email ILIKE $${values.length} OR u.phone ILIKE $${values.length})`);
    }
    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const page = Math.max(1, params.page ?? 1);
    const pageSize = Math.min(100, Math.max(1, params.pageSize ?? 20));
    const offset = (page - 1) * pageSize;
    const countRes = await this.pool.query(
      `SELECT count(*)::int AS n FROM users u JOIN roles r ON r.id = u.role_id ${where}`,
      values,
    );
    const res = await this.pool.query(
      `SELECT u.id, u.email, u.phone, u.full_name, u.is_active, u.created_at, r.name AS role
       FROM users u JOIN roles r ON r.id = u.role_id
       ${where}
       ORDER BY u.created_at DESC LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, offset],
    );
    return { rows: res.rows.map((r) => this.map(r)), total: toNumber(countRes.rows[0]?.n ?? 0) };
  }

  async create(input: { email: string; password: string; fullName: string; phone: string; role: string }): Promise<UserRow> {
    const roleRes = await this.pool.query('SELECT id FROM roles WHERE name = $1', [input.role]);
    if (!roleRes.rows.length) throw new NotFoundError('Role not found');
    const dup = await this.pool.query('SELECT id FROM users WHERE email = $1', [input.email]);
    if (dup.rows.length) throw new ConflictError('A user with this email already exists');
    const id = randomUUID();
    await this.pool.query(
      `INSERT INTO users (id, email, phone, full_name, role_id, password_hash)
       VALUES ($1,$2,$3,$4,$5,$6)`,
      [id, input.email, input.phone, input.fullName, roleRes.rows[0].id, input.password],
    );
    const user = await this.getById(id);
    if (!user) throw new NotFoundError('User was not created');
    return user;
  }

  async setRole(id: string, role: string): Promise<UserRow> {
    const roleRes = await this.pool.query('SELECT id FROM roles WHERE name = $1', [role]);
    if (!roleRes.rows.length) throw new NotFoundError('Role not found');
    const res = await this.pool.query(
      'UPDATE users SET role_id = $2, updated_at = now() WHERE id = $1 RETURNING id',
      [id, roleRes.rows[0].id],
    );
    if (!res.rows.length) throw new NotFoundError('User not found');
    const user = await this.getById(id);
    if (!user) throw new NotFoundError('User not found');
    return user;
  }

  async setActive(id: string, isActive: boolean): Promise<UserRow> {
    const res = await this.pool.query(
      'UPDATE users SET is_active = $2, updated_at = now() WHERE id = $1 RETURNING id',
      [id, isActive],
    );
    if (!res.rows.length) throw new NotFoundError('User not found');
    const user = await this.getById(id);
    if (!user) throw new NotFoundError('User not found');
    return user;
  }
}