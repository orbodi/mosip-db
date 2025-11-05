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

COPY_RE = re.compile(
    r"^\s*\\COPY\s+((?P<schema>\w+)|\"(?P<schemaq>[^\"]+)\")\.?((?P<table>\w+)|\"(?P<tableq>[^\"]+)\")\s*\((?P<cols>[^)]*)\)\s+FROM\s+'(?P<csv>[^']+)'",
    re.IGNORECASE,
)

def sanitize_sql(sql_path):
    with open(sql_path, encoding='utf-8') as f:
        lines = f.readlines()
    changed = False
    for i, line in enumerate(lines):
        m = COPY_RE.search(line)
        if not m:
            continue
        schema = (m.group('schema') or m.group('schemaq') or 'public')
        table = (m.group('table') or m.group('tableq'))
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
                    # Build aligned pairs of (db_col, csv_header)
                    pairs = []
                    for c in keep:
                        h = header_map.get(c.lower())
                        if h:
                            pairs.append((c, h))
                    # Ensure we do not drop required columns
                    missing_required = [c for c in required_cols if c not in [db for db, _ in pairs]]
                    if missing_required:
                        continue
                    if not pairs:
                        pass
                    else:
                        db_cols = [db for db, _ in pairs]
                        csv_headers = [h for _, h in pairs]
                        filtered_csv = csv_path + '.filtered.csv'
                        with open(filtered_csv, 'w', newline='', encoding='utf-8') as f_out:
                            w = csv.DictWriter(f_out, fieldnames=csv_headers)
                            w.writeheader()
                            for row in r:
                                w.writerow({k: row.get(k, '') for k in csv_headers})
                        cols_str = ','.join(db_cols)
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

  # Targeted fallback fix for mosip_ida: normalize ida.key_policy_def COPY to actual columns
  if [[ "$DB_NAME" == "mosip_ida" ]]; then
    SQL_PATH="$TMP_DIR/$BASE_NAME"
    if grep -Eqi "^\\s*\\COPY\\s+ida\\.key_policy_def" "$SQL_PATH"; then
      CSV_REL=$(sed -n -E "s/.*ida\\.key_policy_def[^)]*\)\\s+FROM\s+'([^']+)'.*/\1/p" "$SQL_PATH" | head -n1)
      python3 - "$PGHOST" "$PGPORT" "$PGUSER" "$DB_NAME" "$TMP_DIR" "$SQL_PATH" "$CSV_REL" <<'PY2'
import os, csv, sys, subprocess
PGHOST, PGPORT, PGUSER, DBNAME, TMP_DIR, SQL_PATH, CSV_REL = sys.argv[1:8]
env = os.environ.copy()
if 'PGPASSWORD' in os.environ:
    env['PGPASSWORD'] = os.environ['PGPASSWORD']

def psql(q):
    out = subprocess.check_output(['psql','-h',PGHOST,'-p',PGPORT,'-U',PGUSER,'-d',DBNAME,'-At','-c',q], env=env).decode().strip()
    return [x for x in out.split('\n') if x]

actual = psql("select column_name from information_schema.columns where table_schema='ida' and table_name='key_policy_def' order by ordinal_position")
req = set(psql("select column_name from information_schema.columns where table_schema='ida' and table_name='key_policy_def' and is_nullable='NO' and column_default is null"))

csv_path = os.path.join(TMP_DIR, CSV_REL) if CSV_REL else ''
if not CSV_REL or not os.path.exists(csv_path):
    sys.exit(0)

