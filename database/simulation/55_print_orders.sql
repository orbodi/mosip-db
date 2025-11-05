\c mosip_regprc 

-- Générer des ordres d'impression pour des registrations APPROVED
-- Usage: psql -v sim_print_orders=200 -f 55_print_orders.sql
\set sim_print_orders 200

DO $$
DECLARE has_reg_id boolean; has_regid_col boolean; has_registration_id_col boolean;
  v_cnt int := 200;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_schema='regprc' AND table_name='registration' AND column_name='reg_id'
  ) INTO has_reg_id;
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='regid'
  ) INTO has_regid_col;
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='registration_id'
  ) INTO has_registration_id_col;

  IF has_regid_col THEN
    WITH approved AS (
      SELECT CASE WHEN has_reg_id THEN reg_id ELSE id::text END AS key
      FROM regprc.registration WHERE status_code='APPROVED' ORDER BY random() LIMIT v_cnt
    )
    INSERT INTO regprc.printing_orders (id, regid, cr_by, cr_dtimes)
    SELECT gen_random_uuid(), key, 'sim', now() FROM approved;
  ELSIF has_registration_id_col THEN
    WITH approved AS (
      SELECT id AS key FROM regprc.registration WHERE status_code='APPROVED' ORDER BY random() LIMIT v_cnt
    )
    INSERT INTO regprc.printing_orders (id, registration_id, cr_by, cr_dtimes)
    SELECT gen_random_uuid(), key, 'sim', now() FROM approved;
  ELSE
    -- Fallback: insert orders without link; adapt to ID type and optional audit columns
    DECLARE has_cr_by boolean; has_cr_dtimes boolean; id_dtype text;
    BEGIN
      SELECT EXISTS (
        SELECT 1 FROM information_schema.columns WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='cr_by'
      ) INTO has_cr_by;
      SELECT EXISTS (
        SELECT 1 FROM information_schema.columns WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='cr_dtimes'
      ) INTO has_cr_dtimes;
      SELECT data_type INTO id_dtype
      FROM information_schema.columns
      WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='id'
      LIMIT 1;

      IF coalesce(id_dtype,'') = 'uuid' THEN
        IF has_cr_by AND has_cr_dtimes THEN
          INSERT INTO regprc.printing_orders (id, cr_by, cr_dtimes)
          SELECT gen_random_uuid(), 'sim', now() FROM generate_series(1, v_cnt);
        ELSIF has_cr_by THEN
          INSERT INTO regprc.printing_orders (id, cr_by)
          SELECT gen_random_uuid(), 'sim' FROM generate_series(1, v_cnt);
        ELSIF has_cr_dtimes THEN
          INSERT INTO regprc.printing_orders (id, cr_dtimes)
          SELECT gen_random_uuid(), now() FROM generate_series(1, v_cnt);
        ELSE
          INSERT INTO regprc.printing_orders (id)
          SELECT gen_random_uuid() FROM generate_series(1, v_cnt);
        END IF;
      ELSE
        -- Assume numeric/bigint; synthesize numeric IDs
        IF has_cr_by AND has_cr_dtimes THEN
          INSERT INTO regprc.printing_orders (id, cr_by, cr_dtimes)
          SELECT (extract(epoch from now())*1000000)::bigint + i, 'sim', now()
          FROM generate_series(1, v_cnt) s(i);
        ELSIF has_cr_by THEN
          INSERT INTO regprc.printing_orders (id, cr_by)
          SELECT (extract(epoch from now())*1000000)::bigint + i, 'sim'
          FROM generate_series(1, v_cnt) s(i);
        ELSIF has_cr_dtimes THEN
          INSERT INTO regprc.printing_orders (id, cr_dtimes)
          SELECT (extract(epoch from now())*1000000)::bigint + i, now()
          FROM generate_series(1, v_cnt) s(i);
        ELSE
          INSERT INTO regprc.printing_orders (id)
          SELECT (extract(epoch from now())*1000000)::bigint + i FROM generate_series(1, v_cnt) s(i);
        END IF;
      END IF;
    END;
  END IF;
END $$;


