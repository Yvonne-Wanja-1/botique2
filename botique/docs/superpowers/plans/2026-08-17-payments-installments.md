# Payments + Installments Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a manual Family Bank payment system (Paybill **222111**, Account **65727**, no payment gateway) and a full installment flow for Queens' Touch: customer places order → sees payment instructions → pays externally → submits proof (amount, date, M-Pesa/Family Bank confirmation message) → admin verifies or rejects → order balance updates (verified vs remaining) → installment plans auto-created on checkout, admin approved, payments applied against the schedule.

**Architecture:** Backend (Express + pg) becomes the single source of truth for payments and installments. The auto-created `payments` row and the GTBank `transferDetails` dead code are removed and replaced with real per-submission `payments` rows plus Family Bank Paybill transfer details. Each submitted payment is a row in `pending_verification`; admin `verify` marks it `successful` (and applies it to an active installment plan) or `reject`s it with a reason. Order `payment_status` becomes a live rollup: `pending_verification` / `partially_paid` / `successful`. Installment plans are created `pending_approval` on checkout when `installmentRequested=true`, admin approves (`active`) or rejects. Notifications and audit logs are written server-side on every state change. Flutter customer/admin screens consume the shared `OrderRepository` (API or mock) instead of hard-coded mock lists, and use **KSh** formatting on all new screens.

**Tech Stack:** Express 4, pg (Postgres), zod, vitest + pg-mem + supertest (backend); Flutter, provider, go_router, http/MockClient (frontend). `npm run typecheck`, `npm test`, `flutter analyze`, `flutter test` for verification.

**Spec:** User priorities #8 (Payments) and #9 (Installments) from this session: Family Bank Paybill manual payment flow, proof submission, admin verification, balance/remaining computation, and installment request → approval → per-payment application → completion. See `docs/superpowers/plans/2026-08-15-queens-touch-backend-foundation.md` for established conventions (auth stub headers, pg-mem testing, response shape).

## Global Constraints

- Currency is **KSh** on every new payment/installment screen via a shared `formatKsh(double)` helper. Existing screens keep `$` (leave untouched; note in final report).
- Backend is the source of truth. Do NOT rebuild working features (orders, cart, products), duplicate endpoints/tables, or touch unrelated routes.
- DB is `queens1` (localhost:5432, `postgres`/`password`). `database/schema.sql` is the single source of truth for pg-mem tests — edit `CREATE TYPE`/`CREATE TABLE` lines there, then apply a separate migration SQL to the live DB. **No destructive changes.**
- Auth: dev stub reads `x-user-id` (required) / `x-user-role` (default `customer`). Staff payment/installment actions = `requireRole('super_admin', 'store_manager', 'sales_staff')`. Seed staff `...203` (store_manager), customer `...201`.
- pg-mem limitations: NO window functions (`OVER` unsupported) — compute sums/duplicates in JS. Prefer editing CREATE lines over ALTER TYPE in schema.sql.
- Role routing: `GET /api/payments/` and `GET /api/installments/` return the caller's own rows for `customer`, all rows for staff.
- Over-submission rule: a submitted `amount` cannot make `SUM(non-rejected payments) + amount` exceed the order `total` → reject with 409/422.
- Duplicate submissions (same customer+order+amount AND [same reference OR payment_date within ±2 days], excluding rejected) are **flagged** via `duplicate_of`, never auto-rejected; admin decides.
- Notifications via `NotificationRepository.create`; audit via `AuditRepository.log` on every verify/reject/approve.
- Live E2E must clean up its own test rows afterward.

---

### Task 1: Schema + TypeScript models

**Files:**
- Modify: `database/schema.sql:134-135, 259-304`
- Create: `database/migrations/2026-08-17-payments-installments.sql`
- Modify: `backend/src/models/index.ts:100-126`
- Test: `backend/src/db/schema.test.ts` (existing), `backend/src/validation/schemas.test.ts` (existing)

**Interfaces:**
- Consumes: existing `payment_status`/`payment_method`/`installments` definitions.
- Produces: `PaymentStatus` includes `'pending_verification' | 'partially_paid' | 'rejected'`; `PaymentMethod` includes `'paybill'`; `payments` table gains `payment_date`, `confirmation_message`, `note`, `verified_at`, `verified_by`, `rejected_at`, `rejected_by`, `reject_reason`, `duplicate_of`; `payments.reference` UNIQUE is dropped; `installments` gains `rejected_by`, `rejected_at`, `reject_reason`.

- [ ] **Step 1: Edit the enums in `database/schema.sql`**

Change lines 134-135 to:

```sql
CREATE TYPE payment_method AS ENUM ('cash_on_delivery', 'bank_transfer', 'paybill', 'card', 'installment');

CREATE TYPE payment_status AS ENUM ('pending', 'pending_verification', 'successful', 'partially_paid', 'failed', 'refunded', 'rejected');
```

- [ ] **Step 2: Edit the `payments` table in `database/schema.sql`**

Replace the `payments` CREATE TABLE (lines 259-269) with:

```sql
CREATE TABLE payments (
  id                    UUID PRIMARY KEY,
  order_id              UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  customer_id           UUID NOT NULL REFERENCES users(id),
  amount                NUMERIC(10,2) NOT NULL CHECK (amount > 0),
  method                payment_method NOT NULL,
  status                payment_status NOT NULL DEFAULT 'pending',
  reference             TEXT,
  payment_date          DATE,
  confirmation_message  TEXT,
  note                  TEXT,
  verified_at           TIMESTAMPTZ,
  verified_by           UUID REFERENCES users(id),
  rejected_at           TIMESTAMPTZ,
  rejected_by           UUID REFERENCES users(id),
  reject_reason         TEXT,
  duplicate_of          UUID REFERENCES payments(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

- [ ] **Step 3: Edit the `installments` table in `database/schema.sql`**

Add to the `installments` CREATE TABLE (after line 286 `approved_at TIMESTAMPTZ,`):

```sql
  rejected_by           UUID REFERENCES users(id),
  rejected_at           TIMESTAMPTZ,
  reject_reason         TEXT,
```

- [ ] **Step 4: Create the live-DB migration file**

Create `database/migrations/2026-08-17-payments-installments.sql`:

```sql
-- Apply to queens1 AFTER Task 5 backend code is running.
-- Requires: ALTER TYPE ... ADD VALUE cannot run inside a transaction block in older PG;
-- run with psql directly (one statement per line is fine here).

ALTER TYPE payment_method ADD VALUE IF NOT EXISTS 'paybill';
ALTER TYPE payment_status ADD VALUE IF NOT EXISTS 'pending_verification';
ALTER TYPE payment_status ADD VALUE IF NOT EXISTS 'partially_paid';
ALTER TYPE payment_status ADD VALUE IF NOT EXISTS 'rejected';

ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_reference_key;

ALTER TABLE payments ADD COLUMN IF NOT EXISTS payment_date DATE;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS confirmation_message TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS note TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES users(id);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMPTZ;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS rejected_by UUID REFERENCES users(id);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS reject_reason TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS duplicate_of UUID REFERENCES payments(id);

ALTER TABLE installments ADD COLUMN IF NOT EXISTS rejected_by UUID REFERENCES users(id);
ALTER TABLE installments ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMPTZ;
ALTER TABLE installments ADD COLUMN IF NOT EXISTS reject_reason TEXT;
```

- [ ] **Step 5: Update `backend/src/models/index.ts`**

Change lines 101-103 to:

```ts
export type OrderStatus = 'pending' | 'paid' | 'processing' | 'ready' | 'delivered' | 'cancelled';
export type PaymentStatus = 'pending' | 'pending_verification' | 'successful' | 'partially_paid' | 'failed' | 'refunded' | 'rejected';
export type PaymentMethod = 'cash_on_delivery' | 'bank_transfer' | 'paybill' | 'card' | 'installment';
```

Replace `PAYMENT_STATUS_TRANSITIONS` (lines 113-118) with:

```ts
export const PAYMENT_STATUS_TRANSITIONS: Record<PaymentStatus, PaymentStatus[]> = {
  pending: ['pending_verification', 'failed'],
  pending_verification: ['successful', 'rejected'],
  successful: ['refunded'],
  partially_paid: ['successful', 'pending_verification'],
  failed: ['pending'],
  refunded: [],
  rejected: [],
};
```

- [ ] **Step 6: Run existing tests to verify schema loads in pg-mem**

Run: `npm.cmd test` (in `backend/`, Windows: `npm.cmd run test`). Expected: all pass; `schema.test.ts` still lists the same tables; no enum/table errors.

- [ ] **Step 7: Typecheck**

Run: `npm.cmd run typecheck`. Expected: clean (models/index.ts changes are backward compatible with existing unions).

- [ ] **Step 8: Add `paybill` to `placeOrderSchema` in `backend/src/validation/schemas.ts`**

Change the `paymentMethod` enum in `placeOrderSchema` (line 76) to include `paybill` (needed by the tests that create orders via `paymentMethod: 'paybill'`):

```ts
  paymentMethod: z.enum(['cash_on_delivery', 'bank_transfer', 'paybill', 'card', 'installment']),
```

- [ ] **Step 9: Commit**

```bash
git add database/schema.sql database/migrations/2026-08-17-payments-installments.sql backend/src/models/index.ts
git commit -m "feat: extend payment/installment schema for manual paybill flow"
```

---

### Task 2: Order changes — remove auto payment, add payments + summary, auto-create installment plan

**Files:**
- Modify: `backend/src/repositories/orderRepository.ts:24-38, 47-69, 96-114, 195-199`
- Modify: `backend/src/services/orderService.ts` (constructor + `create`)
- Modify: `backend/src/app.ts:84-94` (wiring order — create `installmentRepo` before `orderService`, pass to `OrderService`)
- Test: `backend/src/routes/orderRouter.test.ts`

**Interfaces:**
- Consumes: `InstallmentRepository.createPlan` (signature `createPlan(orderId, customerId, planCount): Promise<Installment>` — still returns status `active` until Task 3, that's fine).
- Produces: `OrderRepository.findById` returns `Order` with `payments: Payment[]` and `paymentSummary: { total, verified, pending, remaining }`; `OrderRepository.create` NO longer inserts a `payments` row; `OrderService` constructor becomes `(orderRepo, installmentRepo)`; `create()` auto-creates a 3-month `pending_approval`-destined plan when `input.installmentRequested === true`. `Order` interface: `payment` field is replaced by `payments` + `paymentSummary`.

- [ ] **Step 1: Write the failing tests in `backend/src/routes/orderRouter.test.ts`**

Append inside the existing `describe('orders API', ...)` block:

```ts
it('does not auto-create a payment row for a new order', async () => {
  const res = await request(app).post('/api/orders').set(customer).send(payload);
  expect(res.status).toBe(201);
  const pays = await pool.query('SELECT * FROM payments WHERE order_id = $1', [res.body.data.id]);
  expect(pays.rows).toHaveLength(0);
});

it('includes an empty payments list and summary on order detail', async () => {
  const res = await request(app).post('/api/orders').set(customer).send(payload);
  const orderId = res.body.data.id;
  const detail = await request(app).get(`/api/orders/${orderId}`).set(customer);
  expect(detail.status).toBe(200);
  expect(detail.body.data.payments).toEqual([]);
  expect(detail.body.data.paymentSummary).toEqual({
    total: detail.body.data.total,
    verified: 0,
    pending: 0,
    remaining: detail.body.data.total,
  });
});

it('auto-creates an installment plan when installmentRequested is true', async () => {
  const res = await request(app)
    .post('/api/orders')
    .set(customer)
    .send({ ...payload, paymentMethod: 'installment', installmentRequested: true });
  expect(res.status).toBe(201);
  const plans = await pool.query('SELECT * FROM installments WHERE order_id = $1', [res.body.data.id]);
  expect(plans.rows).toHaveLength(1);
  expect(plans.rows[0].term_months).toBe(3);
});
```

(The plan's status becomes `pending_approval` in Task 3, which asserts it.)

- [ ] **Step 2: Run the tests to verify they fail**

Run: `npm.cmd run test -- orderRouter` (vitest filter). Expected: first test FAILS (`pays.rows` has 1), third FAILS (no installments row), second may FAIL (`payments`/`paymentSummary` undefined on order).

- [ ] **Step 3: Update `backend/src/repositories/orderRepository.ts`**

> **Note:** the auto-created plan in `OrderService.create` calls `InstallmentRepository.createPlan`, which currently rejects non-`paid` orders. Fix that guard first (it is rewritten fully in Task 3):

In `backend/src/repositories/installmentRepository.ts`, in `createPlan` (lines 87-89), replace:

```ts
      if (String(order.status) !== 'paid') {
        throw new ConflictError('Only paid orders can have installment plans');
      }
```

with:

```ts
      if (String(order.status) === 'cancelled') {
        throw new ConflictError('Cancelled orders cannot have installment plans');
      }
```

(a) Replace the `OrderPayment` interface and `Order` interface (lines 24-38) with:

```ts
export interface PaymentSummary {
  total: number;
  verified: number;
  pending: number;
  remaining: number;
}

export interface Order extends OrderRow {
  items: OrderItemRow[];
  payments: Payment[];
  paymentSummary: PaymentSummary;
}
```

(b) Extend the `Payment` interface in `backend/src/repositories/paymentRepository.ts` (schema-driven, so this type exists before Task 4 rewrites the repo):

```ts
export interface Payment {
  id: string;
  orderId: string;
  customerId: string;
  amount: number;
  method: PaymentMethod;
  status: PaymentStatus;
  reference: string | null;
  paymentDate: string | null;
  confirmationMessage: string | null;
  note: string | null;
  verifiedAt: string | null;
  verifiedBy: string | null;
  rejectedAt: string | null;
  rejectedBy: string | null;
  rejectReason: string | null;
  duplicateOf: string | null;
  createdAt: string;
  updatedAt: string | null;
}
```

(c) Import `Payment` at the top (after the existing imports):

```ts
import type { Payment } from './paymentRepository.js';
```

(d) In `mapOrder` (line 67), replace `payment: null,` with:

```ts
    payments: [],
    paymentSummary: { total: Number(row.total), verified: 0, pending: 0, remaining: Number(row.total) },
```

(e) Replace the payment-loading block in `findById` (lines 96-112) with:

```ts
    const pays = await this.pool.query(
      'SELECT * FROM payments WHERE order_id = $1 ORDER BY created_at DESC',
      [id],
    );
    const payments: Payment[] = pays.rows.map((r) => ({
      id: String(r.id),
      orderId: String(r.order_id),
      customerId: String(r.customer_id),
      amount: Number(r.amount),
      method: r.method as PaymentMethod,
      status: r.status as PaymentStatus,
      reference: r.reference ? String(r.reference) : null,
      paymentDate: r.payment_date ? String(r.payment_date) : null,
      confirmationMessage: r.confirmation_message ? String(r.confirmation_message) : null,
      note: r.note ? String(r.note) : null,
      verifiedAt: r.verified_at ? String(r.verified_at) : null,
      verifiedBy: r.verified_by ? String(r.verified_by) : null,
      rejectedAt: r.rejected_at ? String(r.rejected_at) : null,
      rejectedBy: r.rejected_by ? String(r.rejected_by) : null,
      rejectReason: r.reject_reason ? String(r.reject_reason) : null,
      duplicateOf: r.duplicate_of ? String(r.duplicate_of) : null,
      createdAt: String(r.created_at),
      updatedAt: r.updated_at ? String(r.updated_at) : null,
    }));
    order.payments = payments;
    const verified = payments.filter((p) => p.status === 'successful').reduce((s, p) => s + p.amount, 0);
    const pending = payments.filter((p) => p.status === 'pending_verification').reduce((s, p) => s + p.amount, 0);
    order.paymentSummary = {
      total: order.total,
      verified,
      pending,
      remaining: order.total - verified,
    };
