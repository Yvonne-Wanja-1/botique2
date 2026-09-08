import { randomUUID } from 'node:crypto';
import { mkdirSync } from 'node:fs';
import { extname, resolve } from 'node:path';
import { Router, type RequestHandler } from 'express';
import multer from 'multer';
import { authController } from '../controllers/authController.js';
import { validateBody } from '../middleware/validate.js';
import { changePasswordSchema, loginSchema, registerSchema } from '../validation/schemas.js';
import { ValidationError } from '../utils/errors.js';
import type { AuthService } from '../services/authService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export function authRouter(
  authService: AuthService,
  authenticate: RequestHandler,
  options: { uploadsDir?: string } = {},
): Router {
  const router = Router();
  const c = authController(authService);

  const uploadsDir = resolve(process.cwd(), options.uploadsDir ?? 'uploads');
  mkdirSync(uploadsDir, { recursive: true });
  const upload = multer({
    storage: multer.diskStorage({
      destination: uploadsDir,
      filename: (_req, file, cb) => cb(null, `avatar-${randomUUID()}${extname(file.originalname) || '.jpg'}`),
    }),
    limits: { fileSize: 5 * 1024 * 1024, files: 1 },
    fileFilter: (_req, file, cb) => {
      const allowed = ['image/jpeg', 'image/png', 'image/webp'];
      if (allowed.includes(file.mimetype)) cb(null, true);
      else cb(new ValidationError('Only JPEG, PNG and WEBP images are allowed') as never, false);
    },
  });

  router.post('/register', validateBody(registerSchema), asyncHandler(c.register));
  router.post('/login', validateBody(loginSchema), asyncHandler(c.login));
  router.get('/me', authenticate, asyncHandler(c.me));
  router.post('/logout', authenticate, asyncHandler(c.logout));
  router.post('/avatar', authenticate, upload.single('avatar'), asyncHandler(c.updateAvatar));
  router.put('/password', authenticate, validateBody(changePasswordSchema), asyncHandler(c.changePassword));

  return router;
}