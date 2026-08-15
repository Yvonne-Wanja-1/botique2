import { describe, expect, it } from 'vitest';
import { ApiError, ConflictError, NotFoundError, ValidationError } from './errors.js';

describe('errors', () => {
  it('carries status code and code', () => {
    const err = new ConflictError('boom');
    expect(err.statusCode).toBe(409);
    expect(err.code).toBe('CONFLICT');
    expect(err.message).toBe('boom');
    expect(err).toBeInstanceOf(ApiError);
    expect(err).toBeInstanceOf(Error);
  });

  it('validation error is 422 with details', () => {
    const err = new ValidationError([{ path: ['qty'], message: 'must be > 0' }]);
    expect(err.statusCode).toBe(422);
    expect(err.details).toHaveLength(1);
  });

  it('not found is 404', () => {
    expect(new NotFoundError().statusCode).toBe(404);
  });
});