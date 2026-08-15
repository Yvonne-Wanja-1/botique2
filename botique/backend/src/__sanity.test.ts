import { describe, expect, it } from 'vitest';
import { loadConfig } from './config/env.js';

describe('config', () => {
  it('parses PORT and DATABASE_URL from env', () => {
    const cfg = loadConfig({ PORT: '9090', DATABASE_URL: 'postgresql://u:p@localhost:5432/q' });
    expect(cfg.port).toBe(9090);
    expect(cfg.databaseUrl).toBe('postgresql://u:p@localhost:5432/q');
    expect(cfg.nodeEnv).toBe('development');
  });

  it('rejects a missing DATABASE_URL', () => {
    expect(() => loadConfig({ PORT: '8080' })).toThrow(/DATABASE_URL/);
  });
});