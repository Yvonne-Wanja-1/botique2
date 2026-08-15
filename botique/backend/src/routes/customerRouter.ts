import { Router } from 'express';
import { customerController } from '../controllers/customerController.js';
import { anyAuthenticated, requireRole } from '../middleware/authStub.js';
import { validateBody } from '../middleware/validate.js';
import { addressSchema } from '../validation/schemas.js';
import type { CustomerService } from '../services/customerService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const STAFF_ROLES = ['super_admin', 'store_manager'];

export function customerRouter(customerService: CustomerService): Router {
  const router = Router();
  const c = customerController(customerService);

  router.get('/me', anyAuthenticated, asyncHandler(c.getMe));
  router.get('/me/orders', anyAuthenticated, asyncHandler(c.getMeOrders));
  router.get('/me/addresses', anyAuthenticated, asyncHandler(c.getMeAddresses));
  router.post('/me/addresses', anyAuthenticated, validateBody(addressSchema), asyncHandler(c.addMeAddress));
  router.patch('/me/addresses/:id/default', anyAuthenticated, asyncHandler(c.setDefaultAddress));
  router.get('/', requireRole(...STAFF_ROLES), asyncHandler(c.list));

  return router;
}