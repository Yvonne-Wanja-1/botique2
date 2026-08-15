import { Router } from 'express';
import { notificationController } from '../controllers/notificationController.js';
import { anyAuthenticated, requireRole } from '../middleware/authStub.js';
import { validateBody } from '../middleware/validate.js';
import { notificationCreateSchema } from '../validation/schemas.js';
import type { NotificationService } from '../services/notificationService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export function notificationRouter(notificationService: NotificationService): Router {
  const router = Router();
  const c = notificationController(notificationService);

  router.get('/', anyAuthenticated, asyncHandler(c.list));
  router.post('/', requireRole('super_admin', 'store_manager'), validateBody(notificationCreateSchema), asyncHandler(c.create));
  router.patch('/read-all', anyAuthenticated, asyncHandler(c.markAllRead));
  router.patch('/:id/read', anyAuthenticated, asyncHandler(c.markRead));

  return router;
}