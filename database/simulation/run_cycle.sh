#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/.env" ]]; then source "$SCRIPT_DIR/.env"; fi

export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGUSER="${PGUSER:-postgres}"
export PGPASSWORD="${PGPASSWORD:-}"

SIM_REG_COUNT="${SIM_REG_COUNT:-200}"
SIM_PREREG_COUNT="${SIM_PREREG_COUNT:-300}"
SIM_AUTH_COUNT="${SIM_AUTH_COUNT:-800}"
SIM_OTP_COUNT="${SIM_OTP_COUNT:-1200}"
SIM_DEVICE_COUNT="${SIM_DEVICE_COUNT:-50}"
SIM_RESIDENT_REQ_COUNT="${SIM_RESIDENT_REQ_COUNT:-100}"
SIM_IAM_USER_COUNT="${SIM_IAM_USER_COUNT:-10}"

psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/10_baseline_load.sql"
# Extra master tables
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/12_sim_master_extras.sql" || true
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/15_sim_zones.sql"
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -v sim_reg_count=$SIM_REG_COUNT -f "$SCRIPT_DIR/20_sim_registrations.sql"
# Extra regprc tables
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/22_sim_reg_extras.sql" || true
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -v sim_reg_progress=$((SIM_REG_COUNT*9/10)) -f "$SCRIPT_DIR/21_link_prereg_to_reg.sql" || true
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -v sim_prereg_count=$SIM_PREREG_COUNT -f "$SCRIPT_DIR/25_sim_prereg.sql" || true
# Extra prereg tables
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/26_sim_prereg_extras.sql" || true
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -v sim_uin_count=$((SIM_REG_COUNT/2)) -f "$SCRIPT_DIR/30_sim_idrepo.sql"
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -v sim_uin_from_reg=$((SIM_REG_COUNT/3)) -f "$SCRIPT_DIR/31_generate_uin_from_reg.sql"
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -v sim_vid_count=$((SIM_REG_COUNT/4)) -f "$SCRIPT_DIR/35_generate_vid.sql" || true
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -v sim_otp_count=$SIM_OTP_COUNT -v sim_auth_count=$SIM_AUTH_COUNT -f "$SCRIPT_DIR/40_sim_auth.sql"
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -v sim_auth_from_ids=$((SIM_AUTH_COUNT/2)) -f "$SCRIPT_DIR/41_sim_auth_from_uin.sql"
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/50_sim_master_updates.sql"
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/60_sim_pms.sql" || true
# Additional DB simulations (authdevice, resident, iam) — adaptive
db_exists() { psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -tAc "SELECT 1 FROM pg_database WHERE datname='$1'" | grep -q 1; }

if db_exists mosip_authdevice; then
  psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -c "SET app.sim_device_count='$SIM_DEVICE_COUNT'" -f "$SCRIPT_DIR/62_sim_authdevice.sql" || true
fi
if db_exists mosip_resident; then
  psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -c "SET app.sim_resident_req_count='$SIM_RESIDENT_REQ_COUNT'" -f "$SCRIPT_DIR/70_sim_resident.sql" || true
fi
if db_exists mosip_iam; then
  psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -c "SET app.sim_iam_user_count='$SIM_IAM_USER_COUNT'" -f "$SCRIPT_DIR/75_sim_iam.sql" || true
fi
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/55_print_orders.sql" || true
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/45_notifications.sql" || true
# Cross-DB audit feeds (tsp_audit, auaudit, kernel, mosip_audit)
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/85_sim_audit_feeds.sql" || true
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/90_etl_to_dw.sql"

echo "Cycle done."


