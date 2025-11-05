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
    DECLARE has_cr_by boolean; has_cr_dtimes boolean; id_dtype text; crdt_is_generated boolean;
            has_rid boolean; rid_dtype text; rid_not_null boolean;
            has_reqid boolean; reqid_dtype text; reqid_not_null boolean; reqid_maxlen integer;
            has_reqtype boolean; reqtype_dtype text; reqtype_not_null boolean;
            has_target_reqtype boolean; target_reqtype_maxlen integer;
    BEGIN
      SELECT EXISTS (
        SELECT 1 FROM information_schema.columns WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='cr_by'
      ) INTO has_cr_by;
      SELECT EXISTS (
        SELECT 1 FROM information_schema.columns WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='cr_dtimes'
      ) INTO has_cr_dtimes;
      SELECT (is_generated='ALWAYS') INTO crdt_is_generated
      FROM information_schema.columns
      WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='cr_dtimes'
      LIMIT 1;
      SELECT data_type INTO id_dtype
      FROM information_schema.columns
      WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='id'
      LIMIT 1;

      -- Detect required RID column
      SELECT EXISTS (
        SELECT 1 FROM information_schema.columns WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='rid'
      ) INTO has_rid;
      IF has_rid THEN
        SELECT data_type, (is_nullable='NO') INTO rid_dtype, rid_not_null
        FROM information_schema.columns
        WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='rid'
        LIMIT 1;
      END IF;
      -- Detect required request_id column
      SELECT EXISTS (
        SELECT 1 FROM information_schema.columns WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='request_id'
      ) INTO has_reqid;
      IF has_reqid THEN
        SELECT data_type, (is_nullable='NO'), character_maximum_length INTO reqid_dtype, reqid_not_null, reqid_maxlen
        FROM information_schema.columns
        WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='request_id'
        LIMIT 1;
      END IF;
      -- Detect required request_type column
      SELECT EXISTS (
        SELECT 1 FROM information_schema.columns WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='request_type'
      ) INTO has_reqtype;
      IF has_reqtype THEN
        SELECT data_type, (is_nullable='NO') INTO reqtype_dtype, reqtype_not_null
        FROM information_schema.columns
        WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='request_type'
        LIMIT 1;
      END IF;
      -- Detect target_request_type column
      SELECT EXISTS (
        SELECT 1 FROM information_schema.columns WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='target_request_type'
      ) INTO has_target_reqtype;
      IF has_target_reqtype THEN
        SELECT character_maximum_length INTO target_reqtype_maxlen
        FROM information_schema.columns
        WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='target_request_type'
        LIMIT 1;
      END IF;

      -- Ensure defaults for type columns to avoid NOT NULL insert issues when not explicitly provided
      BEGIN
        IF has_reqtype THEN
          EXECUTE 'ALTER TABLE regprc.printing_orders ALTER COLUMN request_type SET DEFAULT ''PRINT''';
        END IF;
      EXCEPTION WHEN others THEN
        -- ignore if no rights or incompatible
      END;
      BEGIN
        PERFORM 1 FROM information_schema.columns 
         WHERE table_schema='regprc' AND table_name='printing_orders' AND column_name='target_request_type';
        IF FOUND THEN
          EXECUTE 'ALTER TABLE regprc.printing_orders ALTER COLUMN target_request_type SET DEFAULT ''PRINT''';
        END IF;
      EXCEPTION WHEN others THEN
        -- ignore if no rights or incompatible
      END;

      IF coalesce(id_dtype,'') = 'uuid' THEN
        IF has_rid AND rid_not_null THEN
          IF has_cr_by AND has_cr_dtimes AND NOT coalesce(crdt_is_generated,false) THEN
            IF has_target_reqtype THEN
              INSERT INTO regprc.printing_orders (id, rid, request_id, request_type, target_request_type, cr_by, cr_dtimes)
              SELECT gen_random_uuid(),
                     CASE WHEN coalesce(rid_dtype,'') IN ('character varying','text','character')
                          THEN to_char(now(),'YYYYMMDDHH24MISS')
                          ELSE ((extract(epoch from now())*1000000)::bigint + i)::text END,
                     (CASE 
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') IN ('character varying','text','character') THEN 
                         CASE WHEN coalesce(reqid_maxlen,0) >= 14 THEN to_char(now(),'YYYYMMDDHH24MISS')
                              WHEN coalesce(reqid_maxlen,0) >= 12 THEN to_char(now(),'YYYYMMDDHH24MI')
                              WHEN coalesce(reqid_maxlen,0) >= 10 THEN ((extract(epoch from now())*1000)::bigint)::text
                              ELSE lpad(i::text, GREATEST(coalesce(reqid_maxlen,1),1), '0') END
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') = 'uuid' THEN gen_random_uuid()::text
                       WHEN has_reqid AND reqid_not_null THEN ((extract(epoch from now())*1000)::bigint)::text
                       ELSE NULL::text
                     END)::text,
                     CASE WHEN has_reqtype THEN 
                       CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                            ELSE 'PRINT'::text
                       END
                       ELSE NULL::text
                     END,
                     CASE WHEN has_target_reqtype AND coalesce(target_reqtype_maxlen,0) > 0 AND target_reqtype_maxlen <= 3 THEN 'PRT'
                          WHEN has_target_reqtype THEN 'PRINT'
                          ELSE NULL::text
                     END,
                     'sim', now()
              FROM generate_series(1, v_cnt) s(i);
            ELSE
              INSERT INTO regprc.printing_orders (id, rid, request_id, request_type, cr_by, cr_dtimes)
              SELECT gen_random_uuid(),
                     CASE WHEN coalesce(rid_dtype,'') IN ('character varying','text','character')
                          THEN to_char(now(),'YYYYMMDDHH24MISS')
                          ELSE ((extract(epoch from now())*1000000)::bigint + i)::text END,
                     (CASE 
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') IN ('character varying','text','character') THEN 
                         CASE WHEN coalesce(reqid_maxlen,0) >= 14 THEN to_char(now(),'YYYYMMDDHH24MISS')
                              WHEN coalesce(reqid_maxlen,0) >= 12 THEN to_char(now(),'YYYYMMDDHH24MI')
                              WHEN coalesce(reqid_maxlen,0) >= 10 THEN ((extract(epoch from now())*1000)::bigint)::text
                              ELSE lpad(i::text, GREATEST(coalesce(reqid_maxlen,1),1), '0') END
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') = 'uuid' THEN gen_random_uuid()::text
                       WHEN has_reqid AND reqid_not_null THEN ((extract(epoch from now())*1000)::bigint)::text
                       ELSE NULL::text
                     END)::text,
                     CASE WHEN has_reqtype THEN 
                       CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                            ELSE 'PRINT'::text
                       END
                       ELSE NULL::text
                     END,
                     'sim', now()
              FROM generate_series(1, v_cnt) s(i);
            END IF;
          ELSIF has_cr_by THEN
            IF has_target_reqtype THEN
              INSERT INTO regprc.printing_orders (id, rid, request_id, request_type, target_request_type, cr_by)
              SELECT gen_random_uuid(),
                     CASE WHEN coalesce(rid_dtype,'') IN ('character varying','text','character')
                          THEN to_char(now(),'YYYYMMDDHH24MISS')
                          ELSE ((extract(epoch from now())*1000000)::bigint + i)::text END,
                     (CASE 
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') IN ('character varying','text','character') THEN 
                         CASE WHEN coalesce(reqid_maxlen,0) >= 14 THEN to_char(now(),'YYYYMMDDHH24MISS')
                              WHEN coalesce(reqid_maxlen,0) >= 12 THEN to_char(now(),'YYYYMMDDHH24MI')
                              WHEN coalesce(reqid_maxlen,0) >= 10 THEN ((extract(epoch from now())*1000)::bigint)::text
                              ELSE lpad(i::text, GREATEST(coalesce(reqid_maxlen,1),1), '0') END
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') = 'uuid' THEN gen_random_uuid()::text
                       WHEN has_reqid AND reqid_not_null THEN ((extract(epoch from now())*1000)::bigint)::text
                       ELSE NULL::text
                     END)::text,
                     CASE WHEN has_reqtype THEN 
                       CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                            ELSE 'PRINT'::text
                       END
                       ELSE NULL::text
                     END,
                     CASE WHEN has_target_reqtype AND coalesce(target_reqtype_maxlen,0) > 0 AND target_reqtype_maxlen <= 3 THEN 'PRT'
                          WHEN has_target_reqtype THEN 'PRINT'
                          ELSE NULL::text
                     END,
                     'sim'
              FROM generate_series(1, v_cnt) s(i);
            ELSE
              INSERT INTO regprc.printing_orders (id, rid, request_id, request_type, cr_by)
              SELECT gen_random_uuid(),
                     CASE WHEN coalesce(rid_dtype,'') IN ('character varying','text','character')
                          THEN to_char(now(),'YYYYMMDDHH24MISS')
                          ELSE ((extract(epoch from now())*1000000)::bigint + i)::text END,
                     (CASE 
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') IN ('character varying','text','character') THEN 
                         CASE WHEN coalesce(reqid_maxlen,0) >= 14 THEN to_char(now(),'YYYYMMDDHH24MISS')
                              WHEN coalesce(reqid_maxlen,0) >= 12 THEN to_char(now(),'YYYYMMDDHH24MI')
                              WHEN coalesce(reqid_maxlen,0) >= 10 THEN ((extract(epoch from now())*1000)::bigint)::text
                              ELSE lpad(i::text, GREATEST(coalesce(reqid_maxlen,1),1), '0') END
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') = 'uuid' THEN gen_random_uuid()::text
                       WHEN has_reqid AND reqid_not_null THEN ((extract(epoch from now())*1000)::bigint)::text
                       ELSE NULL::text
                     END)::text,
                     CASE WHEN has_reqtype THEN 
                       CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                            ELSE 'PRINT'::text
                       END
                       ELSE NULL::text
                     END,
                     'sim'
              FROM generate_series(1, v_cnt) s(i);
            END IF;
          ELSIF has_cr_dtimes AND NOT coalesce(crdt_is_generated,false) THEN
            IF has_target_reqtype THEN
              INSERT INTO regprc.printing_orders (id, rid, request_id, request_type, target_request_type, cr_dtimes)
              SELECT gen_random_uuid(),
                     CASE WHEN coalesce(rid_dtype,'') IN ('character varying','text','character')
                          THEN to_char(now(),'YYYYMMDDHH24MISS')
                          ELSE ((extract(epoch from now())*1000000)::bigint + i)::text END,
                     (CASE 
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') IN ('character varying','text','character') THEN 
                         CASE WHEN coalesce(reqid_maxlen,0) >= 14 THEN to_char(now(),'YYYYMMDDHH24MISS')
                              WHEN coalesce(reqid_maxlen,0) >= 12 THEN to_char(now(),'YYYYMMDDHH24MI')
                              WHEN coalesce(reqid_maxlen,0) >= 10 THEN ((extract(epoch from now())*1000)::bigint)::text
                              ELSE lpad(i::text, GREATEST(coalesce(reqid_maxlen,1),1), '0') END
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') = 'uuid' THEN gen_random_uuid()::text
                       WHEN has_reqid AND reqid_not_null THEN ((extract(epoch from now())*1000)::bigint)::text
                       ELSE NULL::text
                     END)::text,
                     CASE WHEN has_reqtype THEN 
                       CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                            ELSE 'PRINT'::text
                       END
                       ELSE NULL::text
                     END,
                     CASE WHEN has_target_reqtype AND coalesce(target_reqtype_maxlen,0) > 0 AND target_reqtype_maxlen <= 3 THEN 'PRT'
                          WHEN has_target_reqtype THEN 'PRINT'
                          ELSE NULL::text
                     END,
                     now()
              FROM generate_series(1, v_cnt) s(i);
            ELSE
              INSERT INTO regprc.printing_orders (id, rid, request_id, request_type, cr_dtimes)
              SELECT gen_random_uuid(),
                     CASE WHEN coalesce(rid_dtype,'') IN ('character varying','text','character')
                          THEN to_char(now(),'YYYYMMDDHH24MISS')
                          ELSE ((extract(epoch from now())*1000000)::bigint + i)::text END,
                     (CASE 
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') IN ('character varying','text','character') THEN 
                         CASE WHEN coalesce(reqid_maxlen,0) >= 14 THEN to_char(now(),'YYYYMMDDHH24MISS')
                              WHEN coalesce(reqid_maxlen,0) >= 12 THEN to_char(now(),'YYYYMMDDHH24MI')
                              WHEN coalesce(reqid_maxlen,0) >= 10 THEN ((extract(epoch from now())*1000)::bigint)::text
                              ELSE lpad(i::text, GREATEST(coalesce(reqid_maxlen,1),1), '0') END
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') = 'uuid' THEN gen_random_uuid()::text
                       WHEN has_reqid AND reqid_not_null THEN ((extract(epoch from now())*1000)::bigint)::text
                       ELSE NULL::text
                     END)::text,
                     CASE WHEN has_reqtype THEN 
                       CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                            ELSE 'PRINT'::text
                       END
                       ELSE NULL::text
                     END,
                     now()
              FROM generate_series(1, v_cnt) s(i);
            END IF;
          ELSE
            IF has_target_reqtype THEN
              INSERT INTO regprc.printing_orders (id, rid, request_id, request_type, target_request_type)
              SELECT gen_random_uuid(),
                     CASE WHEN coalesce(rid_dtype,'') IN ('character varying','text','character')
                          THEN to_char(now(),'YYYYMMDDHH24MISS')
                          ELSE ((extract(epoch from now())*1000000)::bigint + i)::text END,
                     (CASE 
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') IN ('character varying','text','character') THEN 
                         CASE WHEN coalesce(reqid_maxlen,0) >= 14 THEN to_char(now(),'YYYYMMDDHH24MISS')
                              WHEN coalesce(reqid_maxlen,0) >= 12 THEN to_char(now(),'YYYYMMDDHH24MI')
                              WHEN coalesce(reqid_maxlen,0) >= 10 THEN ((extract(epoch from now())*1000)::bigint)::text
                              ELSE lpad(i::text, GREATEST(coalesce(reqid_maxlen,1),1), '0') END
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') = 'uuid' THEN gen_random_uuid()::text
                       WHEN has_reqid AND reqid_not_null THEN ((extract(epoch from now())*1000)::bigint)::text
                       ELSE NULL::text
                     END)::text,
                     CASE WHEN has_reqtype THEN 
                       CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                            ELSE 'PRINT'::text
                       END
                       ELSE NULL::text
                     END,
                     CASE WHEN has_target_reqtype AND coalesce(target_reqtype_maxlen,0) > 0 AND target_reqtype_maxlen <= 3 THEN 'PRT'
                          WHEN has_target_reqtype THEN 'PRINT'
                          ELSE NULL::text
                     END
              FROM generate_series(1, v_cnt) s(i);
            ELSE
              INSERT INTO regprc.printing_orders (id, rid, request_id, request_type)
              SELECT gen_random_uuid(),
                     CASE WHEN coalesce(rid_dtype,'') IN ('character varying','text','character')
                          THEN to_char(now(),'YYYYMMDDHH24MISS')
                          ELSE ((extract(epoch from now())*1000000)::bigint + i)::text END,
                     (CASE 
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') IN ('character varying','text','character') THEN 
                         CASE WHEN coalesce(reqid_maxlen,0) >= 14 THEN to_char(now(),'YYYYMMDDHH24MISS')
                              WHEN coalesce(reqid_maxlen,0) >= 12 THEN to_char(now(),'YYYYMMDDHH24MI')
                              WHEN coalesce(reqid_maxlen,0) >= 10 THEN ((extract(epoch from now())*1000)::bigint)::text
                              ELSE lpad(i::text, GREATEST(coalesce(reqid_maxlen,1),1), '0') END
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') = 'uuid' THEN gen_random_uuid()::text
                       WHEN has_reqid AND reqid_not_null THEN ((extract(epoch from now())*1000)::bigint)::text
                       ELSE NULL::text
                     END)::text,
                     CASE WHEN has_reqtype THEN 
                       CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                            ELSE 'PRINT'::text
                       END
                       ELSE NULL::text
                     END
              FROM generate_series(1, v_cnt) s(i);
            END IF;
          END IF;
        ELSIF has_cr_by AND has_cr_dtimes AND NOT coalesce(crdt_is_generated,false) THEN
          INSERT INTO regprc.printing_orders (id, cr_by, cr_dtimes)
          SELECT gen_random_uuid(), 'sim', now() FROM generate_series(1, v_cnt);
        ELSIF has_cr_by THEN
          INSERT INTO regprc.printing_orders (id, cr_by)
          SELECT gen_random_uuid(), 'sim' FROM generate_series(1, v_cnt);
        ELSIF has_cr_dtimes AND NOT coalesce(crdt_is_generated,false) THEN
          INSERT INTO regprc.printing_orders (id, cr_dtimes)
          SELECT gen_random_uuid(), now() FROM generate_series(1, v_cnt);
        ELSE
          INSERT INTO regprc.printing_orders (id)
          SELECT gen_random_uuid() FROM generate_series(1, v_cnt);
        END IF;
      ELSE
        -- Assume numeric/bigint; synthesize numeric IDs
        IF has_rid AND rid_not_null THEN
          IF has_cr_by AND has_cr_dtimes AND NOT coalesce(crdt_is_generated,false) THEN
            IF has_target_reqtype THEN
              INSERT INTO regprc.printing_orders (id, rid, request_id, request_type, target_request_type, cr_by, cr_dtimes)
              SELECT (extract(epoch from now())*1000000)::bigint + i,
                   CASE WHEN coalesce(rid_dtype,'') IN ('character varying','text','character')
                        THEN to_char(now(),'YYYYMMDDHH24MISS')
                        ELSE ((extract(epoch from now())*1000000)::bigint + i)::text END,
                   (CASE 
                     WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') IN ('character varying','text','character') THEN 
                       CASE WHEN coalesce(reqid_maxlen,0) >= 14 THEN to_char(now(),'YYYYMMDDHH24MISS')
                            WHEN coalesce(reqid_maxlen,0) >= 12 THEN to_char(now(),'YYYYMMDDHH24MI')
                            WHEN coalesce(reqid_maxlen,0) >= 10 THEN ((extract(epoch from now())*1000)::bigint)::text
                            ELSE lpad(i::text, GREATEST(coalesce(reqid_maxlen,1),1), '0') END
                     WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') = 'uuid' THEN gen_random_uuid()::text
                     WHEN has_reqid AND reqid_not_null THEN ((extract(epoch from now())*1000)::bigint)::text
                     ELSE NULL::text
                  END)::text,
                  CASE WHEN has_reqtype THEN 
                     CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                          ELSE 'PRINT'::text
                     END
                     ELSE NULL::text
                  END,
                     CASE WHEN has_target_reqtype AND coalesce(target_reqtype_maxlen,0) > 0 AND target_reqtype_maxlen <= 3 THEN 'PRT'
                          WHEN has_target_reqtype THEN 'PRINT'
                          ELSE NULL::text
                     END,
                   'sim', now()
              FROM generate_series(1, v_cnt) s(i);
            ELSE
              INSERT INTO regprc.printing_orders (id, rid, request_id, request_type, cr_by, cr_dtimes)
              SELECT (extract(epoch from now())*1000000)::bigint + i,
                     CASE WHEN coalesce(rid_dtype,'') IN ('character varying','text','character')
                          THEN to_char(now(),'YYYYMMDDHH24MISS')
                          ELSE ((extract(epoch from now())*1000000)::bigint + i)::text END,
                     (CASE 
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') IN ('character varying','text','character') THEN 
                         CASE WHEN coalesce(reqid_maxlen,0) >= 14 THEN to_char(now(),'YYYYMMDDHH24MISS')
                              WHEN coalesce(reqid_maxlen,0) >= 12 THEN to_char(now(),'YYYYMMDDHH24MI')
                              WHEN coalesce(reqid_maxlen,0) >= 10 THEN ((extract(epoch from now())*1000)::bigint)::text
                              ELSE lpad(i::text, GREATEST(coalesce(reqid_maxlen,1),1), '0') END
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') = 'uuid' THEN gen_random_uuid()::text
                       WHEN has_reqid AND reqid_not_null THEN ((extract(epoch from now())*1000)::bigint)::text
                       ELSE NULL::text
                     END)::text,
                     CASE WHEN has_reqtype THEN 
                       CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                            ELSE 'PRINT'::text
                       END
                       ELSE NULL::text
                     END,
                     'sim', now()
              FROM generate_series(1, v_cnt) s(i);
            END IF;
          ELSIF has_cr_by THEN
            IF has_target_reqtype THEN
              INSERT INTO regprc.printing_orders (id, rid, request_id, request_type, target_request_type, cr_by)
              SELECT (extract(epoch from now())*1000000)::bigint + i,
                     CASE WHEN coalesce(rid_dtype,'') IN ('character varying','text','character')
                          THEN to_char(now(),'YYYYMMDDHH24MISS')
                          ELSE ((extract(epoch from now())*1000000)::bigint + i)::text END,
                     (CASE 
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') IN ('character varying','text','character') THEN 
                         CASE WHEN coalesce(reqid_maxlen,0) >= 14 THEN to_char(now(),'YYYYMMDDHH24MISS')
                              WHEN coalesce(reqid_maxlen,0) >= 12 THEN to_char(now(),'YYYYMMDDHH24MI')
                              WHEN coalesce(reqid_maxlen,0) >= 10 THEN ((extract(epoch from now())*1000)::bigint)::text
                              ELSE lpad(i::text, GREATEST(coalesce(reqid_maxlen,1),1), '0') END
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') = 'uuid' THEN gen_random_uuid()::text
                       WHEN has_reqid AND reqid_not_null THEN ((extract(epoch from now())*1000)::bigint)::text
                       ELSE NULL::text
                     END)::text,
                     CASE WHEN has_reqtype THEN 
                       CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                            ELSE 'PRINT'::text
                       END
                       ELSE NULL::text
                     END,
                     CASE WHEN has_target_reqtype AND coalesce(target_reqtype_maxlen,0) > 0 AND target_reqtype_maxlen <= 3 THEN 'PRT'
                          WHEN has_target_reqtype THEN 'PRINT'
                          ELSE NULL::text
                     END,
                     'sim'
              FROM generate_series(1, v_cnt) s(i);
            ELSE
              INSERT INTO regprc.printing_orders (id, rid, request_id, request_type, cr_by)
              SELECT (extract(epoch from now())*1000000)::bigint + i,
                     CASE WHEN coalesce(rid_dtype,'') IN ('character varying','text','character')
                          THEN to_char(now(),'YYYYMMDDHH24MISS')
                          ELSE ((extract(epoch from now())*1000000)::bigint + i)::text END,
                     (CASE 
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') IN ('character varying','text','character') THEN 
                         CASE WHEN coalesce(reqid_maxlen,0) >= 14 THEN to_char(now(),'YYYYMMDDHH24MISS')
                              WHEN coalesce(reqid_maxlen,0) >= 12 THEN to_char(now(),'YYYYMMDDHH24MI')
                              WHEN coalesce(reqid_maxlen,0) >= 10 THEN ((extract(epoch from now())*1000)::bigint)::text
                              ELSE lpad(i::text, GREATEST(coalesce(reqid_maxlen,1),1), '0') END
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') = 'uuid' THEN gen_random_uuid()::text
                       WHEN has_reqid AND reqid_not_null THEN ((extract(epoch from now())*1000)::bigint)::text
                       ELSE NULL::text
                     END)::text,
                     CASE WHEN has_reqtype THEN 
                       CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                            ELSE 'PRINT'::text
                       END
                       ELSE NULL::text
                     END,
                     'sim'
              FROM generate_series(1, v_cnt) s(i);
            END IF;
          ELSIF has_cr_dtimes AND NOT coalesce(crdt_is_generated,false) THEN
            IF has_target_reqtype THEN
              INSERT INTO regprc.printing_orders (id, rid, request_id, request_type, target_request_type, cr_dtimes)
              SELECT (extract(epoch from now())*1000000)::bigint + i,
                     CASE WHEN coalesce(rid_dtype,'') IN ('character varying','text','character')
                          THEN to_char(now(),'YYYYMMDDHH24MISS')
                          ELSE ((extract(epoch from now())*1000000)::bigint + i)::text END,
                     (CASE 
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') IN ('character varying','text','character') THEN 
                         CASE WHEN coalesce(reqid_maxlen,0) >= 14 THEN to_char(now(),'YYYYMMDDHH24MISS')
                              WHEN coalesce(reqid_maxlen,0) >= 12 THEN to_char(now(),'YYYYMMDDHH24MI')
                              WHEN coalesce(reqid_maxlen,0) >= 10 THEN ((extract(epoch from now())*1000)::bigint)::text
                              ELSE lpad(i::text, GREATEST(coalesce(reqid_maxlen,1),1), '0') END
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') = 'uuid' THEN gen_random_uuid()::text
                       WHEN has_reqid AND reqid_not_null THEN ((extract(epoch from now())*1000)::bigint)::text
                       ELSE NULL::text
                     END)::text,
                     CASE WHEN has_reqtype THEN 
                       CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                            ELSE 'PRINT'::text
                       END
                       ELSE NULL::text
                     END,
                     CASE WHEN has_target_reqtype AND coalesce(target_reqtype_maxlen,0) > 0 AND target_reqtype_maxlen <= 3 THEN 'PRT'
                          WHEN has_target_reqtype THEN 'PRINT'
                          ELSE NULL::text
                     END,
                     now()
              FROM generate_series(1, v_cnt) s(i);
            ELSE
              INSERT INTO regprc.printing_orders (id, rid, request_id, request_type, cr_dtimes)
              SELECT (extract(epoch from now())*1000000)::bigint + i,
                     CASE WHEN coalesce(rid_dtype,'') IN ('character varying','text','character')
                          THEN to_char(now(),'YYYYMMDDHH24MISS')
                          ELSE ((extract(epoch from now())*1000000)::bigint + i)::text END,
                     (CASE 
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') IN ('character varying','text','character') THEN 
                         CASE WHEN coalesce(reqid_maxlen,0) >= 14 THEN to_char(now(),'YYYYMMDDHH24MISS')
                              WHEN coalesce(reqid_maxlen,0) >= 12 THEN to_char(now(),'YYYYMMDDHH24MI')
                              WHEN coalesce(reqid_maxlen,0) >= 10 THEN ((extract(epoch from now())*1000)::bigint)::text
                              ELSE lpad(i::text, GREATEST(coalesce(reqid_maxlen,1),1), '0') END
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') = 'uuid' THEN gen_random_uuid()::text
                       WHEN has_reqid AND reqid_not_null THEN ((extract(epoch from now())*1000)::bigint)::text
                       ELSE NULL::text
                     END)::text,
                     CASE WHEN has_reqtype THEN 
                       CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                            ELSE 'PRINT'::text
                       END
                       ELSE NULL::text
                     END,
                     now()
              FROM generate_series(1, v_cnt) s(i);
            END IF;
          ELSE
            IF has_target_reqtype THEN
              INSERT INTO regprc.printing_orders (id, rid, request_id, request_type, target_request_type)
              SELECT (extract(epoch from now())*1000000)::bigint + i,
                     CASE WHEN coalesce(rid_dtype,'') IN ('character varying','text','character')
                          THEN to_char(now(),'YYYYMMDDHH24MISS')
                          ELSE ((extract(epoch from now())*1000000)::bigint + i)::text END,
                     (CASE 
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') IN ('character varying','text','character') THEN 
                         CASE WHEN coalesce(reqid_maxlen,0) >= 14 THEN to_char(now(),'YYYYMMDDHH24MISS')
                              WHEN coalesce(reqid_maxlen,0) >= 12 THEN to_char(now(),'YYYYMMDDHH24MI')
                              WHEN coalesce(reqid_maxlen,0) >= 10 THEN ((extract(epoch from now())*1000)::bigint)::text
                              ELSE lpad(i::text, GREATEST(coalesce(reqid_maxlen,1),1), '0') END
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') = 'uuid' THEN gen_random_uuid()::text
                       WHEN has_reqid AND reqid_not_null THEN ((extract(epoch from now())*1000)::bigint)::text
                       ELSE NULL::text
                     END)::text,
                     CASE WHEN has_reqtype THEN 
                       CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                            ELSE 'PRINT'::text
                       END
                       ELSE NULL::text
                     END,
                     CASE WHEN has_target_reqtype AND coalesce(target_reqtype_maxlen,0) > 0 AND target_reqtype_maxlen <= 3 THEN 'PRT'
                          WHEN has_target_reqtype THEN 'PRINT'
                          ELSE NULL::text
                     END
              FROM generate_series(1, v_cnt) s(i);
            ELSE
              INSERT INTO regprc.printing_orders (id, rid, request_id, request_type)
              SELECT (extract(epoch from now())*1000000)::bigint + i,
                     CASE WHEN coalesce(rid_dtype,'') IN ('character varying','text','character')
                          THEN to_char(now(),'YYYYMMDDHH24MISS')
                          ELSE ((extract(epoch from now())*1000000)::bigint + i)::text END,
                     (CASE 
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') IN ('character varying','text','character') THEN 
                         CASE WHEN coalesce(reqid_maxlen,0) >= 14 THEN to_char(now(),'YYYYMMDDHH24MISS')
                              WHEN coalesce(reqid_maxlen,0) >= 12 THEN to_char(now(),'YYYYMMDDHH24MI')
                              WHEN coalesce(reqid_maxlen,0) >= 10 THEN ((extract(epoch from now())*1000)::bigint)::text
                              ELSE lpad(i::text, GREATEST(coalesce(reqid_maxlen,1),1), '0') END
                       WHEN has_reqid AND reqid_not_null AND coalesce(reqid_dtype,'') = 'uuid' THEN gen_random_uuid()::text
                       WHEN has_reqid AND reqid_not_null THEN ((extract(epoch from now())*1000)::bigint)::text
                       ELSE NULL::text
                     END)::text,
                     CASE WHEN has_reqtype THEN 
                       CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                            ELSE 'PRINT'::text
                       END
                       ELSE NULL::text
                     END
              FROM generate_series(1, v_cnt) s(i);
            END IF;
          END IF;
        ELSIF has_cr_by AND has_cr_dtimes AND NOT coalesce(crdt_is_generated,false) THEN
          INSERT INTO regprc.printing_orders (id, request_type, cr_by, cr_dtimes)
          SELECT (extract(epoch from now())*1000000)::bigint + i, 
                 CASE WHEN has_reqtype AND reqtype_not_null THEN 
                   CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                        ELSE 'PRINT'::text
                   END
                   ELSE NULL::text
                 END,
                 'sim', now()
          FROM generate_series(1, v_cnt) s(i);
        ELSIF has_cr_by THEN
          INSERT INTO regprc.printing_orders (id, request_type, cr_by)
          SELECT (extract(epoch from now())*1000000)::bigint + i,
                 CASE WHEN has_reqtype AND reqtype_not_null THEN 
                   CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                        ELSE 'PRINT'::text
                   END
                   ELSE NULL::text
                 END,
                 'sim'
          FROM generate_series(1, v_cnt) s(i);
        ELSIF has_cr_dtimes AND NOT coalesce(crdt_is_generated,false) THEN
          INSERT INTO regprc.printing_orders (id, request_type, cr_dtimes)
          SELECT (extract(epoch from now())*1000000)::bigint + i,
                 CASE WHEN has_reqtype AND reqtype_not_null THEN 
                   CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                        ELSE 'PRINT'::text
                   END
                   ELSE NULL::text
                 END,
                 now()
          FROM generate_series(1, v_cnt) s(i);
        ELSE
          INSERT INTO regprc.printing_orders (id, request_type)
          SELECT (extract(epoch from now())*1000000)::bigint + i,
                 CASE WHEN has_reqtype AND reqtype_not_null THEN 
                   CASE WHEN coalesce(reqtype_dtype,'') IN ('character varying','text','character') THEN 'PRINT'
                        ELSE 'PRINT'::text
                   END
                   ELSE NULL::text
                 END
          FROM generate_series(1, v_cnt) s(i);
        END IF;
      END IF;
    END;
  END IF;
END $$;


