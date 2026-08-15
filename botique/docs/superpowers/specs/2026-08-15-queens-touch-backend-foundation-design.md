# Queens' Touch — Backend/API & PostgreSQL Foundation — Design

**Date:** 2026-08-15
**Status:** Approved design (pre-implementation)

## 1. Purpose

Build the real backend + complete PostgreSQL persistence foundation for the existing
"Queens' Touch" Flutter boutique app. The Flutter app is currently a high-fidelity UI
prototype backed entirely by in-memory mock repositories. This task establishes:

- A complete executable PostgreSQL schema (`database/schema.sql`)
- A Node.js + Express + TypeScript backend
- PostgreSQL-backed persistence reachable by the Flutter app via a new HTTP data layer

Explicitly **out of scope** (deferred to a future phase, per requirements):
payment gateways, Firebase push notifications, production deployment, and full
authentication.

## 2. Decisions (agreed with user)

| Decision | Choice |
|---|---|
| Backend stack | Node.js + Express + TypeScript |
| Database | PostgreSQL 18 (installed, running locally) |
| DB access | Raw `pg` connection pool + repository layer (no ORM) |
| `schema.sql` is the single executable blueprint | Yes |
| Flutter HTTP client | `package:http` |
| Local DB testing | User creates the database and runs `schema.sql` themselves; backend must start and degrade gracefully when the DB is unreachable; DB-gated integration tests auto-skip |
| Secrets | Never hardcoded; `.env` (gitignored) + `.env.example` placeholders |

## 3. Repository layout

```
backend/                          # new Express API (gitignored: node_modules, .env)
  package.json
  tsconfig.json
  .env.example
  .gitignore
  src/
    config/       env.ts, db.ts (pool)
    models/       TS interfaces mirroring tables
    repositories/ pg-backed data access, one module per entity
    services/     business logic (order transaction, inventory, promotions, status transitions)
    controllers/  thin request/response handling
    routes/       /api/* routers
    middleware/   error handler, request logging, stub auth, validation
    validation/   zod schemas
    utils/        apiResponse helpers, asyncHandler, errors
    app.ts        express app assembly
    server.ts     bootstrap
  test/           vitest unit + supertest integration (DB-gated skip)
database/schema.sql               # complete executable PostgreSQL blueprint
lib/data/api/                     # Flutter HTTP-backed repositories
```

## 4. Backend architecture

- **Config**: dotenv. Required vars `DATABASE_URL`, `PORT`. On startup, validate config;
  if the DB is unreachable, log a clear warning and continue so startup can be verified
  without credentials.
- **Models**: TypeScript interfaces/type aliases mirroring the PostgreSQL tables and the
  existing Dart models' domain concepts.
- **Repositories**: `pg.Pool` with parameterized SQL only. One module per entity:
  products, categories, brands, cart, wishlist, orders, payments, installments, reviews,
  customers, inventory, promotions, notifications, users/staff, audit, reports.
- **Services**: business rules — order placement transaction, inventory adjustment rules,
  promotion application, status-transition validation (order/payment/installment),
  verified-purchase review logic.
- **Controllers**: thin; parse validated input, call services, return standard JSON.
- **Routes**: routers per module under `/api/*` (products, categories, brands, cart,
  wishlist, orders, payments, installments, reviews, customers, inventory, promotions,
  notifications, admin, reports, staff) plus `/health`.
- **Validation**: `zod` schemas on request bodies/params/query. Rejects negative
  quantities, invalid FKs, invalid totals, invalid status transitions.
- **Middleware**:
  - Centralized error handler → consistent JSON error shape
  - Request logging
  - **Stub auth** middleware reading optional `X-User-Id` / `X-User-Role` headers so
    role-gated routes work now; full auth deferred
- **Transactions**: order creation runs in a single transaction: lock variant stock with
  `SELECT ... FOR UPDATE`, decrement inventory, record inventory transactions, insert
  order + items, apply payment/installment records, clear the cart. Any failure rolls
  back the whole operation. No partially-completed data.

