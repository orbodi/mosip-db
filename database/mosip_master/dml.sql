\c mosip_master 
SET client_encoding TO 'UTF8';

-------------- Level 1 data load scripts ------------------------

----- TRUNCATE master.app_detail TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.app_detail cascade ;

\COPY master.app_detail (id,name,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-app_detail.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.authentication_method TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.authentication_method cascade ;

\COPY master.authentication_method (code,method_seq,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-authentication_method.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.biometric_type TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.biometric_type cascade ;

\COPY master.biometric_type (code,name,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-biometric_type.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.doc_category TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.doc_category cascade ;

\COPY master.doc_category (code,name,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-doc_category.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.gender TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.gender cascade ;

\COPY master.gender (code,name,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-gender.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.module_detail TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.module_detail cascade ;

\COPY master.module_detail (id,name,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-module_detail.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.process_list TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.process_list cascade ;

\COPY master.process_list (id,name,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-process_list.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.reason_category TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.reason_category cascade ;

\COPY master.reason_category (code,name,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-reason_category.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.role_list TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.role_list cascade ;

\COPY master.role_list (code,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-role_list.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.status_type TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.status_type cascade ;

\COPY master.status_type (code,name,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-status_type.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.template_file_format TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.template_file_format cascade ;

\COPY master.template_file_format (code,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-template_file_format.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.template_type TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.template_type cascade ;

\COPY master.template_type (code,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-template_type.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.daysofweek_list TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.daysofweek_list cascade ;

\COPY master.daysofweek_list (code,name,day_seq,is_global_working,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-daysofweek_list.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.loc_hierarchy_list TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.loc_hierarchy_list cascade ;

\COPY master.loc_hierarchy_list (hierarchy_level,hierarchy_level_name,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-loc_hierarchy_list.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.sync_job_def TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.sync_job_def  cascade ;

\COPY master.sync_job_def (ID,NAME,API_NAME,PARENT_SYNCJOB_ID,SYNC_FREQ,LOCK_DURATION,LANG_CODE,IS_ACTIVE,CR_BY,CR_DTIMES,UPD_BY,UPD_DTIMES,IS_DELETED,DEL_DTIMES,JOB_TYPE) FROM './dml/master-sync_job_def.csv' delimiter ',' HEADER  csv;

-------------- Level 2 data load scripts ------------------------

----- TRUNCATE master.app_authentication_method TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.app_authentication_method cascade ;

-- Stage then insert with lang_code normalized to match existing authentication_method
DROP TABLE IF EXISTS _app_auth_m_stg;
CREATE TEMP TABLE _app_auth_m_stg (
    app_id character varying(36),
    process_id character varying(36),
    role_code character varying(36),
    auth_method_code character varying(36),
    method_seq smallint,
    lang_code character varying(3),
    is_active boolean,
    cr_by character varying(256),
    cr_dtimes timestamp
);
\COPY _app_auth_m_stg (app_id,process_id,role_code,auth_method_code,method_seq,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-app_authentication_method.csv' delimiter ',' HEADER  csv;
INSERT INTO master.app_authentication_method (app_id,process_id,role_code,auth_method_code,method_seq,lang_code,is_active,cr_by,cr_dtimes)
SELECT s.app_id,
       s.process_id,
       s.role_code,
       s.auth_method_code,
       s.method_seq,
       'fra'::character varying(3) AS lang_code,
       s.is_active,
       s.cr_by,
       s.cr_dtimes
FROM _app_auth_m_stg s
JOIN master.authentication_method am
  ON am.code = s.auth_method_code AND am.lang_code = 'fra'
JOIN master.role_list rl
  ON rl.code = s.role_code AND rl.lang_code = 'fra';

----- TRUNCATE master.app_role_priority TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.app_role_priority cascade ;

\COPY master.app_role_priority (app_id,process_id,role_code,priority,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-app_role_priority.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.biometric_attribute TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.biometric_attribute cascade ;

\COPY master.biometric_attribute (code,name,descr,bmtyp_code,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-biometric_attribute.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.screen_detail TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.screen_detail cascade ;

\COPY master.screen_detail (id,app_id,name,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-screen_detail.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.status_list TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.status_list cascade ;

\COPY master.status_list (code,descr,sttyp_code,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-status_list.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.template TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.template cascade ;

\COPY master.template (id,name,descr,file_format_code,model,file_txt,module_id,module_name,template_typ_code,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-template.csv' delimiter ',' HEADER  csv;

-------------- Level 3 data load scripts ------------------------

----- TRUNCATE master.screen_authorization TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.screen_authorization cascade ;

\COPY master.screen_authorization (screen_id,role_code,lang_code,is_permitted,is_active,cr_by,cr_dtimes) FROM './dml/master-screen_authorization.csv' delimiter ',' HEADER  csv;

-------------- Level 4 data load scripts ------------------------

-- Moved after doc_type/doc_category to satisfy FK constraints

----- TRUNCATE master.blacklisted_words TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.blacklisted_words cascade ;

\COPY master.blacklisted_words (word,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-blacklisted_words.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.device_type TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.device_type cascade ;

\COPY master.device_type (code,name,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-device_type.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.device_spec TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.device_spec cascade ;

\COPY master.device_spec (id,name,brand,model,dtyp_code,min_driver_ver,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-device_spec.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.device_master_h TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.device_master_h cascade ;

-- Load into a staging table to deduplicate by id, then insert distinct rows
DROP TABLE IF EXISTS _device_master_h_stg;
CREATE TEMP TABLE _device_master_h_stg (
    id character varying(36),
    name character varying(64),
    mac_address character varying(64),
    serial_num character varying(64),
    ip_address character varying(17),
    dspec_id character varying(36),
    zone_code character varying(36),
    lang_code character varying(3),
    is_active boolean,
    cr_by character varying(256),
    cr_dtimes timestamp,
    eff_dtimes timestamp
);

\COPY _device_master_h_stg (id,name,mac_address,serial_num,ip_address,dspec_id,zone_code,lang_code,is_active,cr_by,cr_dtimes,eff_dtimes) FROM './dml/master-device_master_h.csv' delimiter ',' HEADER  csv;

INSERT INTO master.device_master_h (id,name,mac_address,serial_num,ip_address,dspec_id,zone_code,lang_code,is_active,cr_by,cr_dtimes,eff_dtimes)
SELECT DISTINCT ON (id)
       id,name,mac_address,serial_num,ip_address,dspec_id,zone_code,'fra'::character varying,is_active,cr_by,cr_dtimes,eff_dtimes
FROM _device_master_h_stg
ORDER BY id, eff_dtimes;

----- TRUNCATE master.device_master TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.device_master cascade ;

-- Deduplicate device_master by id; prefer a single row per id and force lang_code='fra'
DROP TABLE IF EXISTS _device_master_stg;
CREATE TEMP TABLE _device_master_stg (
    id character varying(36),
    name character varying(64),
    mac_address character varying(64),
    serial_num character varying(64),
    ip_address character varying(17),
    dspec_id character varying(36),
    zone_code character varying(36),
    lang_code character varying(3),
    is_active boolean,
    cr_by character varying(256),
    cr_dtimes timestamp
);

\COPY _device_master_stg (id,name,mac_address,serial_num,ip_address,dspec_id,zone_code,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-device_master.csv' delimiter ',' HEADER  csv;

INSERT INTO master.device_master (id,name,mac_address,serial_num,ip_address,dspec_id,zone_code,lang_code,is_active,cr_by,cr_dtimes)
SELECT DISTINCT ON (s.name)
       s.id,s.name,s.mac_address,s.serial_num,s.ip_address,s.dspec_id,s.zone_code,'fra'::character varying,s.is_active,s.cr_by,s.cr_dtimes
FROM _device_master_stg s
WHERE EXISTS (
  SELECT 1 FROM master.zone z
  WHERE z.code = s.zone_code AND z.lang_code = 'fra'
)
ORDER BY s.name, s.cr_dtimes;

----- TRUNCATE master.doc_type TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.doc_type cascade ;

\COPY master.doc_type (code,name,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-doc_type.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.applicant_valid_document TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.applicant_valid_document cascade ;

\COPY master.applicant_valid_document (apptyp_code,doccat_code,doctyp_code,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-applicant_valid_document.csv' delimiter ',' HEADER  csv;

TRUNCATE TABLE master.id_type cascade ;

\COPY master.id_type (code,name,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-id_type.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.individual_type TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.individual_type cascade ;

\COPY master.individual_type (code,name,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-individual_type.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.language TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.language cascade ;

\COPY master.language (code,name,family,native_name,is_active,cr_by,cr_dtimes) FROM './dml/master-language.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.loc_holiday TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.loc_holiday cascade ;

-- Deduplicate loc_holiday by (holiday_date, location_code); force lang_code='fra'
DROP TABLE IF EXISTS _loc_holiday_stg;
CREATE TEMP TABLE _loc_holiday_stg (
    id integer,
    location_code character varying(36),
    holiday_date date,
    holiday_name character varying(64),
    holiday_desc character varying(128),
    lang_code character varying(3),
    is_active boolean,
    cr_by character varying(256),
    cr_dtimes timestamp
);

\COPY _loc_holiday_stg (id,location_code,holiday_date,holiday_name,holiday_desc,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-loc_holiday.csv' delimiter ',' HEADER  csv;

INSERT INTO master.loc_holiday (id,location_code,holiday_date,holiday_name,holiday_desc,lang_code,is_active,cr_by,cr_dtimes)
SELECT DISTINCT ON (holiday_date, location_code)
       id,location_code,holiday_date,holiday_name,holiday_desc,'fra'::character varying,is_active,cr_by,cr_dtimes
FROM _loc_holiday_stg s
WHERE EXISTS (
    SELECT 1 FROM master.location l
    WHERE l.code = s.location_code AND l.lang_code = 'fra'
)
ORDER BY holiday_date, location_code, cr_dtimes;

----- TRUNCATE master.location TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.location cascade ;

-- Load into staging to normalize hierarchy_level_name encoding and values
DROP TABLE IF EXISTS _location_stg;
CREATE TEMP TABLE _location_stg (
    code character varying(36),
    name character varying(128),
    hierarchy_level smallint,
    hierarchy_level_name text,
    parent_loc_code character varying(36),
    lang_code character varying(3),
    is_active boolean,
    cr_by character varying(256),
    cr_dtimes timestamp
);

\COPY _location_stg (code,name,hierarchy_level,hierarchy_level_name,parent_loc_code,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-location.csv' delimiter ',' HEADER  csv;

INSERT INTO master.location (code,name,hierarchy_level,hierarchy_level_name,parent_loc_code,lang_code,is_active,cr_by,cr_dtimes)
SELECT s.code,
       s.name,
       s.hierarchy_level,
       CASE s.lang_code
         WHEN 'fra' THEN CASE s.hierarchy_level
             WHEN 0 THEN 'Pays'
             WHEN 1 THEN 'Region'
             WHEN 2 THEN 'Prefecture'
             WHEN 3 THEN 'Commune'
             WHEN 4 THEN 'Canton'
             WHEN 5 THEN 'Locality'
           END
         ELSE CASE s.hierarchy_level
             WHEN 0 THEN 'Country'
             WHEN 1 THEN 'Region'
             WHEN 2 THEN 'Prefecture'
             WHEN 3 THEN 'Commune'
             WHEN 4 THEN 'Canton'
             WHEN 5 THEN 'Locality'
           END
       END AS hierarchy_level_name,
       NULLIF(s.parent_loc_code,'') AS parent_loc_code,
       s.lang_code,
       s.is_active,
       s.cr_by,
       s.cr_dtimes
FROM _location_stg s;

----- TRUNCATE master.machine_type TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.machine_type cascade ;

\COPY master.machine_type (code,name,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-machine_type.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.machine_spec TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.machine_spec cascade ;

-- Deduplicate machine_spec by id; prefer one row per id and force lang_code='fra'
DROP TABLE IF EXISTS _machine_spec_stg;
CREATE TEMP TABLE _machine_spec_stg (
    id character varying(36),
    name character varying(64),
    brand character varying(32),
    model character varying(16),
    mtyp_code character varying(36),
    min_driver_ver character varying(16),
    descr character varying(256),
    lang_code character varying(3),
    is_active boolean,
    cr_by character varying(256),
    cr_dtimes timestamp
);

\COPY _machine_spec_stg (id,name,brand,model,mtyp_code,min_driver_ver,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-machine_spec.csv' delimiter ',' HEADER  csv;

INSERT INTO master.machine_spec (id,name,brand,model,mtyp_code,min_driver_ver,descr,lang_code,is_active,cr_by,cr_dtimes)
SELECT DISTINCT ON (id)
       id,name,brand,model,mtyp_code,min_driver_ver,descr,'fra'::character varying,is_active,cr_by,cr_dtimes
FROM _machine_spec_stg
ORDER BY id, cr_dtimes;

----- TRUNCATE master.machine_master_h TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.machine_master_h cascade ;

-- Deduplicate machine_master_h by (id, eff_dtimes); keep one per pair and force lang_code='fra'
DROP TABLE IF EXISTS _machine_master_h_stg;
CREATE TEMP TABLE _machine_master_h_stg (
    id character varying(10),
    name character varying(64),
    mac_address character varying(64),
    serial_num character varying(64),
    ip_address character varying(17),
    mspec_id character varying(36),
    zone_code character varying(36),
    lang_code character varying(3),
    is_active boolean,
    cr_by character varying(256),
    cr_dtimes timestamp,
    eff_dtimes timestamp
);

\COPY _machine_master_h_stg (id,name,mac_address,serial_num,ip_address,mspec_id,zone_code,lang_code,is_active,cr_by,cr_dtimes,eff_dtimes) FROM './dml/master-machine_master_h.csv' delimiter ',' HEADER  csv;

INSERT INTO master.machine_master_h (id,name,mac_address,serial_num,ip_address,mspec_id,zone_code,lang_code,is_active,cr_by,cr_dtimes,eff_dtimes)
SELECT DISTINCT ON (id, eff_dtimes)
       id,name,mac_address,serial_num,ip_address,mspec_id,zone_code,'fra'::character varying,is_active,cr_by,cr_dtimes,eff_dtimes
FROM _machine_master_h_stg
ORDER BY id, eff_dtimes, cr_dtimes;

----- TRUNCATE master.machine_master TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.machine_master cascade ;

-- Deduplicate machine_master by unique name; prefer one row per name and force lang_code='fra'
DROP TABLE IF EXISTS _machine_master_stg2;
CREATE TEMP TABLE _machine_master_stg2 (
    id character varying(10),
    name character varying(64),
    mac_address character varying(64),
    serial_num character varying(64),
    ip_address character varying(17),
    mspec_id character varying(36),
    zone_code character varying(36),
    lang_code character varying(3),
    is_active boolean,
    cr_by character varying(256),
    cr_dtimes timestamp
);

\COPY _machine_master_stg2 (id,name,mac_address,serial_num,ip_address,mspec_id,zone_code,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-machine_master.csv' delimiter ',' HEADER  csv;

INSERT INTO master.machine_master (id,name,mac_address,serial_num,ip_address,mspec_id,zone_code,lang_code,is_active,cr_by,cr_dtimes)
SELECT DISTINCT ON (name)
       id,name,mac_address,serial_num,ip_address,mspec_id,zone_code,'fra'::character varying,is_active,cr_by,cr_dtimes
FROM _machine_master_stg2
ORDER BY name, cr_dtimes;

----- TRUNCATE master.reason_list TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.reason_list cascade ;

\COPY master.reason_list (code,name,descr,rsncat_code,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-reason_list.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.reg_center_type TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.reg_center_type cascade ;

\COPY master.reg_center_type (code,name,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-reg_center_type.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.reg_center_device_h TABLE Data and It's reference Data and COPY Data from CSV file -----
-- SKIP: reg_center_device_h (DDL not present)
-- TRUNCATE TABLE master.reg_center_device_h cascade ;
-- \COPY master.reg_center_device_h (regcntr_id,device_id,lang_code,is_active,cr_by,cr_dtimes,eff_dtimes) FROM './dml/master-reg_center_device_h.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.reg_center_device TABLE Data and It's reference Data and COPY Data from CSV file -----
-- SKIP: reg_center_device (DDL not present)
-- TRUNCATE TABLE master.reg_center_device cascade ;
-- \COPY master.reg_center_device (regcntr_id,device_id,lang_code,is_active,cr_by,cr_dtimes,eff_dtimes) FROM './dml/master-reg_center_device.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.reg_center_machine_h TABLE Data and It's reference Data and COPY Data from CSV file -----
-- SKIP: reg_center_machine_h (DDL not present)
-- TRUNCATE TABLE master.reg_center_machine_h cascade ;
-- \COPY master.reg_center_machine_h (regcntr_id,machine_id,lang_code,is_active,cr_by,cr_dtimes,eff_dtimes) FROM './dml/master-reg_center_machine_h.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.reg_center_machine TABLE Data and It's reference Data and COPY Data from CSV file -----
-- SKIP: reg_center_machine (DDL not present)
-- TRUNCATE TABLE master.reg_center_machine cascade ;
-- \COPY master.reg_center_machine (regcntr_id,machine_id,lang_code,is_active,cr_by,cr_dtimes,eff_dtimes) FROM './dml/master-reg_center_machine.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.reg_center_machine_device_h TABLE Data and It's reference Data and COPY Data from CSV file -----
-- SKIP: reg_center_machine_device_h (DDL not present)
-- TRUNCATE TABLE master.reg_center_machine_device_h cascade ;
-- \COPY master.reg_center_machine_device_h (regcntr_id,machine_id,device_id,lang_code,is_active,cr_by,cr_dtimes,eff_dtimes) FROM './dml/master-reg_center_machine_device_h.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.reg_center_machine_device TABLE Data and It's reference Data and COPY Data from CSV file -----
-- SKIP: reg_center_machine_device (DDL not present)
-- TRUNCATE TABLE master.reg_center_machine_device cascade ;
-- \COPY master.reg_center_machine_device (regcntr_id,machine_id,device_id,lang_code,is_active,cr_by,cr_dtimes,eff_dtimes) FROM './dml/master-reg_center_machine_device.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.reg_center_user_h TABLE Data and It's reference Data and COPY Data from CSV file -----
-- SKIP: reg_center_user_h (DDL not present)
-- TRUNCATE TABLE master.reg_center_user_h cascade ;
-- \COPY master.reg_center_user_h (regcntr_id,user_id,lang_code,is_active,cr_by,cr_dtimes,eff_dtimes) FROM './dml/master-reg_center_user_h.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.reg_center_user TABLE Data and It's reference Data and COPY Data from CSV file -----
-- SKIP: reg_center_user (DDL not present)
-- TRUNCATE TABLE master.reg_center_user cascade ;
-- \COPY master.reg_center_user (regcntr_id,user_id,lang_code,is_active,cr_by,cr_dtimes,eff_dtimes) FROM './dml/master-reg_center_user.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.reg_center_user_machine_h TABLE Data and It's reference Data and COPY Data from CSV file -----
-- SKIP: reg_center_user_machine_h (DDL not present)
-- TRUNCATE TABLE master.reg_center_user_machine_h cascade ;
-- \COPY master.reg_center_user_machine_h (regcntr_id,user_id,machine_id,lang_code,is_active,cr_by,cr_dtimes,eff_dtimes) FROM './dml/master-reg_center_user_machine_h.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.reg_center_user_machine TABLE Data and It's reference Data and COPY Data from CSV file -----
-- SKIP: reg_center_user_machine (DDL not present)
-- TRUNCATE TABLE master.reg_center_user_machine cascade ;
-- \COPY master.reg_center_user_machine (regcntr_id,user_id,machine_id,lang_code,is_active,cr_by,cr_dtimes,eff_dtimes) FROM './dml/master-reg_center_user_machine.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.title TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.title cascade ;

\COPY master.title (code,name,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-title.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.user_detail_h TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.user_detail_h cascade ;

-- Stage CSV (has extra columns) then insert only required fields
DROP TABLE IF EXISTS _user_detail_h_stg;
CREATE TEMP TABLE _user_detail_h_stg (
    id character varying(256),
    uin text,
    name character varying(64),
    email text,
    mobile text,
    status_code character varying(36),
    lang_code character varying(3),
    last_login_method character varying(64),
    is_active boolean,
    cr_by character varying(256),
    cr_dtimes timestamp,
    eff_dtimes timestamp
);

\COPY _user_detail_h_stg FROM './dml/master-user_detail_h.csv' delimiter ',' HEADER  csv;

INSERT INTO master.user_detail_h (id,name,status_code,regcntr_id,lang_code,last_login_dtimes,last_login_method,is_active,cr_by,cr_dtimes,eff_dtimes)
SELECT id,
       name,
       status_code,
       NULL::character varying(10) AS regcntr_id,
       'fra'::character varying(3) AS lang_code,
       NULL::timestamp AS last_login_dtimes,
       last_login_method,
       is_active,
       cr_by,
       cr_dtimes,
       eff_dtimes
FROM _user_detail_h_stg;

----- TRUNCATE master.user_detail TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.user_detail cascade ;

-- Stage CSV (has extra columns) then insert only required fields
DROP TABLE IF EXISTS _user_detail_stg;
CREATE TEMP TABLE _user_detail_stg (
    id character varying(256),
    uin text,
    name character varying(64),
    email text,
    mobile text,
    status_code character varying(36),
    lang_code character varying(3),
    last_login_method character varying(64),
    is_active boolean,
    cr_by character varying(256),
    cr_dtimes timestamp
);

\COPY _user_detail_stg FROM './dml/master-user_detail.csv' delimiter ',' HEADER  csv;

INSERT INTO master.user_detail (id,name,status_code,regcntr_id,lang_code,last_login_dtimes,last_login_method,is_active,cr_by,cr_dtimes)
SELECT id,
       name,
       status_code,
       NULL::character varying(10) AS regcntr_id,
       'fra'::character varying(3) AS lang_code,
       NULL::timestamp AS last_login_dtimes,
       last_login_method,
       is_active,
       cr_by,
       cr_dtimes
FROM _user_detail_stg;

----- TRUNCATE master.valid_document TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.valid_document cascade ;

-- Stage and load only rows with lang_code='fra' and existing doc_type
DROP TABLE IF EXISTS _valid_document_stg;
CREATE TEMP TABLE _valid_document_stg (
    doctyp_code character varying(36),
    doccat_code character varying(36),
    lang_code character varying(3),
    is_active boolean,
    cr_by character varying(256),
    cr_dtimes timestamp
);

\COPY _valid_document_stg (doctyp_code,doccat_code,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-valid_document.csv' delimiter ',' HEADER  csv;

INSERT INTO master.valid_document (doctyp_code,doccat_code,lang_code,is_active,cr_by,cr_dtimes)
SELECT v.doctyp_code,
       v.doccat_code,
       'fra'::character varying(3) AS lang_code,
        v.is_active,
        v.cr_by,
        v.cr_dtimes
FROM _valid_document_stg v
WHERE EXISTS (
    SELECT 1 FROM master.doc_type d
    WHERE d.code = v.doctyp_code AND d.lang_code = 'fra'
)
AND EXISTS (
    SELECT 1 FROM master.doc_category c
    WHERE c.code = v.doccat_code AND c.lang_code = 'fra'
);

----- TRUNCATE master.zone TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.zone cascade ;

\COPY master.zone (code,name,hierarchy_level,hierarchy_level_name,hierarchy_path,parent_zone_code,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-zone.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.zone_user_h TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.zone_user_h cascade ;

\COPY master.zone_user_h (zone_code,usr_id,lang_code,is_active,cr_by,cr_dtimes,eff_dtimes) FROM './dml/master-zone_user_h.csv' delimiter ',' HEADER  csv;

----- TRUNCATE master.zone_user TABLE Data and It's reference Data and COPY Data from CSV file -----
TRUNCATE TABLE master.zone_user cascade ;

\COPY master.zone_user (zone_code,usr_id,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-zone_user.csv' delimiter ',' HEADER  csv;

















