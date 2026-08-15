import { Router } from 'express';
import type { Pool } from 'pg';
import { checkDatabase } from '../db/pool.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { ok } from '../utils/apiResponse.js';

export function healthRouter(pool: Pool): Router {
  const router = Router();

  router.get(
    '/',
    asyncHandler(async (_req, res) => {
      const dbOk = await checkDatabase(pool);
      if (!dbOk) {
        res.status(503).json({
          success: false,
          error: { code: 'DATABASE_UNAVAILABLE', message: 'PostgreSQL is not reachable' },
        });
        return;
      }
      ok(res, { status: 'ok', database: 'connected' });
    }),
  );

  return router;
}