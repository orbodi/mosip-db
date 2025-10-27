#!/bin/bash

# Script de gestion des slots de réplication MOSIP
# Permet de créer, lister, et supprimer les slots de réplication

echo "🔧 Gestion des slots de réplication MOSIP"
echo "=========================================="

# Configuration
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
DB_PASSWORD="mosip@123"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Bases de données MOSIP
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

# Fonction pour afficher le menu
show_menu() {
    echo ""
    echo "📋 Options disponibles:"
    echo "1. Lister les slots de réplication"
    echo "2. Créer tous les slots MOSIP"
    echo "3. Créer un slot spécifique"
    echo "4. Supprimer un slot spécifique"
    echo "5. Supprimer tous les slots MOSIP"
    echo "6. Vérifier l'état des slots"
    echo "7. Nettoyer les slots inactifs"
    echo "8. Quitter"
    echo ""
}

# Fonction pour lister les slots
list_slots() {
    echo ""
    echo "📋 Slots de réplication existants:"
    echo "=================================="
    
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "
        SELECT 
            slot_name,
            plugin,
            slot_type,
            active,
            confirmed_flush_lsn,
            pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) as lag
        FROM pg_replication_slots
        ORDER BY slot_name;
    "
}

# Fonction pour créer tous les slots MOSIP
create_all_slots() {
    echo ""
    echo "🔧 Création de tous les slots MOSIP..."
    echo "======================================"
    
    for db in "${mosip_databases[@]}"; do
        local slot_name="${db}_replication_slot"
        local schema_name=$(echo $db | cut -d'_' -f2)
        
        echo -n "Création du slot $slot_name pour $db ($schema_name)... "
        
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
}

# Fonction pour créer un slot spécifique
create_specific_slot() {
    echo ""
    echo "🔧 Création d'un slot spécifique"
    echo "================================"
    
    echo "Bases de données disponibles:"
    for i in "${!mosip_databases[@]}"; do
        echo "  $((i+1)). ${mosip_databases[$i]}"
    done
    
    read -p "Choisissez une base de données (1-${#mosip_databases[@]}): " choice
    
    if [ "$choice" -ge 1 ] && [ "$choice" -le "${#mosip_databases[@]}" ]; then
        local db="${mosip_databases[$((choice-1))]}"
        local slot_name="${db}_replication_slot"
        local schema_name=$(echo $db | cut -d'_' -f2)
        
        echo -n "Création du slot $slot_name pour $db ($schema_name)... "
        
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
    else
        echo -e "${RED}❌ Choix invalide${NC}"
    fi
}

# Fonction pour supprimer un slot spécifique
delete_specific_slot() {
    echo ""
    echo "🗑️  Suppression d'un slot spécifique"
    echo "===================================="
    
    # Lister les slots existants
    local slots=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -t -c "
        SELECT slot_name FROM pg_replication_slots ORDER BY slot_name;
    " 2>/dev/null)
    
    if [ -z "$slots" ]; then
        echo "Aucun slot de réplication trouvé."
        return
    fi
    
    echo "Slots existants:"
    echo "$slots" | nl -w2 -s'. '
    
    read -p "Entrez le nom du slot à supprimer: " slot_name
    
    if [ -n "$slot_name" ]; then
        echo -n "Suppression du slot $slot_name... "
        
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "
            SELECT pg_drop_replication_slot('$slot_name');
        " > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Supprimé${NC}"
        else
            echo -e "${RED}❌ Erreur${NC}"
        fi
    else
        echo -e "${RED}❌ Nom de slot invalide${NC}"
    fi
}

# Fonction pour supprimer tous les slots MOSIP
delete_all_mosip_slots() {
    echo ""
    echo "🗑️  Suppression de tous les slots MOSIP"
    echo "======================================"
    
    read -p "Êtes-vous sûr de vouloir supprimer tous les slots MOSIP? (oui/non): " confirm
    
    if [ "$confirm" = "oui" ]; then
        for db in "${mosip_databases[@]}"; do
            local slot_name="${db}_replication_slot"
            
            echo -n "Suppression du slot $slot_name... "
            
            PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "
                SELECT pg_drop_replication_slot('$slot_name');
            " > /dev/null 2>&1
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Supprimé${NC}"
            else
                echo -e "${YELLOW}⚠️  Non trouvé ou erreur${NC}"
            fi
        done
    else
        echo "Opération annulée."
    fi
}

# Fonction pour vérifier l'état des slots
check_slots_status() {
    echo ""
    echo "📊 État des slots de réplication"
    echo "================================"
    
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "
        SELECT 
            slot_name,
            CASE 
                WHEN active THEN '${GREEN}Actif${NC}'
                ELSE '${YELLOW}Inactif${NC}'
            END as statut,
            pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) as lag,
            confirmed_flush_lsn
        FROM pg_replication_slots
        ORDER BY slot_name;
    "
}

# Fonction pour nettoyer les slots inactifs
cleanup_inactive_slots() {
    echo ""
    echo "🧹 Nettoyage des slots inactifs"
    echo "==============================="
    
    local inactive_slots=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -t -c "
        SELECT slot_name FROM pg_replication_slots WHERE NOT active;
    " 2>/dev/null)
    
    if [ -z "$inactive_slots" ]; then
        echo "Aucun slot inactif trouvé."
        return
    fi
    
    echo "Slots inactifs trouvés:"
    echo "$inactive_slots"
    
    read -p "Voulez-vous supprimer ces slots inactifs? (oui/non): " confirm
    
    if [ "$confirm" = "oui" ]; then
        echo "$inactive_slots" | while read -r slot; do
            if [ -n "$slot" ]; then
                echo -n "Suppression du slot $slot... "
                
                PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "
                    SELECT pg_drop_replication_slot('$slot');
                " > /dev/null 2>&1
                
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✅ Supprimé${NC}"
                else
                    echo -e "${RED}❌ Erreur${NC}"
                fi
            fi
        done
    else
        echo "Opération annulée."
    fi
}

# Boucle principale
while true; do
    show_menu
    read -p "Votre choix (1-8): " choice
    
    case $choice in
        1) list_slots ;;
        2) create_all_slots ;;
        3) create_specific_slot ;;
        4) delete_specific_slot ;;
        5) delete_all_mosip_slots ;;
        6) check_slots_status ;;
        7) cleanup_inactive_slots ;;
        8) 
            echo "👋 Au revoir!"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Choix invalide${NC}"
            ;;
    esac
    
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
done