```

(f) In `create`, DELETE the `payments` INSERT block (lines 195-199) so no payment row is created.

- [ ] **Step 4: Update `backend/src/services/orderService.ts`**

Replace the whole file content with:

```ts
import { ForbiddenError, NotFoundError } from '../utils/errors.js';
import type { CheckoutInput, Order, OrderRepository } from '../repositories/orderRepository.js';
import type { InstallmentRepository } from '../repositories/installmentRepository.js';

export class OrderService {
  constructor(
    private orderRepo: OrderRepository,
    private installmentRepo: InstallmentRepository,
  ) {}

  async create(customerId: string, input: CheckoutInput): Promise<Order> {
    const order = await this.orderRepo.create(customerId, input);
    if (input.installmentRequested) {
      await this.installmentRepo.createPlan(order.id, customerId, 3);
    }
    return order;
  }

  async getById(id: string, viewerId: string, viewerRole: string): Promise<Order> {
    const order = await this.orderRepo.findById(id);
    if (!order) throw new NotFoundError('Order not found');
    if (viewerRole === 'customer' && order.customerId !== viewerId) {
      throw new ForbiddenError('You can only view your own orders');
    }
    return order;
  }

  listForCustomer(customerId: string, status?: string) {
    return this.orderRepo.listByCustomer(customerId, status);
  }

  listForStaff(params: { status?: string; page?: number; pageSize?: number }) {
    return this.orderRepo.listAll(params);
  }

  cancel(customerId: string, orderId: string) {
    return this.orderRepo.cancel(customerId, orderId);
  }

  async updateStatus(orderId: string, status: string, staffUserId: string) {
    const order = await this.orderRepo.setStatus(orderId, status as Order['status']);
    if (!order) throw new NotFoundError('Order not found');
    await this.orderRepo.logAudit('order', orderId, 'update', staffUserId, `Order status changed to ${status}`, { status });
    return order;
  }
}
```

- [ ] **Step 5: Update `backend/src/app.ts` wiring**

Change lines 84-94 so the installment repository/service are created BEFORE the order service, and the order service receives it:

```ts
  const orderRepo = new OrderRepository(pool);

  const installmentRepo = new InstallmentRepository(pool);
  const installmentService = new InstallmentService(installmentRepo);
  app.use('/api/installments', installmentRouter(installmentService));

  const orderService = new OrderService(orderRepo, installmentRepo);
  app.use('/api/orders', orderRouter(orderService));

  const paymentRepo = new PaymentRepository(pool);
  const paymentService = new PaymentService(paymentRepo);
  app.use('/api/payments', paymentRouter(paymentService));
```

Note: `InstallmentService` currently takes `(installmentRepo)` only, so this compiles as-is; `paymentService` stays `new PaymentService(paymentRepo)` until Task 4.

- [ ] **Step 6: Run tests and fix compile errors**

Run: `npm.cmd run test -- orderRouter`. Expected: all three new tests PASS. The `paymentRouter.test.ts`/`installmentRouter.test.ts` will now FAIL (they relied on the auto-payment row + old verify) — that is expected and they are rewritten in Tasks 3-4.

- [ ] **Step 7: Typecheck**

Run: `npm.cmd run typecheck`. Expected: clean (orderService/app.ts updated consistently). If `paymentService`/`installmentService` throw type errors about removed repo methods, leave those for Tasks 3-4 — instead temporarily keep old `PaymentRepository`/`InstallmentRepository` as-is (Task 2 does not change them).

- [ ] **Step 8: Commit**

```bash
git add backend/src/repositories/orderRepository.ts backend/src/services/orderService.ts backend/src/app.ts backend/src/routes/orderRouter.test.ts
git commit -m "feat: orders expose payment summary and auto-create installment plans"
```

---

### Task 3: Installment backend — pending_approval, list, approve, reject, applyPayment

**Files:**
- Modify: `backend/src/repositories/installmentRepository.ts`
- Modify: `backend/src/services/installmentService.ts`
- Modify: `backend/src/controllers/installmentController.ts`
- Modify: `backend/src/routes/installmentRouter.ts`
- Modify: `backend/src/validation/schemas.ts` (add `installmentRejectSchema`)
- Modify: `backend/src/app.ts` (construct `InstallmentService` with `notificationRepo` + `auditRepo`)
- Test: `backend/src/routes/installmentRouter.test.ts` (rewrite)

**Interfaces:**
- Consumes: `NotificationRepository.create`, `AuditRepository.log`, `OrderRepository` (via SQL join for order number/customer name — done in repo).
- Produces: `InstallmentRepository.createPlan(orderId, customerId, planCount)` → status `'pending_approval'`, allows order status `pending`/`paid` (any except `cancelled`); `listAll({status?, page?, pageSize?})` → `{rows, total}` where each row adds `orderNumber`, `customerName`, `payments`; `listForCustomer(customerId)`; `getById(id)`; `approve(id, staffUserId)` → status `'active'` + `approved_by`/`approved_at`; `reject(id, staffUserId, reason)` → status `'rejected'` + `rejected_by`/`rejected_at`/`reject_reason`; `applyPayment(installmentId, amount)` marks `installment_payments` paid in due-date order up to `amount`, bumps `amount_paid`, completes plan when full. Removed: `payPayment`. `Installment` type adds `orderNumber`, `customerName`, `rejectedBy`, `rejectedAt`, `rejectReason`. `InstallmentService` constructor becomes `(installmentRepo, notificationRepo, auditRepo)`; methods `getByOrder`, `createPlan`, `list(customerId, viewerRole, params)`, `approve(id, staffUserId)`, `reject(id, staffUserId, reason)`.

- [ ] **Step 1: Rewrite `backend/src/routes/installmentRouter.test.ts` (failing tests first)**

Replace the whole file with:

```ts
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('installments API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;
  const customer = { 'x-user-id': '00000000-0000-0000-0000-000000000201', 'x-user-role': 'customer' };
  const otherCustomer = { 'x-user-id': '00000000-0000-0000-0000-000000000202', 'x-user-role': 'customer' };
  const manager = { 'x-user-id': '00000000-0000-0000-0000-000000000203', 'x-user-role': 'store_manager' };
  const PID = '00000000-0000-0000-0000-000000000501';
  const VID = '00000000-0000-0000-0000-000000000601';

  async function makeOrder(principal: Record<string, string>, installment = false): Promise<string> {
    const res = await request(app).post('/api/orders').set(principal).send({
      customerName: 'Amara Okafor',
      customerPhone: '08011111111',
      customerEmail: 'amara@queenstouch.ng',
      shippingAddress: '12 Broad St, Lagos Island, Lagos',
      paymentMethod: installment ? 'installment' : 'bank_transfer',
      installmentRequested: installment,
      items: [{ productId: PID, variantId: VID, quantity: 1 }],
    });
    return res.body.data.id;
  }

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool);
  });
  afterAll(async () => {
    await pool.end();
  });

  it('creates a pending_approval plan when checkout requests installments', async () => {
    const orderId = await makeOrder(customer, true);
    const plan = await request(app).get(`/api/installments/orders/${orderId}/plans`).set(customer);
    expect(plan.status).toBe(200);
    expect(plan.body.data.status).toBe('pending_approval');
    expect(plan.body.data.payments).toHaveLength(3);
    expect(plan.body.data.termMonths).toBe(3);
  });

  it('explicitly creates a plan on a pending order via the endpoint', async () => {
    const orderId = await makeOrder(customer);
    const res = await request(app).post(`/api/installments/orders/${orderId}/plans`).set(customer).send({ plans: 2 });
    expect(res.status).toBe(201);
    expect(res.body.data.payments).toHaveLength(2);
    expect(res.body.data.status).toBe('pending_approval');
  });

  it('rejects a second plan on the same order', async () => {
    const orderId = await makeOrder(customer, true);
    const res = await request(app).post(`/api/installments/orders/${orderId}/plans`).set(customer).send({ plans: 3 });
    expect(res.status).toBe(409);
  });

  it('staff approve activates the plan; reject rejects it with a reason', async () => {
    const orderId = await makeOrder(customer, true);
    const plan = await request(app).get(`/api/installments/orders/${orderId}/plans`).set(customer);
    const id = plan.body.data.id;

    const rejectRes = await request(app).post(`/api/installments/${id}/reject`).set(manager).send({ reason: 'Customer did not meet criteria' });
    expect(rejectRes.status).toBe(200);
    expect(rejectRes.body.data.status).toBe('rejected');
    expect(rejectRes.body.data.rejectReason).toBe('Customer did not meet criteria');

    const orderId2 = await makeOrder(customer, true);
    const plan2 = await request(app).get(`/api/installments/orders/${orderId2}/plans`).set(customer);
    const approveRes = await request(app).post(`/api/installments/${plan2.body.data.id}/approve`).set(manager);
    expect(approveRes.status).toBe(200);
    expect(approveRes.body.data.status).toBe('active');
    expect(approveRes.body.data.approvedBy).toBe('00000000-0000-0000-0000-000000000203');
  });

  it('does not let a customer approve or reject', async () => {
    const orderId = await makeOrder(customer, true);
    const plan = await request(app).get(`/api/installments/orders/${orderId}/plans`).set(customer);
    const approve = await request(app).post(`/api/installments/${plan.body.data.id}/approve`).set(customer);
    const reject = await request(app).post(`/api/installments/${plan.body.data.id}/reject`).set(customer).send({ reason: 'nope' });
    expect(approve.status).toBe(403);
    expect(reject.status).toBe(403);
  });

  it('staff can list all installments with order metadata; customers see only their own', async () => {
    await makeOrder(customer, true);
    await makeOrder(otherCustomer, true);

    const staff = await request(app).get('/api/installments').set(manager);
    expect(staff.status).toBe(200);
    expect(staff.body.data.rows.length).toBeGreaterThanOrEqual(2);
    expect(staff.body.data.rows[0].orderNumber).toMatch(/^QT-/);
    expect(staff.body.data.rows[0].customerName).toBeTruthy();

    const own = await request(app).get('/api/installments').set(customer);
    expect(own.status).toBe(200);
    expect(own.body.data.rows.length).toBe(1);
  });

  it('prevents a customer from reading another user\'s plan', async () => {
    const orderId = await makeOrder(otherCustomer, true);
    const res = await request(app).get(`/api/installments/orders/${orderId}/plans`).set(customer);
    expect(res.status).toBe(403);
  });
});
```

- [ ] **Step 2: Run to verify failures**

Run: `npm.cmd run test -- installmentRouter`. Expected: multiple failures (no `/approve`/`/reject`/`/`, `createPlan` requires `paid` status, plans not created on checkout, etc.).

- [ ] **Step 3: Rewrite `backend/src/repositories/installmentRepository.ts`**

Replace the whole file with:

```ts
import { randomUUID } from 'node:crypto';
import type { Pool } from 'pg';
import { toNumber } from '../models/index.js';
import { ConflictError, NotFoundError } from '../utils/errors.js';

export interface InstallmentPaymentRow {
  id: string;
  installmentId: string;
  amount: number;
  dueDate: string;
  paidAt: string | null;
  isPaid: boolean;
}

export interface Installment {
  id: string;
  orderId: string;
  customerId: string;
  orderNumber: string | null;
  customerName: string | null;
  totalAmount: number;
  amountPaid: number;
  termMonths: number;
  status: string;
  approvedBy: string | null;
  approvedAt: string | null;
  rejectedBy: string | null;
  rejectedAt: string | null;
  rejectReason: string | null;
  payments: InstallmentPaymentRow[];
}

function addMonths(date: Date, months: number): Date {
  const d = new Date(date);
  d.setMonth(d.getMonth() + months);
  return d;
}

function mapPayment(row: Record<string, unknown>): InstallmentPaymentRow {
  return {
    id: String(row.id),
    installmentId: String(row.installment_id),
    amount: Number(row.amount),
    dueDate: String(row.due_date),
    paidAt: row.paid_at ? String(row.paid_at) : null,
    isPaid: Boolean(row.is_paid),
  };
}

function mapPlan(row: Record<string, unknown>, payments: InstallmentPaymentRow[]): Installment {
  return {
    id: String(row.id),
    orderId: String(row.order_id),
    customerId: String(row.customer_id),
    orderNumber: row.order_number ? String(row.order_number) : null,
    customerName: row.customer_name ? String(row.customer_name) : null,
    totalAmount: Number(row.total_amount),
    amountPaid: Number(row.amount_paid),
    termMonths: toNumber(row.term_months),
    status: String(row.status),
    approvedBy: row.approved_by ? String(row.approved_by) : null,
    approvedAt: row.approved_at ? String(row.approved_at) : null,
    rejectedBy: row.rejected_by ? String(row.rejected_by) : null,
    rejectedAt: row.rejected_at ? String(row.rejected_at) : null,
    rejectReason: row.reject_reason ? String(row.reject_reason) : null,
    payments,
  };
}

export class InstallmentRepository {
  constructor(private pool: Pool) {}

  private async paymentsFor(installmentId: string): Promise<InstallmentPaymentRow[]> {
    const res = await this.pool.query(
      'SELECT * FROM installment_payments WHERE installment_id = $1 ORDER BY due_date ASC',
      [installmentId],
    );
    return res.rows.map(mapPayment);
  }

  async getById(id: string): Promise<Installment | null> {
    const res = await this.pool.query(
      `SELECT i.*, o.order_number, o.customer_name
       FROM installments i JOIN orders o ON o.id = i.order_id
       WHERE i.id = $1`,
      [id],
    );
    if (!res.rows.length) return null;
    return mapPlan(res.rows[0], await this.paymentsFor(id));
  }

  async getByOrder(orderId: string): Promise<Installment | null> {
    const res = await this.pool.query(
      `SELECT i.*, o.order_number, o.customer_name
       FROM installments i JOIN orders o ON o.id = i.order_id
       WHERE i.order_id = $1 ORDER BY i.created_at DESC LIMIT 1`,
      [orderId],
    );
    if (!res.rows.length) return null;
    return mapPlan(res.rows[0], await this.paymentsFor(String(res.rows[0].id)));
  }

