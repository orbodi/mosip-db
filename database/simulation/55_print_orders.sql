\c mosip_regprc 

-- Générer des ordres d'impression pour des registrations APPROVED
-- Usage: psql -v sim_print_orders=200 -f 55_print_orders.sql
\set sim_print_orders :sim_print_orders 200

WITH approved AS (
  SELECT reg_id FROM regprc.registration WHERE status_code='APPROVED' ORDER BY random() LIMIT :sim_print_orders
)
INSERT INTO regprc.printing_orders (id, regid, cr_by, cr_dtimes)
SELECT gen_random_uuid(), a.reg_id, 'sim', now()
FROM approved a;


