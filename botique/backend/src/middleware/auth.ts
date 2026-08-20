import type { Request, RequestHandler } from 'express';
import jwt, { type JwtPayload, type SignOptions } from 'jsonwebtoken';
import type { UserRepository } from '../repositories/userRepository.js';
import { ForbiddenError, UnauthorizedError } from '../utils/errors.js';

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

export interface AuthenticateDeps {
  jwtSecret: string;
  userRepo: UserRepository;
  /**
   * When true (dev/test), requests carrying the legacy `x-user-id` header are
   * treated as authenticated. Never enabled in production.
   */
  allowDevStub?: boolean;
}

export interface TokenPayload {
  userId: string;
  role: string;
}

export function signToken(payload: TokenPayload, jwtSecret: string, expiresIn: string): string {
  const options: SignOptions = { subject: payload.userId };
  return jwt.sign({ role: payload.role }, jwtSecret, { ...options, expiresIn } as SignOptions);
}

export function verifyToken(token: string, jwtSecret: string): TokenPayload {
  let decoded: string | JwtPayload;
  try {
    decoded = jwt.verify(token, jwtSecret);
  } catch {
    throw new UnauthorizedError('Your session has expired. Please log in again.');
  }
  if (typeof decoded === 'string' || typeof decoded.sub !== 'string') {
    throw new UnauthorizedError('Your session is invalid. Please log in again.');
  }
  return { userId: decoded.sub, role: String(decoded.role ?? 'customer') };
}

/**
 * Real authentication middleware. Verifies the `Authorization: Bearer <jwt>`
 * header, loads the user, and enforces the account is active before setting
 * `req.principal` from the database (authoritative role, not the token).
 *
 * In non-production environments the legacy `x-user-id` / `x-user-role` header
 * stub is accepted so existing integration tests continue to run. It is never
 * enabled in production.
 */
export function createAuthenticate(deps: AuthenticateDeps): RequestHandler {
  const { jwtSecret, userRepo, allowDevStub = false } = deps;

  return async (req, _res, next) => {
    const header = req.header('authorization');
    const token = header?.startsWith('Bearer ') ? header.slice('Bearer '.length).trim() : null;

    if (token) {
      try {
        const payload = verifyToken(token, jwtSecret);
        const user = await userRepo.getById(payload.userId);
        if (!user || !user.isActive) {
          next(new UnauthorizedError('Your session is invalid. Please log in again.'));
          return;
        }
        req.principal = { userId: user.id, role: user.role };
        next();
        return;
      } catch (e) {
        next(e);
        return;
      }
    }

    if (allowDevStub) {
      const userId = req.header('x-user-id');
      if (userId) {
        req.principal = { userId, role: req.header('x-user-role') ?? 'customer' };
        next();
        return;
      }
    }

    next(new UnauthorizedError('Authentication required'));
  };
}

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

export const anyAuthenticated = requireRole('customer', 'super_admin', 'store_manager', 'sales_staff', 'inventory_staff');

export function principalId(req: Request): string {
  const principal = req.principal;
  if (!principal) throw new UnauthorizedError('Authentication required');
  return principal.userId;
}