with open(csv_path, newline='', encoding='utf-8') as f_in:
    r = csv.reader(f_in)
    rows = list(r)
    if not rows:
        sys.exit(0)
    header = rows[0]
    # Determine indices for the 5 required columns by header names; fallback to first 5
    want = ['app_id','key_validity_duration','is_active','cr_by','cr_dtimes']
    lower = [h.strip().lower() for h in header]
    idx = []
    for w in want:
        try:
            idx.append(lower.index(w))
        except ValueError:
            idx = list(range(min(5, len(header))))
            break
    out_path = csv_path + '.filtered.csv'
    with open(out_path, 'w', newline='', encoding='utf-8') as f_out:
        w = csv.writer(f_out)
        w.writerow(want)
        for row in rows[1:]:
            # pad row if shorter
            row = list(row) + [''] * (max(idx)+1 - len(row) if len(row) <= max(idx) else 0)
            w.writerow([row[i] for i in idx])
    # rewrite COPY line in SQL to exactly 5 expected columns
    rel_dir = os.path.dirname(CSV_REL)
    rel_new = os.path.join(rel_dir, os.path.basename(out_path)) if rel_dir else os.path.basename(out_path)
    import re
    with open(SQL_PATH, encoding='utf-8') as f:
        s = f.read()
    s = re.sub(r"(\\COPY\s+ida\.key_policy_def\s*)\([^)]*\)(\s*FROM\s*')([^']+)(')",
               lambda m: f"{m.group(1)}(app_id,key_validity_duration,is_active,cr_by,cr_dtimes){m.group(2)}{rel_new}{m.group(4)}",
               s, flags=re.IGNORECASE)
    with open(SQL_PATH, 'w', encoding='utf-8') as f:
        f.write(s)
PY2
    fi
    # Also ensure we drop access_allowed from column list if present
    sed -i -E "s/(\\COPY[[:space:]]+ida\\.key_policy_def[[:space:]]*\([^)]*)\s*,\s*access_allowed\b/\1/I" "$SQL_PATH"
    sed -i -E "s/(\\COPY[[:space:]]+ida\\.key_policy_def[[:space:]]*\()\s*access_allowed\s*,/\1/I" "$SQL_PATH"

    # Ensure filtered CSV exists in temp tree if referenced by dml.sql
    ORIG_CSV_PATH="$TMP_DIR/dml/ida-key_policy_def.csv"
    FILT_CSV_PATH="$TMP_DIR/dml/ida-key_policy_def.filtered.csv"
    if [[ -f "$ORIG_CSV_PATH" && ! -f "$FILT_CSV_PATH" ]]; then
      python3 - "$ORIG_CSV_PATH" "$FILT_CSV_PATH" <<'PY3'
import csv, sys
src, dst = sys.argv[1], sys.argv[2]
keep = ['app_id','key_validity_duration','is_active','cr_by','cr_dtimes']
with open(src, newline='', encoding='utf-8') as f_in:
    r = csv.DictReader(f_in)
    if not r.fieldnames:
        sys.exit(1)
    # Build case-insensitive mapping from original headers
    hdr_map = {h.lower(): h for h in r.fieldnames}
    with open(dst, 'w', newline='', encoding='utf-8') as f_out:
        w = csv.DictWriter(f_out, fieldnames=keep)
        w.writeheader()
        for row in r:
            # Map from original column names (case-insensitive) to output
            out_row = {}
            for out_col in keep:
                orig_col = hdr_map.get(out_col.lower())
                out_row[out_col] = row.get(orig_col, '') if orig_col else ''
            w.writerow(out_row)
PY3
    fi
  fi

  if [[ "$DB_NAME" == "mosip_pms" ]]; then
    SQL_PATH="$TMP_DIR/$BASE_NAME"
    # Simplify pms-auth_policy.csv: keep only id,policy_group_id,name,descr
    ORIG_APCSV="$TMP_DIR/dml/pms-auth_policy.csv"
    SIMP_APCSV="$TMP_DIR/dml/pms-auth_policy.simplified.csv"
    if [[ -f "$ORIG_APCSV" ]]; then
      python3 - "$ORIG_APCSV" "$SIMP_APCSV" <<'PY_PMS1'
import csv, sys
src, dst = sys.argv[1], sys.argv[2]
keep = ['id','policy_group_id','name','descr']
with open(src, newline='', encoding='utf-8') as f_in, open(dst, 'w', newline='', encoding='utf-8') as f_out:
    r = csv.DictReader(f_in)
    w = csv.DictWriter(f_out, fieldnames=keep)
    w.writeheader()
    for row in r:
        w.writerow({k: row.get(k, '') for k in keep})