  async listAll(params: { status?: string; page?: number; pageSize?: number }) {
    const conditions: string[] = [];
    const values: unknown[] = [];
    if (params.status) {
      values.push(params.status);
      conditions.push(`i.status = $${values.length}`);
    }
    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const page = Math.max(1, params.page ?? 1);
    const pageSize = Math.min(100, Math.max(1, params.pageSize ?? 20));
    const offset = (page - 1) * pageSize;
    const countRes = await this.pool.query(`SELECT count(*)::int AS n FROM installments i ${where}`, values);
    const res = await this.pool.query(
      `SELECT i.*, o.order_number, o.customer_name
       FROM installments i JOIN orders o ON o.id = i.order_id
       ${where} ORDER BY i.created_at DESC LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, offset],
    );
    const rows: Installment[] = [];
    for (const row of res.rows) {
      rows.push(mapPlan(row, await this.paymentsFor(String(row.id))));
    }
    return { rows, total: toNumber(countRes.rows[0]?.n ?? 0) };
  }

  async listForCustomer(customerId: string): Promise<Installment[]> {
    const res = await this.pool.query(
      `SELECT i.*, o.order_number, o.customer_name
       FROM installments i JOIN orders o ON o.id = i.order_id
       WHERE i.customer_id = $1 ORDER BY i.created_at DESC`,
      [customerId],
    );
    const rows: Installment[] = [];
    for (const row of res.rows) {
      rows.push(mapPlan(row, await this.paymentsFor(String(row.id))));
    }
    return rows;
  }

  async createPlan(orderId: string, customerId: string, planCount: number): Promise<Installment> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const orderRes = await client.query(
        'SELECT id, customer_id, total, status FROM orders WHERE id = $1',
        [orderId],
      );
      if (!orderRes.rows.length) throw new NotFoundError('Order not found');
      const order = orderRes.rows[0];
      if (String(order.customer_id) !== customerId) {
        throw new ConflictError('Order does not belong to this customer');
      }
      if (String(order.status) === 'cancelled') {
        throw new ConflictError('Cancelled orders cannot have installment plans');
      }

      const existing = await client.query('SELECT id FROM installments WHERE order_id = $1', [orderId]);
      if (existing.rows.length) throw new ConflictError('An installment plan already exists for this order');

      const total = Number(order.total);
      const installmentId = randomUUID();
      await client.query(
        `INSERT INTO installments (id, order_id, customer_id, total_amount, amount_paid, term_months, status)
         VALUES ($1,$2,$3,$4,0,$5,'pending_approval')`,
        [installmentId, orderId, customerId, total, planCount],
      );

      const base = Math.floor((total * 100) / planCount) / 100;
      const first = Math.round((total - base * (planCount - 1)) * 100) / 100;
      const due = new Date();
      for (let i = 0; i < planCount; i++) {
        const amount = i === 0 ? first : base;
        await client.query(
          `INSERT INTO installment_payments (id, installment_id, amount, due_date, is_paid)
           VALUES ($1,$2,$3,$4,FALSE)`,
          [randomUUID(), installmentId, amount, addMonths(due, i + 1)],
        );
      }

      await client.query('COMMIT');
      const plan = await this.getById(installmentId);
      if (!plan) throw new NotFoundError('Installment plan was not created');
      return plan;
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }

  async approve(id: string, staffUserId: string): Promise<Installment> {
    const res = await this.pool.query(
      `UPDATE installments SET status = 'active', approved_by = $2, approved_at = now(), updated_at = now()
       WHERE id = $1 AND status = 'pending_approval'
       RETURNING id`,
      [id, staffUserId],
    );
    if (!res.rows.length) {
      const exists = await this.pool.query('SELECT status FROM installments WHERE id = $1', [id]);
      if (!exists.rows.length) throw new NotFoundError('Installment plan not found');
      throw new ConflictError('Only pending_approval plans can be approved');
    }
    const plan = await this.getById(id);
    if (!plan) throw new NotFoundError('Installment plan not found');
    return plan;
  }

  async reject(id: string, staffUserId: string, reason: string): Promise<Installment> {
    const res = await this.pool.query(
      `UPDATE installments SET status = 'rejected', rejected_by = $2, rejected_at = now(), reject_reason = $3, updated_at = now()
       WHERE id = $1 AND status = 'pending_approval'
       RETURNING id`,
      [id, staffUserId, reason],
    );
    if (!res.rows.length) {
      const exists = await this.pool.query('SELECT status FROM installments WHERE id = $1', [id]);
      if (!exists.rows.length) throw new NotFoundError('Installment plan not found');
      throw new ConflictError('Only pending_approval plans can be rejected');
    }
    const plan = await this.getById(id);
    if (!plan) throw new NotFoundError('Installment plan not found');
    return plan;
  }

  async applyPayment(installmentId: string, amount: number): Promise<Installment> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const planRes = await client.query(
        'SELECT id, amount_paid, total_amount, status FROM installments WHERE id = $1 FOR UPDATE',
        [installmentId],
      );
      if (!planRes.rows.length) throw new NotFoundError('Installment plan not found');
      const plan = planRes.rows[0];
      if (String(plan.status) !== 'active') {
        throw new ConflictError('Only active installment plans accept payments');
      }

      const unpaid = await client.query(
        `SELECT id, amount FROM installment_payments
         WHERE installment_id = $1 AND is_paid = FALSE
         ORDER BY due_date ASC FOR UPDATE`,
        [installmentId],
      );

      let remaining = amount;
      for (const p of unpaid.rows) {
        if (remaining <= 0) break;
        remaining -= Number(p.amount);
        await client.query(
          'UPDATE installment_payments SET is_paid = TRUE, paid_at = now() WHERE id = $1',
          [p.id],
        );
      }

      const newPaid = Math.min(Number(plan.amount_paid) + amount, Number(plan.total_amount));
      await client.query('UPDATE installments SET amount_paid = $2, updated_at = now() WHERE id = $1', [
        installmentId,
        newPaid,
      ]);

      const unpaidCount = await client.query(
        `SELECT count(*)::int AS n FROM installment_payments
         WHERE installment_id = $1 AND is_paid = FALSE`,
        [installmentId],
      );
      if (toNumber(unpaidCount.rows[0]?.n ?? 0) === 0) {
        await client.query(
          "UPDATE installments SET status = 'completed', amount_paid = total_amount, updated_at = now() WHERE id = $1",
          [installmentId],
        );
      }

      await client.query('COMMIT');
      const plan = await this.getById(installmentId);
      if (!plan) throw new NotFoundError('Installment plan not found');
      return plan;
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }
}
```

- [ ] **Step 4: Rewrite `backend/src/services/installmentService.ts`**

Replace the whole file with:

```ts
import { ForbiddenError, NotFoundError } from '../utils/errors.js';
import type { InstallmentRepository } from '../repositories/installmentRepository.js';
import type { NotificationRepository } from '../repositories/notificationRepository.js';
import type { AuditRepository } from '../repositories/auditRepository.js';
import type { OrderRepository } from '../repositories/orderRepository.js';

export class InstallmentService {
  constructor(
    private installmentRepo: InstallmentRepository,
    private notificationRepo: NotificationRepository,
    private auditRepo: AuditRepository,
    private orderRepo: OrderRepository,
  ) {}

  async getByOrder(orderId: string, viewerId: string, viewerRole: string) {
    const plan = await this.installmentRepo.getByOrder(orderId);
    if (!plan) throw new NotFoundError('No installment plan exists for this order');
    if (viewerRole === 'customer' && plan.customerId !== viewerId) {
      throw new ForbiddenError('You can only view your own installment plans');
    }
    return plan;
  }

  createPlan(orderId: string, customerId: string, planCount: number) {
    return this.installmentRepo.createPlan(orderId, customerId, planCount);
  }

  async list(customerId: string, viewerRole: string, params: { status?: string; page?: number; pageSize?: number }) {
    if (viewerRole === 'customer') {
      return { rows: await this.installmentRepo.listForCustomer(customerId), total: 0 };
    }
    return this.installmentRepo.listAll(params);
  }

  async approve(id: string, staffUserId: string) {
    const plan = await this.installmentRepo.approve(id, staffUserId);
    const order = await this.orderRepo.findById(plan.orderId);
    const orderNumber = order?.orderNumber ?? plan.orderId;
    await this.notificationRepo.create({
      userId: plan.customerId,
      type: 'installment',
      title: 'Installment plan approved',
      body: `Your installment plan for order ${orderNumber} has been approved.`,
    });
    await this.auditRepo.log({
      actorUserId: staffUserId,
      action: 'approve',
      resource: 'installment',
      resourceId: id,
      description: `Approved installment plan for order ${orderNumber}`,
    });
    return plan;
  }

  async reject(id: string, staffUserId: string, reason: string) {
    const plan = await this.installmentRepo.reject(id, staffUserId, reason);
    const order = await this.orderRepo.findById(plan.orderId);
    const orderNumber = order?.orderNumber ?? plan.orderId;
    await this.notificationRepo.create({
      userId: plan.customerId,
      type: 'installment',
      title: 'Installment request declined',
      body: `Your installment request for order ${orderNumber} was declined.`,
    });
    await this.auditRepo.log({
      actorUserId: staffUserId,
      action: 'reject',
      resource: 'installment',
      resourceId: id,
      description: `Rejected installment plan for order ${orderNumber}: ${reason}`,
      newValue: { reason },
    });
    return plan;
  }
}
```

- [ ] **Step 5: Rewrite `backend/src/controllers/installmentController.ts`**

Replace the whole file with:

```ts
import type { Request, Response } from 'express';
import type { InstallmentService } from '../services/installmentService.js';
import { ok } from '../utils/apiResponse.js';

export function installmentController(installmentService: InstallmentService) {
  return {
    async createPlan(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await installmentService.createPlan(req.params.orderId, principal.userId, req.body.plans), 201);
    },
    async listPlans(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await installmentService.getByOrder(req.params.orderId, principal.userId, principal.role));
    },
    async list(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      const page = req.query.page ? Number(req.query.page) : undefined;
      const pageSize = req.query.pageSize ? Number(req.query.pageSize) : undefined;
      ok(res, await installmentService.list(principal.userId, principal.role, {
        status: req.query.status ? String(req.query.status) : undefined,
        page,
        pageSize,
      }));
    },
    async approve(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await installmentService.approve(req.params.id, principal.userId));
    },
    async reject(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await installmentService.reject(req.params.id, principal.userId, req.body.reason));
    },
  };
}
```

- [ ] **Step 6: Rewrite `backend/src/routes/installmentRouter.ts`**

Replace the whole file with:

```ts
import { Router } from 'express';
import { installmentController } from '../controllers/installmentController.js';
import { anyAuthenticated, requireRole } from '../middleware/authStub.js';
import { validateBody } from '../middleware/validate.js';
import { installmentPlanSchema, installmentRejectSchema } from '../validation/schemas.js';
import type { InstallmentService } from '../services/installmentService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export function installmentRouter(installmentService: InstallmentService): Router {
  const router = Router();
  const c = installmentController(installmentService);

  router.post('/orders/:orderId/plans', anyAuthenticated, validateBody(installmentPlanSchema), asyncHandler(c.createPlan));
  router.get('/orders/:orderId/plans', anyAuthenticated, asyncHandler(c.listPlans));
  router.get('/', anyAuthenticated, asyncHandler(c.list));
  router.post(
    '/:id/approve',
    requireRole('super_admin', 'store_manager', 'sales_staff'),
    asyncHandler(c.approve),
  );
  router.post(
    '/:id/reject',
    requireRole('super_admin', 'store_manager', 'sales_staff'),
    validateBody(installmentRejectSchema),
    asyncHandler(c.reject),
  );

  return router;
}
```

- [ ] **Step 7: Add `installmentRejectSchema` to `backend/src/validation/schemas.ts`**

Insert after the `installmentPaySchema` definition (line 183):

```ts
export const installmentRejectSchema = z.object({
  reason: z.string().min(1),
});
```

(Keep `installmentPaySchema` — it is removed with `payPayment` in Task 3 but harmless. If you prefer, delete both `installmentPaySchema` and its usage in the same pass.)

- [ ] **Step 8: Update `backend/src/app.ts` wiring**

`auditRepo` is already constructed at line 72. Move `notificationRepo` construction up next to it (delete the later `const notificationRepo = new NotificationRepository(pool);` at line 108), then replace the installment service construction (currently `const installmentService = new InstallmentService(installmentRepo);`) with:

```ts
  const installmentService = new InstallmentService(installmentRepo, notificationRepo, auditRepo, orderRepo);
```

And make the `notificationService` (line 109) reuse the same `notificationRepo` instance. The final `app.ts` is verified in Task 5.

- [ ] **Step 9: Run the installments tests**

Run: `npm.cmd run test -- installmentRouter`. Expected: all new tests PASS.

- [ ] **Step 10: Typecheck**

Run: `npm.cmd run typecheck`. Expected: clean.

- [ ] **Step 11: Commit**

```bash
git add backend/src/repositories/installmentRepository.ts backend/src/services/installmentService.ts backend/src/controllers/installmentController.ts backend/src/routes/installmentRouter.ts backend/src/validation/schemas.ts backend/src/app.ts backend/src/routes/installmentRouter.test.ts
git commit -m "feat: installments pending_approval flow with admin approve/reject"
```

---

### Task 4: Payment backend — submit proof, verify, reject, list, Family Bank transfer details

**Files:**
- Modify: `backend/src/repositories/paymentRepository.ts`
- Modify: `backend/src/services/paymentService.ts`
- Modify: `backend/src/controllers/paymentController.ts`
- Modify: `backend/src/routes/paymentRouter.ts`
- Modify: `backend/src/validation/schemas.ts` (add `paymentSubmitSchema`, `paymentRejectSchema`)
- Modify: `backend/src/app.ts` (construct `PaymentService` with all deps)
- Test: `backend/src/routes/paymentRouter.test.ts` (rewrite)

**Interfaces:**
- Consumes: `OrderRepository.findById`, `InstallmentRepository.applyPayment`, `NotificationRepository.create`, `AuditRepository.log`.
- Produces: `PaymentRepository.submit(input)` → creates `pending_verification` row with duplicate flag + over-submission guard; `listForOrder(orderId)` → `Payment[]` DESC; `listAll({status?, page?, pageSize?})` → `{rows,total}` with `orderNumber`/`customerName`; `listForCustomer(customerId)`; `getById(id)`; `verify(id, staffUserId)`; `reject(id, staffUserId, reason)`; `transferDetails()` → `{ bankName: 'Family Bank', paybillNumber: '222111', accountNumber: '65727' }`. `Payment` type adds `orderNumber`, `customerName`, `paymentDate`, `confirmationMessage`, `note`, `verifiedAt`, `verifiedBy`, `rejectedAt`, `rejectedBy`, `rejectReason`, `duplicateOf`, `updatedAt`. `PaymentService` constructor `(paymentRepo, orderRepo, installmentRepo, notificationRepo, auditRepo)`; methods `submit`, `listForOrder`, `list`, `getById`, `verify`, `reject`, `transferDetails`.

- [ ] **Step 1: Rewrite `backend/src/routes/paymentRouter.test.ts` (failing tests first)**

Replace the whole file with:

```ts
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

describe('payments API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;
  const customer = { 'x-user-id': '00000000-0000-0000-0000-000000000201', 'x-user-role': 'customer' };
  const otherCustomer = { 'x-user-id': '00000000-0000-0000-0000-000000000202', 'x-user-role': 'customer' };
  const manager = { 'x-user-id': '00000000-0000-0000-0000-000000000203', 'x-user-role': 'store_manager' };
  const PID = '00000000-0000-0000-0000-000000000501';
  const VID = '00000000-0000-0000-0000-000000000601';

  async function makeOrder(principal: Record<string, string>, qty = 1): Promise<string> {
    const res = await request(app).post('/api/orders').set(principal).send({
      customerName: 'Amara Okafor',
      customerPhone: '08011111111',
      customerEmail: 'amara@queenstouch.ng',
      shippingAddress: '12 Broad St, Lagos Island, Lagos',
      paymentMethod: 'paybill',
      items: [{ productId: PID, variantId: VID, quantity: qty }],
    });
    return res.body.data.id;
  }

  function submitBody(overrides: Record<string, unknown> = {}) {
    return {
      orderId: 'ignored', // replaced below
      amount: 100,
      paymentDate: '2026-08-17',
      confirmationMessage: 'Confirmed via M-Pesa, balance is fine',
      ...overrides,
    };
  }

  beforeAll(async () => {
    pool = loadPgMem(schemaPath());
    app = createApp(pool);
  });
  afterAll(async () => {
    await pool.end();
  });

  it('submits a payment proof as pending_verification', async () => {
    const orderId = await makeOrder(customer);
    const res = await request(app)
      .post('/api/payments')
      .set(customer)
      .send({ ...submitBody({ orderId, amount: 100 }) });
    expect(res.status).toBe(201);
    expect(res.body.data.status).toBe('pending_verification');
    expect(res.body.data.amount).toBe(100);
    expect(res.body.data.confirmationMessage).toBe('Confirmed via M-Pesa, balance is fine');
    const order = await request(app).get(`/api/orders/${orderId}`).set(customer);
    expect(order.body.data.paymentStatus).toBe('pending_verification');
    expect(order.body.data.paymentSummary.pending).toBe(100);
    expect(order.body.data.paymentSummary.remaining).toBe(order.body.data.total - 100);
  });

  it('rejects a submission that exceeds the order balance', async () => {
    const orderId = await makeOrder(customer);
    const res = await request(app)
      .post('/api/payments')
      .set(customer)
      .send({ ...submitBody({ orderId, amount: 999999 }) });
    expect(res.status).toBe(409);
  });

  it('flags duplicate submissions with duplicateOf instead of rejecting', async () => {
    const orderId = await makeOrder(customer);
    await request(app).post('/api/payments').set(customer).send({ ...submitBody({ orderId, amount: 100, reference: 'MP-111' }) });
    const dup = await request(app).post('/api/payments').set(customer).send({ ...submitBody({ orderId, amount: 100, reference: 'MP-111' }) });
    expect(dup.status).toBe(201);
    expect(dup.body.data.duplicateOf).toBeTruthy();
  });

  it('staff verifies a payment and advances the order to paid when fully paid', async () => {
    const orderId = await makeOrder(customer);
    const orderRes = await request(app).get(`/api/orders/${orderId}`).set(customer);
    const total = orderRes.body.data.total;
    const sub = await request(app).post('/api/payments').set(customer).send({ ...submitBody({ orderId, amount: total }) });
    expect(sub.status).toBe(201);
    const verify = await request(app).post(`/api/payments/${sub.body.data.id}/verify`).set(manager);
    expect(verify.status).toBe(200);
    expect(verify.body.data.status).toBe('successful');
    expect(verify.body.data.verifiedBy).toBe('00000000-0000-0000-0000-000000000203');
    const order = await request(app).get(`/api/orders/${orderId}`).set(customer);
    expect(order.body.data.status).toBe('paid');
    expect(order.body.data.paymentStatus).toBe('successful');
    expect(order.body.data.paymentSummary.verified).toBe(total);
  });

  it('keeps an order partially_paid when only part is verified', async () => {
    const orderId = await makeOrder(customer, 2); // subtotal 2 * unit price -> total > 100
    const sub = await request(app).post('/api/payments').set(customer).send({ ...submitBody({ orderId, amount: 100 }) });
    await request(app).post(`/api/payments/${sub.body.data.id}/verify`).set(manager);
    const order = await request(app).get(`/api/orders/${orderId}`).set(customer);
    expect(order.body.data.paymentStatus).toBe('partially_paid');
    expect(order.body.data.status).toBe('pending');
  });

  it('staff rejects a payment with a reason', async () => {
    const orderId = await makeOrder(customer);
    const sub = await request(app).post('/api/payments').set(customer).send({ ...submitBody({ orderId, amount: 100 }) });
    const reject = await request(app).post(`/api/payments/${sub.body.data.id}/reject`).set(manager).send({ reason: 'Transaction not found' });
    expect(reject.status).toBe(200);
    expect(reject.body.data.status).toBe('rejected');
    expect(reject.body.data.rejectReason).toBe('Transaction not found');
  });

  it('does not let a customer verify or reject', async () => {
    const orderId = await makeOrder(customer);
    const sub = await request(app).post('/api/payments').set(customer).send({ ...submitBody({ orderId, amount: 100 }) });
    const verify = await request(app).post(`/api/payments/${sub.body.data.id}/verify`).set(customer);
    const reject = await request(app).post(`/api/payments/${sub.body.data.id}/reject`).set(customer).send({ reason: 'x' });
    expect(verify.status).toBe(403);
    expect(reject.status).toBe(403);
  });

  it('lists payments for an order; staff see all, customers only their own', async () => {
    const myOrder = await makeOrder(customer);
    await request(app).post('/api/payments').set(customer).send({ ...submitBody({ orderId: myOrder, amount: 100 }) });
    const otherOrder = await makeOrder(otherCustomer);
    await request(app).post('/api/payments').set(otherCustomer).send({ ...submitBody({ orderId: otherOrder, amount: 100 }) });

    const staff = await request(app).get('/api/payments').set(manager);
    expect(staff.status).toBe(200);
    expect(staff.body.data.rows.length).toBeGreaterThanOrEqual(2);
    expect(staff.body.data.rows[0].orderNumber).toMatch(/^QT-/);
    expect(staff.body.data.rows[0].customerName).toBeTruthy();

    const own = await request(app).get('/api/payments').set(customer);
    expect(own.status).toBe(200);
    expect(own.body.data.rows.length).toBe(1);
  });

  it('returns Family Bank paybill transfer details', async () => {
    const res = await request(app).get('/api/payments/transfer-details').set(customer);
    expect(res.status).toBe(200);
    expect(res.body.data.bankName).toBe('Family Bank');
    expect(res.body.data.paybillNumber).toBe('222111');
    expect(res.body.data.accountNumber).toBe('65727');
  });

  it('prevents a customer from reading another user\'s payment list', async () => {
    const orderId = await makeOrder(otherCustomer);
    const res = await request(app).get(`/api/payments/orders/${orderId}`).set(customer);
    expect(res.status).toBe(403);
  });
});
```

- [ ] **Step 2: Run to verify failures**

Run: `npm.cmd run test -- paymentRouter`. Expected: many failures (no `POST /`, no `/orders/:orderId`, no `/:id/verify|reject`, old `GET /:orderId` behavior, transfer-details returns GTBank).

- [ ] **Step 3: Rewrite `backend/src/repositories/paymentRepository.ts`**

Replace the whole file with:

```ts
import { randomUUID } from 'node:crypto';
import type { Pool, PoolClient } from 'pg';
import type { PaymentMethod, PaymentStatus } from '../models/index.js';
import { ConflictError, NotFoundError } from '../utils/errors.js';

export interface Payment {
  id: string;
  orderId: string;
  customerId: string;
  orderNumber: string | null;
  customerName: string | null;
  amount: number;
  method: PaymentMethod;
  status: PaymentStatus;
  reference: string | null;
  paymentDate: string | null;
  confirmationMessage: string | null;
  note: string | null;
  verifiedAt: string | null;
  verifiedBy: string | null;
  rejectedAt: string | null;
  rejectedBy: string | null;
  rejectReason: string | null;
  duplicateOf: string | null;
  createdAt: string;
  updatedAt: string | null;
}

export interface SubmitPaymentInput {
  orderId: string;
  customerId: string;
  amount: number;
  paymentDate: string;
  reference?: string | null;
  confirmationMessage: string;
  note?: string | null;
}

const DAY_MS = 24 * 60 * 60 * 1000;

function mapPayment(r: Record<string, unknown>): Payment {
  return {
    id: String(r.id),
    orderId: String(r.order_id),
    customerId: String(r.customer_id),
    orderNumber: r.order_number ? String(r.order_number) : null,
    customerName: r.customer_name ? String(r.customer_name) : null,
    amount: Number(r.amount),
    method: r.method as PaymentMethod,
    status: r.status as PaymentStatus,
    reference: r.reference ? String(r.reference) : null,
    paymentDate: r.payment_date ? String(r.payment_date) : null,
    confirmationMessage: r.confirmation_message ? String(r.confirmation_message) : null,
    note: r.note ? String(r.note) : null,
    verifiedAt: r.verified_at ? String(r.verified_at) : null,
    verifiedBy: r.verified_by ? String(r.verified_by) : null,
    rejectedAt: r.rejected_at ? String(r.rejected_at) : null,
    rejectedBy: r.rejected_by ? String(r.rejected_by) : null,
    rejectReason: r.reject_reason ? String(r.reject_reason) : null,
    duplicateOf: r.duplicate_of ? String(r.duplicate_of) : null,
    createdAt: String(r.created_at),
    updatedAt: r.updated_at ? String(r.updated_at) : null,
  };
}

const SELECT_PAYMENT = `SELECT p.*, o.order_number, o.customer_name
  FROM payments p JOIN orders o ON o.id = p.order_id`;

function sameReference(a: string | null | undefined, b: string | null | undefined): boolean {
  if (!a || !b) return false;
  return a.trim().toLowerCase() === b.trim().toLowerCase();
}

function withinDays(a: string, b: string, days: number): boolean {
  const da = new Date(a).getTime();
  const db = new Date(b).getTime();
  return Math.abs(da - db) <= days * DAY_MS;
}

export class PaymentRepository {
  constructor(private pool: Pool) {}

  private async setOrderPaymentStatus(
    q: PoolClient,
    orderId: string,
    orderStatus: 'pending' | 'paid',
    paymentStatus: PaymentStatus,
  ): Promise<void> {
    await q.query(
      'UPDATE orders SET status = $2, payment_status = $3, updated_at = now() WHERE id = $1',
      [orderId, orderStatus, paymentStatus],
    );
  }

  async listForOrder(orderId: string): Promise<Payment[]> {
    const res = await this.pool.query(
      `${SELECT_PAYMENT} WHERE p.order_id = $1 ORDER BY p.created_at DESC`,
      [orderId],
    );
    return res.rows.map(mapPayment);
  }

  async listForCustomer(customerId: string): Promise<Payment[]> {
    const res = await this.pool.query(
      `${SELECT_PAYMENT} WHERE p.customer_id = $1 ORDER BY p.created_at DESC`,
      [customerId],
    );
    return res.rows.map(mapPayment);
  }

  async listAll(params: { status?: string; page?: number; pageSize?: number }) {
    const conditions: string[] = [];
    const values: unknown[] = [];
    if (params.status) {
      values.push(params.status);
      conditions.push(`p.status = $${values.length}`);
    }
    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const page = Math.max(1, params.page ?? 1);
    const pageSize = Math.min(100, Math.max(1, params.pageSize ?? 20));
    const offset = (page - 1) * pageSize;
    const countRes = await this.pool.query(`SELECT count(*)::int AS n FROM payments p ${where}`, values);
    const res = await this.pool.query(
      `${SELECT_PAYMENT} ${where} ORDER BY p.created_at DESC LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, offset],
    );
    return { rows: res.rows.map(mapPayment), total: Number(countRes.rows[0]?.n ?? 0) };
  }

  async getById(id: string): Promise<Payment | null> {
    const res = await this.pool.query(`${SELECT_PAYMENT} WHERE p.id = $1`, [id]);
    return res.rows.length ? mapPayment(res.rows[0]) : null;
  }

  async submit(input: SubmitPaymentInput): Promise<Payment> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const orderRes = await client.query(
        'SELECT id, customer_id, total, status, payment_status FROM orders WHERE id = $1 FOR UPDATE',
        [input.orderId],
      );
      if (!orderRes.rows.length) throw new NotFoundError('Order not found');
      const order = orderRes.rows[0];
      if (String(order.customer_id) !== input.customerId) {
        throw new ConflictError('Order does not belong to this customer');
      }
      if (String(order.status) === 'cancelled') {
        throw new ConflictError('Cancelled orders cannot accept payments');
      }

      const total = Number(order.total);
      const existing = await client.query(
        "SELECT id, amount, reference, payment_date, status FROM payments WHERE order_id = $1 AND status != 'rejected'",
        [input.orderId],
      );
      const nonRejectedSum = existing.rows.reduce((s, r) => s + Number(r.amount), 0);
      if (nonRejectedSum + input.amount > total) {
        throw new ConflictError('Payment would exceed the order balance');
      }

      let duplicateId: string | null = null;
      for (const r of existing.rows) {
        if (Number(r.amount) !== input.amount) continue;
        if (sameReference(r.reference, input.reference)) {
          duplicateId = String(r.id);
          break;
        }
        if (r.payment_date && withinDays(String(r.payment_date), input.paymentDate, 2)) {
          duplicateId = String(r.id);
          break;
        }
      }

      const paymentId = randomUUID();
      await client.query(
        `INSERT INTO payments (id, order_id, customer_id, amount, method, status, reference,
            payment_date, confirmation_message, note, duplicate_of)
         VALUES ($1,$2,$3,$4,'paybill','pending_verification',$5,$6,$7,$8,$9)`,
        [
          paymentId,
          input.orderId,
          input.customerId,
          input.amount,
          input.reference ?? null,
          input.paymentDate,
          input.confirmationMessage,
          input.note ?? null,
          duplicateId,
        ],
      );

      if (String(order.payment_status) === 'pending') {
        await client.query(
          "UPDATE orders SET payment_status = 'pending_verification', updated_at = now() WHERE id = $1",
          [input.orderId],
        );
      }

      await client.query('COMMIT');
      const payment = await this.getById(paymentId);
      if (!payment) throw new NotFoundError('Payment was not created');
      return payment;
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }

  async verify(id: string, staffUserId: string): Promise<Payment> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const payRes = await client.query(
        'SELECT * FROM payments WHERE id = $1 FOR UPDATE',
        [id],
      );
      if (!payRes.rows.length) throw new NotFoundError('Payment not found');
      const pay = payRes.rows[0];
      if (String(pay.status) !== 'pending_verification') {
        throw new ConflictError('Only pending_verification payments can be verified');
      }

      await client.query(
        "UPDATE payments SET status = 'successful', verified_at = now(), verified_by = $2, updated_at = now() WHERE id = $1",
        [id, staffUserId],
      );

      const orderRes = await client.query(
        'SELECT id, total, status FROM orders WHERE id = $1 FOR UPDATE',
        [pay.order_id],
      );
      const order = orderRes.rows[0];
      const total = Number(order.total);
      const sums = await client.query(
        "SELECT COALESCE(SUM(amount),0) AS verified FROM payments WHERE order_id = $1 AND status = 'successful'",
        [pay.order_id],
      );
      const verified = Number(sums.rows[0].verified);

      if (verified >= total) {
        await this.setOrderPaymentStatus(client, String(pay.order_id), 'paid', 'successful');
      } else {
        await this.setOrderPaymentStatus(client, String(pay.order_id), 'pending', 'partially_paid');
      }

      await client.query('COMMIT');
      const payment = await this.getById(id);
      if (!payment) throw new NotFoundError('Payment not found');
      return payment;
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }

  async reject(id: string, staffUserId: string, reason: string): Promise<Payment> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const payRes = await client.query(
        'SELECT * FROM payments WHERE id = $1 FOR UPDATE',
        [id],
      );
      if (!payRes.rows.length) throw new NotFoundError('Payment not found');
      const pay = payRes.rows[0];
      if (String(pay.status) !== 'pending_verification') {
        throw new ConflictError('Only pending_verification payments can be rejected');
      }

      await client.query(
        "UPDATE payments SET status = 'rejected', rejected_at = now(), rejected_by = $2, reject_reason = $3, updated_at = now() WHERE id = $1",
        [id, staffUserId, reason],
      );

      const pending = await client.query(
        "SELECT COALESCE(SUM(amount),0) AS n FROM payments WHERE order_id = $1 AND status = 'pending_verification'",
        [pay.order_id],
      );
      const verified = await client.query(
        "SELECT COALESCE(SUM(amount),0) AS n FROM payments WHERE order_id = $1 AND status = 'successful'",
        [pay.order_id],
      );
      let paymentStatus: PaymentStatus = 'pending';
      if (Number(verified.rows[0].n) > 0) paymentStatus = 'partially_paid';
      else if (Number(pending.rows[0].n) > 0) paymentStatus = 'pending_verification';
      await this.setOrderPaymentStatus(client, String(pay.order_id), 'pending', paymentStatus);

      await client.query('COMMIT');
      const payment = await this.getById(id);
      if (!payment) throw new NotFoundError('Payment not found');
      return payment;
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }

  transferDetails() {
    return {
      bankName: 'Family Bank',
      paybillNumber: '222111',
      accountNumber: '65727',
    };
  }
}
```

- [ ] **Step 4: Rewrite `backend/src/services/paymentService.ts`**

Replace the whole file with:

```ts
import { ConflictError, ForbiddenError, NotFoundError } from '../utils/errors.js';
import type { PaymentRepository, SubmitPaymentInput } from '../repositories/paymentRepository.js';
import type { OrderRepository } from '../repositories/orderRepository.js';
import type { InstallmentRepository } from '../repositories/installmentRepository.js';
import type { NotificationRepository } from '../repositories/notificationRepository.js';
import type { AuditRepository } from '../repositories/auditRepository.js';

