-- Seed minimal master data if needed (idempotent-ish)
\c mosip_master 

-- Ensure a couple of zones/centers exist for references
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM master.zone WHERE code='Z1' AND lang_code='fra') THEN
    INSERT INTO master.zone (code,name,hierarchy_level,hierarchy_level_name,hierarchy_path,parent_zone_code,lang_code,is_active,cr_by,cr_dtimes)
    VALUES ('Z1','Zone-1',1,'Region','/Z1',NULL,'fra',true,'sim',now());
  END IF;
  -- Ensure a matching location exists for FK (location_code, lang_code)
  IF NOT EXISTS (SELECT 1 FROM master.location WHERE code='Z1' AND lang_code='fra') THEN
    INSERT INTO master.location (code,name,hierarchy_level,hierarchy_level_name,parent_loc_code,lang_code,is_active,cr_by,cr_dtimes)
    VALUES ('Z1','Zone-1',1,'Region',NULL,'fra',true,'sim',now());
  END IF;
  IF NOT EXISTS (SELECT 1 FROM master.registration_center WHERE id='RC1') THEN
    -- Ensure center type 'FIXED' exists in FRA
    IF NOT EXISTS (SELECT 1 FROM master.reg_center_type WHERE code='FIXED' AND lang_code='fra') THEN
      INSERT INTO master.reg_center_type (code,name,descr,lang_code,is_active,cr_by,cr_dtimes)
      VALUES ('FIXED','Fixed Center','Fixed Registration Center','fra',true,'sim',now());
    END IF;
    INSERT INTO master.registration_center (id,name,cntrtyp_code,addr_line1,latitude,longitude,location_code,contact_phone,contact_person,number_of_kiosks,working_hours,per_kiosk_process_time,center_start_time,center_end_time,lunch_start_time,lunch_end_time,time_zone,holiday_loc_code,zone_code,lang_code,is_active,cr_by,cr_dtimes)
    VALUES ('RC1','Center-1','FIXED','Addr',0,0,'Z1',NULL,'Ops',5,'08:00-17:00','00:10:00'::time,'08:00','17:00','12:00','13:00','UTC','Z1','Z1','fra',true,'sim',now());
  END IF;
END $$;


