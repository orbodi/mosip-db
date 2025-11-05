\c mosip_ida 

-- Simulate OTP transactions
-- Usage: psql -v sim_otp_count=1200 -v sim_auth_count=800 -f 40_sim_auth.sql
\set sim_otp_count :sim_otp_count 1200
\set sim_auth_count :sim_auth_count 800

INSERT INTO ida.otp_transaction (id, uin_hash, status_code, lang_code, cr_by, cr_dtimes)
SELECT gen_random_uuid(), md5(random()::text),
       CASE WHEN random()<0.85 THEN 'SUCCESS' ELSE 'FAILED' END,
       'fra','sim', now()
FROM generate_series(1, :sim_otp_count);

-- Simulate AUTH transactions
INSERT INTO ida.auth_transaction (id, uin_hash, auth_type_code, status_code, lang_code, cr_by, cr_dtimes)
SELECT gen_random_uuid(), md5(random()::text), 'PWD',
       CASE WHEN random()<0.8 THEN 'SUCCESS' ELSE 'FAILED' END,
       'fra','sim', now()
FROM generate_series(1, :sim_auth_count);


