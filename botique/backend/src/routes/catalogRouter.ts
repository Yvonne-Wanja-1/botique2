import { Router } from 'express';
import { catalogController } from '../controllers/catalogController.js';
import { requireRole } from '../middleware/authStub.js';
import { validateBody } from '../middleware/validate.js';
import { categorySchema } from '../validation/schemas.js';
import type { CatalogService } from '../services/catalogService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export function catalogRouter(catalogService: CatalogService): Router {
  const router = Router();
  const c = catalogController(catalogService);

  router.get('/categories', asyncHandler(c.rootCategories));
  router.get('/categories/:parentId/subcategories', asyncHandler(c.subcategories));
  router.get('/brands', asyncHandler(c.brands));
  router.post(
    '/categories',
    requireRole('super_admin', 'store_manager'),
    validateBody(categorySchema),
    asyncHandler(c.createCategory),
  );

  return router;
}