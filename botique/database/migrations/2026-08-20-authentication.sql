-- Queens' Touch — real authentication (JWT + scrypt)
-- Apply to queens1 AFTER the backend auth code is running: psql -f database/migrations/2026-08-20-authentication.sql
--
-- The users table already carries password_hash / is_active / roles, so no
-- schema changes are required. This migration only gives the seeded demo
-- accounts a known development password so staff can sign in with the real
-- login flow.
--
-- Dev password for all seeded demo accounts: Password123!
-- (scrypt hash below; format is scrypt:salt:hash)

UPDATE users
SET password_hash = 'scrypt:bd7134e3ecb7b3611a5882060e6a42b2:3f1cbe82425173b1e9a3ae6a6c1ab7fd197474cb5ef576e36f0d05fef8c317e74928b067b8a542f0b447470577fca9bc4550e8aefe675decdbb44987849ad6cb',
    updated_at = now()
WHERE id IN (
  '00000000-0000-0000-0000-000000000201', -- amara@example.com (customer)
  '00000000-0000-0000-0000-000000000202', -- admin@queenstouch.com
  '00000000-0000-0000-0000-000000000203', -- manager@queenstouch.com
  '00000000-0000-0000-0000-000000000204', -- sales@queenstouch.com
  '00000000-0000-0000-0000-000000000205'  -- inventory@queenstouch.com
);