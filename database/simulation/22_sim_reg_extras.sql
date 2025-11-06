\c mosip_regprc 

-- Additional regprc data simulation (schema-adaptive)
DO $$
DECLARE
  n int := 100;
BEGIN
  -- registrations / registration
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='regprc' AND table_name='registrations') THEN
    INSERT INTO regprc.registrations (id, rid, status_code, lang_code, cr_by, cr_dtimes)
    SELECT gen_random_uuid(), 'RID'||to_char(now(),'YYYYMMDDHH24')||lpad(i::text,6,'0'), 'CREATED','fra','sim', now() - (random()*'2 days'::interval)
    FROM generate_series(1, n) s(i)
    ON CONFLICT DO NOTHING;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='regprc' AND table_name='registrations_list') THEN
    INSERT INTO regprc.registrations_list (rid, status_code, lang_code, cr_by, cr_dtimes)
    SELECT 'RID'||to_char(now(),'YYYYMMDDHH24')||lpad(i::text,6,'0'), 'CREATED','fra','sim', now()
    FROM generate_series(1, n/2) s(i)
    ON CONFLICT DO NOTHING;
  END IF;

  -- registrations_transactions
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='regprc' AND table_name='registrations_transactions') THEN
    INSERT INTO regprc.registrations_transactions (id, rid, status_code, cr_by, cr_dtimes)
    SELECT gen_random_uuid(),
           'RID'||to_char(now(),'YYYYMMDDHH24')||lpad(i::text,6,'0'),
           CASE WHEN random()<0.9 THEN 'IN_PROGRESS' ELSE 'CREATED' END,
           'sim', now()
    FROM generate_series(1, n) s(i)
    ON CONFLICT DO NOTHING;
  END IF;

  -- rid_uin_link
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='regprc' AND table_name='rid_uin_link') THEN
    INSERT INTO regprc.rid_uin_link (rid, uin, cr_by, cr_dtimes)
    SELECT 'RID'||to_char(now(),'YYYYMMDD')||lpad(i::text,6,'0'), lpad((1000000000+i)::text, 12, '0'), 'sim', now()
    FROM generate_series(1, 20) s(i)
    ON CONFLICT DO NOTHING;
  END IF;

  -- printing_orders_details (attach to existing printing_orders if present)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='regprc' AND table_name='printing_orders_details')
     AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='regprc' AND table_name='printing_orders') THEN
    INSERT INTO regprc.printing_orders_details (printing_order_id, detail_key, detail_value)
    SELECT po.id, 'batch', 'B'||to_char(now(),'HH24MISS')
    FROM regprc.printing_orders po
    ORDER BY po.id DESC LIMIT 50
    ON CONFLICT DO NOTHING;
  END IF;

  -- printing_shipped_cards (based on existing orders if present columns align)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='regprc' AND table_name='printing_shipped_cards')
     AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='regprc' AND table_name='printing_orders') THEN
    INSERT INTO regprc.printing_shipped_cards (printing_order_id, shipped_on, carrier, tracking_no)
    SELECT po.id, now(), 'DHL', 'TRK'||po.id::text
    FROM regprc.printing_orders po
    ORDER BY po.id DESC LIMIT 30
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


