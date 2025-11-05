\c mosip_regprc 

-- Inserts N registrations
-- Usage: psql -v sim_reg_count=500 -f 20_sim_registrations.sql
\set sim_reg_count :sim_reg_count 200

INSERT INTO regprc.registration (id, reg_id, status_code, lang_code, cr_by, cr_dtimes)
SELECT gen_random_uuid(),
       'REG' || to_char(now(), 'YYYYMMDDHH24MISS') || lpad(i::text,6,'0'),
       'CREATED',
       'fra',
       'sim',
       now() - (random()*'2 days'::interval)
FROM generate_series(1, :sim_reg_count) AS s(i);

-- Progress some to IN_PROGRESS, APPROVED, PRINTING, SHIPPED
UPDATE regprc.registration SET status_code='IN_PROGRESS'
WHERE status_code='CREATED' AND random() < 0.9;

UPDATE regprc.registration SET status_code='APPROVED'
WHERE status_code='IN_PROGRESS' AND random() < 0.8;

-- Example printing orders
INSERT INTO regprc.printing_orders (id, regid, cr_by, cr_dtimes)
SELECT gen_random_uuid(), reg_id, 'sim', now()
FROM regprc.registration WHERE status_code='APPROVED' AND random() < 0.6;


