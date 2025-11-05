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

SKIP_DBS_LIST=( )
if [[ -n "${SKIP_DBS:-}" ]]; then
  # space-separated list in SKIP_DBS
  read -r -a SKIP_DBS_LIST <<<"${SKIP_DBS}"
fi

skip_db() {
  local name="$1"
  for s in "${SKIP_DBS_LIST[@]}"; do
    [[ "$s" == "$name" ]] && return 0
  done
  return 1
}

for d in "$SCRIPT_DIR"/*/ ; do
  [[ -d "$d" ]] || continue
  if [[ -x "$d/restore.sh" ]]; then
    dbname="$(basename "$d" | sed 's/\/$//')"
    if skip_db "$dbname"; then
      echo "Skipping $dbname as per SKIP_DBS"
      continue
    fi
    echo "=============================="
    echo "Restoring $dbname"
    echo "=============================="
    "$d/restore.sh"
    if $LOAD_CSV && [[ -x "$d/load_csv.sh" ]]; then
      echo "Loading CSV/DML for $dbname"
      "$d/load_csv.sh"
    fi
  fi
done

echo "All databases processed."


