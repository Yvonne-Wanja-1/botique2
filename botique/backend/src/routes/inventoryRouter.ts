import { Router } from 'express';
import { inventoryController } from '../controllers/inventoryController.js';
import { requireRole } from '../middleware/authStub.js';
import { validateBody } from '../middleware/validate.js';
import { adjustInventorySchema } from '../validation/schemas.js';
import type { InventoryService } from '../services/inventoryService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export function inventoryRouter(inventoryService: InventoryService): Router {
  const router = Router();
  const c = inventoryController(inventoryService);
  const staffRoles = requireRole('super_admin', 'store_manager', 'inventory_staff');

  router.get('/variants', asyncHandler(c.list));
  router.post('/variants/:variantId/adjust', staffRoles, validateBody(adjustInventorySchema), asyncHandler(c.adjust));

  return router;
}