
-- Publications extracted from dump TOCs on 2025-11-03
-- Note: Qualify tables with schema. Adjust owners/privileges separately if needed.

-- mosip_master
DO $$ BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_publication WHERE pubname = 'dbz_publication'
    ) THEN
        EXECUTE 'DROP PUBLICATION dbz_publication';
    END IF;
END $$;

CREATE PUBLICATION dbz_publication WITH (publish = 'insert, update, delete');
ALTER PUBLICATION dbz_publication ADD TABLE
    master.applicant_valid_document,
    master.doc_category,
    master.doc_type,
    master.dynamic_field,
    master.location,
    master.machine_master,
    master.machine_spec,
    master.machine_type,
    master.registration_center,
    master.zone;

-- mosip_regprc
DO $$ BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_publication WHERE pubname = 'dbz_publication'
    ) THEN
        EXECUTE 'DROP PUBLICATION dbz_publication';
    END IF;
END $$;

CREATE PUBLICATION dbz_publication WITH (publish = 'insert, update, delete');
ALTER PUBLICATION dbz_publication ADD TABLE
    regprc.printing_orders,
    regprc.printing_orders_details,
    regprc.printing_processing_jobs,
    regprc.printing_shipped_cards,
    regprc.registration,
    regprc.registration_list,
    regprc.registration_transaction,
    regprc.rid_uin_link;

-- mosip_prereg
DO $$ BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_publication WHERE pubname = 'dbz_publication'
    ) THEN
        EXECUTE 'DROP PUBLICATION dbz_publication';
    END IF;
END $$;

CREATE PUBLICATION dbz_publication WITH (publish = 'insert, update, delete');
ALTER PUBLICATION dbz_publication ADD TABLE
    prereg.applicant_demographic,
    prereg.applicant_demographic_consumed;

-- mosip_ida
DO $$ BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_publication WHERE pubname = 'dbz_publication'
    ) THEN
        EXECUTE 'DROP PUBLICATION dbz_publication';
    END IF;
END $$;

CREATE PUBLICATION dbz_publication WITH (publish = 'insert, update, delete');
ALTER PUBLICATION dbz_publication ADD TABLE
    ida.auth_transaction,
    ida.otp_transaction;

-- mosip_audit
DO $$ BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_publication WHERE pubname = 'dbz_publication'
    ) THEN
        EXECUTE 'DROP PUBLICATION dbz_publication';
    END IF;
END $$;

CREATE PUBLICATION dbz_publication WITH (publish = 'insert, update, delete');
ALTER PUBLICATION dbz_publication ADD TABLE
    audit.app_audit_log;

DO $$ BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_publication WHERE pubname = 'dbz_publication_audit'
    ) THEN
        EXECUTE 'DROP PUBLICATION dbz_publication_audit';
    END IF;
END $$;

CREATE PUBLICATION dbz_publication_audit WITH (publish = 'insert, update, delete');
ALTER PUBLICATION dbz_publication_audit ADD TABLE
    audit.app_audit_log,
    audit.app_audit_log_archive01;

-- tsp_audit
DO $$ BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_publication WHERE pubname = 'dbz_publication'
    ) THEN
        EXECUTE 'DROP PUBLICATION dbz_publication';
    END IF;
END $$;

CREATE PUBLICATION dbz_publication WITH (publish = 'insert, update, delete');
ALTER PUBLICATION dbz_publication ADD TABLE
    schtsp.tsp_audit;

-- auaudit
DO $$ BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_publication WHERE pubname = 'dbz_publication'
    ) THEN
        EXECUTE 'DROP PUBLICATION dbz_publication';
    END IF;
END $$;

CREATE PUBLICATION dbz_publication WITH (publish = 'insert, update, delete');
ALTER PUBLICATION dbz_publication ADD TABLE
    public.audit_data;

-- Note: Run the relevant block in the target database (connection) for each schema above.
-- Example: \c mosip_master, then run the mosip_master block; and so on for each DB.

-- Variables attendues (psql -v):
--   :target_db, :target_schema, :replication_user, :publication_name

-- Ce script doit être exécuté connecté à la base :target_db en tant que :replication_user

-- Privilèges pour l'utilisateur de réplication sur le schéma
GRANT USAGE ON SCHEMA :"target_schema" TO :"replication_user";
GRANT SELECT ON ALL TABLES IN SCHEMA :"target_schema" TO :"replication_user";
ALTER DEFAULT PRIVILEGES IN SCHEMA :"target_schema" GRANT SELECT ON TABLES TO :"replication_user";

-- Injecter les variables côté serveur pour usage dans le DO
SELECT set_config('mosip.rep_pub_name', :'publication_name', false);

-- Créer la publication vide si absente (aucune table ajoutée par défaut)
DO $$
DECLARE
    pub_name text := current_setting('mosip.rep_pub_name');
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = pub_name) THEN
        EXECUTE format('CREATE PUBLICATION %I', pub_name);
    END IF;
END$$;
