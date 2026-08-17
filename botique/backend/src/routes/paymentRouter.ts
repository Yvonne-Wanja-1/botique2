import { Router } from 'express';
import { paymentController } from '../controllers/paymentController.js';
import { anyAuthenticated, requireRole } from '../middleware/authStub.js';
import { validateBody } from '../middleware/validate.js';
import { paymentSubmitSchema, paymentRejectSchema } from '../validation/schemas.js';
import type { PaymentService } from '../services/paymentService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export function paymentRouter(paymentService: PaymentService): Router {
  const router = Router();
  const c = paymentController(paymentService);

  router.get('/transfer-details', anyAuthenticated, asyncHandler(c.transferDetails));
  router.get('/', anyAuthenticated, asyncHandler(c.list));
  router.get('/orders/:orderId', anyAuthenticated, asyncHandler(c.listForOrder));
  router.post('/', anyAuthenticated, validateBody(paymentSubmitSchema), asyncHandler(c.submit));
  router.get('/:id', anyAuthenticated, asyncHandler(c.getById));
  router.post(
    '/:id/verify',
    requireRole('super_admin', 'store_manager', 'sales_staff'),
    asyncHandler(c.verify),
  );
  router.post(
    '/:id/reject',
    requireRole('super_admin', 'store_manager', 'sales_staff'),
    validateBody(paymentRejectSchema),
    asyncHandler(c.reject),
  );

  return router;
}