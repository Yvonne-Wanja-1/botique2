import { Router } from 'express';
import { auditController } from '../controllers/auditController.js';
import { requireRole } from '../middleware/authStub.js';
import type { AuditService } from '../services/auditService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export function auditRouter(auditService: AuditService): Router {
  const router = Router();
  const c = auditController(auditService);

  router.get('/', requireRole('super_admin', 'store_manager'), asyncHandler(c.list));

  return router;
}