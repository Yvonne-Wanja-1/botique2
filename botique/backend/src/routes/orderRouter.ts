import { Router } from 'express';
import { orderController } from '../controllers/orderController.js';
import { anyAuthenticated, requireRole } from '../middleware/authStub.js';
import { validateBody } from '../middleware/validate.js';
import { orderStatusSchema, placeOrderSchema } from '../validation/schemas.js';
import type { OrderService } from '../services/orderService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export function orderRouter(orderService: OrderService): Router {
  const router = Router();
  const c = orderController(orderService);

  router.get('/', anyAuthenticated, asyncHandler(c.list));
  router.post('/', anyAuthenticated, validateBody(placeOrderSchema), asyncHandler(c.create));
  router.get('/:id', anyAuthenticated, asyncHandler(c.get));
  router.delete('/:id', anyAuthenticated, asyncHandler(c.cancel));
  router.patch(
    '/:id/status',
    requireRole('super_admin', 'store_manager', 'inventory_staff'),
    validateBody(orderStatusSchema),
    asyncHandler(c.updateStatus),
  );

  return router;
}