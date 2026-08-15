import { Router } from 'express';
import { productController } from '../controllers/productController.js';
import { requireRole } from '../middleware/authStub.js';
import { validateBody } from '../middleware/validate.js';
import { productObjectSchema, productSchema } from '../validation/schemas.js';
import type { ProductService } from '../services/productService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export function productRouter(productService: ProductService): Router {
  const router = Router();
  const c = productController(productService);
  const staffRoles = requireRole('super_admin', 'store_manager', 'inventory_staff');

  router.get('/', asyncHandler(c.list));
  router.get('/:id', asyncHandler(c.get));
  router.get('/:id/reviews', asyncHandler(c.reviews));
  router.post('/', staffRoles, validateBody(productSchema), asyncHandler(c.create));
  router.patch('/:id', staffRoles, validateBody(productObjectSchema.partial()), asyncHandler(c.update));
  router.delete('/:id', staffRoles, asyncHandler(c.deactivate));

  return router;
}