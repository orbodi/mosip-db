# MOSIP Database Docker Deployment

Ce dossier contient tous les fichiers nécessaires pour déployer les bases de données MOSIP avec Docker.

## 📁 Structure des Dossiers

```
docker/
├── data/                          # Données persistantes PostgreSQL
├── config/                        # Configuration PostgreSQL
│   ├── postgresql.conf
│   └── pg_hba.conf
├── scripts/                       # Scripts de déploiement et maintenance
│   ├── init-db.sh
│   ├── deploy-scripts/
│   └── backup-scripts/
├── docker-compose.yml             # Configuration unifiée avec profils
├── mosip.env                      # Variables d'environnement
└── quick-start.sh                 # Script de démarrage rapide
```

## 🚀 Utilisation

### Démarrage Rapide (Recommandé)
```bash
# Depuis le dossier docker/
cd docker
chmod +x quick-start.sh
./quick-start.sh
```

### Démarrage Manuel avec Profils

#### Développement (PostgreSQL + pgAdmin)
```bash
cd docker
docker-compose --profile dev up -d
```

#### Développement Avancé (PostgreSQL + pgAdmin + Redis)
```bash
cd docker
docker-compose --profile dev-advanced up -d
```

#### Production (PostgreSQL + Sauvegardes automatiques)
```bash
cd docker
# Configurer les variables d'environnement
cp mosip.env .env
# Éditer .env avec vos mots de passe

# Démarrer en production
docker-compose --profile prod up -d
```

#### Tous les services
```bash
cd docker
docker-compose --profile dev --profile dev-advanced --profile prod up -d
```

## 📊 Accès

- **PostgreSQL:** localhost:5432
  - Utilisateur admin: postgres / mosip@123
  - Utilisateur réplication: replicator / replicator123
- **pgAdmin:** http://localhost:8080
  - Email: admin@mosip.local
  - Mot de passe: admin123
- **Redis (dev uniquement):** localhost:6379

## 🔄 Réplication Logique

La réplication logique PostgreSQL est activée avec les paramètres suivants :
- **wal_level:** logical
- **max_wal_senders:** 10
- **max_replication_slots:** 10
- **Utilisateur réplication:** replicator / replicator123

### Tester la réplication
```bash
cd docker
chmod +x scripts/test-replication.sh
./scripts/test-replication.sh
```

### Lister les schémas MOSIP
```bash
cd docker
chmod +x scripts/list-mosip-schemas.sh
./scripts/list-mosip-schemas.sh
```

### Démonstration de la réplication
```bash
cd docker
chmod +x scripts/demo-replication.sh
./scripts/demo-replication.sh
```

### Gérer les slots de réplication
```bash
cd docker
chmod +x scripts/manage-replication-slots.sh
./scripts/manage-replication-slots.sh
```

## 📊 Structure des Schémas

Chaque base de données MOSIP utilise un schéma principal correspondant à son nom :

| Base de données | Schéma principal | Description |
|----------------|------------------|-------------|
| `mosip_master` | `master` | Données de référence et configuration |
| `mosip_kernel` | `kernel` | Services de base et utilitaires |
| `mosip_iam` | `iam` | Gestion des identités et accès |
| `mosip_ida` | `ida` | Services d'authentification |
| `mosip_idrepo` | `idrepo` | Référentiel d'identité (UIN) |
| `mosip_idmap` | `idmap` | Cartographie des identités |
| `mosip_prereg` | `prereg` | Pré-enregistrement |
| `mosip_reg` | `reg` | Enregistrement |
| `mosip_regprc` | `regprc` | Traitement des enregistrements |
| `mosip_audit` | `audit` | Audit et logs |
| `mosip_pmp` | `pmp` | Gestion des partenaires |

L'utilisateur de réplication `replicator` a accès en lecture à tous ces schémas.

## 🔧 Configuration

### Données
Les données PostgreSQL sont stockées dans `./data/`

### Configuration
Les fichiers de configuration PostgreSQL sont dans `./config/`

### Scripts
Les scripts de déploiement et sauvegarde sont dans `./scripts/`

## 🔄 Gestion

### Redémarrer
```bash
docker-compose restart
```

### Arrêter
```bash
docker-compose down
```

### Supprimer les données
```bash
docker-compose down -v
rm -rf data/*
```
