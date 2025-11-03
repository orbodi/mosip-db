#!/usr/bin/env bash
set -euo pipefail

DB_NAME="$(basename "$(cd "$(dirname "$0")" && pwd)")"
"$(cd "$(dirname "$0")/.." && pwd)/load_csv_one.sh" "$DB_NAME"


