-- Reviews moderation: new customer reviews must be reviewed before going public.
-- Aligns the live database with the updated schema.sql.
-- Existing rows are untouched.
-- 1) New reviews start pending instead of auto-approved.
ALTER TABLE reviews ALTER COLUMN is_approved SET DEFAULT FALSE;
-- 2) Distinguish "rejected" from "still pending" (both are is_approved = FALSE).
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS is_rejected BOOLEAN NOT NULL DEFAULT FALSE;