export class PaymentService {
  constructor(
    private paymentRepo: PaymentRepository,
    private orderRepo: OrderRepository,
    private installmentRepo: InstallmentRepository,
    private notificationRepo: NotificationRepository,
    private auditRepo: AuditRepository,
  ) {}

  async submit(customerId: string, input: SubmitPaymentInput) {
    const order = await this.orderRepo.findById(input.orderId);
    if (!order) throw new NotFoundError('Order not found');
    if (order.customerId !== customerId) {
      throw new ForbiddenError('You can only submit payments for your own orders');
    }
    const payment = await this.paymentRepo.submit({ ...input, customerId });
    await this.notificationRepo.create({
      userId: customerId,
      type: 'payment',
      title: 'Payment submitted',
      body: `Payment of ${input.amount} for order ${order.orderNumber} is awaiting verification.`,
    });
    return payment;
  }

  async listForOrder(orderId: string, viewerId: string, viewerRole: string) {
    const order = await this.orderRepo.findById(orderId);
    if (!order) throw new NotFoundError('Order not found');
    if (viewerRole === 'customer' && order.customerId !== viewerId) {
      throw new ForbiddenError('You can only view payments for your own orders');
    }
    return this.paymentRepo.listForOrder(orderId);
  }

  async list(customerId: string, viewerRole: string, params: { status?: string; page?: number; pageSize?: number }) {
    if (viewerRole === 'customer') {
      return { rows: await this.paymentRepo.listForCustomer(customerId), total: 0 };
    }
    return this.paymentRepo.listAll(params);
  }

