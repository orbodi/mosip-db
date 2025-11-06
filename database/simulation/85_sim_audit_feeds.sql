-- Feed audit-like tables across various DBs (schema-adaptive)

-- TSP DB : tsp_audit.schtsp.tsp_audit
\c tsp_audit 
DO $$
DECLARE n int := 100; BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='schtsp' AND table_name='tsp_audit') THEN
    INSERT INTO schtsp.tsp_audit (id, event_type, description, created_at)
    SELECT gen_random_uuid(), 'SIM', 'Simulated TSP event '||i, now()
    FROM generate_series(1, n) s(i)
    ON CONFLICT DO NOTHING;
  END IF;
END $$;

-- AU DB : auaudit.public.audit_data
\c auaudit 
DO $$
DECLARE n int := 100; BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='audit_data') THEN
    INSERT INTO public.audit_data (id, module_name, activity_type, activity_ts, details)
    SELECT gen_random_uuid(), 'SIM', 'WRITE', now(), jsonb_build_object('msg','sim event','i',i)
    FROM generate_series(1, n) s(i)
    ON CONFLICT DO NOTHING;
  END IF;
END $$;

-- KERNEL DB : mosip_kernel.kernel.kernel_notifications_audit
\c mosip_kernel 
DO $$
DECLARE n int := 100; BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='kernel' AND table_name='kernel_notifications_audit') THEN
    INSERT INTO kernel.kernel_notifications_audit (id, module_name, event_name, created_at)
    SELECT gen_random_uuid(), 'SIM', 'NOTIFY', now()
    FROM generate_series(1, n) s(i)
    ON CONFLICT DO NOTHING;
  END IF;
END $$;

-- AUDIT DB : mosip_audit.audit.app_audit_log
\c mosip_audit 
DO $$
DECLARE n int := 100; BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='audit' AND table_name='app_audit_log') THEN
    -- choose flexible minimal columns
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='audit' AND table_name='app_audit_log' AND column_name='module_name') THEN
      INSERT INTO audit.app_audit_log (module_name, event_name, description, created_by, created_at)
      SELECT 'SIM','CYCLE','Simulated audit log','sim', now()
      FROM generate_series(1, n) s(i);
    ELSE
      INSERT INTO audit.app_audit_log (event_name, description)
      SELECT 'CYCLE','Simulated audit log'
      FROM generate_series(1, n) s(i);
    END IF;
  END IF;
END $$;


