import { Pool } from 'pg';
import type { AppConfig } from '../config/env.js';

export function createPool(config: AppConfig): Pool {
  return new Pool({
    connectionString: config.databaseUrl,
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 3000,
  });
}

export async function checkDatabase(pool: Pool): Promise<boolean> {
  try {
    await pool.query('SELECT 1');
    return true;
  } catch {
    return false;
  }
}