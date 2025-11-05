Simulation de flux et alimentation BI

Objectif
- Simuler des activités clés (enrôlement, ID Repo, authentification, mises à jour Master, PMS minimal) puis agréger des indicateurs pour un BI simple.

Pré-requis
- PostgreSQL client (psql) accessible et variables de connexion.
- Bases restaurées depuis les dumps (cf. database/custom-db).

Configuration
1) Copier puis éditer l'environnement:
   - `cd database/simulation`
   - `cp 00_env.example .env`
   - Renseigner `PGHOST/PGPORT/PGUSER/PGPASSWORD` et les volumes `SIM_*`.

Lancer un cycle de simulation
- Script unique (enchaîne baseline + inserts + agrégations):
```bash
cd database/simulation
chmod +x run_cycle.sh
./run_cycle.sh
```

Scripts inclus (exécutables aussi individuellement)
- `10_baseline_load.sql` (mosip_master): crée zone/centre minimaux.
- `20_sim_registrations.sql` (mosip_regprc): crée N registrations et transitions de statut.
- `25_sim_prereg.sql` (mosip_prereg): crée N pré-enregistrements (gestion défensive des colonnes).
- `30_sim_idrepo.sql` (mosip_idrepo): crée des UIN synthétiques.
- `40_sim_auth.sql` (mosip_ida): génère OTP/AUTH (succès/échec) paramétrables.
- `50_sim_master_updates.sql` (mosip_master): petites mises à jour sur devices/locations.
- `60_sim_pms.sql` (mosip_pms): graines minimales si tables présentes.
- `80_cdc_check.sql`: liste les publications `dbz_*` (CDC).
- `90_etl_to_dw.sql`: remplit `dw.fact_auth_daily` (agrégations AUTH/jour/type).

Paramétrage des volumes
- Via variables `SIM_*` (dans `.env` ou en ligne):
```bash
SIM_REG_COUNT=500 SIM_AUTH_COUNT=2000 SIM_OTP_COUNT=3000 ./run_cycle.sh
```

Planification (cron)
- Exemple: toutes les 5 min AUTH + ETL BI
```cron
*/5 * * * * cd /path/to/repo/database/simulation && ./run_cycle.sh >/tmp/sim_cycle.log 2>&1
```

Vérification BI
- Table d’agrégats: `mosip_ida.dw.fact_auth_daily`
```sql
SELECT * FROM dw.fact_auth_daily ORDER BY day DESC, auth_type;
```

Notes
- Les scripts sont idempotents au mieux (seed minimal), mais évitez de multiplier les bases seeds sans purge.
- Pour un CDC temps réel, utiliser Debezium/Kafka en consommant les publications `dbz_publication`.


