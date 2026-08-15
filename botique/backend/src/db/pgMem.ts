import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { newDb } from 'pg-mem';
import type { Pool } from 'pg';

export function schemaPath(): string {
  return resolve(process.cwd(), '..', 'database', 'schema.sql');
}

export function loadPgMem(path: string): Pool {
  const db = newDb();
  const sql = readFileSync(path, 'utf8');
  const statements = sql.split(/;\s*(?:\n|$)/).map((s) => s.trim()).filter((s) => s.length > 0);
  for (const statement of statements) {
    db.public.query(statement);
  }
  const pg = db.adapters.createPg();
  const pool = new pg.Pool();
  return pool as Pool;
}