## 5. PostgreSQL schema (`database/schema.sql`)

Postgres ENUM types for statuses. Tables (with PKs, FKs, UNIQUE, NOT NULL, CHECKs,
indexes, created_at/updated_at):

- `roles`, `permissions`, `role_permissions` (RBAC seed)
- `users` (customers + staff; role FK)
- `categories` (self-referencing `parent_id` for subcategories)
- `brands`
- `products` (category/brand FKs, status soft-deactivate)
- `product_variants` (size/color/cosmetic shade, SKU, price, stock)
- `product_images`
- `inventory` (current qty, stock threshold) + `inventory_transactions` (history,
  change types) — low-stock / out-of-stock derived
- `carts`, `cart_items`
- `wishlists`, `wishlist_items`
- `addresses` (user FK)
- `orders` (order number, totals, status) + `order_items` (snapshot prices)
- `payments` (method, status)
- `installments` (total, amount paid, remaining, schedule, approval info) +
  `installment_payments`
- `reviews` (verified purchase via completed order link)
- `promotions` (type, discount, min order, validity dates, usage tracking)
- `notifications`
- `audit_logs` (admin actions, actor, payload)

Design rules:

- Historical data protection: products/categories/brands use **soft deactivate**
  (status columns), never destructive deletes; order items snapshot prices.
- CHECK constraints: quantities `>= 0`, prices `>= 0`, valid percentage ranges, etc.
- Indexes on FK columns, lookups (category_id, brand_id, user_id, status, order_number),
  and text search where appropriate.
- Seed/reference data: roles + permissions, brands, categories, sample products with
  variants and images, demo promo codes (`QUEEN10`, `ROYAL20`, `FLAT15`), demo users.

Schema delivered as a single executable file: `psql -U <user> -d <dbname> -f database/schema.sql`.

## 6. Flutter data layer (no UI redesign)

- Add `package:http`.
- `ApiClient`: base URL via `--dart-define=API_BASE_URL`, default `http://localhost:8080`.
- HTTP-backed implementations of the **existing repository interfaces**
  (`ProductRepository`, `CategoryRepository`, `CartRepository`, `WishlistRepository`,
  `OrderRepository` from `lib/data/repositories/`) so existing services keep working
  unchanged.
- Add JSON (de)serialization (`fromJson`/`toJson`) to the Dart models that lack it.
- Data-source selection: `--dart-define=USE_API=true` switches `main.dart` to the
  HTTP-backed repositories; the default remains the mock repositories so the existing
  app keeps working with no backend running. Mock repos stay intact as a fallback.
- Existing UI, services, routing, theme untouched.

## 7. API surface (initial modules)

`/api/products`, `/api/categories`, `/api/brands`, `/api/cart`, `/api/wishlist`,
`/api/orders`, `/api/payments`, `/api/installments`, `/api/reviews`, `/api/customers`,
`/api/inventory`, `/api/promotions`, `/api/notifications`, `/api/admin`,
`/api/reports`, `/api/staff`, plus `/health`.

Proper HTTP methods + status codes, consistent JSON response envelope, validation,
centralized error handling, DB error handling, logging.

## 8. Testing & verification

- Backend: `npm run typecheck` (tsc), `npm test` (vitest). Unit tests cover validation
  and service logic with mocked repositories. Integration tests (supertest) hit the real
  DB and **auto-skip when unreachable**.
- Flutter: `flutter analyze`; existing widget test; an API-repository test using a mocked
  `http.Client`.
- Verification without DB credentials: typecheck, unit tests, server boot (graceful
  warning if DB absent), Flutter tests.
- DB-gated verification (documented for user to run after creating the DB): create
  schema, seed, product/category CRUD, inventory persistence, order creation + items +
  inventory decrement, cart/order persistence, Flutter↔backend communication.

## 9. Deferred / intentionally unfinished

- Payment gateway integration
- Firebase / push notifications
- Production deployment
- Full authentication system (stub auth middleware only)
- Completing every mock UI feature unrelated to the data/backend foundation