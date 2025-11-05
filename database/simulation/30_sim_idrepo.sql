\c mosip_idrepo 

-- Create UIN entries (idrepo)
-- Usage: psql -v sim_uin_count=200 -f 30_sim_idrepo.sql
\set sim_uin_count 200

INSERT INTO idrepo.uin (uin_ref_id, uin, uin_hash, uin_data, uin_data_hash, reg_id, status_code, lang_code, cr_by, cr_dtimes)
SELECT gen_random_uuid(),
       lpad((100000000000 + floor(random()*899999999999))::bigint::text,12,'0'),
       md5(random()::text),
       E'\\x'::bytea,
       md5(random()::text),
       NULL,
       'ACTIVE',
       'fra',
       'sim',
       now()
FROM generate_series(1, :sim_uin_count);


