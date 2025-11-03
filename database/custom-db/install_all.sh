#!/usr/bin/env bash
set -euo pipefail

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
export DB_OWNER="${DB_OWNER:-postgres}"

LOAD_CSV=false
if [[ "${1:-}" == "--load-csv" ]]; then
  LOAD_CSV=true
fi

echo "Using PGHOST=$PGHOST PGPORT=$PGPORT PGUSER=$PGUSER DB_OWNER=$DB_OWNER"

for d in "$SCRIPT_DIR"/*/ ; do
  [[ -d "$d" ]] || continue
  if [[ -x "$d/restore.sh" ]]; then
    echo "=============================="
    echo "Restoring $(basename "$d" | sed 's/\/$//')"
    echo "=============================="
    "$d/restore.sh"
    if $LOAD_CSV && [[ -x "$d/load_csv.sh" ]]; then
      echo "Loading CSV/DML for $(basename "$d")"
      "$d/load_csv.sh"
    fi
  fi
done

echo "All databases processed."


