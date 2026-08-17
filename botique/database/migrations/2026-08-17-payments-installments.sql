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
