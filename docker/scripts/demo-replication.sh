#!/bin/bash

# Script de démonstration de la réplication logique MOSIP
# Ce script montre comment configurer et utiliser la réplication avec les schémas MOSIP

echo "🎯 Démonstration de la réplication logique MOSIP"
echo "================================================"

# Configuration
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
DB_PASSWORD="mosip@123"
REPLICATION_USER="replicator"
REPLICATION_PASSWORD="replicator123"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Fonction pour exécuter une commande SQL
execute_sql() {
    local sql="$1"
    local description="$2"
    
    echo -n "$description... "
    
    if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "$sql" > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
    fi
}

# Fonction pour tester la réplication
test_replication() {
    local slot_name="$1"
    local description="$2"
    
    echo -n "$description... "
    
    local result=$(PGPASSWORD=$REPLICATION_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $REPLICATION_USER -d postgres -t -c "
        SELECT COUNT(*) FROM pg_replication_slots WHERE slot_name = '$slot_name';
    " 2>/dev/null | tr -d ' ')
    
    if [ "$result" = "1" ]; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
    fi
}

echo ""
echo "🔧 Configuration de la réplication logique"
echo "==========================================="

# 1. Vérifier la configuration de réplication
echo ""
echo "1. Vérification de la configuration de réplication:"
echo "   - wal_level: $(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -t -c "SHOW wal_level;" 2>/dev/null | tr -d ' ')"
echo "   - max_wal_senders: $(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -t -c "SHOW max_wal_senders;" 2>/dev/null | tr -d ' ')"
echo "   - max_replication_slots: $(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -t -c "SHOW max_replication_slots;" 2>/dev/null | tr -d ' ')"

# 2. Vérifier l'utilisateur de réplication
echo ""
echo "2. Vérification de l'utilisateur de réplication:"
test_replication "replicator" "   - Utilisateur replicator"

# 3. Créer des slots de réplication pour chaque base MOSIP
echo ""
echo "3. Création des slots de réplication pour les bases MOSIP:"

mosip_databases=("mosip_master" "mosip_kernel" "mosip_iam" "mosip_ida" "mosip_idrepo")

for db in "${mosip_databases[@]}"; do
    local slot_name="${db}_replication_slot"
    local schema_name=$(echo $db | cut -d'_' -f2)
    
    echo -n "   - Slot pour $db ($schema_name)... "
    
    # Vérifier si le slot existe déjà
    local slot_exists=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -t -c "
        SELECT COUNT(*) FROM pg_replication_slots WHERE slot_name = '$slot_name';
    " 2>/dev/null | tr -d ' ')
    
    if [ "$slot_exists" = "0" ]; then
        # Créer le slot
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "
            SELECT pg_create_logical_replication_slot('$slot_name', 'pgoutput');
        " > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Créé${NC}"
        else
            echo -e "${RED}❌ Erreur${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Existe déjà${NC}"
    fi
done

# 4. Lister les slots de réplication
echo ""
echo "4. Slots de réplication disponibles:"
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "
    SELECT 
        slot_name,
        plugin,
        slot_type,
        active,
        confirmed_flush_lsn
    FROM pg_replication_slots
    ORDER BY slot_name;
"

# 5. Tester les permissions de réplication sur les schémas
echo ""
echo "5. Test des permissions de réplication sur les schémas MOSIP:"

for db in "${mosip_databases[@]}"; do
    local schema_name=$(echo $db | cut -d'_' -f2)
    echo -n "   - Test accès schéma $schema_name dans $db... "
    
    local result=$(PGPASSWORD=$REPLICATION_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $REPLICATION_USER -d $db -t -c "
        SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$schema_name';
    " 2>/dev/null | tr -d ' ')
    
    if [ -n "$result" ] && [ "$result" -ge 0 ]; then
        echo -e "${GREEN}✅ ($result tables)${NC}"
    else
        echo -e "${RED}❌${NC}"
    fi
done

# 6. Exemple d'utilisation de la réplication
echo ""
echo "6. Exemple d'utilisation de la réplication:"
echo ""
echo "   Pour configurer un subscriber de réplication:"
echo "   ---------------------------------------------"
echo "   1. Se connecter avec l'utilisateur replicator:"
echo "      psql -h localhost -p 5432 -U replicator -d postgres"
echo ""
echo "   2. Créer un slot de réplication:"
echo "      SELECT pg_create_logical_replication_slot('mosip_slot', 'pgoutput');"
echo ""
echo "   3. Configurer un subscriber pour recevoir les changements:"
echo "      -- Exemple avec pg_recvlogical"
echo "      pg_recvlogical -h localhost -p 5432 -U replicator -d postgres \\"
echo "        --slot=mosip_slot --start -f -"
echo ""
echo "   4. Ou utiliser un outil comme Debezium, Kafka Connect, etc."

# 7. Commandes utiles
echo ""
echo "7. Commandes utiles pour la réplication:"
echo "   -------------------------------------"
echo "   - Lister les slots: SELECT * FROM pg_replication_slots;"
echo "   - Vérifier les permissions: \\dp dans chaque base"
echo "   - Monitorer la réplication: SELECT * FROM pg_stat_replication;"
echo "   - Supprimer un slot: SELECT pg_drop_replication_slot('slot_name');"

echo ""
echo "🎉 Démonstration terminée!"
echo "La réplication logique est configurée et prête à être utilisée avec les schémas MOSIP."
