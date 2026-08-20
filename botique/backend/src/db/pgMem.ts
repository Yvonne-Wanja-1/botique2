import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { newDb } from 'pg-mem';
import type { Pool } from 'pg';

export function schemaPath(): string {
  return resolve(process.cwd(), '..', 'database', 'schema.sql');
}

export function loadPgMem(path: string): Pool {
  const db = newDb();
  const sql = readFileSync(path, 'utf8')
    // Full-line comments can strand chunk fragments in a way pg-mem rejects.
    .replace(/^\s*--.*$/gm, '')
    // pg-mem cannot parse plpgsql function bodies, triggers, or partial indexes;
    // they only matter on real PostgreSQL, so skip them for in-memory tests.
    .replace(/CREATE OR REPLACE FUNCTION\s+[\s\S]*?\$\$\s*LANGUAGE\s+plpgsql\s*;/gi, '');
  const statements = sql
    .split(/;\s*(?:\n|$)/)
    .map((s) => s.trim())
    .filter(
      (s) =>
        s.length > 0 &&
        !/^(DROP\s+TRIGGER|CREATE\s+TRIGGER)/i.test(s) &&
        !/^CREATE\s+UNIQUE\s+INDEX\s+[\s\S]*\s+WHERE\s/i.test(s),
    );
  for (const statement of statements) {
    db.public.query(statement);
  }
  const pg = db.adapters.createPg();
  const pool = new pg.Pool();
  return pool as Pool;
}