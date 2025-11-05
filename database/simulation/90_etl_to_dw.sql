-- Simple BI aggregation
\c mosip_ida 

CREATE SCHEMA IF NOT EXISTS dw;

CREATE TABLE IF NOT EXISTS dw.fact_auth_daily (
  day date,
  auth_type text,
  total int,
  success int,
  fail int
);

INSERT INTO dw.fact_auth_daily (day, auth_type, total, success, fail)
SELECT date_trunc('day', cr_dtimes)::date, auth_type_code,
       count(*),
       count(*) FILTER (WHERE status_code='SUCCESS'),
       count(*) FILTER (WHERE status_code<>'SUCCESS')
FROM ida.auth_transaction
WHERE cr_dtimes >= now() - interval '14 days'
GROUP BY 1,2
ON CONFLICT DO NOTHING;


