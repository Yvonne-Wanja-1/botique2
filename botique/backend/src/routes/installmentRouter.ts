import { Router } from 'express';
import { installmentController } from '../controllers/installmentController.js';
import { anyAuthenticated } from '../middleware/authStub.js';
import { validateBody } from '../middleware/validate.js';
import { installmentPaySchema, installmentPlanSchema } from '../validation/schemas.js';
import type { InstallmentService } from '../services/installmentService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export function installmentRouter(installmentService: InstallmentService): Router {
  const router = Router();
  const c = installmentController(installmentService);

  router.post('/orders/:orderId/plans', anyAuthenticated, validateBody(installmentPlanSchema), asyncHandler(c.createPlan));
  router.get('/orders/:orderId/plans', anyAuthenticated, asyncHandler(c.listPlans));
  router.post('/payments/:paymentId/pay', anyAuthenticated, validateBody(installmentPaySchema), asyncHandler(c.payPayment));

  return router;
}