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
export DML_STRICT="${DML_STRICT:-true}"
export SKIP_DBS_DML="${SKIP_DBS_DML:-}"

# Skip list handling (space-separated names)
for SKIP_NAME in $SKIP_DBS_DML; do
  if [[ "$SKIP_NAME" == "$DB_NAME" ]]; then
    echo "[${DB_NAME}] Skipping DML as per SKIP_DBS_DML"
    exit 0
  fi
done

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

  # Generic alignment: for each COPY with explicit column list, intersect with actual DB columns
  echo "[${DB_NAME}] Aligning DML columns to actual schema (generic)"
  python3 - "$PGHOST" "$PGPORT" "$PGUSER" "$DB_NAME" "$TMP_DIR" <<'PY'
import os, re, sys, csv, subprocess, shlex
PGHOST, PGPORT, PGUSER, DBNAME, TMP_DIR = sys.argv[1:6]
PGPASSWORD = os.environ.get('PGPASSWORD', '')

def get_actual_columns(schema, table):
    q = f"select column_name from information_schema.columns where table_schema={shlex.quote(schema)!r} and table_name={shlex.quote(table)!r} order by ordinal_position"
    env = os.environ.copy()
    if PGPASSWORD:
        env['PGPASSWORD'] = PGPASSWORD
    cmd = ['psql', '-h', PGHOST, '-p', PGPORT, '-U', PGUSER, '-d', DBNAME, '-At', '-c', q]
    out = subprocess.check_output(cmd, env=env).decode().strip()
    return [c for c in out.split('\n') if c]

def get_required_columns(schema, table):
    q = (
        "select column_name from information_schema.columns "
        "where is_nullable='NO' and column_default is null and "
        f"table_schema={shlex.quote(schema)!r} and table_name={shlex.quote(table)!r}"
    )
    env = os.environ.copy()
    if PGPASSWORD:
        env['PGPASSWORD'] = PGPASSWORD
    cmd = ['psql', '-h', PGHOST, '-p', PGPORT, '-U', PGUSER, '-d', DBNAME, '-At', '-c', q]
    out = subprocess.check_output(cmd, env=env).decode().strip()
    return [c for c in out.split('\n') if c]

COPY_RE = re.compile(r"^\\COPY\s+((?P<schema>\w+)\.)?(?P<table>\w+)\s*\((?P<cols>[^)]*)\)\s+FROM\s+'(?P<csv>[^']+)'", re.IGNORECASE)

def sanitize_sql(sql_path):
    with open(sql_path, encoding='utf-8') as f:
        lines = f.readlines()
    changed = False
    for i, line in enumerate(lines):
        m = COPY_RE.search(line)
        if not m:
            continue
        schema = m.group('schema') or 'public'
        table = m.group('table')
        cols = [c.strip().strip('"') for c in m.group('cols').split(',') if c.strip()]
        csv_rel = m.group('csv')
        csv_path = os.path.join(os.path.dirname(sql_path), csv_rel)
        if not os.path.exists(csv_path):
            continue
        try:
            actual_cols = get_actual_columns(schema, table)
            required_cols = set(get_required_columns(schema, table))
        except subprocess.CalledProcessError:
            continue
        keep = [c for c in cols if c in actual_cols]
        if not keep:
            continue
        try:
            with open(csv_path, newline='', encoding='utf-8') as f_in:
                r = csv.DictReader(f_in)
                if r.fieldnames:
                    # Case-insensitive header mapping
                    header_map = {h.lower(): h for h in r.fieldnames}
                    csv_keep_headers = []
                    for c in keep:
                        lc = c.lower()
                        if lc in header_map:
                            csv_keep_headers.append(header_map[lc])
                    # If any required columns would be dropped, skip alignment for this COPY
                    missing_required = [c for c in required_cols if c not in [k.lower() for k in keep]]
                    if missing_required:
                        continue
                    if not csv_keep_headers:
                        pass
                    else:
                        filtered_csv = csv_path + '.filtered.csv'
                        with open(filtered_csv, 'w', newline='', encoding='utf-8') as f_out:
                            w = csv.DictWriter(f_out, fieldnames=csv_keep_headers)
                            w.writeheader()
                            for row in r:
                                w.writerow({k: row.get(k, '') for k in csv_keep_headers})
                        cols_str = ','.join(keep)
                        rel_dir = os.path.dirname(csv_rel)
                        rel_filtered = os.path.join(rel_dir, os.path.basename(filtered_csv)) if rel_dir else os.path.basename(filtered_csv)
                        new_line = COPY_RE.sub(lambda mm: mm.group(0)
                            .replace(mm.group('cols'), cols_str)
                            .replace(mm.group('csv'), rel_filtered), line, count=1)
                        lines[i] = new_line
                        changed = True
        except Exception:
            pass
    if changed:
        with open(sql_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)

for root, _, files in os.walk(TMP_DIR):
    for fn in files:
        if fn.lower().endswith('.sql'):
            sanitize_sql(os.path.join(root, fn))
PY

  (
    cd "$TMP_DIR"
    if [[ "$DML_STRICT" == "false" ]]; then
      # continue-on-error: capture errors but do not stop install_all
      set +e
      psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DB_NAME" -v ON_ERROR_STOP=0 -f "$BASE_NAME"
      rc=$?
      set -e
      if [[ $rc -ne 0 ]]; then
        echo "[${DB_NAME}] DML completed with errors (non-strict mode)." >&2
      fi
    else
      psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$BASE_NAME"
    fi
  )
  rm -rf "$TMP_DIR"
  echo "[${DB_NAME}] DML load complete"
else
  echo "[${DB_NAME}] No DML mapping found or file missing; skipping"
fi


