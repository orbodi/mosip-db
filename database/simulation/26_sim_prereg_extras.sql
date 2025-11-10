\c mosip_prereg 

-- Additional prereg data simulation (schema-adaptive)
DO $$
DECLARE
  n int := 150;
BEGIN
  -- reg_appointment
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='prereg' AND table_name='reg_appointment') THEN
    DECLARE
      has_pre_reg boolean := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='prereg' AND table_name='reg_appointment' AND column_name='pre_reg_id');
      has_prereg boolean := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='prereg' AND table_name='reg_appointment' AND column_name='prereg_id');
      has_booking boolean := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='prereg' AND table_name='reg_appointment' AND column_name='booking_dtimes');
      has_appt_date boolean := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='prereg' AND table_name='reg_appointment' AND column_name='appt_date');
      has_appt_time boolean := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='prereg' AND table_name='reg_appointment' AND column_name='appt_time');
      has_appt_ts boolean := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='prereg' AND table_name='reg_appointment' AND column_name='appointment_dtimes');
      col_list text := 'id, regcntr_id';
      val_list text := 'gen_random_uuid(), ''RC1''';
    BEGIN
      IF NOT (has_pre_reg OR has_prereg) THEN
        RAISE NOTICE 'reg_appointment skipped: no prereg column found';
      ELSE
        IF has_pre_reg THEN
          col_list := col_list || ', pre_reg_id';
          val_list := val_list || ', ''PR''||to_char(now(),''YYYYMMDD'')||lpad(i::text,6,''0'')';
        ELSE
          col_list := col_list || ', prereg_id';
          val_list := val_list || ', ''PR''||to_char(now(),''YYYYMMDD'')||lpad(i::text,6,''0'')';
        END IF;

        IF has_booking THEN
          col_list := col_list || ', booking_dtimes';
          val_list := val_list || ', now() + (i||'' minutes'')::interval';
        END IF;

        IF has_appt_ts THEN
          col_list := col_list || ', appointment_dtimes';
          val_list := val_list || ', now() + (i||'' minutes'')::interval';
        ELSE
          IF has_appt_date THEN
            col_list := col_list || ', appt_date';
            val_list := val_list || ', (now()::date + ((i % 7))::int)';
          END IF;
          IF has_appt_time THEN
            col_list := col_list || ', appt_time';
            val_list := val_list || ', ''09:00''';
          END IF;
        END IF;

        col_list := col_list || ', lang_code, cr_by, cr_dtimes';
        val_list := val_list || ', ''fra'', ''sim'', now()';

        EXECUTE format(
          'INSERT INTO prereg.reg_appointment (%s) SELECT %s FROM generate_series(1, %s) AS s(i) ON CONFLICT DO NOTHING',
          col_list,
          val_list,
          n
        );
      END IF;
    END;
  END IF;

  -- applicant_demographic_consumed (if table has minimal columns)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='prereg' AND table_name='applicant_demographic_consumed') THEN
    DECLARE
      has_id boolean := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='prereg' AND table_name='applicant_demographic_consumed' AND column_name='id');
      has_pre_reg boolean := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='prereg' AND table_name='applicant_demographic_consumed' AND column_name='pre_reg_id');
      has_prereg boolean := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='prereg' AND table_name='applicant_demographic_consumed' AND column_name='prereg_id');
      has_status boolean := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='prereg' AND table_name='applicant_demographic_consumed' AND column_name='status_code');
      has_cr_by boolean := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='prereg' AND table_name='applicant_demographic_consumed' AND column_name='cr_by');
      has_cr_dt boolean := EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='prereg' AND table_name='applicant_demographic_consumed' AND column_name='cr_dtimes');
      col_list text := '';
      val_list text := '';
    BEGIN
      IF NOT (has_pre_reg OR has_prereg) THEN
        RAISE NOTICE 'applicant_demographic_consumed skipped: no prereg column';
      ELSE
        IF has_id THEN
          col_list := 'id';
          val_list := 'gen_random_uuid()';
        END IF;

        IF has_pre_reg THEN
          col_list := col_list || CASE WHEN col_list = '' THEN '' ELSE ', ' END || 'pre_reg_id';
          val_list := val_list || CASE WHEN val_list = '' THEN '' ELSE ', ' END || '''PR''||to_char(now(),''YYYYMMDD'')||lpad(i::text,6,''0'')';
        ELSE
          col_list := col_list || CASE WHEN col_list = '' THEN '' ELSE ', ' END || 'prereg_id';
          val_list := val_list || CASE WHEN val_list = '' THEN '' ELSE ', ' END || '''PR''||to_char(now(),''YYYYMMDD'')||lpad(i::text,6,''0'')';
        END IF;

        IF has_status THEN
          col_list := col_list || ', status_code';
          val_list := val_list || ', ''CONSUMED''';
        END IF;
        IF has_cr_by THEN
          col_list := col_list || ', cr_by';
          val_list := val_list || ', ''sim''';
        END IF;
        IF has_cr_dt THEN
          col_list := col_list || ', cr_dtimes';
          val_list := val_list || ', now()';
        END IF;

        EXECUTE format(
          'INSERT INTO prereg.applicant_demographic_consumed (%s) SELECT %s FROM generate_series(1, %s) s(i) ON CONFLICT DO NOTHING',
          col_list,
          val_list,
          n/3
        );
      END IF;
    END;
  END IF;
END $$;


