import { randomUUID } from 'node:crypto';
import type { Pool } from 'pg';
import type { NotificationType } from '../models/index.js';
import { NotFoundError } from '../utils/errors.js';

export interface Notification {
  id: string;
  userId: string | null;
  type: NotificationType;
  title: string;
  body: string;
  isRead: boolean;
  createdAt: string;
}

export class NotificationRepository {
  constructor(private pool: Pool) {}

  private map(r: Record<string, unknown>): Notification {
    return {
      id: String(r.id),
      userId: r.user_id ? String(r.user_id) : null,
      type: r.type as NotificationType,
      title: String(r.title),
      body: String(r.body),
      isRead: Boolean(r.is_read),
      createdAt: String(r.created_at),
    };
  }

  async listForUser(userId: string, unreadOnly = false): Promise<Notification[]> {
    const where = unreadOnly ? 'AND is_read = FALSE' : '';
    const res = await this.pool.query(
      `SELECT * FROM notifications WHERE user_id = $1 ${where} ORDER BY created_at DESC`,
      [userId],
    );
    return res.rows.map((r) => this.map(r));
  }

  async markRead(userId: string, id: string): Promise<Notification> {
    const res = await this.pool.query(
      'UPDATE notifications SET is_read = TRUE WHERE id = $1 AND user_id = $2 RETURNING id',
      [id, userId],
    );
    if (!res.rows.length) throw new NotFoundError('Notification not found');
    const n = await this.pool.query('SELECT * FROM notifications WHERE id = $1', [id]);
    return this.map(n.rows[0]);
  }

  async markAllRead(userId: string): Promise<void> {
    await this.pool.query('UPDATE notifications SET is_read = TRUE WHERE user_id = $1', [userId]);
  }

  async create(input: { userId?: string | null; title: string; body: string; type: NotificationType; target?: 'customer' | 'staff' }): Promise<Notification> {
    const rows: Notification[] = [];
    if (input.userId) {
      const res = await this.pool.query(
        'INSERT INTO notifications (id, user_id, type, title, body) VALUES ($1,$2,$3,$4,$5) RETURNING *',
        [randomUUID(), input.userId, input.type, input.title, input.body],
      );
      rows.push(this.map(res.rows[0]));
    } else {
      const roleNames = input.target === 'staff'
        ? ['super_admin', 'store_manager', 'sales_staff', 'inventory_staff']
        : ['customer'];
      const idsRes = await this.pool.query(
        `SELECT id FROM roles WHERE name IN (${roleNames.map((_, i) => `$${i + 1}`).join(', ')})`,
        roleNames,
      );
      const roleIds: string[] = idsRes.rows.map((r) => String(r.id));
      for (const roleId of roleIds) {
        const userRes = await this.pool.query(
          'SELECT id FROM users WHERE role_id = $1',
          [roleId],
        );
        for (const user of userRes.rows) {
          const notifId = randomUUID();
          const res = await this.pool.query(
            'INSERT INTO notifications (id, user_id, type, title, body) VALUES ($1,$2,$3,$4,$5) RETURNING *',
            [notifId, String(user.id), input.type, input.title, input.body],
          );
          rows.push(this.map(res.rows[0]));
        }
      }
    }
    return rows[0];
  }
}