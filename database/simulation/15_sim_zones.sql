\c mosip_master 

-- Génération synthétique des zones (Région -> Préfecture -> Commune)
-- Paramètres par défaut: 10 régions, 5 préfectures/région, 4 communes/préfecture
-- Usage: psql -v nb_regions=10 -v nb_pref=5 -v nb_comm=4 -f 15_sim_zones.sql
\set nb_regions 10
\set nb_pref 5
\set nb_comm 4

-- Régions (niveau 1)
INSERT INTO master.zone(code,name,hierarchy_level,hierarchy_level_name,hierarchy_path,parent_zone_code,lang_code,is_active,cr_by,cr_dtimes)
SELECT 'R'||i::text, 'Region '||i, 1, 'Region', '/R'||i::text, NULL, 'fra', true, 'sim', now()
FROM generate_series(1, :nb_regions) i
ON CONFLICT DO NOTHING;

-- Préfectures (niveau 2)
INSERT INTO master.zone(code,name,hierarchy_level,hierarchy_level_name,hierarchy_path,parent_zone_code,lang_code,is_active,cr_by,cr_dtimes)
SELECT 'P'||r||'_'||p,
       'Prefecture '||r||'-'||p,
       2,'Prefecture', '/R'||r||'/P'||r||'_'||p,
       'R'||r, 'fra', true, 'sim', now()
FROM generate_series(1, :nb_regions) r,
     generate_series(1, :nb_pref) p
ON CONFLICT DO NOTHING;

-- Communes (niveau 3)
INSERT INTO master.zone(code,name,hierarchy_level,hierarchy_level_name,hierarchy_path,parent_zone_code,lang_code,is_active,cr_by,cr_dtimes)
SELECT 'C'||r||'_'||p||'_'||c,
       'Commune '||r||'-'||p||'-'||c,
       3,'Commune', '/R'||r||'/P'||r||'_'||p||'/C'||r||'_'||p||'_'||c,
       'P'||r||'_'||p, 'fra', true, 'sim', now()
FROM generate_series(1, :nb_regions) r,
     generate_series(1, :nb_pref) p,
     generate_series(1, :nb_comm) c
ON CONFLICT DO NOTHING;


