\c mosip_prereg 

-- Additional prereg data simulation (schema-adaptive)
DO $$
DECLARE
  n int := 150;
BEGIN
  -- reg_appointment
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='prereg' AND table_name='reg_appointment') THEN
    -- detect pre-reg id column name
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='prereg' AND table_name='reg_appointment' AND column_name='pre_reg_id') THEN
      INSERT INTO prereg.reg_appointment (id, pre_reg_id, regcntr_id, appt_date, appt_time, lang_code, cr_by, cr_dtimes)
      SELECT gen_random_uuid(), 'PR'||to_char(now(),'YYYYMMDD')||lpad(i::text,6,'0'), 'RC1', now()::date + (i%7), '09:00', 'fra', 'sim', now()
      FROM generate_series(1, n) s(i)
      ON CONFLICT DO NOTHING;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='prereg' AND table_name='reg_appointment' AND column_name='prereg_id') THEN
      INSERT INTO prereg.reg_appointment (id, prereg_id, regcntr_id, appt_date, appt_time, lang_code, cr_by, cr_dtimes)
      SELECT gen_random_uuid(), 'PR'||to_char(now(),'YYYYMMDD')||lpad(i::text,6,'0'), 'RC1', now()::date + (i%7), '09:00', 'fra', 'sim', now()
      FROM generate_series(1, n) s(i)
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;

  -- applicant_demographic_consumed (if table has minimal columns)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='prereg' AND table_name='applicant_demographic_consumed') THEN
    INSERT INTO prereg.applicant_demographic_consumed (pre_reg_id, status_code, cr_by, cr_dtimes)
    SELECT 'PR'||to_char(now(),'YYYYMMDD')||lpad(i::text,6,'0'), 'CONSUMED', 'sim', now()
    FROM generate_series(1, n/3) s(i)
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


