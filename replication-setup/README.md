# MOSIP Logical Replication Setup

Ce dossier contient les outils pour configurer la réplication logique PostgreSQL pour un schéma MOSIP, en utilisant l’utilisateur `sysadmin` existant.

## Prérequis
- Python 3.8+
- Dépendance Python:
```bash
pip install psycopg2-binary
```
- Accès à PostgreSQL avec l’utilisateur `sysadmin` (déjà créé par les scripts MOSIP) et droit REPLICATION (inclus par défaut).
- Le fichier `pg_hba.conf` doit autoriser votre IP/VM.

## Script principal
- `setup_publication.py`: crée une publication logique pour toutes les tables d’un schéma donné et s’assure que `sysadmin` a les privilèges nécessaires sur ce schéma.

## Usage
```bash
python3 setup_publication.py --db <base> --schema <schema> \
  --host <hôte> --port <port> \
  --sysadmin-user sysadmin --sysadmin-pwd '<motdepasse>' \
  [--publication-name <nom_pub>]
```

- Paramètres principaux:
  - `--db`: base cible (ex: `mosip_iam`)
  - `--schema`: schéma cible (ex: `iam`)
  - `--host`: hôte PostgreSQL (défaut: `localhost`)
  - `--port`: port PostgreSQL (défaut: `5433`)
  - `--sysadmin-user`: utilisateur sysadmin (défaut: `sysadmin`)
  - `--sysadmin-pwd`: mot de passe sysadmin (défaut: `Mosipadm@dev123`)
  - `--publication-name`: optionnel, sinon `<schema>_pub`

## Exemples
- IAM
```bash
python3 setup_publication.py --db mosip_iam --schema iam \
  --host localhost --port 5433 \
  --sysadmin-user sysadmin --sysadmin-pwd 'Mosipadm@dev123'
```

- IDREPO
```bash
python3 setup_publication.py --db mosip_idrepo --schema idrepo \
  --host localhost --port 5433
```

- MASTER
```bash
python3 setup_publication.py --db mosip_master --schema master \
  --host localhost --port 5433
```

## Ce que fait le script
1. Accorde au `sysadmin` les privilèges sur le schéma (`USAGE`, `SELECT`, `DEFAULT PRIVILEGES`).
2. Crée la publication logique `<schema>_pub` (ou `--publication-name`) pour toutes les tables du schéma.

## Vérifications
Dans la base concernée:
```sql
-- Publication
SELECT pubname FROM pg_publication;

-- Tables dans la publication (PostgreSQL >= 15)
SELECT * FROM pg_publication_tables WHERE pubname = '<schema>_pub';
```

## Notes
- Si le schéma n’existe pas encore, créez-le avant d’exécuter le script.
- Pour les nouvelles tables, la publication `FOR ALL TABLES IN SCHEMA` inclut automatiquement les futures tables (PostgreSQL 15+). Pour des versions plus anciennes, il peut être nécessaire d’ajouter les tables via `ALTER PUBLICATION ... ADD TABLE`.
- Assurez-vous que la collation/locale des bases MOSIP est cohérente si vous créez de nouvelles bases (utiliser `TEMPLATE = template0` si besoin).
