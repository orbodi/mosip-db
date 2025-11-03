Custom MOSIP DB restore from dumps

Requirements
- psql and pg_restore available (e.g., PostgreSQL 16 client)
- Access to a PostgreSQL server with a superuser or a role that can create/drop databases

Prepare (one-time)
```bash
cd database/custom-db
# generate per-database scripts from template
chmod +x _gen.sh install_all.sh restore_one.sh load_csv_one.sh
./_gen.sh

# create and edit environment
cp .env.example .env
# then edit .env with PGHOST, PGPORT, PGUSER, PGPASSWORD, DB_OWNER
```

Restore ALL databases from dumps
```bash
cd database/custom-db
./install_all.sh
```

Restore ALL databases and load CSV/DML where available
```bash
cd database/custom-db
# optional environment:
#   DML_STRICT=false     # continue on DML errors (log only)
#   SKIP_DBS_DML="mosip_ida keycloak"  # skip DML for these DBs
DML_STRICT=false ./install_all.sh --load-csv
```

Restore a SINGLE database
```bash
cd database/custom-db
./restore_one.sh mosip_master      # replace with the DB name matching ../custom_db_structures/<name>.dump
```

Load CSV/DML for a SINGLE database (optional)
```bash
cd database/custom-db
./load_csv_one.sh mosip_master     # uses module dml.sql mapping when present
```

Notes
- Dumps are read from ../custom_db_structures/*.dump
- Each generated subfolder contains restore.sh and load_csv.sh wrappers
- CSV/DML loading is optional and uses existing module dml.sql files when present

Troubleshooting
- Ensure the role in DB_OWNER already exists on the target server
- If using a remote server, verify network/firewall and PG HBA settings
- DML schema mismatch: set `DML_STRICT=false` to continue despite DML errors or use `SKIP_DBS_DML` to skip specific DBs


