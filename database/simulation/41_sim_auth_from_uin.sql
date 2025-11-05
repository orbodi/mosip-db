\c mosip_ida 

-- Auth depuis UIN/VID récents (simulation aléatoire)
-- Usage: psql -v sim_auth_from_ids=500 -f 41_sim_auth_from_uin.sql
\set sim_auth_from_ids :sim_auth_from_ids 500

INSERT INTO ida.otp_transaction (id, uin_hash, status_code, lang_code, cr_by, cr_dtimes)
SELECT gen_random_uuid(), md5(random()::text),
       CASE WHEN random()<0.9 THEN 'SUCCESS' ELSE 'FAILED' END,
       'fra','sim', now()
FROM generate_series(1, :sim_auth_from_ids);

INSERT INTO ida.auth_transaction (id, uin_hash, auth_type_code, status_code, lang_code, cr_by, cr_dtimes)
SELECT gen_random_uuid(), md5(random()::text), 'OTP',
       CASE WHEN random()<0.88 THEN 'SUCCESS' ELSE 'FAILED' END,
       'fra','sim', now()
FROM generate_series(1, :sim_auth_from_ids);


