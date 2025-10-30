CREATE DATABASE mosip_pms 
	ENCODING = 'UTF8' 
	LC_COLLATE = 'en_US.utf8' 
	LC_CTYPE = 'en_US.utf8' 
	TABLESPACE = pg_default 
	OWNER = postgres
	TEMPLATE  = template0;

COMMENT ON DATABASE mosip_pms IS 'PMS related entities and its data is stored in this database';

\c mosip_pms 

DROP SCHEMA IF EXISTS pms CASCADE;
CREATE SCHEMA pms;
ALTER SCHEMA pms OWNER TO postgres;
ALTER DATABASE mosip_pms SET search_path TO pms,pg_catalog,public;
