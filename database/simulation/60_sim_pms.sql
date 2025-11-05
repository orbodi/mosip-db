\c mosip_pms 

-- Minimal partners/policies if tables exist
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='pms' AND table_name='partner_type') THEN
    IF NOT EXISTS (SELECT 1 FROM pms.partner_type WHERE code='ORG') THEN
      INSERT INTO pms.partner_type (code,partner_description,is_active,cr_by,cr_dtimes,is_policy_required)
      VALUES ('ORG','Organization',true,'sim',now(),true);
    END IF;
  END IF;
END $$;


