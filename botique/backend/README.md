# Queens' Touch — Backend API

Node.js + Express + TypeScript REST API for the Queens' Touch boutique. Uses raw `pg` with a repository layer, and `pg-mem` for offline integration tests.

## Requirements

- Node.js >= 18
- PostgreSQL >= 14 (optional for tests; required to run the live API)

## Setup

### 1. Create the database

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -c "CREATE DATABASE queens_touch;"
```

### 2. Apply the schema (idempotent)

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d queens_touch -f database\schema.sql
```

The schema lives at `database/schema.sql` and is the single canonical blueprint. It creates all tables, indexes, enums, and seed data.

### 3. Configure the backend

```powershell
Copy-Item backend\.env.example backend\.env
# edit backend\.env
```

Supported variables (all optional except `DATABASE_URL`):

| Variable       | Default | Purpose                                 |
| -------------- | ------- | --------------------------------------- |
| `PORT`         | `8080`  | HTTP listen port                        |
| `DATABASE_URL` | —       | PostgreSQL connection string            |
| `DB_HOST`      | —       | Fallback host when `DATABASE_URL` unset |
| `DB_PORT`      | —       | Fallback port                           |
| `DB_NAME`      | —       | Fallback database name                  |
| `DB_USER`      | —       | Fallback user                           |
| `DB_PASSWORD`  | —       | Fallback password                       |

If `DATABASE_URL` is absent, the connection string is built from the individual `DB_*` variables.

### 4. Run

```powershell
cd backend
npm install
npm run dev
```

The server logs the listen URL. `/health` reports `connected` when PostgreSQL is reachable and a `503` envelope (`DATABASE_UNAVAILABLE`) when it is not — the API still boots without a database.

## Sanity check

```powershell
Invoke-RestMethod http://localhost:3000/health
Invoke-RestMethod http://localhost:3000/api/products -Headers @{ 'x-user-id' = '00000000-0000-0000-0000-000000000201'; 'x-user-role' = 'customer' }
```

## Auth (dev stub)

There is no real authentication yet. The middleware reads `X-User-Id` and `X-User-Role` headers, so role-gated routes can be exercised. Do not use this in production.

Seeded users (from `database/schema.sql`):

| User id                                  | Role           |
| ---------------------------------------- | -------------- |
| `...000000000201` | customer       |
| `...000000000202` | super_admin    |
| `...000000000203` | store_manager  |
| `...000000000204` | sales_staff    |
| `...000000000205` | inventory_staff |

## Scripts

| Command                | Purpose                                             |
| ---------------------- | --------------------------------------------------- |
| `npm run dev`          | Run the API with hot reload (`tsx watch`)           |
| `npm run build`        | Compile TypeScript to `dist/`                       |
| `npm start`            | Run the compiled `dist/server.js`                   |
| `npm run typecheck`    | Type-check without emitting                         |
| `npm test`             | Run the vitest suite (pg-mem, no DB needed)         |

## Test strategy

- **Offline integration tests**: `pg-mem` loads `database/schema.sql` in memory; route tests drive the Express app through `supertest`. No PostgreSQL needed.
- **Real-DB verification**: `database/schema.sql` is executable against PostgreSQL 18; seed data lands and the same routes work against the real cluster.

## API envelope

Responses use `{ "success": true, "data": ... }` or `{ "success": false, "error": { "code", "message", "details?" } }`.