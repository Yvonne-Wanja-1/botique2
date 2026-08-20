-- Queens' Touch — real authentication (JWT + Argon2id)
-- Apply to queens1 AFTER the backend auth code is running: psql -f database/migrations/2026-08-20-authentication.sql
--
-- The users table already carries password_hash / is_active / roles, so no
-- schema changes are required. This migration only gives the seeded demo
-- accounts a known development password so staff can sign in with the real
-- login flow.
--
-- Dev password for all seeded demo accounts: Password123!
-- (argon2id hash below; parameters are embedded in the encoded string.)

UPDATE users
SET password_hash = '$argon2id$v=19$m=65536,p=4,t=3$ssJZsPl5WCXRvAToLl0HiA$ICiY3i0IN2LN+oXmrqeK1rd+j/Xfr3PviNexXdjUidg',
    updated_at = now()
WHERE id IN (
  '00000000-0000-0000-0000-000000000201', -- amara@example.com (customer)
  '00000000-0000-0000-0000-000000000202', -- admin@queenstouch.com
  '00000000-0000-0000-0000-000000000203', -- manager@queenstouch.com
  '00000000-0000-0000-0000-000000000204', -- sales@queenstouch.com
  '00000000-0000-0000-0000-000000000205'  -- inventory@queenstouch.com
);