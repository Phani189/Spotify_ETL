{{ config(materialized='table') }}

WITH activity_data AS (
    SELECT
        user_id,
        timestamp,
        DAYNAME(timestamp) AS day_of_week
    FROM SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.STREAM_ACTIVITY_BRONZE
),

weekly_counts AS (
    SELECT
        day_of_week,
        COUNT(DISTINCT user_id) AS active_user_count
    FROM activity_data
    GROUP BY day_of_week
)

SELECT
    day_of_week,
    active_user_count
FROM weekly_counts