# MOSIP Logical Replication Setup

Ce dossier fournit des scripts shell pour créer et alimenter des publications de réplication logique PostgreSQL sur les bases MOSIP.

## Prérequis
- PostgreSQL ≥ 13 accessible depuis la machine d’exécution.
- L’utilisateur `sysadmin` (créé par les scripts MOSIP) doit avoir le droit REPLICATION et être autorisé dans `pg_hba.conf`.
- `psql` disponible dans le `$PATH`.
- Le fichier `replication_deploy.properties` correctement renseigné.

## Scripts disponibles

### 1. `replication_setup_deploy.sh`
Crée la publication logique et accorde les privilèges à `sysadmin` sur le schéma cible.

Fonctionnement :
- lit `replication_deploy.properties`
- vérifie la connexion via `DEFAULT_DB_NAME`
- exécute `replication_setup.sql` sur `TARGET_DB_NAME` avec `psql`

Ce que fait `replication_setup.sql` :
1. `GRANT USAGE` + `GRANT SELECT` sur le schéma `TARGET_SCHEMA` pour `SYSADMIN_USER`.
2. Pose des `DEFAULT PRIVILEGES` pour les futures tables du schéma.
3. Crée la publication `PUBLICATION_NAME` si elle n’existe pas (publication vide).

### 2. `replication_add_tables_deploy.sh`
Ajoute une liste de tables existantes à une publication logique déjà créée.

Fonctionnement :
- lit le même fichier `.properties`
- exécute `replication_add_tables.sql`
- ajoute chaque table listée (`TABLE_LIST`) à `PUBLICATION_NAME`

## Fichier de propriétés `replication_deploy.properties`
Paramètres principaux :
- **Connexion** : `DB_SERVERIP`, `DB_PORT`, `SU_USER`, `SU_USER_PWD`, `DEFAULT_DB_NAME`
- **Cible** : `TARGET_DB_NAME`, `TARGET_SCHEMA`
- **Publication** : `PUBLICATION_NAME`
- **Tables à ajouter** : `TABLE_LIST` (liste séparée par des virgules)
- **Logs** : `LOG_PATH`

## Exemples d’usage

### Créer une publication vide sur `mosip_master.master`
```bash
cd replication-setup
sed -i 's/^TARGET_DB_NAME=.*/TARGET_DB_NAME=mosip_master/' replication_deploy.properties
sed -i 's/^TARGET_SCHEMA=.*/TARGET_SCHEMA=master/' replication_deploy.properties
sed -i 's/^PUBLICATION_NAME=.*/PUBLICATION_NAME=master_pub/' replication_deploy.properties

bash replication_setup_deploy.sh replication_deploy.properties
```

### Ajouter des tables à la publication `master_pub`
```bash
sed -i 's/^TABLE_LIST=.*/TABLE_LIST=master.location, master.loc_holiday/' replication_deploy.properties
bash replication_add_tables_deploy.sh replication_deploy.properties
```

## Vérifications utiles
Dans la base concernée :
```sql
-- Publications disponibles
SELECT pubname FROM pg_publication;

-- Tables d'une publication (PostgreSQL >= 15)
SELECT * FROM pg_publication_tables WHERE pubname = 'master_pub';
```

## Notes
- Si le schéma n’existe pas encore, créez-le avant d’exécuter les scripts.
- Les publications créées sont initialement vides. Utilisez `replication_add_tables_deploy.sh` pour y ajouter des tables.
- Les scripts ne créent pas de slots de réplication ni de souscriptions : c’est à réaliser côté abonné.
- Assurez-vous que la configuration PostgreSQL (`wal_level`, `max_wal_senders`, etc.) permet la réplication logique.