  async getById(id: string, viewerId: string, viewerRole: string) {
    const payment = await this.paymentRepo.getById(id);
    if (!payment) throw new NotFoundError('Payment not found');
    if (viewerRole === 'customer' && payment.customerId !== viewerId) {
      throw new ForbiddenError('You can only view your own payments');
    }
    return payment;
  }

  async verify(id: string, staffUserId: string) {
    const payment = await this.paymentRepo.getById(id);
    if (!payment) throw new NotFoundError('Payment not found');

    const updated = await this.paymentRepo.verify(id, staffUserId);

    const installment = await this.installmentRepo.getByOrder(payment.orderId);
    if (installment && installment.status === 'active') {
      await this.installmentRepo.applyPayment(installment.id, payment.amount);
    }

    const order = await this.orderRepo.findById(payment.orderId);
    const orderNumber = order?.orderNumber ?? payment.orderId;
    await this.notificationRepo.create({
      userId: payment.customerId,
      type: 'payment',
      title: 'Payment verified',
      body: `Payment of ${payment.amount} for order ${orderNumber} was verified successfully.`,
    });
    if (order && order.paymentStatus === 'successful') {
      await this.notificationRepo.create({
        userId: payment.customerId,
        type: 'payment',
        title: 'Order fully paid',
        body: `Order ${orderNumber} is now fully paid.`,
      });
    }
    await this.auditRepo.log({
      actorUserId: staffUserId,
      action: 'approve',
      resource: 'payment',
      resourceId: id,
      description: `Verified payment of ${payment.amount} for order ${orderNumber}`,
    });
    return updated;
  }

  async reject(id: string, staffUserId: string, reason: string) {
    const payment = await this.paymentRepo.getById(id);
    if (!payment) throw new NotFoundError('Payment not found');

    const updated = await this.paymentRepo.reject(id, staffUserId, reason);

    const order = await this.orderRepo.findById(payment.orderId);
    const orderNumber = order?.orderNumber ?? payment.orderId;
    await this.notificationRepo.create({
      userId: payment.customerId,
      type: 'payment',
      title: 'Payment rejected',
      body: `Your payment of ${payment.amount} for order ${orderNumber} was rejected. ${reason}`,
    });
    await this.auditRepo.log({
      actorUserId: staffUserId,
      action: 'reject',
      resource: 'payment',
      resourceId: id,
      description: `Rejected payment of ${payment.amount} for order ${orderNumber}: ${reason}`,
      newValue: { reason },
    });
    return updated;
  }

  transferDetails() {
    return this.paymentRepo.transferDetails();
  }
}
```

- [ ] **Step 5: Rewrite `backend/src/controllers/paymentController.ts`**

Replace the whole file with:

```ts
import type { Request, Response } from 'express';
import type { PaymentService } from '../services/paymentService.js';
import { ok } from '../utils/apiResponse.js';

export function paymentController(paymentService: PaymentService) {
  return {
    async submit(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await paymentService.submit(principal.userId, req.body), 201);
    },
    async list(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      const page = req.query.page ? Number(req.query.page) : undefined;
      const pageSize = req.query.pageSize ? Number(req.query.pageSize) : undefined;
      ok(res, await paymentService.list(principal.userId, principal.role, {
        status: req.query.status ? String(req.query.status) : undefined,
        page,
        pageSize,
      }));
    },
    async listForOrder(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await paymentService.listForOrder(req.params.orderId, principal.userId, principal.role));
    },
    async getById(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await paymentService.getById(req.params.id, principal.userId, principal.role));
    },
    async verify(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await paymentService.verify(req.params.id, principal.userId));
    },
    async reject(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await paymentService.reject(req.params.id, principal.userId, req.body.reason));
    },
    async transferDetails(_req: Request, res: Response): Promise<void> {
      ok(res, paymentService.transferDetails());
    },
  };
}
```

- [ ] **Step 6: Rewrite `backend/src/routes/paymentRouter.ts`**

Replace the whole file with:

```ts
import { Router } from 'express';
import { paymentController } from '../controllers/paymentController.js';
import { anyAuthenticated, requireRole } from '../middleware/authStub.js';
import { validateBody } from '../middleware/validate.js';
import { paymentSubmitSchema, paymentRejectSchema } from '../validation/schemas.js';
import type { PaymentService } from '../services/paymentService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export function paymentRouter(paymentService: PaymentService): Router {
  const router = Router();
  const c = paymentController(paymentService);

  router.get('/transfer-details', anyAuthenticated, asyncHandler(c.transferDetails));
  router.get('/', anyAuthenticated, asyncHandler(c.list));
  router.get('/orders/:orderId', anyAuthenticated, asyncHandler(c.listForOrder));
  router.post('/', anyAuthenticated, validateBody(paymentSubmitSchema), asyncHandler(c.submit));
  router.get('/:id', anyAuthenticated, asyncHandler(c.getById));
  router.post(
    '/:id/verify',
    requireRole('super_admin', 'store_manager', 'sales_staff'),
    asyncHandler(c.verify),
  );
  router.post(
    '/:id/reject',
    requireRole('super_admin', 'store_manager', 'sales_staff'),
    validateBody(paymentRejectSchema),
    asyncHandler(c.reject),
  );

  return router;
}
```

- [ ] **Step 7: Add payment schemas to `backend/src/validation/schemas.ts`**

Replace the `paymentVerifySchema` block (lines 185-187) with:

```ts
export const paymentSubmitSchema = z.object({
  orderId: uuid,
  amount: z.number().positive(),
  paymentDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'paymentDate must be YYYY-MM-DD'),
  reference: z.string().optional().nullable(),
  confirmationMessage: z.string().min(1),
  note: z.string().optional().nullable(),
});

export const paymentRejectSchema = z.object({
  reason: z.string().min(1),
});
```

- [ ] **Step 8: Update `backend/src/app.ts` wiring**

Replace the payment service construction (currently `const paymentService = new PaymentService(paymentRepo);`) with:

```ts
  const paymentService = new PaymentService(paymentRepo, orderRepo, installmentRepo, notificationRepo, auditRepo);
```

- [ ] **Step 9: Run the payments tests**

Run: `npm.cmd run test -- paymentRouter`. Expected: all new tests PASS.

- [ ] **Step 10: Run the full backend suite and typecheck**

Run: `npm.cmd run test` and `npm.cmd run typecheck`. Expected: all pass, clean typecheck. (Task 5 finalizes `app.ts` ordering if duplicate repo constructions remain.)

- [ ] **Step 11: Commit**

```bash
git add backend/src/repositories/paymentRepository.ts backend/src/services/paymentService.ts backend/src/controllers/paymentController.ts backend/src/routes/paymentRouter.ts backend/src/validation/schemas.ts backend/src/app.ts backend/src/routes/paymentRouter.test.ts
git commit -m "feat: manual paybill payment submission, verification and rejection"
```

---

### Task 5: Backend consolidation — final app.ts, full suite, typecheck

**Files:**
- Modify: `backend/src/app.ts`
- Test: full backend suite

**Interfaces:** None new — verifies everything compiles and passes together.

- [ ] **Step 1: Review `backend/src/app.ts`**

Read `backend/src/app.ts`. Ensure exactly ONE construction each of `AuditRepository`, `NotificationRepository`, `InstallmentRepository`, `PaymentRepository`, `OrderRepository`, and that `OrderService`, `PaymentService`, `InstallmentService` receive the correct deps:

```ts
  const orderRepo = new OrderRepository(pool);
  const auditRepo = new AuditRepository(pool);
  const notificationRepo = new NotificationRepository(pool);
  const installmentRepo = new InstallmentRepository(pool);
  const installmentService = new InstallmentService(installmentRepo, notificationRepo, auditRepo, orderRepo);
  const orderService = new OrderService(orderRepo, installmentRepo);
  const paymentRepo = new PaymentRepository(pool);
  const paymentService = new PaymentService(paymentRepo, orderRepo, installmentRepo, notificationRepo, auditRepo);
```

The `auditService`/`notificationService` and their routers keep using the same `auditRepo`/`notificationRepo` instances. Remove any duplicate `new AuditRepository(...)` / `new NotificationRepository(...)` lines left over from earlier tasks.

- [ ] **Step 2: Run full backend suite**

Run: `npm.cmd run test`. Expected: all tests pass (including orderRouter, paymentRouter, installmentRouter, schemas, schema).

- [ ] **Step 3: Typecheck**

Run: `npm.cmd run typecheck`. Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add backend/src/app.ts
git commit -m "refactor: consolidate payment/installment service wiring in app"
```

---

### Task 6: Flutter models + currency helper

**Files:**
- Modify: `lib/models/order.dart`
- Create: `lib/core/utils/currency.dart`
- Test: `test/models/order_model_test.dart` (create)

**Interfaces:**
- Consumes: existing model shapes.
- Produces: `PaymentStatus` adds `pendingVerification`, `partiallyPaid`, `rejected` (labels 'Pending Verification', 'Partially Paid', 'Rejected'); `PaymentMethod` adds `paybill` (label 'Paybill'); `Payment` adds `orderNumber`, `customerName`, `paymentDate`, `confirmationMessage`, `note`, `verifiedAt`, `rejectedAt`, `rejectReason`, `duplicateOf`; `Order` adds `paymentSummary` (`OrderPaymentSummary { total, verified, pending, remaining }`); `Installment` adds `approvedBy`, `approvedAt`, `rejectedBy`, `rejectedAt`, `rejectReason`; new class `TransferDetails { bankName, paybillNumber, accountNumber }`; new function `formatKsh(double amount) => 'KSh x,xxx.xx'`.

- [ ] **Step 1: Write failing model tests — create `test/models/order_model_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:botique/models/order.dart';
import 'package:botique/core/utils/currency.dart';

void main() {
  test('Order parses paymentSummary and paymentStatus', () {
    final order = Order.fromJson(const {
      'id': 'o1',
      'orderNumber': 'QT-1',
      'customerId': 'u1',
      'customerName': 'A',
      'customerPhone': '080',
      'customerEmail': 'a@b.c',
      'shippingAddress': 's',
      'subtotal': 1000,
      'discount': 0,
      'shippingFee': 0,
      'status': 'pending',
      'paymentStatus': 'partially_paid',
      'paymentMethod': 'paybill',
      'installmentRequested': false,
      'createdAt': '2026-01-01T00:00:00Z',
      'items': [],
      'paymentSummary': {'total': 1000, 'verified': 400, 'pending': 300, 'remaining': 600},
    });
    expect(order.paymentStatus, PaymentStatus.partiallyPaid);
    expect(order.paymentMethod, PaymentMethod.paybill);
    expect(order.paymentSummary.verified, 400);
    expect(order.paymentSummary.pending, 300);
    expect(order.paymentSummary.remaining, 600);
  });

  test('Payment parses verification and rejection fields', () {
    final p = Payment.fromJson(const {
      'id': 'pay1',
      'orderId': 'o1',
      'customerId': 'u1',
      'amount': 100,
      'method': 'paybill',
      'status': 'pending_verification',
      'reference': 'MP-1',
      'paymentDate': '2026-08-17',
      'confirmationMessage': 'Confirmed',
      'note': null,
      'verifiedAt': null,
      'verifiedBy': null,
      'rejectedAt': null,
      'rejectedBy': null,
      'rejectReason': null,
      'duplicateOf': null,
      'createdAt': '2026-01-01T00:00:00Z',
    });
    expect(p.status, PaymentStatus.pendingVerification);
    expect(p.method, PaymentMethod.paybill);
    expect(p.paymentDate, '2026-08-17');
    expect(p.confirmationMessage, 'Confirmed');
  });

  test('Installment parses rejection fields', () {
    final plan = Installment.fromJson(const {
      'id': 'i1',
      'orderId': 'o1',
      'orderNumber': 'QT-1',
      'customerId': 'u1',
      'customerName': 'A',
      'totalAmount': 900,
      'amountPaid': 0,
      'status': 'rejected',
      'termMonths': 3,
      'createdAt': '2026-01-01T00:00:00Z',
      'payments': [],
      'approvedBy': null,
      'approvedAt': null,
      'rejectedBy': 'u203',
      'rejectedAt': '2026-01-02T00:00:00Z',
      'rejectReason': 'No',
    });
    expect(plan.status, InstallmentStatus.rejected);
    expect(plan.rejectReason, 'No');
  });

  test('TransferDetails parses paybill details', () {
    final t = TransferDetails.fromJson(const {
      'bankName': 'Family Bank',
      'paybillNumber': '222111',
      'accountNumber': '65727',
    });
    expect(t.paybillNumber, '222111');
  });

  test('formatKsh formats with thousands separator', () {
    expect(formatKsh(52500), 'KSh 52,500.00');
    expect(formatKsh(0), 'KSh 0.00');
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/models/order_model_test.dart`. Expected: compile errors (missing fields/enum values/`TransferDetails`/`formatKsh`).

