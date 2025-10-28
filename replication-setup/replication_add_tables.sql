-- Add tables to an existing publication
-- Variables attendues (psql -v):
--   :publication_name  (ex: iam_pub)
--   :table_list        (liste séparée par des virgules: iam.user_detail, iam.user_role)

DO $$
DECLARE
	table_names TEXT[] := string_to_array(:'table_list', ',');
	tbl TEXT;
BEGIN
	FOREACH tbl IN ARRAY table_names LOOP
		IF trim(tbl) <> '' THEN
			EXECUTE format('ALTER PUBLICATION %I ADD TABLE %s', :'publication_name', trim(tbl));
		END IF;
	END LOOP;
END$$;
