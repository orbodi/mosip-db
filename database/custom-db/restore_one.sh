#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <database_name>" >&2
  exit 2
fi

DB_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DUMP_DIR="$ROOT_DIR/custom_db_structures"
DUMP_FILE="$DUMP_DIR/${DB_NAME}.dump"

if [[ ! -f "$DUMP_FILE" ]]; then
  echo "Dump not found: $DUMP_FILE" >&2
  exit 1
fi

# Load env
if [[ -f "$SCRIPT_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/.env"
fi

export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGUSER="${PGUSER:-postgres}"
export PGPASSWORD="${PGPASSWORD:-}"
export DB_OWNER="${DB_OWNER:-postgres}"
export JOBS="${JOBS:-4}"

echo "[${DB_NAME}] Dropping existing database (if any)"
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS \"$DB_NAME\";"

echo "[${DB_NAME}] Creating database owned by '$DB_OWNER'"
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -c "CREATE DATABASE \"$DB_NAME\" OWNER \"$DB_OWNER\";"

echo "[${DB_NAME}] Restoring from $DUMP_FILE"
pg_restore \
  -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" \
  -d "$DB_NAME" \
  --no-owner --role="$DB_OWNER" --no-privileges \
  --jobs="$JOBS" \
  "$DUMP_FILE"

echo "[${DB_NAME}] ANALYZE"
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -c "ANALYZE;"

echo "[${DB_NAME}] Done"


