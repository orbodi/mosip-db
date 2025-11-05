\c mosip_idrepo 

-- Create UIN entries (idrepo)
-- Usage: psql -v sim_uin_count=200 -f 30_sim_idrepo.sql
\set sim_uin_count 200

DO $$
DECLARE 
  v_cnt int := 200;
  reg_exists boolean;
  reg_dtype text;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema='idrepo' AND table_name='uin' AND column_name='reg_id'
  ) INTO reg_exists;

  IF reg_exists THEN
    SELECT data_type INTO reg_dtype
    FROM information_schema.columns 
    WHERE table_schema='idrepo' AND table_name='uin' AND column_name='reg_id'
    LIMIT 1;

    IF reg_dtype IN ('character varying','text','character') THEN
      INSERT INTO idrepo.uin (uin_ref_id, uin, uin_hash, uin_data, uin_data_hash, reg_id, status_code, lang_code, cr_by, cr_dtimes)
      SELECT gen_random_uuid(),
             lpad((100000000000 + floor(random()*899999999999))::bigint::text,12,'0'),
             md5(random()::text),
             E'\\x'::bytea,
             md5(random()::text),
             'REG' || to_char(now(), 'YYYYMMDDHH24MISS') || lpad(i::text,6,'0'),
             'ACTIVE','fra','sim', now()
      FROM generate_series(1, v_cnt) AS s(i);
    ELSIF reg_dtype IN ('uuid') THEN
      INSERT INTO idrepo.uin (uin_ref_id, uin, uin_hash, uin_data, uin_data_hash, reg_id, status_code, lang_code, cr_by, cr_dtimes)
      SELECT gen_random_uuid(),
             lpad((100000000000 + floor(random()*899999999999))::bigint::text,12,'0'),
             md5(random()::text),
             E'\\x'::bytea,
             md5(random()::text),
             gen_random_uuid(),
             'ACTIVE','fra','sim', now()
      FROM generate_series(1, v_cnt) AS s(i);
    ELSE
      -- Fallback: try text
      INSERT INTO idrepo.uin (uin_ref_id, uin, uin_hash, uin_data, uin_data_hash, reg_id, status_code, lang_code, cr_by, cr_dtimes)
      SELECT gen_random_uuid(),
             lpad((100000000000 + floor(random()*899999999999))::bigint::text,12,'0'),
             md5(random()::text),
             E'\\x'::bytea,
             md5(random()::text),
             'REG' || to_char(now(), 'YYYYMMDDHH24MISS') || lpad(i::text,6,'0'),
             'ACTIVE','fra','sim', now()
      FROM generate_series(1, v_cnt) AS s(i);
    END IF;
  ELSE
    INSERT INTO idrepo.uin (uin_ref_id, uin, uin_hash, uin_data, uin_data_hash, status_code, lang_code, cr_by, cr_dtimes)
    SELECT gen_random_uuid(),
           lpad((100000000000 + floor(random()*899999999999))::bigint::text,12,'0'),
           md5(random()::text),
           E'\\x'::bytea,
           md5(random()::text),
           'ACTIVE','fra','sim', now()
    FROM generate_series(1, v_cnt) AS s(i);
  END IF;
END $$;