- [ ] **Step 3: Create `lib/core/utils/currency.dart`**

```dart
String formatKsh(double amount) {
  final fixed = amount.toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts[0];
  final negative = digits.startsWith('-');
  final abs = negative ? digits.substring(1) : digits;
  final buf = StringBuffer();
  for (var i = 0; i < abs.length; i++) {
    if (i > 0 && (abs.length - i) % 3 == 0) buf.write(',');
    buf.write(abs[i]);
  }
  final formatted = buf.toString();
  return 'KSh ${negative ? '-' : ''}$formatted.${parts[1]}';
}
```

- [ ] **Step 4: Update `lib/models/order.dart`**

(a) `PaymentStatus` enum + label extension (lines 14-23):

```dart
enum PaymentStatus { pending, pendingVerification, successful, partiallyPaid, failed, refunded, rejected }

extension PaymentStatusLabel on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.pending => 'Pending',
        PaymentStatus.pendingVerification => 'Pending Verification',
        PaymentStatus.successful => 'Successful',
        PaymentStatus.partiallyPaid => 'Partially Paid',
        PaymentStatus.failed => 'Failed',
        PaymentStatus.refunded => 'Refunded',
        PaymentStatus.rejected => 'Rejected',
      };
}
```

(b) `PaymentMethod` enum + label extension (lines 25-34):

```dart
enum PaymentMethod { cashOnDelivery, bankTransfer, paybill, card, installment }

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cashOnDelivery => 'Cash on Delivery',
        PaymentMethod.bankTransfer => 'Bank Transfer',
        PaymentMethod.paybill => 'Paybill',
        PaymentMethod.card => 'Card',
        PaymentMethod.installment => 'Installment',
      };
}
```

(c) Add `OrderPaymentSummary` class after `OrderItem`:

```dart
class OrderPaymentSummary {
  const OrderPaymentSummary({required this.total, required this.verified, required this.pending, required this.remaining});

  factory OrderPaymentSummary.fromJson(Map<String, dynamic> json) => OrderPaymentSummary(
        total: (json['total'] as num?)?.toDouble() ?? 0,
        verified: (json['verified'] as num?)?.toDouble() ?? 0,
        pending: (json['pending'] as num?)?.toDouble() ?? 0,
        remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
      );

  final double total;
  final double verified;
  final double pending;
  final double remaining;
}
```

(d) `Order`: add field + parse `paymentSummary`; update `paymentStatus` switch to include `'pending_verification'`, `'partially_paid'`, `'rejected'`. Add a constructor param `this.paymentSummary = const OrderPaymentSummary(total: 0, verified: 0, pending: 0, remaining: 0),` and a field `final OrderPaymentSummary paymentSummary;`. In `fromJson`, the local variables `subtotal`, `discount`, `shippingFee` already exist — compute a `final orderTotal = subtotal - discount + shippingFee;` and pass:

```dart
      paymentSummary: json['paymentSummary'] is Map<String, dynamic>
          ? OrderPaymentSummary.fromJson(json['paymentSummary'] as Map<String, dynamic>)
          : OrderPaymentSummary(total: orderTotal, verified: 0, pending: 0, remaining: orderTotal),
```

(e) `Payment`: add fields + parse. Replace the `Payment` class body with:

```dart
class Payment {
  const Payment({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.amount,
    required this.method,
    required this.status,
    this.reference,
    this.orderNumber,
    this.customerName,
    this.paymentDate,
    this.confirmationMessage,
    this.note,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectedAt,
    this.rejectedBy,
    this.rejectReason,
    this.duplicateOf,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    final method = switch (json['method'] as String?) {
      'bank_transfer' => PaymentMethod.bankTransfer,
      'paybill' => PaymentMethod.paybill,
      'card' => PaymentMethod.card,
      'installment' => PaymentMethod.installment,
      _ => PaymentMethod.cashOnDelivery,
    };
    final status = switch (json['status'] as String?) {
      'successful' || 'paid' => PaymentStatus.successful,
      'pending_verification' => PaymentStatus.pendingVerification,
      'partially_paid' => PaymentStatus.partiallyPaid,
      'rejected' => PaymentStatus.rejected,
      'failed' => PaymentStatus.failed,
      'refunded' => PaymentStatus.refunded,
      _ => PaymentStatus.pending,
    };
    return Payment(
      id: json['id'] as String,
      orderId: json['orderId'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      method: method,
      status: status,
      reference: json['reference'] as String?,
      orderNumber: json['orderNumber'] as String?,
      customerName: json['customerName'] as String?,
      paymentDate: json['paymentDate'] as String?,
      confirmationMessage: json['confirmationMessage'] as String?,
      note: json['note'] as String?,
      verifiedAt: json['verifiedAt'] as String?,
      verifiedBy: json['verifiedBy'] as String?,
      rejectedAt: json['rejectedAt'] as String?,
      rejectedBy: json['rejectedBy'] as String?,
      rejectReason: json['rejectReason'] as String?,
      duplicateOf: json['duplicateOf'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  final String id;
  final String orderId;
  final String customerId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? reference;
  final String? orderNumber;
  final String? customerName;
  final String? paymentDate;
  final String? confirmationMessage;
  final String? note;
  final String? verifiedAt;
  final String? verifiedBy;
  final String? rejectedAt;
  final String? rejectedBy;
  final String? rejectReason;
  final String? duplicateOf;
  final DateTime? createdAt;
}
```

(f) `Installment`: add `approvedBy`, `approvedAt`, `rejectedBy`, `rejectedAt`, `rejectReason` fields (nullable String) and parse them in `fromJson`.

(g) Add `TransferDetails` at the end of the file:

```dart
class TransferDetails {
  const TransferDetails({required this.bankName, required this.paybillNumber, required this.accountNumber});

  factory TransferDetails.fromJson(Map<String, dynamic> json) => TransferDetails(
        bankName: json['bankName'] as String? ?? '',
        paybillNumber: json['paybillNumber'] as String? ?? '',
        accountNumber: json['accountNumber'] as String? ?? '',
      );

  final String bankName;
  final String paybillNumber;
  final String accountNumber;
}
```

- [ ] **Step 5: Run the model tests**

Run: `flutter test test/models/order_model_test.dart`. Expected: PASS.

- [ ] **Step 6: Analyze + commit**

Run: `flutter analyze`. Fix any warnings in edited files. Commit:

```bash
git add lib/models/order.dart lib/core/utils/currency.dart test/models/order_model_test.dart
git commit -m "feat: extend order/payment/installment models and add KSh formatting"
```

---

### Task 7: Flutter repositories — OrderRepository interface + API + mock

**Files:**
- Modify: `lib/data/repositories/commerce_repository.dart`
- Modify: `lib/data/repositories/api/api_order_repository.dart`
- Modify: `lib/data/mock/mock_commerce_repositories.dart`
- Test: `test/data/repositories/api_order_repository_test.dart`

**Interfaces:**
- Consumes: new model fields from Task 6.
- Produces on `OrderRepository`: `getPaymentsForOrder(String orderId)`, `getTransferDetails()`, `submitPayment(SubmitPaymentPayload)`, `getPayments({customerId})` (now via `GET /api/payments/`), `verifyPayment(String id)`, `rejectPayment(String id, {required String reason})`, `getInstallments({customerId})` (now via `GET /api/installments/`), `approveInstallment(String id)`, `rejectInstallment(String id, {required String reason})`, plus existing methods. New class `SubmitPaymentPayload { orderId, amount, paymentDate, reference?, confirmationMessage, note? }`.

- [ ] **Step 1: Write failing repo tests — extend `test/data/repositories/api_order_repository_test.dart`**

Append to the existing `main()`:

```dart
const paymentJson = '{"id": "pay1", "orderId": "o1", "customerId": "u1", "orderNumber": "QT-123",'
    '"customerName": "Amara", "amount": 52500, "method": "paybill", "status": "pending_verification",'
    '"reference": "MP-1", "paymentDate": "2026-08-17", "confirmationMessage": "Confirmed",'
    '"note": null, "verifiedAt": null, "verifiedBy": null, "rejectedAt": null, "rejectedBy": null,'
    '"rejectReason": null, "duplicateOf": null, "createdAt": "2026-08-17T10:00:00Z"}';

const installmentJson = '{"id": "i1", "orderId": "o1", "orderNumber": "QT-123", "customerId": "u1",'
    '"customerName": "Amara", "totalAmount": 52500, "amountPaid": 0, "status": "pending_approval",'
    '"termMonths": 3, "createdAt": "2026-08-17T10:00:00Z", "payments": [],'
    '"approvedBy": null, "approvedAt": null, "rejectedBy": null, "rejectedAt": null, "rejectReason": null}';

test('submitPayment posts to /api/payments and maps the payment', () async {
  final mock = MockClient((request) async {
    expect(request.url.path, '/api/payments');
    expect(request.method, 'POST');
    expect(request.body, contains('"orderId":"o1"'));
    expect(request.body, contains('"amount":52500'));
    expect(request.body, contains('"paymentDate":"2026-08-17"'));
    expect(request.body, contains('"confirmationMessage":"Confirmed"'));
    return http.Response('{"success": true, "data": $paymentJson}', 201,
        headers: {'content-type': 'application/json'});
  });
  final repo = ApiOrderRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
  final p = await repo.submitPayment(const SubmitPaymentPayload(
    orderId: 'o1',
    amount: 52500,
    paymentDate: '2026-08-17',
    reference: 'MP-1',
    confirmationMessage: 'Confirmed',
  ));
  expect(p.status, PaymentStatus.pendingVerification);
  expect(p.confirmationMessage, 'Confirmed');
});

test('getTransferDetails returns the paybill details', () async {
  final mock = MockClient((request) async {
    expect(request.url.path, '/api/payments/transfer-details');
    return http.Response(
        '{"success": true, "data": {"bankName": "Family Bank", "paybillNumber": "222111", "accountNumber": "65727"}}',
        200, headers: {'content-type': 'application/json'});
  });
  final repo = ApiOrderRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
  final t = await repo.getTransferDetails();
  expect(t.bankName, 'Family Bank');
  expect(t.paybillNumber, '222111');
  expect(t.accountNumber, '65727');
});

test('getPayments calls /api/payments and maps the list', () async {
  final mock = MockClient((request) async {
    expect(request.url.path, '/api/payments');
    return http.Response('{"success": true, "data": {"rows": [$paymentJson], "total": 1}}', 200,
        headers: {'content-type': 'application/json'});
  });
  final repo = ApiOrderRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
  final payments = await repo.getPayments();
  expect(payments, hasLength(1));
  expect(payments.first.id, 'pay1');
});

test('verifyPayment and rejectPayment call the right endpoints', () async {
  final mock = MockClient((request) async {
    expect(request.method, 'POST');
    if (request.url.path == '/api/payments/pay1/verify') {
      return http.Response('{"success": true, "data": $paymentJson}', 200,
          headers: {'content-type': 'application/json'});
    }
    expect(request.url.path, '/api/payments/pay1/reject');
    expect(request.body, contains('"reason":"fraud"'));
    return http.Response('{"success": true, "data": $paymentJson}', 200,
        headers: {'content-type': 'application/json'});
  });
  final repo = ApiOrderRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
  await repo.verifyPayment('pay1');
  await repo.rejectPayment('pay1', reason: 'fraud');
});

test('getInstallments calls /api/installments and maps the list', () async {
  final mock = MockClient((request) async {
    expect(request.url.path, '/api/installments');
    return http.Response('{"success": true, "data": {"rows": [$installmentJson], "total": 1}}', 200,
        headers: {'content-type': 'application/json'});
  });
  final repo = ApiOrderRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
  final plans = await repo.getInstallments();
  expect(plans, hasLength(1));
  expect(plans.first.status, InstallmentStatus.pendingApproval);
});

test('approveInstallment and rejectInstallment call the right endpoints', () async {
  final mock = MockClient((request) async {
    expect(request.method, 'POST');
    if (request.url.path == '/api/installments/i1/approve') {
      return http.Response('{"success": true, "data": $installmentJson}', 200,
          headers: {'content-type': 'application/json'});
    }
    expect(request.url.path, '/api/installments/i1/reject');
    expect(request.body, contains('"reason":"No"'));
    return http.Response('{"success": true, "data": $installmentJson}', 200,
        headers: {'content-type': 'application/json'});
  });
  final repo = ApiOrderRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
  await repo.approveInstallment('i1');
  await repo.rejectInstallment('i1', reason: 'No');
});
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/data/repositories/api_order_repository_test.dart`. Expected: compile errors (missing methods/classes).

- [ ] **Step 3: Update `lib/data/repositories/commerce_repository.dart`**

Add `SubmitPaymentPayload` after `CheckoutPayload`:

```dart
class SubmitPaymentPayload {
  const SubmitPaymentPayload({
    required this.orderId,
    required this.amount,
    required this.paymentDate,
    required this.confirmationMessage,
    this.reference,
    this.note,
  });

  final String orderId;
  final double amount;
  final String paymentDate;
  final String confirmationMessage;
  final String? reference;
  final String? note;
}
```

Extend the `OrderRepository` abstract:

```dart
abstract class OrderRepository {
  Future<List<Order>> getOrders({String? customerId});
  Future<Order?> getById(String id);
  Future<Order> placeOrder(CheckoutPayload payload);
  Future<List<Payment>> getPayments({String? customerId});
  Future<List<Payment>> getPaymentsForOrder(String orderId);
  Future<TransferDetails> getTransferDetails();
  Future<Payment> submitPayment(SubmitPaymentPayload payload);
  Future<Payment> verifyPayment(String id);
  Future<Payment> rejectPayment(String id, {required String reason});
  Future<List<Installment>> getInstallments({String? customerId});
  Future<Installment> approveInstallment(String id);
  Future<Installment> rejectInstallment(String id, {required String reason});
}
```

