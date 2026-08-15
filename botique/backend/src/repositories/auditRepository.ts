import { randomUUID } from 'node:crypto';
import type { Pool } from 'pg';
import type { AuditAction } from '../models/index.js';

export interface AuditLogRow {
  id: string;
  actorUserId: string | null;
  actorName: string;
  action: AuditAction;
  resource: string;
  resourceId: string | null;
  description: string;
  previousValue: unknown;
  newValue: unknown;
  createdAt: string;
}

export class AuditRepository {
  constructor(private pool: Pool) {}

  private map(r: Record<string, unknown>): AuditLogRow {
    return {
      id: String(r.id),
      actorUserId: r.actor_user_id ? String(r.actor_user_id) : null,
      actorName: String(r.actor_name),
      action: r.action as AuditAction,
      resource: String(r.resource),
      resourceId: r.resource_id ? String(r.resource_id) : null,
      description: String(r.description),
      previousValue: r.previous_value ?? null,
      newValue: r.new_value ?? null,
      createdAt: String(r.created_at),
    };
  }

  async log(input: {
    actorUserId: string | null;
    actorName?: string;
    action: AuditAction;
    resource: string;
    resourceId?: string | null;
    description: string;
    previousValue?: unknown;
    newValue?: unknown;
  }): Promise<AuditLogRow> {
    let actorName = input.actorName;
    if (!actorName && input.actorUserId) {
      const actor = await this.pool.query('SELECT full_name FROM users WHERE id = $1', [input.actorUserId]);
      actorName = String(actor.rows[0]?.full_name ?? 'unknown');
    }
    const res = await this.pool.query(
      `INSERT INTO audit_logs (id, actor_user_id, actor_name, action, resource, resource_id, description, previous_value, new_value)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       RETURNING *`,
      [
        randomUUID(),
        input.actorUserId,
        actorName ?? 'system',
        input.action,
        input.resource,
        input.resourceId ?? null,
        input.description,
        input.previousValue === undefined ? null : JSON.stringify(input.previousValue),
        input.newValue === undefined ? null : JSON.stringify(input.newValue),
      ],
    );
    return this.map(res.rows[0]);
  }

  async list(params: {
    resource?: string;
    action?: string;
    userId?: string;
    page?: number;
    pageSize?: number;
  }) {
    const conditions: string[] = [];
    const values: unknown[] = [];
    if (params.resource) {
      values.push(params.resource);
      conditions.push(`resource = $${values.length}`);
    }
    if (params.action) {
      values.push(params.action);
      conditions.push(`action = $${values.length}`);
    }
    if (params.userId) {
      values.push(params.userId);
      conditions.push(`actor_user_id = $${values.length}`);
    }
    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const page = Math.max(1, params.page ?? 1);
    const pageSize = Math.min(100, Math.max(1, params.pageSize ?? 20));
    const offset = (page - 1) * pageSize;
    const countRes = await this.pool.query(`SELECT count(*)::int AS n FROM audit_logs ${where}`, values);
    const res = await this.pool.query(
      `SELECT * FROM audit_logs ${where} ORDER BY created_at DESC LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, offset],
    );
    return {
      rows: res.rows.map((r) => this.map(r)),
      total: Number(countRes.rows[0]?.n ?? 0),
      page,
      pageSize,
    };
  }
}