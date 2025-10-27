# MOSIP Database Docker Deployment

Ce projet fournit une solution Docker Compose pour déployer facilement toutes les bases de données MOSIP.

## 🚀 Démarrage Rapide

### Prérequis
- Docker
- Docker Compose
- Au moins 4GB de RAM disponible
- 10GB d'espace disque libre

### Installation

1. **Cloner le projet** (si ce n'est pas déjà fait)
```bash
git clone <repository-url>
cd mosip-db
```

2. **Démarrer les services**
```bash
docker-compose up -d
```

3. **Vérifier le déploiement**
```bash
docker-compose logs -f mosip-db-deployer
```

### Accès aux Bases de Données

Une fois le déploiement terminé, vous pouvez vous connecter à PostgreSQL :

**Host:** localhost  
**Port:** 5432  
**Utilisateur:** postgres  
**Mot de passe:** mosip@123  

**Bases de données créées:**
- mosip_master
- mosip_kernel  
- mosip_iam
- mosip_ida
- mosip_idrepo
- mosip_idmap
- mosip_prereg
- mosip_reg
- mosip_regprc
- mosip_audit
- mosip_pmp

## 🔧 Configuration

### Variables d'Environnement

Modifiez le fichier `mosip.env` pour personnaliser la configuration :

```env
POSTGRES_PASSWORD=mosip@123
SYSADMIN_PASSWORD=Mosipadm@dev123
# ... autres variables
```

### Ports

Par défaut, PostgreSQL est accessible sur le port 5432. Pour le modifier :

```yaml
# Dans docker-compose.yml
ports:
  - "VOTRE_PORT:5432"
```

## 📊 Monitoring

### Vérifier l'état des services
```bash
docker-compose ps
```

### Consulter les logs
```bash
# Tous les logs
docker-compose logs

# Logs spécifiques
docker-compose logs postgres
docker-compose logs mosip-db-deployer
```

### Accès direct à PostgreSQL
```bash
docker-compose exec postgres psql -U postgres
```

## 🗂️ Structure des Fichiers

```
mosip-db/
├── docker-compose.yml          # Configuration Docker Compose
├── init-db.sh                  # Script d'initialisation
├── mosip.env                   # Variables d'environnement
├── deploy-scripts/             # Scripts de déploiement
│   └── deploy-all-databases.sh
└── database/                   # Scripts de base de données MOSIP
    ├── mosip_master/
    ├── mosip_kernel/
    └── ...
```

## 🔄 Gestion des Services

### Redémarrer les services
```bash
docker-compose restart
```

### Arrêter les services
```bash
docker-compose down
```

### Supprimer toutes les données (ATTENTION!)
```bash
docker-compose down -v
```

## 🐛 Dépannage

### Problèmes courants

1. **Erreur de connexion à PostgreSQL**
   - Vérifiez que le port 5432 n'est pas utilisé
   - Attendez que PostgreSQL soit complètement démarré

2. **Échec du déploiement des bases de données**
   - Consultez les logs : `docker-compose logs mosip-db-deployer`
   - Vérifiez les permissions des scripts

3. **Problèmes de mémoire**
   - Augmentez la mémoire allouée à Docker
   - Redémarrez Docker Desktop

### Logs de déploiement

Les logs de déploiement sont disponibles dans le conteneur :
```bash
docker-compose exec mosip-db-deployer cat /var/log/mosip/deployment.log
```

## 🔒 Sécurité

⚠️ **Important:** Cette configuration est destinée au développement. Pour la production :

1. Changez tous les mots de passe par défaut
2. Utilisez des secrets Docker
3. Configurez un réseau privé
4. Activez SSL/TLS
5. Configurez des sauvegardes automatiques

## 📝 Notes

- Le déploiement initial peut prendre 5-10 minutes
- Les données sont persistantes via le volume Docker `postgres_data`
- Le conteneur `mosip-db-deployer` s'arrête automatiquement après le déploiement
