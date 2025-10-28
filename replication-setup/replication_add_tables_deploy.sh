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
TARGET_DB_NAME=${CFG[TARGET_DB_NAME]:-}
SYSADMIN_USER=${CFG[SYSADMIN_USER]:-sysadmin}
SYSADMIN_PWD=${CFG[SYSADMIN_PWD]:-}
PUBLICATION_NAME=${CFG[PUBLICATION_NAME]:-}
TABLE_LIST=${CFG[TABLE_LIST]:-}
LOG_PATH=${CFG[LOG_PATH]:-/tmp/replication-setup/}

mkdir -p "$LOG_PATH"
LOG="${LOG_PATH}replication_add_${TARGET_DB_NAME}_${PUBLICATION_NAME}_$(date '+%d%m%Y_%H%M%S').log"
touch "$LOG"

if [[ -z "$TARGET_DB_NAME" || -z "$PUBLICATION_NAME" || -z "$TABLE_LIST" ]]; then
	echo $(date "+%m/%d/%Y %H:%M:%S") ": TARGET_DB_NAME, PUBLICATION_NAME and TABLE_LIST are required" | tee -a "$LOG"
	exit 1
fi

echo $(date "+%m/%d/%Y %H:%M:%S") ": Adding tables to publication $PUBLICATION_NAME on $TARGET_DB_NAME" | tee -a "$LOG"

PGPASSWORD="$SYSADMIN_PWD" psql --username="$SYSADMIN_USER" --host="$DB_SERVERIP" --port="$DB_PORT" --dbname="$TARGET_DB_NAME" \
	-v publication_name="$PUBLICATION_NAME" -v table_list="$TABLE_LIST" \
	-f "$(dirname "$0")/replication_add_tables.sql" >> "$LOG" 2>&1

if grep -q "ERROR" "$LOG"; then
	echo $(date "+%m/%d/%Y %H:%M:%S") ": Add tables completed with ERRORS. See log: $LOG" | tee -a "$LOG"
	exit 1
else
	echo $(date "+%m/%d/%Y %H:%M:%S") ": Tables added successfully. Log: $LOG" | tee -a "$LOG"
fi
