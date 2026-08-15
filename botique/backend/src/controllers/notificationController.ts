import type { Request, Response } from 'express';
import type { NotificationService } from '../services/notificationService.js';
import { principalId } from '../middleware/authStub.js';
import { ok } from '../utils/apiResponse.js';

export function notificationController(notificationService: NotificationService) {
  return {
    async list(req: Request, res: Response): Promise<void> {
      ok(res, await notificationService.listForUser(principalId(req), req.query.unreadOnly === 'true'));
    },
    async create(req: Request, res: Response): Promise<void> {
      ok(res, await notificationService.create(req.body), 201);
    },
    async markRead(req: Request, res: Response): Promise<void> {
      ok(res, await notificationService.markRead(principalId(req), req.params.id));
    },
    async markAllRead(req: Request, res: Response): Promise<void> {
      await notificationService.markAllRead(principalId(req));
      ok(res, { success: true });
    },
  };
}