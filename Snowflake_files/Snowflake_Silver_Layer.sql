USE ROLE SYSADMIN

-- Create a Warehouse for Silver ETL operations

CREATE OR REPLACE WAREHOUSE SILVER_ETL_WH
WAREHOUSE_TYPE= 'STANDARD'
WAREHOUSE_SIZE = 'SMALL'
AUTO_SUSPEND = 60
AUTO_RESUME = TRUE
INITIALLY_SUSPENDED = TRUE;

USE WAREHOUSE SILVER_ETL_WH;

-- Create Database and Schema for Silver Layer

CREATE OR REPLACE DATABASE SPOTIFY_SILVER_DB
WITH COMMENT = 'Database for Silver Layer of Spotify Data';


USE DATABASE SPOTIFY_SILVER_DB;

CREATE OR REPLACE SCHEMA SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA
WITH COMMENT = 'Schema for Silver Layer of Spotify Data';

USE DATABASE SPOTIFY_SILVER_DB;
USE SCHEMA SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA;

-- Create Tables for Silver Layer

CREATE OR REPLACE TABLE SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.USERS_SILVER
(
    user_id INT,
    name STRING,
    age STRING,
    email STRING,
    address STRING,
    device_type STRING,
    listening_time STRING,
    subscription_type STRING,
    subscription_category STRING,
    subscription_days_left INT
);

CREATE OR REPLACE TABLE SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.SUBSCRIPTIONS_SILVER
(
    user_id INT,
    subscription_type STRING,
    subscription_category STRING,
    start_date DATE,
    end_date DATE,
    amount STRING,
    subscription_expired BOOLEAN DEFAULT FALSE
);

CREATE OR REPLACE TABLE SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.ARTISTS_SILVER
(
    artist_id INT,
    name STRING,
    country STRING,
    popularity STRING,
    genre STRING
);

CREATE OR REPLACE TABLE SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.ALBUMS_SILVER
(
    album_id INT,
    album_name STRING,
    artist_id INT,
    release_date DATE,
    genre STRING,
    latest_release_date DATE,
    total_songs INT,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE OR REPLACE TABLE SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.SONGS_SILVER
(
    song_id INT,
    song_name STRING,
    album_id INT,
    artist_id INT,
    release_date DATE,
    genre STRING,
    duration STRING,
    category STRING,
);

CREATE OR REPLACE TABLE SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.PLAYLISTS_SILVER
(
    playlist_id INT,
    playlist_name STRING,
    user_id INT,
    song_id INT,
    created_at TIMESTAMP
);

CREATE OR REPLACE TABLE SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.STREAM_ACTIVITY_SILVER 
(
    user_id INT,
    artist_id INT,
    song_id INT,
    stream_date DATE,
    stream_time STRING
);


INSERT INTO SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.USERS_SILVER
SELECT
    U.user_id,
    U.name,
    U.age,
    U.email,
    U.address,
    U.device_type,
    U.listening_time,
    COALESCE(U.subscription_type,'New User') AS subscription_type,
    U.subscription_category,
    S.DATEDIFF(DAY, CURRENT_DATE, S.end_date) AS subscription_days_left
FROM SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.USERS_BRONZE U
LEFT JOIN SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.SUBSCRIPTIONS_BRONZE S
ON U.user_id = S.user_id
WHERE SUBSCRIPTIONS_BRONZE.subscription_type != 'Free';


INSERT INTO SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.SUBSCRIPTIONS_SILVER
SELECT
    user_id,
    subscription_type,
    subscription_category,
    start_date,
    end_date,
    amount,
    CASE 
        WHEN end_date < CURRENT_DATE THEN TRUE 
        ELSE FALSE 
    END AS subscription_expired
FROM SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.SUBSCRIPTIONS_BRONZE
WHERE subscription_type != 'Free'
;


INSERT INTO SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.ARTISTS_SILVER
SELECT
    A.artist_id,
    A.name,
    A.country,
    A.popularity,
    A.genre,
    A.latest_release_date,
    CASE 
        WHEN A.popularity >= 50 THEN TRUE 
        ELSE FALSE 
    END AS is_active
FROM SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.ARTISTS_BRONZE A 
LEFT JOIN (
    SELECT 
        artist_id, 
        MAX(release_date) AS latest_release_date 
    FROM SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.ALBUMS_BRONZE 
    GROUP BY artist_id
) AS L ON A.artist_id = L.artist_id
WHERE A.popularity IS NOT NULL;


INSERT INTO SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.ALBUMS_SILVER
SELECT
    A.album_id,
    A.album_name,
    A.artist_id,
    A.release_date,
    A.genre,
    L.latest_release_date,
    COUNT(S.song_id) AS total_songs,
    CASE 
        WHEN L.latest_release_date >= DATEADD(YEAR, -1, CURRENT_DATE) THEN TRUE 
        ELSE FALSE 
    END AS is_active
FROM SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.ALBUMS_BRONZE A
LEFT JOIN (
    SELECT 
        album_id, 
        MAX(release_date) AS latest_release_date 
    FROM SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.ALBUMS_BRONZE 
    GROUP BY album_id
) AS L ON A.album_id = L.album_id
LEFT JOIN SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.SONGS_BRONZE S ON A.album_id = S.album_id
GROUP BY 
    A.album_id, 
    A.album_name, 
    A.artist_id, 
    A.release_date, 
    A.genre, 
    L.latest_release_date
;   


INSERT INTO SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.SONGS_SILVER
SELECT
    song_id,
    name AS song_name,
    album_id,
    artist_id,
    release_date,
    genre,
    duration,
    CASE
        WHEN release_date >= DATEADD(YEAR, -1, CURRENT_DATE) THEN 'New Release'
        WHEN release_date < DATEADD(YEAR, -1, CURRENT_DATE) AND release_date >= DATEADD(YEAR, -5, CURRENT_DATE) THEN 'Old Release'
        ELSE 'Classic'
    END AS category
FROM SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.SONGS_BRONZE
WHERE genre IS NOT NULL
AND duration IS NOT NULL;



INSERT INTO SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.PLAYLISTS_SILVER
SELECT
    playlist_id,
    playlist_name,
    user_id,
    song_id,
    created_at
FROM SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.PLAYLISTS_BRONZE
WHERE created_at >= DATEADD(MONTH, -6, CURRENT_DATE);


INSERT INTO SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.STREAM_ACTIVITY_SILVER
SELECT
    user_id INT,
    artist_id INT,
    song_id INT,
    play_count STRING,
    listening_time STRING,
    device_type STRING,
    album_id INT,
    timestamp TIMESTAMP,
    is_liked BOOLEAN,
    is_skipped BOOLEAN
FROM SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.STREAM_ACTIVITY_BRONZE
WHERE device_type IS NOT NULL
AND listening_time IS NOT NULL;




