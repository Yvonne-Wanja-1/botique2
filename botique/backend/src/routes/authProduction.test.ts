import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('auth middleware production mode', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    // allowDevAuthStub: false simulates NODE_ENV=production.
    app = createApp(pool, { jwtSecret: 'test-secret-at-least-16-chars', allowDevAuthStub: false });
  });
  afterAll(async () => {
    await pool.end();
  });

  it('ignores the legacy x-user-id header when the dev stub is disabled', async () => {
    const res = await request(app)
      .get('/api/products')
      .set('x-user-id', '00000000-0000-0000-0000-000000000202')
      .set('x-user-role', 'super_admin');
    expect(res.status).toBe(401);
  });

  it('still accepts a real bearer token', async () => {
    const register = await request(app).post('/api/auth/register').send({
      fullName: 'Prod Customer',
      email: 'prod@example.com',
      phone: '08055555555',
      password: 'Secret123!',
    });
    expect(register.status).toBe(201);
    const res = await request(app)
      .get('/api/products')
      .set('Authorization', `Bearer ${register.body.data.token}`);
    expect(res.status).toBe(200);
  });
});