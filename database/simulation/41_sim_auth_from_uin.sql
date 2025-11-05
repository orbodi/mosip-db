\c mosip_ida 

-- Auth depuis UIN/VID récents (schema-adaptatif)
-- Usage: psql -f 41_sim_auth_from_uin.sql
DO $$
DECLARE has_otp boolean; has_otp_uin_hash boolean; has_auth boolean; has_auth_uin_hash boolean; has_auth_type boolean;
  cnt int := 500;
BEGIN
  SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='ida' AND table_name='otp_transaction') INTO has_otp;
  IF has_otp THEN
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='ida' AND table_name='otp_transaction' AND column_name='uin_hash') INTO has_otp_uin_hash;
    IF has_otp_uin_hash THEN
      INSERT INTO ida.otp_transaction (id, uin_hash, status_code, lang_code, cr_by, cr_dtimes)
      SELECT gen_random_uuid(), md5(random()::text),
             CASE WHEN random()<0.9 THEN 'SUCCESS' ELSE 'FAILED' END,
             'fra','sim', now()
      FROM generate_series(1, cnt);
    END IF;
  END IF;

  SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='ida' AND table_name='auth_transaction') INTO has_auth;
  IF has_auth THEN
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='ida' AND table_name='auth_transaction' AND column_name='uin_hash') INTO has_auth_uin_hash;
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='ida' AND table_name='auth_transaction' AND column_name='auth_type_code') INTO has_auth_type;
    IF has_auth_uin_hash AND has_auth_type THEN
      INSERT INTO ida.auth_transaction (id, uin_hash, auth_type_code, status_code, lang_code, cr_by, cr_dtimes)
      SELECT gen_random_uuid(), md5(random()::text), 'OTP',
             CASE WHEN random()<0.88 THEN 'SUCCESS' ELSE 'FAILED' END,
             'fra','sim', now()
      FROM generate_series(1, cnt);
    END IF;
  END IF;
END $$;


