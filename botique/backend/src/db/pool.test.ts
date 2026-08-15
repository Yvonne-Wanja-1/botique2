import { describe, expect, it } from 'vitest';
import { loadConfig } from '../config/env.js';
import { checkDatabase } from './pool.js';

describe('pool', () => {
  it('reports database unreachable without throwing', async () => {
    const cfg = loadConfig({
      DATABASE_URL: 'postgresql://invalid:invalid@127.0.0.1:59999/nope',
      PORT: '8080',
    });
    const pool = (await import('./pool.js')).createPool(cfg);
    const ok = await checkDatabase(pool);
    expect(ok).toBe(false);
    await pool.end();
  });
});