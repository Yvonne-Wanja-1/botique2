import type { Request, Response } from 'express';
import type { AuthService } from '../services/authService.js';
import { principalId } from '../middleware/auth.js';
import { ok } from '../utils/apiResponse.js';

export function authController(authService: AuthService) {
  return {
    async register(req: Request, res: Response): Promise<void> {
      ok(res, await authService.register(req.body), 201);
    },
    async login(req: Request, res: Response): Promise<void> {
      ok(res, await authService.login(req.body));
    },
    async me(req: Request, res: Response): Promise<void> {
      ok(res, await authService.me(principalId(req)));
    },
    async logout(_req: Request, res: Response): Promise<void> {
      // JWT is stateless: the client discards the token. The endpoint exists so
      // clients can confirm a clean logout.
      ok(res, { loggedOut: true });
    },
  };
}
