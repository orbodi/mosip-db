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

# Map DB -> module dml.sql (preferred), with fallbacks and auto-detect
declare -A DML_PATHS=()
DML_PATHS[mosip_master]="$ROOT_DIR/mosip_master/dml.sql"
DML_PATHS[mosip_pms]="$ROOT_DIR/mosip_pms/dml.sql"
DML_PATHS[mosip_ida]="$ROOT_DIR/mosip_ida/dml.sql"
DML_PATHS[mosip_authdevice]="$ROOT_DIR/mosip_authdevice/dml.sql"
DML_PATHS[mosip_regdevice]="$ROOT_DIR/mosip_regdevice/dml.sql"
DML_PATHS[mosip_regprc]="$ROOT_DIR/mosip_regprc/dml.sql"
DML_PATHS[mosip_prereg]="$ROOT_DIR/mosip_prereg/dml.sql"
DML_PATHS[mosip_iam]="$ROOT_DIR/mosip_iam/mosip_iam_dml_deploy.sql"
DML_PATHS[mosip_credential]="$ROOT_DIR/mosip_credential/dml.sql"
DML_PATHS[mosip_kernel]="$ROOT_DIR/mosip_kernel/dml.sql"
DML_PATHS[mosip_idmap]="$ROOT_DIR/mosip_idmap/dml.sql"

# Resolve DML file path
DML_FILE="${DML_PATHS[$DB_NAME]:-}"
if [[ -z "${DML_FILE}" || ! -f "$DML_FILE" ]]; then
  CAND_DIR="$ROOT_DIR/$DB_NAME"
  if [[ -d "$CAND_DIR" ]]; then
    if [[ -f "$CAND_DIR/dml.sql" ]]; then
      DML_FILE="$CAND_DIR/dml.sql"
    else
      # pick the first *_dml*.sql file if exists
      CAND=$(ls -1 "$CAND_DIR"/*dml*.sql 2>/dev/null | head -n1 || true)
      if [[ -n "$CAND" ]]; then
        DML_FILE="$CAND"
      fi
    fi
  fi
fi

if [[ -n "${DML_FILE}" && -f "$DML_FILE" ]]; then
  echo "[${DB_NAME}] Loading DML/CSV via $DML_FILE"
  MODULE_DIR="$(cd "$(dirname "$DML_FILE")" && pwd)"
  BASE_NAME="$(basename "$DML_FILE")"
  # Create a temp working copy of the module directory to sanitize \connect across all included files
  TMP_DIR="$(mktemp -d "dml_${DB_NAME}_XXXX")"
  rsync -a "$MODULE_DIR/" "$TMP_DIR/" >/dev/null 2>&1 || cp -r "$MODULE_DIR/." "$TMP_DIR/"
  # Comment out any \connect / \c lines in all sql files
  find "$TMP_DIR" -type f -name "*.sql" -print0 | xargs -0 -r sed -i -E 's/^\\c(onn?ect)?\b/-- &/Ig'
  (
    cd "$TMP_DIR"
    psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$BASE_NAME"
  )
  rm -rf "$TMP_DIR"
  echo "[${DB_NAME}] DML load complete"
else
  echo "[${DB_NAME}] No DML mapping found or file missing; skipping"
fi


