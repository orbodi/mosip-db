#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <database_name>" >&2
  exit 2
fi

DB_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load env
if [[ -f "$SCRIPT_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/.env"
fi

export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGUSER="${PGUSER:-postgres}"
export PGPASSWORD="${PGPASSWORD:-}"

# Map DB -> module dml.sql (if exists)
declare -A DML_PATHS=()
DML_PATHS[mosip_master]="$ROOT_DIR/mosip_master/dml.sql"
DML_PATHS[mosip_pms]="$ROOT_DIR/mosip_pms/dml.sql"
DML_PATHS[mosip_ida]="$ROOT_DIR/mosip_ida/dml.sql"
DML_PATHS[mosip_authdevice]="$ROOT_DIR/mosip_authdevice/dml.sql"
DML_PATHS[mosip_regdevice]="$ROOT_DIR/mosip_regdevice/dml.sql"
DML_PATHS[mosip_regprc]="$ROOT_DIR/mosip_regprc/dml.sql"
DML_PATHS[mosip_prereg]="$ROOT_DIR/mosip_prereg/dml.sql"
DML_PATHS[mosip_iam]="$ROOT_DIR/mosip_iam/mosip_iam_dml_deploy.sql"

DML_FILE="${DML_PATHS[$DB_NAME]:-}"
if [[ -n "${DML_FILE}" && -f "$DML_FILE" ]]; then
  echo "[${DB_NAME}] Loading DML/CSV via $DML_FILE"
  psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$DML_FILE"
  echo "[${DB_NAME}] DML load complete"
else
  echo "[${DB_NAME}] No DML mapping found or file missing; skipping"
fi


