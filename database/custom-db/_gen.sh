#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

names=(
  auaudit biintegration edb giteadb keycloak mds_auth mds_enroll mosip_audit
  mosip_authdevice mosip_credential mosip_iam mosip_ida mosip_idmap mosip_idrepo
  mosip_kernel mosip_keymgr mosip_master mosip_pms mosip_prereg mosip_regdevice
  mosip_regprc mosip_websub postgres tsp_audit
)

for n in "${names[@]}"; do
  d="$SCRIPT_DIR/$n"
  mkdir -p "$d"
  cp "$SCRIPT_DIR/_template/restore.sh" "$d/restore.sh"
  cp "$SCRIPT_DIR/_template/load_csv.sh" "$d/load_csv.sh"
  chmod +x "$d/restore.sh" "$d/load_csv.sh"
done

echo "Generated per-database scripts."


