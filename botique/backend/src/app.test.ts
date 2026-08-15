import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { loadConfig } from './config/env.js';
import { createPool } from './db/pool.js';
import { createApp } from './app.js';

describe('app', () => {
  const cfg = loadConfig({ DATABASE_URL: 'postgresql://x:x@127.0.0.1:59999/nope', PORT: '8080' });

  it('GET /health returns service status', async () => {
    const pool = createPool(cfg);
    const app = createApp(pool);
    const res = await request(app).get('/health');
    expect(res.status).toBe(503);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('DATABASE_UNAVAILABLE');
    await pool.end();
  });

  it('unknown route returns 404 envelope', async () => {
    const pool = createPool(cfg);
    const app = createApp(pool);
    const res = await request(app).get('/nope');
    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
    await pool.end();
  });

  it('auth stub rejects requests without x-user-id', async () => {
    const pool = createPool(cfg);
    const app = createApp(pool);
    const res = await request(app).get('/api/products');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
    await pool.end();
  });
});