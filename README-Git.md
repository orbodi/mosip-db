# Configuration Git - MOSIP Database

Ce document explique la configuration Git du projet MOSIP Database.

## 📁 Fichiers de Configuration Git

### `.gitignore`
Exclut les fichiers qui ne doivent pas être versionnés :
- **Données sensibles** : mots de passe, clés privées, certificats
- **Fichiers temporaires** : logs, cache, fichiers temporaires
- **Données Docker** : volumes, données de base de données
- **Fichiers IDE** : configuration d'éditeurs
- **Fichiers système** : fichiers OS spécifiques

### `.gitattributes`
Définit les attributs des fichiers :
- **Fins de ligne** : LF pour Unix/Linux, CRLF pour Windows
- **Types de fichiers** : texte vs binaire
- **Diff personnalisés** : pour SQL, YAML, JSON
- **Merge settings** : pour les fichiers de configuration

### `.dockerignore`
Optimise les builds Docker en excluant :
- **Documentation** : README, docs
- **Fichiers Git** : .git, .gitignore
- **Données** : volumes Docker, logs
- **Fichiers temporaires** : cache, build

## 🔧 Configuration Recommandée

### Configuration Git Globale
```bash
# Configurer l'éditeur par défaut
git config --global core.editor "code --wait"

# Configurer les fins de ligne
git config --global core.autocrlf input  # Linux/Mac
git config --global core.autocrlf true   # Windows

# Configurer le diff pour les fichiers SQL
git config --global diff.sql.textconv "cat"
```

### Configuration du Projet
```bash
# Initialiser le dépôt
git init

# Ajouter les fichiers de configuration
git add .gitignore .gitattributes .dockerignore

# Premier commit
git commit -m "Initial commit: Add Git configuration files"
```

## 📋 Workflow Recommandé

### 1. Branches
```bash
# Branche principale
main

# Branches de développement
develop
feature/docker-compose-profiles
feature/replication-logical
hotfix/security-update
```

### 2. Commits
```bash
# Format des messages de commit
<type>(<scope>): <description>

# Exemples
feat(docker): Add Docker Compose profiles
fix(replication): Fix logical replication configuration
docs(readme): Update deployment instructions
refactor(scripts): Simplify database deployment
```

### 3. Tags
```bash
# Tags de version
v1.0.0
v1.1.0
v2.0.0-beta

# Créer un tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

## 🚫 Fichiers à Ne Jamais Commiter

### Données Sensibles
- Mots de passe
- Clés privées
- Certificats
- Tokens d'API

### Données de Base de Données
- Fichiers de données PostgreSQL
- Dumps de base de données
- Logs de base de données

### Fichiers Temporaires
- Cache
- Fichiers temporaires
- Logs d'application

## ✅ Fichiers à Toujours Commiter

### Configuration
- `docker-compose.yml`
- `mosip.env` (template)
- Scripts de déploiement
- Configuration PostgreSQL

### Documentation
- `README.md`
- `PROFILES.md`
- Scripts d'aide

### Code Source
- Scripts Shell
- Scripts SQL
- Scripts PowerShell

## 🔍 Vérification des Fichiers

### Vérifier les fichiers ignorés
```bash
# Lister les fichiers ignorés
git status --ignored

# Vérifier si un fichier est ignoré
git check-ignore <fichier>
```

### Vérifier les attributs
```bash
# Voir les attributs d'un fichier
git check-attr -a <fichier>

# Voir tous les attributs
git check-attr -a -- <fichier>
```

## 🛠️ Maintenance

### Nettoyer les fichiers ignorés
```bash
# Supprimer les fichiers ignorés du working directory
git clean -fd

# Voir ce qui sera supprimé (dry run)
git clean -fd --dry-run
```

### Mettre à jour .gitignore
```bash
# Ajouter un fichier déjà tracké au .gitignore
git rm --cached <fichier>
git add .gitignore
git commit -m "Add <fichier> to .gitignore"
```

## 📚 Ressources

- [Git Documentation](https://git-scm.com/doc)
- [Git Ignore Patterns](https://git-scm.com/docs/gitignore)
- [Git Attributes](https://git-scm.com/docs/gitattributes)
- [Docker Ignore](https://docs.docker.com/engine/reference/builder/#dockerignore-file)

## ⚠️ Notes Importantes

1. **Ne jamais commiter de données sensibles**
2. **Toujours tester les changements avant de commiter**
3. **Utiliser des messages de commit descriptifs**
4. **Maintenir la cohérence des fins de ligne**
5. **Documenter les changements importants**
