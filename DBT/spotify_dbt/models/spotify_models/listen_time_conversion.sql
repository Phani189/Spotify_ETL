{{ config(materialized='table') }}

SELECT
    user_id,
    song_id,
    timestamp,
    {{ listentime_mins_to_hrs('listening_time') }} AS listening_time_in_hours
FROM SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.STREAM_ACTIVITY_BRONZE
WHERE listening_time IS NOT NULL;
