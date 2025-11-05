-- Notifications simples (audit) si base mosip_audit disponible
\c mosip_audit 

DO $$
DECLARE has_table boolean;
        has_id boolean; has_module boolean; has_event boolean; has_descr boolean; has_cby boolean; has_cat boolean;
BEGIN
  SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='audit' AND table_name='app_audit_log') INTO has_table;
  IF NOT has_table THEN RETURN; END IF;

  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='audit' AND table_name='app_audit_log' AND column_name='id') INTO has_id;
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='audit' AND table_name='app_audit_log' AND column_name='module_name') INTO has_module;
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='audit' AND table_name='app_audit_log' AND column_name='event_name') INTO has_event;
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='audit' AND table_name='app_audit_log' AND column_name='description') INTO has_descr;
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='audit' AND table_name='app_audit_log' AND column_name='created_by') INTO has_cby;
  SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='audit' AND table_name='app_audit_log' AND column_name='created_at') INTO has_cat;

  IF has_module AND has_event THEN
    -- Prefer columns with defaults or nullable PKs, otherwise skip to avoid NOT NULL violations
    IF has_id AND EXISTS (
         SELECT 1 FROM information_schema.columns 
         WHERE table_schema='audit' AND table_name='app_audit_log' AND column_name='id' AND (column_default IS NOT NULL OR is_nullable='YES')
       ) THEN
      IF has_descr AND has_cby AND has_cat THEN
        INSERT INTO audit.app_audit_log (module_name, event_name, description, created_by, created_at)
        VALUES ('simulation', 'workflow_step', 'Cycle simulation step completed', 'sim', now());
      ELSE
        INSERT INTO audit.app_audit_log (module_name, event_name)
        VALUES ('simulation', 'workflow_step');
      END IF;
    ELSIF EXISTS (
         SELECT 1 FROM information_schema.columns 
         WHERE table_schema='audit' AND table_name='app_audit_log' AND column_name='log_id' AND (column_default IS NOT NULL OR is_nullable='YES')
       ) THEN
      IF has_descr AND has_cby AND has_cat THEN
        INSERT INTO audit.app_audit_log (log_id, module_name, event_name, description, created_by, created_at)
        VALUES (DEFAULT, 'simulation', 'workflow_step', 'Cycle simulation step completed', 'sim', now());
      ELSE
        INSERT INTO audit.app_audit_log (log_id, module_name, event_name)
        VALUES (DEFAULT, 'simulation', 'workflow_step');
      END IF;
    END IF;
  END IF;
END $$;


