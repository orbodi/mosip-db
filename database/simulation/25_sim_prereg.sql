\c mosip_prereg 

-- Simulate pre-registrations with defensive column handling
-- Usage: psql -v sim_prereg_count=300 -f 25_sim_prereg.sql
\set sim_prereg_count 300

DO $$
DECLARE
  n int := 300;
BEGIN
  BEGIN
    -- Variant A (common): columns (pre_reg_id, applicant_detail, status_code, lang_code, cr_by, cr_dtimes)
    INSERT INTO prereg.applicant_demographic (pre_reg_id, applicant_detail, status_code, lang_code, cr_by, cr_dtimes)
    SELECT 'PR' || to_char(now(), 'YYYYMMDD') || lpad(i::text,6,'0'),
           jsonb_build_object('fullName', 'John Doe '||i, 'phone', '99'||lpad(i::text,8,'0')),
           'CREATED','fra','sim', now() - (random()*'12 hours'::interval)
    FROM generate_series(1, n) s(i);
  EXCEPTION WHEN undefined_column OR undefined_table THEN
    BEGIN
      -- Variant B: (prereg_id, applicant_detail_json, status_code, lang_code, cr_by, cr_dtimes)
      INSERT INTO prereg.applicant_demographic (prereg_id, applicant_detail_json, status_code, lang_code, cr_by, cr_dtimes)
      SELECT 'PR' || to_char(now(), 'YYYYMMDD') || lpad(i::text,6,'0'),
             jsonb_build_object('fullName', 'John Doe '||i, 'phone', '99'||lpad(i::text,8,'0')),
             'CREATED','fra','sim', now() - (random()*'12 hours'::interval)
      FROM generate_series(1, n) s(i);
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'prereg.applicant_demographic simulation skipped: %', SQLERRM;
    END;
  END;

  -- Optionally insert into consumed table if exists
  BEGIN
    INSERT INTO prereg.applicant_demographic_consumed (prereg_id, consumed_dtimes)
    SELECT CASE WHEN EXISTS (
             SELECT 1 FROM information_schema.columns 
             WHERE table_schema='prereg' AND table_name='applicant_demographic' AND column_name IN ('pre_reg_id','prereg_id')
           ) THEN (
             SELECT COALESCE((SELECT pre_reg_id FROM prereg.applicant_demographic LIMIT 1), (SELECT prereg_id FROM prereg.applicant_demographic LIMIT 1))
           ) ELSE 'PR'||to_char(now(),'YYYYMMDD')||'000001' END,
           now()
    LIMIT 0; -- no-op placeholder to keep block valid if table exists with different structure
  EXCEPTION WHEN undefined_table THEN
    -- ignore if table not present
    NULL;
  END;
END $$;


