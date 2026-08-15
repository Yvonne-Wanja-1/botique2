import { Router } from 'express';
import { userController } from '../controllers/userController.js';
import { requireRole } from '../middleware/authStub.js';
import { validateBody } from '../middleware/validate.js';
import { roleUpdateSchema, staffCreateSchema, userActiveSchema } from '../validation/schemas.js';
import type { UserService } from '../services/userService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export function userRouter(userService: UserService): Router {
  const router = Router();
  const c = userController(userService);

  router.get('/', requireRole('super_admin', 'store_manager'), asyncHandler(c.list));
  router.post('/', requireRole('super_admin'), validateBody(staffCreateSchema), asyncHandler(c.create));
  router.patch('/:id/role', requireRole('super_admin'), validateBody(roleUpdateSchema), asyncHandler(c.setRole));
  router.patch('/:id/active', requireRole('super_admin'), validateBody(userActiveSchema), asyncHandler(c.setActive));

  return router;
}