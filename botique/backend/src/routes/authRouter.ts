import { Router, type RequestHandler } from 'express';
import { authController } from '../controllers/authController.js';
import { validateBody } from '../middleware/validate.js';
import { loginSchema, registerSchema } from '../validation/schemas.js';
import type { AuthService } from '../services/authService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export function authRouter(authService: AuthService, authenticate: RequestHandler): Router {
  const router = Router();
  const c = authController(authService);

  router.post('/register', validateBody(registerSchema), asyncHandler(c.register));
  router.post('/login', validateBody(loginSchema), asyncHandler(c.login));
  router.get('/me', authenticate, asyncHandler(c.me));
  router.post('/logout', authenticate, asyncHandler(c.logout));

  return router;
}
