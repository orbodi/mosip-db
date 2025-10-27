#!/bin/bash
set -e

# Configuration de sauvegarde
DB_HOST="postgres"
DB_PORT="5432"
DB_USER="postgres"
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Créer le répertoire de sauvegarde s'il n'existe pas
mkdir -p $BACKUP_DIR

echo "Starting backup at $(date)"

# Liste des bases de données MOSIP
DATABASES=(
    "mosip_master"
    "mosip_kernel"
    "mosip_iam"
    "mosip_ida"
    "mosip_idrepo"
    "mosip_idmap"
    "mosip_prereg"
    "mosip_reg"
    "mosip_regprc"
    "mosip_audit"
    "mosip_pmp"
)

# Fonction de sauvegarde d'une base de données
backup_database() {
    local db_name=$1
    local backup_file="$BACKUP_DIR/${db_name}_${DATE}.sql"
    
    echo "Backing up database: $db_name"
    
    if PGPASSWORD=$POSTGRES_PASSWORD pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $db_name > $backup_file; then
        echo "✅ Backup successful for $db_name"
        
        # Compresser la sauvegarde
        gzip $backup_file
        echo "✅ Compressed backup: ${backup_file}.gz"
        
        # Supprimer les sauvegardes de plus de 7 jours
        find $BACKUP_DIR -name "${db_name}_*.sql.gz" -mtime +7 -delete
        echo "✅ Cleaned old backups for $db_name"
    else
        echo "❌ Backup failed for $db_name"
        return 1
    fi
}

# Attendre que PostgreSQL soit prêt
echo "Waiting for PostgreSQL to be ready..."
until PGPASSWORD=$POSTGRES_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c '\q' 2>/dev/null; do
    echo "PostgreSQL is unavailable - sleeping"
    sleep 2
done

echo "PostgreSQL is ready - starting backup process"

# Sauvegarder chaque base de données
for db in "${DATABASES[@]}"; do
    backup_database $db
done

# Créer une sauvegarde complète
echo "Creating full database backup..."
FULL_BACKUP_FILE="$BACKUP_DIR/mosip_full_${DATE}.sql"
if PGPASSWORD=$POSTGRES_PASSWORD pg_dumpall -h $DB_HOST -p $DB_PORT -U $DB_USER > $FULL_BACKUP_FILE; then
    echo "✅ Full backup successful"
    gzip $FULL_BACKUP_FILE
    echo "✅ Compressed full backup: ${FULL_BACKUP_FILE}.gz"
    
    # Supprimer les sauvegardes complètes de plus de 30 jours
    find $BACKUP_DIR -name "mosip_full_*.sql.gz" -mtime +30 -delete
    echo "✅ Cleaned old full backups"
else
    echo "❌ Full backup failed"
fi

echo "Backup process completed at $(date)"
echo "Backup files created:"
ls -la $BACKUP_DIR/*.gz
