\c mosip_resident 

-- Simulate minimal resident requests if tables exist (schema-adaptive)
DO $$
DECLARE
  n int := COALESCE(NULLIF(current_setting('app.sim_resident_req_count', true), '')::int, 100);
BEGIN
  -- print/download requests if present
  IF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='resident' AND table_name='print_request'
  ) THEN
    INSERT INTO resident.print_request (id, request_id, status_code, lang_code, cr_by, cr_dtimes)
    SELECT gen_random_uuid(), 'PR-'||to_char(now(),'YYYYMMDD')||lpad(i::text,6,'0'),
           CASE WHEN random()<0.85 THEN 'SUCCESS' ELSE 'FAILED' END,
           'fra','sim', now()
    FROM generate_series(1, n) s(i)
    ON CONFLICT DO NOTHING;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='resident' AND table_name='user_request'
  ) THEN
    INSERT INTO resident.user_request (id, request_type, status_code, lang_code, cr_by, cr_dtimes)
    SELECT gen_random_uuid(), 'DOWNLOAD',
           CASE WHEN random()<0.8 THEN 'SUCCESS' ELSE 'FAILED' END,
           'fra','sim', now()
    FROM generate_series(1, n) s(i)
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


