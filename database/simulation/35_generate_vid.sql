\c mosip_idrepo 

-- Générer des VID si une table vid existe, sinon no-op
-- Usage: psql -v sim_vid_count=100 -f 35_generate_vid.sql
\set sim_vid_count 100

DO $$
DECLARE n int := 100;
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='idrepo' AND table_name='vid') THEN
    INSERT INTO idrepo.vid (id, uin_hash, vid, status_code, cr_by, cr_dtimes)
    SELECT gen_random_uuid(), md5(random()::text), md5(random()::text), 'ACTIVE','sim', now()
    FROM generate_series(1, n);
  END IF;
END $$;


