#!/bin/bash
set -euo pipefail

PROP_FILE="$1"
if [[ ! -f "$PROP_FILE" ]]; then
	echo "Property file not found"
	exit 1
fi

declare -A CFG
while IFS='=' read -r key value; do
	[[ -z "$key" || "$key" =~ ^# ]] && continue
	key=$(echo "$key" | tr '.' '_')
	CFG[$key]="$value"
done < "$PROP_FILE"

DB_SERVERIP=${CFG[DB_SERVERIP]:-localhost}
DB_PORT=${CFG[DB_PORT]:-5433}
DB_NAME=${CFG[DB_NAME]:-mosip_master}
DB_USER=${CFG[DB_USER]:-sysadmin}
DB_PASSWORD=${CFG[DB_PASSWORD]:-}
SCHEMA_NAME=${CFG[SCHEMA_NAME]:-master}
CSV_DIR_ABS=${CFG[CSV_DIR_ABS]:-}
OUTPUT_SQL=${CFG[OUTPUT_SQL]:-copy_mosip_master.sql}

if [[ -z "$CSV_DIR_ABS" ]]; then
	echo "CSV_DIR_ABS is required (absolute path to master-*.csv)"
	exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1) Generate plan
PGPASSWORD="$DB_PASSWORD" python3 "$SCRIPT_DIR/prepare_csv_copy_plan.py" \
	--host "$DB_SERVERIP" --port "$DB_PORT" --db "$DB_NAME" --user "$DB_USER" --password "$DB_PASSWORD" \
	--schema "$SCHEMA_NAME" --csv-dir "$CSV_DIR_ABS" --output-sql "$OUTPUT_SQL"

# 2) Execute plan
PGPASSWORD="$DB_PASSWORD" psql --username="$DB_USER" --host="$DB_SERVERIP" --port="$DB_PORT" --dbname="$DB_NAME" -f "$OUTPUT_SQL"

echo "Import completed from $CSV_DIR_ABS"
