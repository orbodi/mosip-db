\c mosip_regprc 

-- Inserts N registrations (schema-adaptive)
-- Usage: psql -v sim_reg_count=500 -f 20_sim_registrations.sql
-- Note: DO blocks n'acceptent pas l'expansion psql ":var"; utiliser la constante ci-dessous
\set sim_reg_count 200

DO $$
DECLARE
  has_reg_id boolean;
  v_count int := 200; -- ajuster si besoin
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema='regprc' AND table_name='registration' AND column_name='reg_id'
  ) INTO has_reg_id;

  IF has_reg_id THEN
    INSERT INTO regprc.registration (id, reg_id, status_code, lang_code, cr_by, cr_dtimes)
    SELECT gen_random_uuid(),
           'REG' || to_char(now(), 'YYYYMMDDHH24MISS') || lpad(i::text,6,'0'),
           'CREATED','fra','sim', now() - (random()*'2 days'::interval)
    FROM generate_series(1, v_count) AS s(i);
  ELSE
    INSERT INTO regprc.registration (id, status_code, lang_code, cr_by, cr_dtimes)
    SELECT gen_random_uuid(), 'CREATED','fra','sim', now() - (random()*'2 days'::interval)
    FROM generate_series(1, v_count) AS s(i);
  END IF;
END $$;

-- Progress some to IN_PROGRESS, APPROVED
UPDATE regprc.registration SET status_code='IN_PROGRESS'
WHERE status_code='CREATED' AND random() < 0.9;

UPDATE regprc.registration SET status_code='APPROVED'
WHERE status_code='IN_PROGRESS' AND random() < 0.8;


