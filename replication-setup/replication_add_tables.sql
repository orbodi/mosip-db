-- Add tables to an existing publication
-- Variables attendues (psql -v):
--   :publication_name  (ex: iam_pub)
--   :table_list        (liste séparée par des virgules: iam.user_detail, iam.user_role)

-- Injecter les variables côté serveur
SELECT set_config('mosip.rep_pub_name', :'publication_name', false);
SELECT set_config('mosip.rep_table_list', :'table_list', false);

DO $$
DECLARE
	pub_name text := current_setting('mosip.rep_pub_name');
	raw_list text := current_setting('mosip.rep_table_list');
	table_names text[] := regexp_split_to_array(raw_list, '\s*,\s*');
	tbl text;
BEGIN
	FOREACH tbl IN ARRAY table_names LOOP
		IF tbl IS NOT NULL AND length(trim(tbl)) > 0 THEN
			EXECUTE format('ALTER PUBLICATION %I ADD TABLE %s', pub_name, trim(tbl));
		END IF;
	END LOOP;
END$$;
