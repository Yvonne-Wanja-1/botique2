import { Router } from 'express';
import { reviewController } from '../controllers/reviewController.js';
import { anyAuthenticated, requireRole } from '../middleware/authStub.js';
import { validateBody } from '../middleware/validate.js';
import { reviewCreateSchema, reviewModerateSchema } from '../validation/schemas.js';
import type { ReviewService } from '../services/reviewService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const MODERATOR_ROLES = ['super_admin', 'store_manager'];

export function reviewRouter(reviewService: ReviewService): Router {
  const router = Router();
  const c = reviewController(reviewService);

  router.get('/products/:productId/reviews', anyAuthenticated, asyncHandler(c.listForProduct));
  router.get('/products/:productId/eligibility', anyAuthenticated, asyncHandler(c.eligibility));
  router.post('/products/:productId/reviews', anyAuthenticated, validateBody(reviewCreateSchema), asyncHandler(c.add));
  router.get('/pending', requireRole(...MODERATOR_ROLES), asyncHandler(c.listPending));
  router.patch('/:id/moderate', requireRole(...MODERATOR_ROLES), validateBody(reviewModerateSchema), asyncHandler(c.moderate));
  router.patch('/:id/report', anyAuthenticated, asyncHandler(c.report));

  return router;
}