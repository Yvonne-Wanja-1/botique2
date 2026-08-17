import { randomUUID } from 'node:crypto';
import { mkdirSync } from 'node:fs';
import { extname, resolve } from 'node:path';
import { Router } from 'express';
import multer from 'multer';
import { productController } from '../controllers/productController.js';
import { requireRole } from '../middleware/authStub.js';
import { validateBody } from '../middleware/validate.js';
import { productImageUpdateSchema, productObjectSchema, productSchema } from '../validation/schemas.js';
import { ValidationError } from '../utils/errors.js';
import type { ProductService } from '../services/productService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export function productRouter(productService: ProductService, options: { uploadsDir?: string } = {}): Router {
  const router = Router();
  const c = productController(productService);
  const staffRoles = requireRole('super_admin', 'store_manager', 'inventory_staff');

  const uploadsDir = resolve(process.cwd(), options.uploadsDir ?? 'uploads');
  mkdirSync(uploadsDir, { recursive: true });
  const upload = multer({
    storage: multer.diskStorage({
      destination: uploadsDir,
      filename: (_req, file, cb) => cb(null, `${randomUUID()}${extname(file.originalname) || '.jpg'}`),
    }),
    limits: { fileSize: 5 * 1024 * 1024, files: 10 },
    fileFilter: (_req, file, cb) => {
      const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
      if (allowed.includes(file.mimetype)) cb(null, true);
      else cb(new ValidationError('Only JPEG, PNG, WEBP and GIF images are allowed') as never, false);
    },
  });

  router.get('/', asyncHandler(c.list));
  router.get('/all', staffRoles, asyncHandler(c.listAll));
  router.get('/:id', asyncHandler(c.get));
  router.get('/:id/reviews', asyncHandler(c.reviews));
  router.get('/:id/images', staffRoles, asyncHandler(c.listImages));
  router.post('/:id/images', staffRoles, upload.array('images', 10), asyncHandler(c.uploadImages));
  router.delete('/:id/images/:imageId', staffRoles, asyncHandler(c.removeImage));
  router.patch(
    '/:id/images/:imageId',
    staffRoles,
    validateBody(productImageUpdateSchema),
    asyncHandler(c.setPrimaryImage),
  );
  router.post('/', staffRoles, validateBody(productSchema), asyncHandler(c.create));
  router.patch('/:id', staffRoles, validateBody(productObjectSchema.partial()), asyncHandler(c.update));
  router.delete('/:id', staffRoles, asyncHandler(c.deactivate));

  return router;
}