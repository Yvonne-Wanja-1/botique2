// Compatibility module. Real authentication lives in ./auth.ts.
// Routers and tests import from here for the `principal` helpers.
export {
  anyAuthenticated,
  createAuthenticate,
  principalId,
  requireRole,
  signToken,
  verifyToken,
} from './auth.js';
export type { AuthenticateDeps, StubPrincipal, TokenPayload } from './auth.js';
