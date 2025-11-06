\c mosip_iam 

-- Simulate minimal IAM data (users/roles) if tables exist (schema-adaptive)
DO $$
DECLARE
  n int := COALESCE(NULLIF(current_setting('app.sim_iam_user_count', true), '')::int, 10);
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='iam' AND table_name='user'
  ) THEN
    INSERT INTO iam.user (id, user_name, email, is_active, cr_by, cr_dtimes)
    SELECT gen_random_uuid(), 'simuser'||lpad(i::text,3,'0'), 'sim'||lpad(i::text,3,'0')||'@example.org', true, 'sim', now()
    FROM generate_series(1, n) s(i)
    ON CONFLICT DO NOTHING;
  ELSIF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='iam' AND table_name='users'
  ) THEN
    INSERT INTO iam.users (id, user_name, email, is_active, cr_by, cr_dtimes)
    SELECT gen_random_uuid(), 'simuser'||lpad(i::text,3,'0'), 'sim'||lpad(i::text,3,'0')||'@example.org', true, 'sim', now()
    FROM generate_series(1, n) s(i)
    ON CONFLICT DO NOTHING;
  END IF;

  -- Optionally assign roles if mapping table exists
  IF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='iam' AND table_name='user_role'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='iam' AND table_name='role'
  ) THEN
    INSERT INTO iam.role (code, name, descr, is_active, cr_by, cr_dtimes)
    VALUES ('SIM_OPS', 'Simulation Operator', 'Role for simulation', true, 'sim', now())
    ON CONFLICT DO NOTHING;

    INSERT INTO iam.user_role (id, user_id, role_code, is_active, cr_by, cr_dtimes)
    SELECT gen_random_uuid(), u.id, 'SIM_OPS', true, 'sim', now()
    FROM (
      SELECT id FROM iam.user
      UNION ALL
      SELECT id FROM iam.users
    ) u
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


