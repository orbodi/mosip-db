\c mosip_authdevice 

-- Simulate minimal authdevice data if tables exist (schema-adaptive)
DO $$
DECLARE
  n int := COALESCE(NULLIF(current_setting('app.sim_device_count', true), '')::int, 50);
BEGIN
  -- reg_device_type
  IF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='authdevice' AND table_name='reg_device_type'
  ) THEN
    INSERT INTO authdevice.reg_device_type (code, name, descr, is_active, cr_by, cr_dtimes)
    VALUES ('BIO', 'Biometric', 'Biometric Device', true, 'sim', now())
    ON CONFLICT DO NOTHING;
  END IF;

  -- reg_device_sub_type (if present)
  IF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='authdevice' AND table_name='reg_device_sub_type'
  ) THEN
    INSERT INTO authdevice.reg_device_sub_type (code, name, descr, reg_device_type_code, is_active, cr_by, cr_dtimes)
    VALUES ('FINGER', 'Fingerprint', 'Fingerprint Biometric', 'BIO', true, 'sim', now())
    ON CONFLICT DO NOTHING;
  END IF;

  -- registered_device_master or device_detail
  IF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='authdevice' AND table_name='registered_device_master'
  ) THEN
    INSERT INTO authdevice.registered_device_master (id, serial_no, make, model, reg_device_type_code, is_active, cr_by, cr_dtimes)
    SELECT gen_random_uuid(), 'SN'||to_char(now(),'YYYYMMDD')||lpad(i::text,6,'0'), 'MakeX', 'ModelY', 'BIO', true, 'sim', now()
    FROM generate_series(1, LEAST(n, 200)) s(i)
    ON CONFLICT DO NOTHING;
  ELSIF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema='authdevice' AND table_name='device_detail'
  ) THEN
    INSERT INTO authdevice.device_detail (id, serial_number, make, model, is_active, cr_by, cr_dtimes)
    SELECT gen_random_uuid(), 'SN'||to_char(now(),'YYYYMMDD')||lpad(i::text,6,'0'), 'MakeX', 'ModelY', true, 'sim', now()
    FROM generate_series(1, LEAST(n, 200)) s(i)
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


