\c mosip_master 

-- Toggle a small sample of devices to simulate churn
WITH samp AS (
  SELECT id FROM master.device_master WHERE lang_code='fra' ORDER BY random() LIMIT GREATEST(1, (SELECT count(*)/50 FROM master.device_master))
)
UPDATE master.device_master d SET is_active = NOT d.is_active, upd_dtimes = now()
FROM samp s WHERE d.id = s.id;

-- Minor location updates
UPDATE master.location SET name = name
WHERE lang_code='fra' AND random() < 0.01;


