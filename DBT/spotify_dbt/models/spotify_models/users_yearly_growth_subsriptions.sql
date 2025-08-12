{{ config(materialized='table') }}

WITH subscription_data AS (
    SELECT
        user_id,
        subscription_type,
        DATE_TRUNC('year', start_date) AS subscription_year,
        COALESCE(end_date, CURRENT_DATE) AS end_date
    FROM SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.SUBSCRIPTIONS_BRONZE
),

yearly_counts AS (
    SELECT
        subscription_year,
        subscription_type,
        COUNT(DISTINCT user_id) AS user_count
    FROM subscription_data
    WHERE subscription_year <= CURRENT_DATE
    GROUP BY subscription_year, subscription_type
)

SELECT
    subscription_year,
    subscription_type,
    user_count
FROM yearly_counts
ORDER BY subscription_year, subscription_type;