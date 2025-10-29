#!/usr/bin/env python3
import argparse
import csv
import os
from pathlib import Path

import psycopg2


def list_csvs(directory: Path):
	return sorted([p for p in directory.glob('master-*.csv') if p.is_file()])


def table_name_from_csv(path: Path) -> str:
	# master-<table>.csv -> <table>
	name = path.stem
	if name.startswith('master-'):
		return name[len('master-'):]
	return name


def fetch_table_columns(conn, schema: str, table: str):
	with conn.cursor() as cur:
		cur.execute(
			"""
			SELECT column_name
			FROM information_schema.columns
			WHERE table_schema = %s AND table_name = %s
			ORDER BY ordinal_position
			""",
			(schema, table),
		)
		return [r[0] for r in cur.fetchall()]


def read_csv_header(path: Path):
	with path.open(newline='', encoding='utf-8') as f:
		reader = csv.reader(f)
		headers = next(reader)
		return [h.strip() for h in headers]


def main():
	parser = argparse.ArgumentParser(description='Generate COPY plan for mosip_master CSVs')
	parser.add_argument('--host', default=os.getenv('PGHOST', 'localhost'))
	parser.add_argument('--port', type=int, default=int(os.getenv('PGPORT', '5433')))
	parser.add_argument('--db', default=os.getenv('PGDATABASE', 'mosip_master'))
	parser.add_argument('--user', default=os.getenv('PGUSER', 'sysadmin'))
	parser.add_argument('--password', default=os.getenv('PGPASSWORD', ''))
	parser.add_argument('--schema', default='master')
	parser.add_argument('--csv-dir', required=True, help='Directory with master-*.csv files')
	parser.add_argument('--output-sql', default='copy_mosip_master.sql')
	args = parser.parse_args()

	conn = psycopg2.connect(
		host=args.host, port=args.port, dbname=args.db, user=args.user, password=args.password
	)
	csv_dir = Path(args.csv_dir)
	csv_files = list_csvs(csv_dir)

	lines = ["-- Auto-generated COPY plan for mosip_master", "SET search_path TO %s, public;" % args.schema]
	for csv_path in csv_files:
		table = table_name_from_csv(csv_path)
		db_cols = fetch_table_columns(conn, args.schema, table)
		csv_cols = read_csv_header(csv_path)
		# Use CSV column order, but only keep columns that exist in DB
		cols = [c for c in csv_cols if c in db_cols]
		if not cols:
			continue
		col_list = ', '.join('"%s"' % c for c in cols)
		abs_path = str(csv_path.resolve()).replace('\\', '/')
		lines.append(f"\\copy {args.schema}.{table} ({col_list}) FROM '{abs_path}' WITH CSV HEADER")

	with open(args.output_sql, 'w', encoding='utf-8') as out:
		out.write('\n'.join(lines) + '\n')

	print(f"Wrote {args.output_sql} with {len(csv_files)} files processed.")


if __name__ == '__main__':
	main()
