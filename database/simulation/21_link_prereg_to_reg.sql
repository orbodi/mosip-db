\c mosip_regprc 

-- Simuler le lien prereg -> registration en progressant des statuts
-- Usage: psql -v sim_reg_progress=300 -f 21_link_prereg_to_reg.sql
\set sim_reg_progress :sim_reg_progress 300

-- Passer CREATED -> IN_PROGRESS -> APPROVED sur un échantillon
DO $$
DECLARE has_reg_id boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema='regprc' AND table_name='registration' AND column_name='reg_id'
  ) INTO has_reg_id;

  IF has_reg_id THEN
    WITH samp AS (
      SELECT reg_id FROM regprc.registration WHERE status_code='CREATED' ORDER BY random() LIMIT :sim_reg_progress
    )
    UPDATE regprc.registration r SET status_code='IN_PROGRESS'
    FROM samp s WHERE r.reg_id = s.reg_id;

    WITH samp AS (
      SELECT reg_id FROM regprc.registration WHERE status_code='IN_PROGRESS' ORDER BY random() LIMIT (:sim_reg_progress*0.9)
    )
    UPDATE regprc.registration r SET status_code='APPROVED'
    FROM samp s WHERE r.reg_id = s.reg_id;
  ELSE
    WITH samp AS (
      SELECT id FROM regprc.registration WHERE status_code='CREATED' ORDER BY random() LIMIT :sim_reg_progress
    )
    UPDATE regprc.registration r SET status_code='IN_PROGRESS'
    FROM samp s WHERE r.id = s.id;

    WITH samp AS (
      SELECT id FROM regprc.registration WHERE status_code='IN_PROGRESS' ORDER BY random() LIMIT (:sim_reg_progress*0.9)
    )
    UPDATE regprc.registration r SET status_code='APPROVED'
    FROM samp s WHERE r.id = s.id;
  END IF;
END $$;

-- Optionnel: émettre une notification dans mosip_audit si la table existe
DO $$
BEGIN
  PERFORM 1 FROM pg_database WHERE datname='mosip_audit';
  -- Rien à faire ici (cross-DB direct non supporté); notifications globales dans 45_notifications.sql
END $$;


