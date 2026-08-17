import { loadConfig } from './config/env.js';
import { createApp } from './app.js';
import { checkDatabase, createPool } from './db/pool.js';

export function main(): void {
  const config = loadConfig();
  const pool = createPool(config);
  const app = createApp(pool, { uploadsDir: config.uploadsDir });

  app.listen(config.port, async () => {
    console.log(`Queens' Touch API listening on http://localhost:${config.port}`);
    const dbOk = await checkDatabase(pool);
    if (dbOk) {
      console.log('PostgreSQL connection: OK');
    } else {
      console.warn(
        'WARNING: could not reach PostgreSQL. Set DATABASE_URL in backend/.env and ' +
          'create the database from database/schema.sql.',
      );
    }
  });
}

if (process.argv[1]?.endsWith('server.js') || process.argv[1]?.endsWith('server.ts')) {
  main();
}