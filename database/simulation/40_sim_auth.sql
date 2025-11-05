\c mosip_ida 

-- Simulate OTP/AUTH transactions (schema-adaptive)
-- Usage: psql -f 40_sim_auth.sql
DO $$
DECLARE has_otp boolean; has_otp_uin_hash boolean; has_auth boolean; has_auth_uin_hash boolean; has_auth_type boolean;
  otp_cnt int := 1200; auth_cnt int := 800;
BEGIN
  SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='ida' AND table_name='otp_transaction') INTO has_otp;
  IF has_otp THEN
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='ida' AND table_name='otp_transaction' AND column_name='uin_hash') INTO has_otp_uin_hash;
    IF has_otp_uin_hash THEN
      INSERT INTO ida.otp_transaction (id, uin_hash, status_code, lang_code, cr_by, cr_dtimes)
      SELECT gen_random_uuid(), md5(random()::text),
             CASE WHEN random()<0.85 THEN 'SUCCESS' ELSE 'FAILED' END,
             'fra','sim', now()
      FROM generate_series(1, otp_cnt);
    ELSE
      -- Skip if critical columns absent
      PERFORM 1;
    END IF;
  END IF;

  SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='ida' AND table_name='auth_transaction') INTO has_auth;
  IF has_auth THEN
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='ida' AND table_name='auth_transaction' AND column_name='uin_hash') INTO has_auth_uin_hash;
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='ida' AND table_name='auth_transaction' AND column_name='auth_type_code') INTO has_auth_type;
    IF has_auth_uin_hash AND has_auth_type THEN
      INSERT INTO ida.auth_transaction (id, uin_hash, auth_type_code, status_code, lang_code, cr_by, cr_dtimes)
      SELECT gen_random_uuid(), md5(random()::text), 'PWD',
             CASE WHEN random()<0.8 THEN 'SUCCESS' ELSE 'FAILED' END,
             'fra','sim', now()
      FROM generate_series(1, auth_cnt);
    ELSE
      PERFORM 1;
    END IF;
  END IF;
END $$;


