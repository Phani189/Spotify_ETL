{{ config(materialized='table') }}

WITH activity_data AS (
    SELECT
        user_id,
        song_id,
        -- Extract the year from the timestamp
        YEAR(timestamp) AS activity_year
    FROM SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.STREAM_ACTIVITY_BRONZE
),

song_user_counts AS (
    SELECT
        activity_year,
        song_id,
        COUNT(DISTINCT user_id) AS user_count
    FROM activity_data
    GROUP BY activity_year, song_id
),

ranked_songs AS (
    SELECT
        activity_year,
        song_id,
        user_count,
    
        RANK() OVER (PARTITION BY activity_year ORDER BY user_count DESC) AS song_rank
    FROM song_user_counts
)

SELECT
    activity_year,
    song_id,
    user_count
FROM ranked_songs
WHERE song_rank = 1 
ORDER BY activity_year;