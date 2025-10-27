-- Script de création de l'utilisateur de réplication pour MOSIP
-- Ce script doit être exécuté après la création des bases de données

-- Créer l'utilisateur de réplication
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'replicator') THEN
        CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replicator123';
        COMMENT ON ROLE replicator IS 'Utilisateur pour la réplication logique PostgreSQL';
    END IF;
END
$$;

-- Accorder les permissions nécessaires pour la réplication
GRANT CONNECT ON DATABASE postgres TO replicator;
GRANT USAGE ON SCHEMA public TO replicator;

-- Accorder les permissions sur toutes les bases de données MOSIP
DO $$
DECLARE
    db_name TEXT;
    schema_name TEXT;
    mosip_databases TEXT[] := ARRAY[
        'mosip_master',
        'mosip_kernel', 
        'mosip_iam',
        'mosip_ida',
        'mosip_idrepo',
        'mosip_idmap',
        'mosip_prereg',
        'mosip_reg',
        'mosip_regprc',
        'mosip_audit',
        'mosip_pmp'
    ];
BEGIN
    FOREACH db_name IN ARRAY mosip_databases
    LOOP
        -- Extraire le nom du schéma (partie après mosip_)
        schema_name := split_part(db_name, '_', 2);
        
        -- Accorder la connexion à la base de données
        EXECUTE format('GRANT CONNECT ON DATABASE %I TO replicator', db_name);
        
        -- Accorder l'usage du schéma correspondant
        EXECUTE format('GRANT USAGE ON SCHEMA %I TO replicator', schema_name);
        
        -- Accorder la lecture sur toutes les tables du schéma
        EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO replicator', schema_name);
        
        -- Accorder la lecture sur les futures tables du schéma
        EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT SELECT ON TABLES TO replicator', schema_name);
        
        -- Afficher les permissions accordées
        RAISE NOTICE 'Permissions accordées sur la base % et le schéma %', db_name, schema_name;
    END LOOP;
END
$$;

-- Créer un slot de réplication logique (optionnel)
-- SELECT pg_create_logical_replication_slot('mosip_replication_slot', 'pgoutput');

-- Afficher les informations de réplication
SELECT 
    rolname as role_name,
    rolreplication as can_replicate,
    rolcanlogin as can_login
FROM pg_roles 
WHERE rolname = 'replicator';

-- Afficher les slots de réplication
SELECT 
    slot_name,
    plugin,
    slot_type,
    active
FROM pg_replication_slots;
