import type { RequestHandler } from 'express';
import type { ZodSchema } from 'zod';
import { asyncHandler } from '../utils/asyncHandler.js';
import { ValidationError } from '../utils/errors.js';

export function validateBody<T>(schema: ZodSchema<T>): RequestHandler {
  return asyncHandler(async (req, _res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      throw new ValidationError(result.error.issues);
    }
    req.body = result.data;
    next();
  });
}