USE ROLE SYSADMIN;

-- Create a Warehouse for Gold ETL operations

CREATE OR REPLACE WAREHOUSE GOLD_ETL_WH
WAREHOUSE_TYPE= 'STANDARD'
WAREHOUSE_SIZE = 'SMALL'
AUTO_SUSPEND = 60
AUTO_RESUME = TRUE
INITIALLY_SUSPENDED = TRUE;

USE WAREHOUSE GOLD_ETL_WH;

-- Create Database and Schema for Gold Layer

CREATE OR REPLACE DATABASE SPOTIFY_GOLD_DB
WITH COMMENT = 'Database for Gold Layer of Spotify Data';

USE DATABASE SPOTIFY_GOLD_DB;

CREATE OR REPLACE SCHEMA SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA
WITH COMMENT = 'Schema for Gold Layer of Spotify Data';

USE DATABASE SPOTIFY_GOLD_DB;
USE SCHEMA SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA;

-- Create Tables for Gold Layer

CREATE OR REPLACE TABLE SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.USERS_GOLD
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
    is_expired BOOLEAN DEFAULT FALSE
);


CREATE OR REPLACE TABLE SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.SUBSCRIPTIONS_GOLD
(
    user_id INT,
    subscription_type STRING,
    subscription_category STRING,
    start_date DATE,
    end_date DATE,
    amount STRING,
    subscription_expired BOOLEAN DEFAULT FALSE
);


CREATE OR REPLACE TABLE SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.ARTISTS_GOLD
(
    artist_id INT,
    name STRING,
    country STRING,
    popularity STRING,
    genre STRING
);


CREATE OR REPLACE TABLE SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.ALBUMS_GOLD
(
    album_id INT,
    album_name STRING,
    release_date DATE,
    artist_id INT
);



CREATE OR REPLACE TABLE SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.SONGS_GOLD
(
    song_id INT,
    name STRING,
    album_id INT,
    artist_id INT,
    duration STRING,
    genre STRING,
    release_date DATE
);



CREATE OR REPLACE TABLE SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.STREAM_ACTIVITY_GOLD
(
    user_id INT,
    artist_id INT,
    song_id INT,
    stream_date DATE,
    stream_count INT,
    listening_time STRING,
    device_type STRING,
    album_id INT,
    subscription_type STRING,
    subscription_category STRING,
    is_liked BOOLEAN DEFAULT FALSE,
    is_skipped BOOLEAN DEFAULT FALSE
);


CREATE OR REPLACE TABLE SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.PLAYLISTS_GOLD
(
    playlist_id INT,
    playlist_name STRING,
    user_id INT,
    song_id INT,
    created_at TIMESTAMP
);


INSERT INTO SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.USERS_GOLD
SELECT
    U.user_id,
    U.name,
    U.age,
    U.email,
    U.address,
    U.device_type,
    U.listening_time,
    S.subscription_type,
    S.subscription_category,
    DATEDIFF(DAY, CURRENT_DATE, S.end_date) AS subscription_days_left,
    CASE WHEN DATEDIFF(DAY, CURRENT_DATE, S.end_date) <= 0 THEN TRUE ELSE FALSE END AS is_expired
FROM SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.USERS_SILVER U
LEFT JOIN SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.SUBSCRIPTIONS_SILVER S
ON U.user_id = S.user_id
WHERE S.subscription_type != 'Free';



INSERT INTO SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.SUBSCRIPTIONS_GOLD
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
FROM SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.SUBSCRIPTIONS_SILVER;



INSERT INTO SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.ARTISTS_GOLD
SELECT
    artist_id,
    name,
    country,
    popularity,
    genre
FROM SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.ARTISTS_SILVER;
INSERT INTO SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.ALBUMS_GOLD
SELECT
    album_id,
    album_name,
    release_date,
    artist_id
FROM SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.ALBUMS_SILVER;

INSERT INTO SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.SONGS_GOLD
SELECT
    song_id,
    name,
    album_id,
    artist_id,
    duration,
    genre,
    release_date
FROM SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.SONGS_SILVER;


INSERT INTO SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.STREAM_ACTIVITY_GOLD
SELECT
    user_id,
    artist_id,
    song_id,
    stream_date,
    COUNT(*) AS stream_count,
    listening_time,
    device_type,
    album_id,
    subscription_type,
    subscription_category,
    CASE WHEN is_liked = TRUE THEN TRUE ELSE FALSE END AS is_liked,
    CASE WHEN is_skipped = TRUE THEN TRUE ELSE FALSE END AS is_skipped
FROM SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.STREAM_ACTIVITY_SILVER
GROUP BY
    user_id,
    artist_id,
    song_id,
    stream_date,
    listening_time,
    device_type,
    album_id,
    subscription_type,
    subscription_category,
    is_liked,
    is_skipped;











