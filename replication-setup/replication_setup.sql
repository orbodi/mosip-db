-- Replication setup SQL
-- Variables attendues (psql -v):
--   :target_db, :target_schema, :sysadmin_user, :publication_name

-- Ce script doit être exécuté connecté à la base :target_db en tant que :sysadmin_user

-- Privilèges pour le sysadmin sur le schéma
GRANT USAGE ON SCHEMA :"target_schema" TO :"sysadmin_user";
GRANT SELECT ON ALL TABLES IN SCHEMA :"target_schema" TO :"sysadmin_user";
ALTER DEFAULT PRIVILEGES IN SCHEMA :"target_schema" GRANT SELECT ON TABLES TO :"sysadmin_user";

-- Créer la publication vide si absente (aucune table ajoutée par défaut)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = :'publication_name') THEN
        EXECUTE format('CREATE PUBLICATION %I', :'publication_name');
    END IF;
END$$;
