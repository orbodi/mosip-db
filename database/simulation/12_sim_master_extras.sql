\c mosip_master 

-- Additional master data simulation (schema-adaptive)
DO $$
DECLARE
  n int := 50;
  name_maxlen int;
  serial_maxlen int;
BEGIN
  -- locations / location
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='master' AND table_name='locations') THEN
    INSERT INTO master.locations (code,name,hierarchy_level,hierarchy_level_name,parent_loc_code,lang_code,is_active,cr_by,cr_dtimes)
    SELECT 'L'||i::text, 'Loc '||i, 1, 'Region', NULL, 'fra', true, 'sim', now()
    FROM generate_series(1, n) s(i)
    ON CONFLICT DO NOTHING;
  ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='master' AND table_name='location') THEN
    INSERT INTO master.location (code,name,hierarchy_level,hierarchy_level_name,parent_loc_code,lang_code,is_active,cr_by,cr_dtimes)
    SELECT 'L'||i::text, 'Loc '||i, 1, 'Region', NULL, 'fra', true, 'sim', now()
    FROM generate_series(1, n) s(i)
    ON CONFLICT DO NOTHING;
  END IF;

  -- zones / zone (level 1 only)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='master' AND table_name='zones') THEN
    INSERT INTO master.zones (code,name,hierarchy_level,hierarchy_level_name,hierarchy_path,parent_zone_code,lang_code,is_active,cr_by,cr_dtimes)
    SELECT 'Z'||i::text, 'Zone '||i, 1, 'Region', '/Z'||i::text, NULL, 'fra', true, 'sim', now()
    FROM generate_series(1, n) s(i)
    ON CONFLICT DO NOTHING;
  ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='master' AND table_name='zone') THEN
    INSERT INTO master.zone (code,name,hierarchy_level,hierarchy_level_name,hierarchy_path,parent_zone_code,lang_code,is_active,cr_by,cr_dtimes)
    SELECT 'Z'||i::text, 'Zone '||i, 1, 'Region', '/Z'||i::text, NULL, 'fra', true, 'sim', now()
    FROM generate_series(1, n) s(i)
    ON CONFLICT DO NOTHING;
  END IF;

  -- registration_center (fallback if not created by baseline)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='master' AND table_name='registration_center') THEN
    INSERT INTO master.registration_center (id,name,cntrtyp_code,addr_line1,latitude,longitude,location_code,contact_phone,contact_person,number_of_kiosks,working_hours,per_kiosk_process_time,center_start_time,center_end_time,lunch_start_time,lunch_end_time,time_zone,holiday_loc_code,zone_code,lang_code,is_active,cr_by,cr_dtimes)
    SELECT 'RCX'||lpad(i::text,3,'0'),'Center '||i,'FIXED','Addr',0,0,'Z1',NULL,'Ops',5,'08:00-17:00','00:10:00'::time,'08:00','17:00','12:00','13:00','UTC','Z1','Z1','fra',true,'sim',now()
    FROM generate_series(1, 5) s(i)
    ON CONFLICT DO NOTHING;
  END IF;

  -- dynamic_fields
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='master' AND table_name='dynamic_fields') THEN
    INSERT INTO master.dynamic_fields (id, field_key, field_label, lang_code, is_active, cr_by, cr_dtimes)
    SELECT gen_random_uuid(), 'key_'||i, 'Label '||i, 'fra', true, 'sim', now()
    FROM generate_series(1, 10) s(i)
    ON CONFLICT DO NOTHING;
  END IF;

  -- doc_category and doc_types
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='master' AND table_name='doc_category') THEN
    INSERT INTO master.doc_category (code,name,descr,lang_code,is_active,cr_by,cr_dtimes)
    VALUES ('ID','Identity','Identity Docs','fra',true,'sim',now()) ON CONFLICT DO NOTHING;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='master' AND table_name='doc_types') THEN
    INSERT INTO master.doc_types (code,name,descr,category_code,lang_code,is_active,cr_by,cr_dtimes)
    VALUES ('NATID','National ID','National ID Card','ID','fra',true,'sim',now()) ON CONFLICT DO NOTHING;
  END IF;

  -- applicant_valid_document (schema may differ; insert only if expected columns exist)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='master' AND table_name='applicant_valid_document')
     AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='applicant_valid_document' AND column_name='applicant_type')
     AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='applicant_valid_document' AND column_name='doc_category')
     AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='master' AND table_name='applicant_valid_document' AND column_name='doc_type')
  THEN
    INSERT INTO master.applicant_valid_document (applicant_type, doc_category, doc_type, lang_code, is_active, cr_by, cr_dtimes)
    VALUES ('ADULT','ID','NATID','fra',true,'sim',now())
    ON CONFLICT DO NOTHING;
  END IF;

  -- machines / machine_master
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='master' AND table_name='machines') THEN
      SELECT COALESCE(character_maximum_length, 255) INTO name_maxlen FROM information_schema.columns WHERE table_schema='master' AND table_name='machines' AND column_name='name';
      SELECT COALESCE(character_maximum_length, 255) INTO serial_maxlen FROM information_schema.columns WHERE table_schema='master' AND table_name='machines' AND column_name='serial_num';
      INSERT INTO master.machines (id,name,serial_num,zone_code,lang_code,is_active,cr_by,cr_dtimes)
      SELECT gen_random_uuid(),
             LEFT('M'||i::text, name_maxlen),
             LEFT('S'||lpad(i::text, GREATEST(LEAST(serial_maxlen-1, 6), 1), '0'), serial_maxlen),
             'Z1','fra',true,'sim',now()
      FROM generate_series(1, 10) s(i)
      ON CONFLICT DO NOTHING;
    ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='master' AND table_name='machine_master') THEN
      SELECT COALESCE(character_maximum_length, 255) INTO name_maxlen FROM information_schema.columns WHERE table_schema='master' AND table_name='machine_master' AND column_name='name';
      SELECT COALESCE(character_maximum_length, 255) INTO serial_maxlen FROM information_schema.columns WHERE table_schema='master' AND table_name='machine_master' AND column_name='serial_num';
      INSERT INTO master.machine_master (id,name,serial_num,zone_code,lang_code,is_active,cr_by,cr_dtimes)
      SELECT gen_random_uuid(),
             LEFT('M'||i::text, name_maxlen),
             LEFT('S'||lpad(i::text, GREATEST(LEAST(serial_maxlen-1, 6), 1), '0'), serial_maxlen),
             'Z1','fra',true,'sim',now()
      FROM generate_series(1, 10) s(i)
      ON CONFLICT DO NOTHING;
  END IF;
END $$;


