-- Notifications simples (audit) si base mosip_audit disponible
\c mosip_audit 

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='audit' AND table_name='app_audit_log') THEN
    INSERT INTO audit.app_audit_log (id, module_name, event_name, description, created_by, created_at)
    VALUES (gen_random_uuid(), 'simulation', 'workflow_step', 'Cycle simulation step completed', 'sim', now());
  END IF;
END $$;