- [ ] **Step 4: Update `lib/data/repositories/api/api_order_repository.dart`**

Replace the `getPayments` body with a single call:

```dart
  @override
  Future<List<Payment>> getPayments({String? customerId}) async {
    final data = await _client.get('/api/payments');
    return _paymentsFromData(data);
  }

  List<Payment> _paymentsFromData(dynamic data) {
    if (data is Map<String, dynamic> && data['rows'] is List<dynamic>) {
      return (data['rows'] as List<dynamic>)
          .map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return (data as List<dynamic>)
        .map((e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Payment>> getPaymentsForOrder(String orderId) async {
    final data = await _client.get('/api/payments/orders/$orderId');
    return _paymentsFromData(data);
  }

  @override
  Future<TransferDetails> getTransferDetails() async {
    final data = await _client.get('/api/payments/transfer-details');
    return TransferDetails.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Payment> submitPayment(SubmitPaymentPayload payload) async {
    final data = await _client.post('/api/payments', body: {
      'orderId': payload.orderId,
      'amount': payload.amount,
      'paymentDate': payload.paymentDate,
      'confirmationMessage': payload.confirmationMessage,
      if (payload.reference != null) 'reference': payload.reference,
      if (payload.note != null) 'note': payload.note,
    });
    return Payment.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Payment> verifyPayment(String id) async {
    final data = await _client.post('/api/payments/$id/verify');
    return Payment.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Payment> rejectPayment(String id, {required String reason}) async {
    final data = await _client.post('/api/payments/$id/reject', body: {'reason': reason});
    return Payment.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Installment>> getInstallments({String? customerId}) async {
    final data = await _client.get('/api/installments');
    final List<Installment> plans;
    if (data is Map<String, dynamic> && data['rows'] is List<dynamic>) {
      plans = (data['rows'] as List<dynamic>)
          .map((e) => Installment.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      plans = (data as List<dynamic>)
          .map((e) => Installment.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return plans;
  }

  @override
  Future<Installment> approveInstallment(String id) async {
    final data = await _client.post('/api/installments/$id/approve');
    return Installment.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Installment> rejectInstallment(String id, {required String reason}) async {
    final data = await _client.post('/api/installments/$id/reject', body: {'reason': reason});
    return Installment.fromJson(data as Map<String, dynamic>);
  }
```

Delete the now-unused `_withOrderMeta` helper and the old per-order loop logic in `getPayments`/`getInstallments`.

Also update `_methodToApi` to handle the new `paybill` value (Dart exhaustiveness requires it after Task 6 adds the enum member):

```dart
  String _methodToApi(PaymentMethod method) => switch (method) {
        PaymentMethod.cashOnDelivery => 'cash_on_delivery',
        PaymentMethod.bankTransfer => 'bank_transfer',
        PaymentMethod.paybill => 'paybill',
        PaymentMethod.card => 'card',
        PaymentMethod.installment => 'installment',
      };
```

