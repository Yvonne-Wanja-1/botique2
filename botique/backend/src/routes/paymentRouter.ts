import { Router } from 'express';
import { paymentController } from '../controllers/paymentController.js';
import { anyAuthenticated } from '../middleware/authStub.js';
import { validateBody } from '../middleware/validate.js';
import { paymentVerifySchema } from '../validation/schemas.js';
import type { PaymentService } from '../services/paymentService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export function paymentRouter(paymentService: PaymentService): Router {
  const router = Router();
  const c = paymentController(paymentService);

  router.get('/transfer-details', anyAuthenticated, asyncHandler(c.transferDetails));
  router.get('/:orderId', anyAuthenticated, asyncHandler(c.get));
  router.post('/:orderId/verify', anyAuthenticated, validateBody(paymentVerifySchema), asyncHandler(c.verify));

  return router;
}