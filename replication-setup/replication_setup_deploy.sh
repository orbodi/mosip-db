#!/bin/bash
set -euo pipefail

properties_file="$1"
echo $(date "+%m/%d/%Y %H:%M:%S") ": $properties_file"

if [ ! -f "$properties_file" ]; then
	echo $(date "+%m/%d/%Y %H:%M:%S") ": Property file not found, pass the properties file as argument."
	exit 1
fi

declare -A CFG
while IFS='=' read -r key value; do
	[[ -z "$key" || "$key" =~ ^# ]] && continue
	key=$(echo "$key" | tr '.' '_')
	CFG[$key]="$value"
done < "$properties_file"

DB_SERVERIP=${CFG[DB_SERVERIP]:-localhost}
DB_PORT=${CFG[DB_PORT]:-5433}
SU_USER=${CFG[SU_USER]:-postgres}
SU_USER_PWD=${CFG[SU_USER_PWD]:-}
DEFAULT_DB_NAME=${CFG[DEFAULT_DB_NAME]:-postgres}

TARGET_DB_NAME=${CFG[TARGET_DB_NAME]:-}
TARGET_SCHEMA=${CFG[TARGET_SCHEMA]:-}
REPLICATION_USER=${CFG[REPLICATION_USER]:-${CFG[SYSADMIN_USER]:-postgres}}
REPLICATION_PWD=${CFG[REPLICATION_PWD]:-${CFG[SYSADMIN_PWD]:-}}
PUBLICATION_NAME=${CFG[PUBLICATION_NAME]:-$TARGET_SCHEMA_pub}
LOG_PATH=${CFG[LOG_PATH]:-/tmp/replication-setup/}

mkdir -p "$LOG_PATH"
LOG="${LOG_PATH}replication_${TARGET_DB_NAME}_${TARGET_SCHEMA}_$(date '+%d%m%Y_%H%M%S').log"
touch "$LOG"

if [[ -z "$TARGET_DB_NAME" || -z "$TARGET_SCHEMA" ]]; then
	echo $(date "+%m/%d/%Y %H:%M:%S") ": TARGET_DB_NAME and TARGET_SCHEMA are required" | tee -a "$LOG"
	exit 1
fi

echo $(date "+%m/%d/%Y %H:%M:%S") ": Starting replication setup for $TARGET_DB_NAME.$TARGET_SCHEMA" | tee -a "$LOG"

# Vérifier l'accès
PGPASSWORD="$SU_USER_PWD" psql --username="$SU_USER" --host="$DB_SERVERIP" --port="$DB_PORT" --dbname="$DEFAULT_DB_NAME" -t -c "SELECT 1" >/dev/null

echo $(date "+%m/%d/%Y %H:%M:%S") ": Applying privileges and publication..." | tee -a "$LOG"
PGPASSWORD="$REPLICATION_PWD" psql --username="$REPLICATION_USER" --host="$DB_SERVERIP" --port="$DB_PORT" --dbname="$TARGET_DB_NAME" \
	-v target_schema="$TARGET_SCHEMA" -v replication_user="$REPLICATION_USER" -v publication_name="$PUBLICATION_NAME" \
	-f "$(dirname "$0")/replication_setup.sql" >> "$LOG" 2>&1

if grep -q "ERROR" "$LOG"; then
	echo $(date "+%m/%d/%Y %H:%M:%S") ": Replication setup completed with ERRORS. See log: $LOG" | tee -a "$LOG"
	exit 1
else
	echo $(date "+%m/%d/%Y %H:%M:%S") ": Replication setup completed successfully. Log: $LOG" | tee -a "$LOG"
fi
