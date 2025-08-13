SELECT *
FROM SILVER_LAYER_DB.SILVER_LAYER_SCHEMA.USERS
WHERE subscription_type = 'Free'
  AND subscription_days >= 0;