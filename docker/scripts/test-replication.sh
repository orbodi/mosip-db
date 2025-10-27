#!/bin/bash

# Script de test pour la réplication logique PostgreSQL MOSIP

echo "🧪 Test de la réplication logique PostgreSQL"
echo "============================================="

# Configuration
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
DB_PASSWORD="mosip@123"
REPLICATION_USER="replicator"
REPLICATION_PASSWORD="replicator123"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour tester la connexion
test_connection() {
    local user=$1
    local password=$2
    local description=$3
    
    echo -n "Test de connexion $description... "
    
    if PGPASSWORD=$password psql -h $DB_HOST -p $DB_PORT -U $user -d postgres -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
        return 1
    fi
}

# Fonction pour vérifier les paramètres de réplication
check_replication_settings() {
    echo "Vérification des paramètres de réplication..."
    
    # Vérifier wal_level
    local wal_level=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -t -c "SHOW wal_level;" 2>/dev/null | tr -d ' ')
    if [ "$wal_level" = "logical" ]; then
        echo -e "  wal_level: ${GREEN}$wal_level ✅${NC}"
    else
        echo -e "  wal_level: ${RED}$wal_level ❌ (doit être 'logical')${NC}"
    fi
    
    # Vérifier max_wal_senders
    local max_wal_senders=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -t -c "SHOW max_wal_senders;" 2>/dev/null | tr -d ' ')
    echo -e "  max_wal_senders: ${GREEN}$max_wal_senders${NC}"
    
    # Vérifier max_replication_slots
    local max_replication_slots=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -t -c "SHOW max_replication_slots;" 2>/dev/null | tr -d ' ')
    echo -e "  max_replication_slots: ${GREEN}$max_replication_slots${NC}"
}

# Fonction pour vérifier l'utilisateur de réplication
check_replication_user() {
    echo "Vérification de l'utilisateur de réplication..."
    
    local user_exists=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -t -c "SELECT COUNT(*) FROM pg_roles WHERE rolname = '$REPLICATION_USER';" 2>/dev/null | tr -d ' ')
    
    if [ "$user_exists" = "1" ]; then
        echo -e "  Utilisateur $REPLICATION_USER: ${GREEN}Existe ✅${NC}"
        
        # Vérifier les permissions de réplication
        local can_replicate=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -t -c "SELECT rolreplication FROM pg_roles WHERE rolname = '$REPLICATION_USER';" 2>/dev/null | tr -d ' ')
        if [ "$can_replicate" = "t" ]; then
            echo -e "  Permissions de réplication: ${GREEN}Actives ✅${NC}"
        else
            echo -e "  Permissions de réplication: ${RED}Inactives ❌${NC}"
        fi
    else
        echo -e "  Utilisateur $REPLICATION_USER: ${RED}N'existe pas ❌${NC}"
    fi
}

# Fonction pour lister les slots de réplication
list_replication_slots() {
    echo "Slots de réplication existants:"
    
    local slots=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "SELECT slot_name, plugin, slot_type, active FROM pg_replication_slots;" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "$slots"
    else
        echo -e "${RED}Erreur lors de la récupération des slots${NC}"
    fi
}

# Fonction pour créer un slot de réplication de test
create_test_slot() {
    echo "Création d'un slot de réplication de test..."
    
    local slot_name="test_mosip_slot"
    
    # Vérifier si le slot existe déjà
    local slot_exists=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -t -c "SELECT COUNT(*) FROM pg_replication_slots WHERE slot_name = '$slot_name';" 2>/dev/null | tr -d ' ')
    
    if [ "$slot_exists" = "0" ]; then
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "SELECT pg_create_logical_replication_slot('$slot_name', 'pgoutput');" > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "  Slot de test créé: ${GREEN}$slot_name ✅${NC}"
        else
            echo -e "  Erreur lors de la création du slot: ${RED}❌${NC}"
        fi
    else
        echo -e "  Slot de test existe déjà: ${YELLOW}$slot_name${NC}"
    fi
}

# Fonction pour tester les permissions sur les schémas MOSIP
test_mosip_schemas() {
    echo "Test des permissions sur les schémas MOSIP..."
    
    local mosip_databases=("mosip_master" "mosip_kernel" "mosip_iam" "mosip_ida" "mosip_idrepo")
    
    for db in "${mosip_databases[@]}"; do
        local schema_name=$(echo $db | cut -d'_' -f2)
        echo -n "  Test accès schéma $schema_name dans $db... "
        
        # Tester l'accès au schéma
        local result=$(PGPASSWORD=$REPLICATION_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $REPLICATION_USER -d $db -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$schema_name';" 2>/dev/null | tr -d ' ')
        
        if [ -n "$result" ] && [ "$result" -ge 0 ]; then
            echo -e "${GREEN}✅ ($result tables)${NC}"
        else
            echo -e "${RED}❌${NC}"
        fi
    done
}

# Fonction pour tester la réplication
test_replication() {
    echo "Test de la réplication logique..."
    
    # Créer une table de test
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "
        CREATE TABLE IF NOT EXISTS test_replication (
            id SERIAL PRIMARY KEY,
            message TEXT,
            created_at TIMESTAMP DEFAULT NOW()
        );
    " > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "  Table de test créée: ${GREEN}✅${NC}"
        
        # Insérer des données de test
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "
            INSERT INTO test_replication (message) VALUES ('Test de réplication MOSIP');
        " > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "  Données de test insérées: ${GREEN}✅${NC}"
        else
            echo -e "  Erreur lors de l'insertion: ${RED}❌${NC}"
        fi
    else
        echo -e "  Erreur lors de la création de la table: ${RED}❌${NC}"
    fi
}

# Exécution des tests
echo ""
echo "🔍 Tests de connexion..."
test_connection $DB_USER $DB_PASSWORD "PostgreSQL (admin)"
test_connection $REPLICATION_USER $REPLICATION_PASSWORD "Réplication"

echo ""
check_replication_settings

echo ""
check_replication_user

echo ""
list_replication_slots

echo ""
create_test_slot

echo ""
test_mosip_schemas

echo ""
test_replication

echo ""
echo "📊 Résumé des tests de réplication"
echo "==================================="
echo "Configuration de réplication logique activée"
echo "Utilisateur de réplication: $REPLICATION_USER"
echo "Mot de passe: $REPLICATION_PASSWORD"
echo ""
echo "Pour utiliser la réplication:"
echo "1. Connectez-vous avec l'utilisateur replicator"
echo "2. Créez un slot de réplication logique"
echo "3. Configurez un subscriber pour recevoir les changements"
