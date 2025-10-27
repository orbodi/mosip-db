#!/bin/bash

# Script pour lister les schémas de chaque base de données MOSIP

echo "📋 Schémas des bases de données MOSIP"
echo "====================================="

# Configuration
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
DB_PASSWORD="mosip@123"

# Couleurs pour l'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Liste des bases de données MOSIP
mosip_databases=(
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

# Fonction pour lister les schémas d'une base de données
list_schemas() {
    local db_name=$1
    local schema_name=$(echo $db_name | cut -d'_' -f2)
    
    echo ""
    echo -e "${BLUE}Base de données: $db_name${NC}"
    echo -e "${YELLOW}Schéma principal: $schema_name${NC}"
    echo "----------------------------------------"
    
    # Lister tous les schémas de la base
    local schemas=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $db_name -t -c "
        SELECT schema_name 
        FROM information_schema.schemata 
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
        ORDER BY schema_name;
    " 2>/dev/null | tr -d ' ')
    
    if [ -n "$schemas" ]; then
        echo "Schémas disponibles:"
        echo "$schemas" | while read -r schema; do
            if [ "$schema" = "$schema_name" ]; then
                echo -e "  ${GREEN}✓ $schema (principal)${NC}"
            else
                echo -e "  - $schema"
            fi
        done
        
        # Compter les tables dans le schéma principal
        local table_count=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $db_name -t -c "
            SELECT COUNT(*) 
            FROM information_schema.tables 
            WHERE table_schema = '$schema_name';
        " 2>/dev/null | tr -d ' ')
        
        echo -e "  ${GREEN}Tables dans le schéma $schema_name: $table_count${NC}"
    else
        echo -e "${RED}Erreur lors de la récupération des schémas${NC}"
    fi
}

# Fonction pour tester la connexion
test_connection() {
    echo "Test de connexion à PostgreSQL..."
    if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Connexion réussie${NC}"
        return 0
    else
        echo -e "${RED}❌ Impossible de se connecter à PostgreSQL${NC}"
        return 1
    fi
}

# Exécution
if test_connection; then
    echo ""
    echo "Récupération des informations sur les schémas MOSIP..."
    
    for db in "${mosip_databases[@]}"; do
        list_schemas $db
    done
    
    echo ""
    echo "📊 Résumé"
    echo "========="
    echo "Chaque base de données MOSIP utilise un schéma principal correspondant à son nom :"
    echo "- mosip_master → schéma 'master'"
    echo "- mosip_kernel → schéma 'kernel'"
    echo "- mosip_iam → schéma 'iam'"
    echo "- etc."
    echo ""
    echo "L'utilisateur de réplication 'replicator' a accès à tous ces schémas."
else
    echo "Impossible de continuer sans connexion à PostgreSQL"
    exit 1
fi
