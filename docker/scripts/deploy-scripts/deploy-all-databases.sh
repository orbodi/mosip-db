#!/bin/bash
set -e

echo "Starting MOSIP Database Deployment..."

# Database connection parameters
DB_HOST="postgres"
DB_PORT="5432"
DB_USER="postgres"
DB_PASSWORD="mosip@123"
DEFAULT_DB="postgres"

# Base paths
BASE_PATH="/database"
LOG_PATH="/var/log/mosip"

# Create log directory
mkdir -p $LOG_PATH

# Function to update properties file
update_properties() {
    local module=$1
    local properties_file="$BASE_PATH/$module/${module}_deploy.properties"
    
    if [ -f "$properties_file" ]; then
        echo "Updating properties for $module..."
        sed -i "s|DB_SERVERIP=.*|DB_SERVERIP=$DB_HOST|g" "$properties_file"
        sed -i "s|DB_PORT=.*|DB_PORT=$DB_PORT|g" "$properties_file"
        sed -i "s|SU_USER=.*|SU_USER=$DB_USER|g" "$properties_file"
        sed -i "s|SU_USER_PWD=.*|SU_USER_PWD=$DB_PASSWORD|g" "$properties_file"
        sed -i "s|DEFAULT_DB_NAME=.*|DEFAULT_DB_NAME=$DEFAULT_DB|g" "$properties_file"
        sed -i "s|BASEPATH=.*|BASEPATH=$BASE_PATH/|g" "$properties_file"
        sed -i "s|LOG_PATH=.*|LOG_PATH=$LOG_PATH/|g" "$properties_file"
    fi
}

# Function to deploy a single database
deploy_database() {
    local module=$1
    echo "Deploying $module database..."
    
    update_properties $module
    
    cd "$BASE_PATH/$module"
    
    if [ -f "${module}_db_deploy.sh" ]; then
        chmod +x "${module}_db_deploy.sh"
        ./${module}_db_deploy.sh ${module}_deploy.properties
        echo "$module database deployment completed."
    else
        echo "Warning: ${module}_db_deploy.sh not found for $module"
    fi
}

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
until PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DEFAULT_DB -c '\q' 2>/dev/null; do
    echo "PostgreSQL is unavailable - sleeping"
    sleep 2
done

echo "PostgreSQL is ready - starting database deployment"

# Deploy databases in the correct order
deploy_database "mosip_master"
deploy_database "mosip_kernel"
deploy_database "mosip_iam"
deploy_database "mosip_ida"
deploy_database "mosip_idrepo"
deploy_database "mosip_prereg"
deploy_database "mosip_regprc"
deploy_database "mosip_idmap"
deploy_database "mosip_audit"
deploy_database "mosip_pmp"

# Create replication user
echo "Creating replication user..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DEFAULT_DB -f /deploy-scripts/create-replication-user.sql

echo "All MOSIP databases have been deployed successfully!"
echo "You can now connect to PostgreSQL on localhost:5432"
echo "Default credentials: postgres / mosip@123"
echo "Replication user: replicator / replicator123"