Also remove the now-unused `import '../../api/api_exception.dart';` if `getPayments` no longer catches `ApiException` (the new implementation in this task doesn't).

- [ ] **Step 5: Update `lib/data/mock/mock_commerce_repositories.dart`**

(a) In `MockOrderRepository.placeOrder`, make paybill/bank-transfer orders land in a "proof pending" state and include a payment summary so the detail screen shows the Pay button:

```dart
  @override
  Future<Order> placeOrder(CheckoutPayload payload) async {
    _orderSeq++;
    final orderTotal = payload.subtotal - payload.discount;
    final paid = payload.paymentMethod == PaymentMethod.card;
    final order = Order(
      id: 'ord-$_orderSeq',
      orderNumber: 'QT-${DateTime.now().year}-$_orderSeq',
      customerId: payload.customerEmail,
      customerName: payload.customerName,
      customerPhone: payload.customerPhone,
      customerEmail: payload.customerEmail,
      shippingAddress: payload.shippingAddress,
      items: payload.items,
      subtotal: payload.subtotal,
      discount: payload.discount,
      status: OrderStatus.pending,
      paymentStatus: paid ? PaymentStatus.successful : PaymentStatus.pending,
      paymentMethod: payload.paymentMethod,
      installmentRequested: payload.installmentRequested,
      createdAt: DateTime.now(),
      paymentSummary: OrderPaymentSummary(
        total: orderTotal,
        verified: paid ? orderTotal : 0,
        pending: 0,
        remaining: paid ? 0 : orderTotal,
      ),
    );
    _orders.add(order);
    return order;
  }
```

(b) Implement the new methods (mock behavior for walkthrough/tests) — reusing the existing in-memory `_payments` list:

```dart
  @override
  Future<List<Payment>> getPaymentsForOrder(String orderId) async {
    return _payments.where((p) => p.orderId == orderId).toList();
  }

  @override
  Future<TransferDetails> getTransferDetails() async {
    return const TransferDetails(
      bankName: 'Family Bank',
      paybillNumber: '222111',
      accountNumber: '65727',
    );
  }

  @override
  Future<Payment> submitPayment(SubmitPaymentPayload payload) async {
    final payment = Payment(
      id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
      orderId: payload.orderId,
      customerId: 'mock',
      amount: payload.amount,
      method: PaymentMethod.paybill,
      status: PaymentStatus.pendingVerification,
      reference: payload.reference,
      paymentDate: payload.paymentDate,
      confirmationMessage: payload.confirmationMessage,
      note: payload.note,
      createdAt: DateTime.now(),
    );
    _payments.add(payment);
    return payment;
  }

  @override
  Future<Payment> verifyPayment(String id) async {
    final idx = _payments.indexWhere((p) => p.id == id);
    final old = _payments[idx];
    _payments[idx] = Payment(
      id: old.id, orderId: old.orderId, customerId: old.customerId, amount: old.amount,
      method: old.method, status: PaymentStatus.successful, reference: old.reference,
      paymentDate: old.paymentDate, confirmationMessage: old.confirmationMessage,
      note: old.note, createdAt: old.createdAt,
    );
    return _payments[idx];
  }

  @override
  Future<Payment> rejectPayment(String id, {required String reason}) async {
    final idx = _payments.indexWhere((p) => p.id == id);
    final old = _payments[idx];
    _payments[idx] = Payment(
      id: old.id, orderId: old.orderId, customerId: old.customerId, amount: old.amount,
      method: old.method, status: PaymentStatus.rejected, reference: old.reference,
      paymentDate: old.paymentDate, confirmationMessage: old.confirmationMessage,
      note: old.note, rejectReason: reason, createdAt: old.createdAt,
    );
    return _payments[idx];
  }

  @override
  Future<Installment> approveInstallment(String id) async {
    return _setInstallmentStatus(id, InstallmentStatus.active);
  }

  @override
  Future<Installment> rejectInstallment(String id, {required String reason}) async {
    return _setInstallmentStatus(id, InstallmentStatus.rejected);
  }

  Installment _setInstallmentStatus(String id, InstallmentStatus status) {
    final idx = _installments.indexWhere((i) => i.id == id);
    final old = _installments[idx];
    final updated = Installment(
      id: old.id, orderId: old.orderId, orderNumber: old.orderNumber, customerId: old.customerId,
      customerName: old.customerName, totalAmount: old.totalAmount, amountPaid: old.amountPaid,
      schedule: old.schedule, status: status, termMonths: old.termMonths, createdAt: old.createdAt,
    );
    _installments[idx] = updated;
    return updated;
  }
```

(The `Installment` constructor's new nullable fields default to null, so the `_setInstallmentStatus` copy still compiles.)

- [ ] **Step 6: Run the repo tests**

Run: `flutter test test/data/repositories/api_order_repository_test.dart`. Expected: all pass.

- [ ] **Step 7: Analyze + commit**

Run: `flutter analyze`. Commit:

```bash
git add lib/data/repositories/commerce_repository.dart lib/data/repositories/api/api_order_repository.dart lib/data/mock/mock_commerce_repositories.dart test/data/repositories/api_order_repository_test.dart
git commit -m "feat: order repository payment/installment API methods"
```

---

### Task 8: Flutter wiring — shared OrderRepository provider, checkout uses provider, notifications API

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/customer/checkout/checkout_screen.dart`
- Create: `lib/data/repositories/api/api_notification_repository.dart`
- Modify: `lib/services/notification_service.dart`
- Test: `test/widget_test.dart` (existing) must still pass

**Interfaces:**
- Consumes: `buildApiRepositories(client)` (has `order`), `MockOrderRepository`.
- Produces: `Provider<OrderRepository>` in `main.dart`; `NotificationService(repo: ApiNotificationRepository?)` with `load()`; `CheckoutScreen` uses `context.read<OrderRepository>()` instead of `MockOrderRepository()`.

- [ ] **Step 1: Write failing test — add a unit test for `ApiNotificationRepository`**

Create `test/data/repositories/api_notification_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:botique/data/api/api_client.dart';
import 'package:botique/data/repositories/api/api_notification_repository.dart';

void main() {
  test('getNotifications maps the API list', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/notifications');
      return http.Response('{"success": true, "data": ['
          '{"id": "n1", "userId": "u1", "type": "payment", "title": "Paid", "body": "ok",'
          '"isRead": false, "createdAt": "2026-08-17T10:00:00Z"}]}', 200,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiNotificationRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    final list = await repo.getNotifications();
    expect(list, hasLength(1));
    expect(list.first.type, NotificationType.payment);
  });

  test('markRead patches the notification', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/notifications/n1/read');
      return http.Response('{"success": true, "data": null}', 200,
          headers: {'content-type': 'application/json'});
    });
    final repo = ApiNotificationRepository(ApiClient(baseUrl: 'http://localhost:8080', client: mock));
    await repo.markRead('n1');
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/data/repositories/api_notification_repository_test.dart`. Expected: file/class missing.

- [ ] **Step 3: Create `lib/data/repositories/api/api_notification_repository.dart`**

```dart
import '../../../models/notification.dart';
import '../../api/api_client.dart';
import '../notification_repository.dart';

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<StoreNotification>> getNotifications({bool unreadOnly = false}) async {
    final data = await _client.get('/api/notifications', query: {
      if (unreadOnly) 'unread': 'true',
    });
    return (data as List<dynamic>)
        .map((e) => StoreNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> markRead(String id) async {
    await _client.patch('/api/notifications/$id/read');
  }

  @override
  Future<void> markAllRead() async {
    await _client.patch('/api/notifications/read-all');
  }
}
```

- [ ] **Step 4: Create `lib/data/repositories/notification_repository.dart`**

```dart
import '../../models/notification.dart';

abstract class NotificationRepository {
  Future<List<StoreNotification>> getNotifications({bool unreadOnly = false});
  Future<void> markRead(String id);
  Future<void> markAllRead();
}
```

- [ ] **Step 5: Update `lib/services/notification_service.dart`**

Make it accept an optional repo and load from it:

```dart
import 'package:flutter/foundation.dart';

import '../data/repositories/notification_repository.dart';
import '../models/notification.dart';

class NotificationService extends ChangeNotifier {
  NotificationService({NotificationRepository? repo, bool useMockFallback = true})
      : _repo = repo,
        _useMockFallback = useMockFallback;

  final NotificationRepository? _repo;
  final bool _useMockFallback;
  List<StoreNotification> _notifications = [];

  List<StoreNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> load() async {
    if (_repo != null) {
      try {
        _notifications = await _repo!.getNotifications();
        notifyListeners();
        return;
      } on Object {
        // fall back to mock seed below if the API is unreachable
      }
    }
    if (_useMockFallback) {
      _notifications = _seed;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    await _repo?.markAllRead();
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    await _repo?.markRead(id);
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void push(StoreNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  static final List<StoreNotification> _seed = [
    StoreNotification(
      id: 'n1',
      type: NotificationType.promotion,
      title: 'Welcome to Queens\' Touch',
      body: 'Enjoy 10% off your first order with code QUEEN10.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    StoreNotification(
      id: 'n2',
      type: NotificationType.order,
      title: 'Your order is being prepared',
      body: 'We are carefully packaging your order. You will be notified when it ships.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    StoreNotification(
      id: 'n3',
      type: NotificationType.payment,
      title: 'Payment confirmed',
      body: 'Thank you! Your payment was received successfully.',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];
}
```

- [ ] **Step 6: Update `lib/main.dart`**

Add an `_orderRepo` field, provide it, and wire the notification service:

```dart
  late final CartRepository _cartRepo;
  late final WishlistRepository _wishlistRepo;
  late final OrderRepository _orderRepo;
  late final NotificationRepository _notificationRepo;

  @override
  void initState() {
    super.initState();
    final api = widget.useApi && widget.apiClient != null
        ? buildApiRepositories(widget.apiClient!)
        : null;
    _productRepo = api?.product ?? MockProductRepository();
    _categoryRepo = api?.category ?? MockCategoryRepository();
    _brandRepo = api?.brand ?? MockBrandRepository();
    _cartRepo = api?.cart ?? MockCartRepository();
    _wishlistRepo = api?.wishlist ?? MockWishlistRepository();
    _orderRepo = api?.order ?? MockOrderRepository();
    _notificationRepo = widget.apiClient != null
        ? ApiNotificationRepository(widget.apiClient!)
        : MockNotificationRepository();
  }
```

Import `MockNotificationRepository` (create it in the mock file as `implements NotificationRepository` returning the seed list) and `ApiNotificationRepository`. Then in `providers`:

```dart
        Provider<OrderRepository>(create: (_) => _orderRepo),
        ChangeNotifierProvider(
          create: (_) => NotificationService(repo: _notificationRepo)..load(),
        ),
```

Also import `package:provider/provider.dart` already present; ensure `Provider` import. Replace the existing `ChangeNotifierProvider(create: (_) => NotificationService())` line.

- [ ] **Step 7: Add `MockNotificationRepository` to `lib/data/mock/mock_commerce_repositories.dart`** (or a new `lib/data/mock/mock_notification_repository.dart`)

```dart
class MockNotificationRepository implements NotificationRepository {
  @override
  Future<List<StoreNotification>> getNotifications({bool unreadOnly = false}) async =>
      _seed.where((n) => !unreadOnly || !n.isRead).toList();

  @override
  Future<void> markRead(String id) async {}

  @override
  Future<void> markAllRead() async {}

  static final List<StoreNotification> _seed = [
    StoreNotification(
      id: 'n1',
      type: NotificationType.promotion,
      title: 'Welcome to Queens\' Touch',
      body: 'Enjoy 10% off your first order with code QUEEN10.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
}
```

- [ ] **Step 8: Update `lib/customer/checkout/checkout_screen.dart`**

(a) Replace `final repo = MockOrderRepository();` in `_placeOrder` with:

```dart
    final repo = context.read<OrderRepository>();
```

(b) Change the default `_method = PaymentMethod.card;` to `PaymentMethod.paybill;`.

(c) Pass `_orderRepo`-independent info to the confirmation screen: keep `_ConfirmationScreen(order: order)` — the Pay button flow is added in Task 9.

Remove the now-unused `import '../../data/mock/mock_commerce_repositories.dart';` if nothing else uses it.

- [ ] **Step 9: Run all Flutter tests + analyze**

Run: `flutter test` and `flutter analyze`. Expected: existing tests pass (widget_test may need a pump with the new providers — if `widget_test.dart` pumps `QueensTouchApp`, it still works because `NotificationService` defaults to mock fallback; fix only if a test breaks).

- [ ] **Step 10: Commit**

```bash
git add lib/main.dart lib/customer/checkout/checkout_screen.dart lib/data/repositories/api/api_notification_repository.dart lib/data/repositories/notification_repository.dart lib/services/notification_service.dart lib/data/mock test/data/repositories/api_notification_repository_test.dart
git commit -m "feat: wire shared order repository and API notifications"
```

---

### Task 9: Customer payment/installment screens

**Files:**
- Create: `lib/customer/orders/order_detail_screen.dart`
- Create: `lib/customer/orders/submit_payment_screen.dart`
- Modify: `lib/customer/account/account_screen.dart` (OrderHistoryScreen, PaymentHistoryScreen, InstallmentsScreen)
- Modify: `lib/customer/checkout/checkout_screen.dart` (`_ConfirmationScreen` Pay button)
- Modify: `lib/core/router/app_router.dart` (order detail route)

**Interfaces:**
- Consumes: `OrderRepository` (provider), `formatKsh`, `TransferDetails`, new `Payment`/`Order`/`Installment` fields.
- Produces: `OrderDetailScreen(orderId)` (public, takes `orderId`); `SubmitPaymentScreen(orderId, amount, orderNumber)`; account menu routes `/account/orders`, `/account/payments`, `/account/installments`; new route `account/order/:id` → `OrderDetailScreen`. All new screens display **KSh**.

- [ ] **Step 1: Write a widget test — create `test/customer/orders/order_detail_screen_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:botique/core/router/app_router.dart';
import 'package:botique/customer/orders/order_detail_screen.dart';
import 'package:botique/data/mock/mock_commerce_repositories.dart';
import 'package:botique/data/repositories/commerce_repository.dart';
import 'package:botique/models/order.dart';

void main() {
  testWidgets('order detail shows remaining balance in KSh and a Pay button', (tester) async {
    final repo = MockOrderRepository();
    final order = await repo.placeOrder(const CheckoutPayload(
      customerName: 'Amara',
      customerPhone: '080',
      customerEmail: 'a@b.c',
      shippingAddress: 'Lagos',
      paymentMethod: PaymentMethod.paybill,
      items: [OrderItem(productId: 'p1', productName: 'Dress', price: 50000, quantity: 1)],
      subtotal: 50000,
    ));
    await tester.pumpWidget(Provider<OrderRepository>(
      create: (_) => repo,
      child: MaterialApp(home: OrderDetailScreen(orderId: order.id)),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('KSh'), findsWidgets);
    expect(find.text('Pay'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/customer/orders/order_detail_screen_test.dart`. Expected: missing file.

- [ ] **Step 3: Create `lib/customer/orders/order_detail_screen.dart`**

Stateful screen loading the order by id via `context.read<OrderRepository>().getById(id)`. Layout (ListView):
1. Status header card: order number, status labels, total in KSh, `formatKsh(order.total)`.
2. Payment summary card: Verified / Pending / Remaining balance (KSh) from `order.paymentSummary`.
3. Payment instructions card (only when not fully paid and method != cashOnDelivery): "Pay via Family Bank Paybill", Paybill `222111`, Account `65727`, total due = remaining, and an `ElevatedButton` "Pay" that pushes `SubmitPaymentScreen(orderId, amount: remaining, orderNumber)`.
4. Installment card (if `order.installmentRequested`): fetch plan via `repo.getInstallments()` filtered by order id; show status + schedule list.
5. Items list with `formatKsh(item.lineTotal)`.
6. "Payment History" section listing `repo.getPaymentsForOrder(order.id)` with status chips (Successful green / Pending Verification amber / Rejected red) and confirmation message.

Use `FutureBuilder`/`StatefulWidget` with loading + error states consistent with existing screens (`product_detail_screen.dart`).

- [ ] **Step 4: Create `lib/customer/orders/submit_payment_screen.dart`**

Form screen: reads `TransferDetails` via `repo.getTransferDetails()`; shows instructions card; fields:
- Amount (TextFormField, `TextInputType.number`, prefilled with widget.amount).
- Payment date (show date picker via `showDatePicker`, format `yyyy-MM-dd`).
- M-Pesa/Family Bank reference (optional).
- Confirmation message (required, `minLines: 3`, hint "Paste the full confirmation message you received").
- Note (optional).
On submit: `repo.submitPayment(SubmitPaymentPayload(...))`, then `showSuccessSnack(context, 'Payment submitted for verification')` and `Navigator.pop(context, true)`.

- [ ] **Step 5: Update `lib/customer/account/account_screen.dart`**

Replace the three stub screens with real implementations:

`OrderHistoryScreen` → StatefulWidget: loads `repo.getOrders()`, `RefreshIndicator`, `ListView.separated` of `Card > ListTile` (orderNumber, `order.status.label`, `formatKsh(order.total)`, date), `onTap: () => context.push('/account/order/${order.id}')`, empty state preserved.

`PaymentHistoryScreen` → StatefulWidget: loads `repo.getPayments()`, list of `Card > ListTile` with `p.method.label`, `formatKsh(p.amount)`, status chip (reuse a local `_PaymentStatusChip`), subtitle `p.paymentDate ?? p.orderNumber`, trailing shows confirmation message if present. Empty state preserved.

`InstallmentsScreen` → StatefulWidget: loads `repo.getInstallments()`, list of expansion tiles showing `orderNumber`, status chip, total/paid/remaining in KSh, and the schedule (due date + paid check). Empty state preserved.

- [ ] **Step 6: Update `lib/customer/checkout/checkout_screen.dart` `_ConfirmationScreen`**

Inside the confirmation card, when `order.paymentMethod == PaymentMethod.paybill || order.paymentMethod == PaymentMethod.bankTransfer` add a "How to pay" block: Paybill `222111`, Account `65727`, Total `formatKsh(order.total)`, and a "Pay" `ElevatedButton` that pushes:

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => SubmitPaymentScreen(
      orderId: order.id,
      orderNumber: order.orderNumber,
      amount: order.total,
    ),
  ),
);
```

- [ ] **Step 7: Update `lib/core/router/app_router.dart`**

Add under the customer routes:

```dart
            GoRoute(
              path: 'account/order/:id',
              builder: (context, state) => OrderDetailScreen(
                orderId: state.pathParameters['id']!,
              ),
            ),
```

Import `../../customer/orders/order_detail_screen.dart`.

- [ ] **Step 8: Run the new widget test + existing suite**

Run: `flutter test test/customer/orders/order_detail_screen_test.dart` then `flutter test`. Expected: pass.

- [ ] **Step 9: Analyze + commit**

Run: `flutter analyze`. Commit:

```bash
git add lib/customer/orders lib/customer/account/account_screen.dart lib/customer/checkout/checkout_screen.dart lib/core/router/app_router.dart test/customer/orders/order_detail_screen_test.dart
git commit -m "feat: customer payment and installment screens"
```

---

### Task 10: Admin payments + installments + dashboard wiring

**Files:**
- Modify: `lib/admin/payments/payments_screen.dart`
- Modify: `lib/admin/installments/installments_screen.dart`
- Modify: `lib/admin/dashboard/dashboard_screen.dart`
- Test: `test/admin/payments_screen_test.dart` (create)

**Interfaces:**
- Consumes: `OrderRepository` (provider), `formatKsh`, `confirmDialog`, `showSuccessSnack`/`showErrorSnack`.
- Produces: `PaymentsScreen`/`InstallmentsScreen` become StatefulWidgets loading from `OrderRepository`; reject flows prompt for a reason; dashboard shows live pending counts.

- [ ] **Step 1: Write a widget test — create `test/admin/payments_screen_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:botique/admin/payments/payments_screen.dart';
import 'package:botique/data/mock/mock_commerce_repositories.dart';
import 'package:botique/data/repositories/commerce_repository.dart';

void main() {
  testWidgets('payments screen lists submissions and shows verify/reject actions', (tester) async {
    final repo = MockOrderRepository();
    final order = await repo.placeOrder(const CheckoutPayload(
      customerName: 'Amara', customerPhone: '080', customerEmail: 'a@b.c',
      shippingAddress: 'Lagos', paymentMethod: PaymentMethod.paybill,
      items: [OrderItem(productId: 'p1', productName: 'Dress', price: 100, quantity: 1)],
      subtotal: 100,
    ));
    await repo.submitPayment(const SubmitPaymentPayload(
      orderId: order.id, amount: 100, paymentDate: '2026-08-17',
      confirmationMessage: 'Confirmed',
    ));

    await tester.pumpWidget(Provider<OrderRepository>(
      create: (_) => repo,
      child: const MaterialApp(home: Scaffold(body: PaymentsScreen())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Paybill'), findsWidgets);
    expect(find.text('Verify'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/admin/payments_screen_test.dart`. Expected: fails (PaymentsScreen ignores repo).

- [ ] **Step 3: Rewrite `lib/admin/payments/payments_screen.dart`**

StatefulWidget with `late Future<List<Payment>> _future` initialized in `initState` from `context.read<OrderRepository>().getPayments()`. Build:
- Keep the search field + filter chips (filters now: All / Pending Verification / Successful / Rejected).
- `FutureBuilder` over `_future` → `RefreshIndicator` + `ListView.builder`.
- Each card: `p.orderNumber ?? p.orderId`, `p.customerName`, `formatKsh(p.amount)`, status chip, confirmation message, payment date, reference.
- When `p.status == PaymentStatus.pendingVerification`: "Verify" (confirmDialog → `repo.verifyPayment(p.id)` → reload + success snack) and "Reject" (prompt reason via dialog → `repo.rejectPayment(p.id, reason: ...)` → reload + snack).
- Reject reason prompt helper:

```dart
Future<String?> _promptReason(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reject payment'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'Reason for rejection'),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Reject'),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 4: Rewrite `lib/admin/installments/installments_screen.dart`**

StatefulWidget loading `repo.getInstallments()`. Keep the filter chips + expansion cards style, but:
- Show `formatKsh` everywhere instead of `$`.
- Approve/Reject buttons only for `InstallmentStatus.pendingApproval`: approve → confirmDialog → `repo.approveInstallment(id)` → reload; reject → `_promptReason` (same pattern as payments) → `repo.rejectInstallment(id, reason:)` → reload.
- Show `rejectReason` when rejected.

- [ ] **Step 5: Update `lib/admin/dashboard/dashboard_screen.dart`**

Convert `DashboardScreen` to a StatefulWidget that also loads `repo.getInstallments()` and `repo.getPayments()` and computes:
- `pendingInstallments = plans.where((p) => p.status == InstallmentStatus.pendingApproval).length`
- `pendingPayments = payments.where((p) => p.status == PaymentStatus.pendingVerification).length`

Wire the existing `_PendingCard(count: pendingInstallments, ...)` to the live value and add a second `_PendingCard`-style card for pending payments ("N payment(s) awaiting verification"). Keep the rest of `MockDashboardData` as-is.

- [ ] **Step 6: Run tests + analyze**

Run: `flutter test test/admin/payments_screen_test.dart` then `flutter test` and `flutter analyze`. Expected: pass, clean.

- [ ] **Step 7: Commit**

```bash
git add lib/admin/payments/payments_screen.dart lib/admin/installments/installments_screen.dart lib/admin/dashboard/dashboard_screen.dart test/admin/payments_screen_test.dart
git commit -m "feat: admin payments and installments from live API"
```

---

### Task 11: Full Flutter verification

**Files:** none changed (verification only).

- [ ] **Step 1: Run all Flutter tests**

Run: `flutter test`. Expected: all pass (existing 31 + new model/repo/widget tests).

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze`. Expected: no new issues (pre-existing warnings OK; flag them).

- [ ] **Step 3: Commit if any fixes were needed**

```bash
git add -A
git commit -m "test: payment/installment flutter coverage green"
```

---

### Task 12: Live migration + E2E + cleanup

**Files:**
- Apply: `database/migrations/2026-08-17-payments-installments.sql` to `queens1`
- Backend must be running (or started with `npm.cmd run dev` in `backend/`)

**Interfaces:** none new.

- [ ] **Step 1: Apply the migration to the live DB**

Run (Windows PowerShell, from repo root):

```powershell
$env:PGPASSWORD="password"
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U postgres -d queens1 -f "database\migrations\2026-08-17-payments-installments.sql"
```

Expected: psql reports success, no errors.

- [ ] **Step 2: Verify the live schema**

Run:

```powershell
$env:PGPASSWORD="password"
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U postgres -d queens1 -c "\d payments"
```

Expected: new columns present; no UNIQUE on `reference`.

- [ ] **Step 3: Start backend**

In `backend/` run: `npm.cmd run dev`. Confirm health: `curl.exe -s http://localhost:3000/health`.

- [ ] **Step 4: E2E payment flow (create order → submit → verify)**

Using customer `x-user-id=...201` and manager `...203`:

```powershell
$base = "http://localhost:3000"
$cust = @{"x-user-id"="00000000-0000-0000-0000-000000000201";"x-user-role"="customer"}
$mgr  = @{"x-user-id"="00000000-0000-0000-0000-000000000203";"x-user-role"="store_manager"}
# create order against a real active product variant (pick any product with stock)
curl.exe -s -X POST "$base/api/orders" -H "content-type: application/json" -H "x-user-id: 00000000-0000-0000-0000-000000000201" -H "x-user-role: customer" -d '{"customerName":"E2E Payment","customerPhone":"08000000000","customerEmail":"e2e@queenstouch.ng","shippingAddress":"E2E Lagos","paymentMethod":"paybill","items":[{productId, variantId, quantity:1}]}'
```

Record the returned `id`. Then submit a partial payment, verify by staff, and check order `paymentSummary`. Repeat with a second submission that completes the order → order status `paid`.

- [ ] **Step 5: E2E installment flow (checkout with installment → approve → pay off)**

Create an order with `installmentRequested: true`, `paymentMethod: "installment"`. Confirm `GET /api/installments` shows a `pending_approval` plan for that order. Approve via `POST /api/installments/<id>/approve` (manager). Submit + verify payments to cover the total; confirm the plan becomes `completed` and order `paid`.

- [ ] **Step 6: E2E reject + duplicate**

Submit a payment with a made-up reference; reject it via manager with a reason; confirm `rejected`. Submit a duplicate of an existing verified payment; confirm `duplicateOf` is set.

- [ ] **Step 7: Clean up test rows**

Delete all rows created in E2E (orders cascade to payments/installments; also remove the created `order_items`/`installments` via cascade). Use psql:

```sql
DELETE FROM orders WHERE customer_email = 'e2e@queenstouch.ng';
```

Verify with `curl.exe` that the orders list no longer includes them.

- [ ] **Step 8: Run full suites one final time**

Run `npm.cmd run test` + `npm.cmd run typecheck` (backend) and `flutter test` + `flutter analyze` (Flutter). Expected: green.

- [ ] **Step 9: Final report + commit any stragglers**

```bash
git add -A
git commit -m "feat: payments and installments complete with live E2E verified"
```

Report to the user: feature summary, test counts, live DB migration applied, E2E evidence, and the note that existing screens still use `$` while new screens use KSh (per spec).
```
