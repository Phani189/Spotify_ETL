{{ config(materialized='table') }}

WITH subscription_data AS (
    SELECT
        user_id,
        subscription_type,
        DATE_TRUNC('month', start_date) AS subscription_month,
        COALESCE(end_date, CURRENT_DATE) AS end_date
    FROM SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.SUBSCRIPTIONS_BRONZE
),

monthly_counts AS (
    SELECT
        subscription_month,
        subscription_type,
        COUNT(DISTINCT user_id) AS user_count
    FROM subscription_data
    WHERE subscription_month <= CURRENT_DATE
    GROUP BY subscription_month, subscription_type
)

SELECT
    subscription_month,
    subscription_type,
    user_count
FROM monthly_counts
ORDER BY subscription_month, subscription_type;