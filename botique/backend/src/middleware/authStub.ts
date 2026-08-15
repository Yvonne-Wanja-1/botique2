import type { Request, RequestHandler } from 'express';
import { ForbiddenError, UnauthorizedError } from '../utils/errors.js';

// DEVELOPMENT-ONLY STUB.
// Real authentication arrives in a later phase. This reads X-User-Id / X-User-Role
// headers so role-gated routes can be exercised now. Do not use in production.
export interface StubPrincipal {
  userId: string;
  role: string;
}

declare global {
  namespace Express {
    interface Request {
      principal?: StubPrincipal;
    }
  }
}

export const authStub: RequestHandler = (req, _res, next) => {
  const userId = req.header('x-user-id');
  if (!userId) {
    next(new UnauthorizedError('Missing x-user-id header (dev auth stub)'));
    return;
  }
  req.principal = { userId, role: req.header('x-user-role') ?? 'customer' };
  next();
};

export const requireRole =
  (...roles: string[]): RequestHandler =>
  (req, _res, next) => {
    if (!req.principal) {
      next(new UnauthorizedError());
      return;
    }
    if (!roles.includes(req.principal.role)) {
      next(new ForbiddenError());
      return;
    }
    next();
  };

export const anyAuthenticated = requireRole('customer', 'super_admin', 'store_manager', 'inventory_staff');

export function principalId(req: Request): string {
  const principal = req.principal;
  if (!principal) throw new UnauthorizedError('Authentication required');
  return principal.userId;
}