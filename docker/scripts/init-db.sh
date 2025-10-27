#!/bin/bash
set -e

echo "Starting MOSIP Database Initialization..."

# Create the base directory structure
mkdir -p /docker-entrypoint-initdb.d/init-scripts

# Copy database scripts
cp -r /docker-entrypoint-initdb.d/database/* /docker-entrypoint-initdb.d/init-scripts/

# Set proper permissions
chmod +x /docker-entrypoint-initdb.d/init-scripts/database/mosip_all_db_deployment.sh

echo "MOSIP Database initialization setup completed."