PY_PMS1
    fi
    # Simplify pms-auth_policy_h.csv: keep id,eff_dtimes,policy_group_id,name,descr
    ORIG_APHCSV="$TMP_DIR/dml/pms-auth_policy_h.csv"
    SIMP_APHCSV="$TMP_DIR/dml/pms-auth_policy_h.simplified.csv"
    if [[ -f "$ORIG_APHCSV" ]]; then
      python3 - "$ORIG_APHCSV" "$SIMP_APHCSV" <<'PY_PMS2'
import csv, sys
src, dst = sys.argv[1], sys.argv[2]
keep = ['id','eff_dtimes','policy_group_id','name','descr']
with open(src, newline='', encoding='utf-8') as f_in, open(dst, 'w', newline='', encoding='utf-8') as f_out:
    r = csv.DictReader(f_in)
    w = csv.DictWriter(f_out, fieldnames=keep)
    w.writeheader()
    for row in r:
        w.writerow({k: row.get(k, '') for k in keep})
PY_PMS2
    fi
    # Rewrite SQL COPY lines to load via staging with safe defaults
    python3 - "$SQL_PATH" <<'PY_PMS3'
import re, sys
sql_path = sys.argv[1]
with open(sql_path, encoding='utf-8') as f:
    s = f.read()

a_block = (
    "DROP TABLE IF EXISTS _auth_policy_min;\n"
    "CREATE TEMP TABLE _auth_policy_min (id text, policy_group_id text, name text, descr text);\n"
    "\\COPY _auth_policy_min (id,policy_group_id,name,descr) FROM './dml/pms-auth_policy.simplified.csv' delimiter ',' HEADER  csv;\n"
    "INSERT INTO pms.auth_policy (id,policy_group_id,name,descr,policy_file_id,policy_type,version,policy_schema,valid_from_date,valid_to_date,is_active,cr_by,cr_dtimes,upd_by,upd_dtimes)\n"
    "SELECT id,policy_group_id,name,descr,NULL::text,'DataShare'::text,'1'::varchar(8),'https://schemas.mosip.io/v1/auth-policy'::text, now(), now() + interval '3 years', TRUE,'admin', now(),'admin', now() FROM _auth_policy_min;"
)

ah_block = (
    "DROP TABLE IF EXISTS _auth_policy_h_min;\n"
    "CREATE TEMP TABLE _auth_policy_h_min (id text, eff_dtimes timestamp, policy_group_id text, name text, descr text);\n"
    "\\COPY _auth_policy_h_min (id,eff_dtimes,policy_group_id,name,descr) FROM './dml/pms-auth_policy_h.simplified.csv' delimiter ',' HEADER  csv;\n"
    "INSERT INTO pms.auth_policy_h (id,eff_dtimes,policy_group_id,name,descr,policy_file_id,policy_type,version,policy_schema,valid_from_date,valid_to_date,is_active,cr_by,cr_dtimes,upd_by,upd_dtimes)\n"
    "SELECT id,COALESCE(eff_dtimes, now()),policy_group_id,name,descr,NULL::text,'DataShare'::text,'1'::varchar(8),'https://schemas.mosip.io/v1/auth-policy'::text, now(), now() + interval '3 years', TRUE,'admin', now(),'admin', now() FROM _auth_policy_h_min;"
)

s = re.sub(r"^\\COPY\s+pms\.auth_policy\b[\s\S]*?\n", a_block+"\n", s, count=1, flags=re.IGNORECASE|re.MULTILINE)
s = re.sub(r"^\\COPY\s+pms\.auth_policy_h\b[\s\S]*?\n", ah_block+"\n", s, count=1, flags=re.IGNORECASE|re.MULTILINE)

with open(sql_path, 'w', encoding='utf-8') as f:
    f.write(s)
PY_PMS3
  fi

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


