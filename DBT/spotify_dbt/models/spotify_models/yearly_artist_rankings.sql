{{ config(materialized='table') }}

WITH activity_data AS (
    SELECT
        user_id,
        artist_id,
        YEAR(timestamp) AS activity_year
    FROM SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.STREAM_ACTIVITY_BRONZE
),

artist_user_counts AS (
    SELECT
        activity_year,
        artist_id,
        COUNT(DISTINCT user_id) AS user_count
    FROM activity_data
    GROUP BY activity_year, artist_id
),

ranked_artists AS (
    SELECT
        activity_year,
        artist_id,
        user_count,
        RANK() OVER (PARTITION BY activity_year ORDER BY user_count DESC) AS artist_rank
    FROM artist_user_counts
)

SELECT
    activity_year,
    artist_id,
    user_count
FROM ranked_artists
WHERE artist_rank <= 5
ORDER BY activity_year, artist_rank;