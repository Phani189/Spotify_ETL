
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
-- USERS_GOLD
CREATE OR REPLACE TABLE SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.USERS_GOLD
(
    user_id INT,
    name STRING,
    age STRING,
    email STRING,
    address STRING,
    device_type STRING,
    listening_time INT,
    subscription_type STRING,
    subscription_category STRING,
    subscription_days_left INT,
    is_expired BOOLEAN DEFAULT FALSE
);

-- SUBSCRIPTIONS_GOLD
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

-- ARTISTS_GOLD
CREATE OR REPLACE TABLE SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.ARTISTS_GOLD
(
    artist_id INT,
    name STRING,
    country STRING,
    popularity STRING,
    genre STRING
);

-- ALBUMS_GOLD
CREATE OR REPLACE TABLE SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.ALBUMS_GOLD
(
    album_id INT,
    album_name STRING,
    release_date DATE,
    artist_id INT
);

-- SONGS_GOLD
CREATE OR REPLACE TABLE SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.SONGS_GOLD
(
    song_id INT,
    song_name STRING,
    album_id INT,
    artist_id INT,
    duration STRING,
    genre STRING
);

-- STREAM_ACTIVITY_GOLD
CREATE OR REPLACE TABLE SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.STREAM_ACTIVITY_GOLD
(
    user_id INT,
    artist_id INT,
    song_id INT,
    stream_date TIMESTAMP,
    stream_count INT,
    listening_time STRING,
    device_type STRING,
    subscription_type STRING,
    subscription_category STRING,
    is_liked BOOLEAN DEFAULT FALSE,
    is_skipped BOOLEAN DEFAULT FALSE
);



-- USERS_GOLD INSERT
INSERT INTO SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.USERS_GOLD
SELECT
    U.user_id,
    U.name,
    U.age,
    U.email,
    U.address,
    U.device_type,
    CAST(U.listening_time AS STRING),
    S.subscription_type,
    S.subscription_category,
    DATEDIFF(day, CURRENT_DATE, S.end_date) AS subscription_days_left,
    CASE WHEN DATEDIFF(day, CURRENT_DATE, S.end_date) <= 0 THEN TRUE ELSE FALSE END AS is_expired
FROM SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.USERS_SILVER U
LEFT JOIN SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.SUBSCRIPTIONS_SILVER S
    ON U.user_id = S.user_id
WHERE S.subscription_type != 'Free';

-- SUBSCRIPTIONS_GOLD INSERT
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

-- ARTISTS_GOLD INSERT
INSERT INTO SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.ARTISTS_GOLD
SELECT
    artist_id,
    name,
    country,
    popularity,
    genre
FROM SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.ARTISTS_SILVER;

-- ALBUMS_GOLD INSERT
INSERT INTO SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.ALBUMS_GOLD
SELECT
    album_id,
    album_name,
    release_date,
    artist_id
FROM SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.ALBUMS_SILVER;

-- SONGS_GOLD INSERT
INSERT INTO SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.SONGS_GOLD
SELECT
    song_id,
    song_name,
    album_id,
    artist_id,
    duration,
    genre
FROM SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.SONGS_SILVER;

-- STREAM_ACTIVITY_GOLD INSERT
INSERT INTO SPOTIFY_GOLD_DB.SPOTIFY_GOLD_SCHEMA.STREAM_ACTIVITY_GOLD
SELECT
    user_id,
    artist_id,
    song_id,
    CURRENT_DATE AS stream_date,
    COUNT(*) AS stream_count,
    CAST(listening_time as INT),
    device_type,
    subscription_type,
    subscription_category,
    CASE WHEN is_liked THEN TRUE ELSE FALSE END AS is_liked,
    CASE WHEN is_skipped THEN TRUE ELSE FALSE END AS is_skipped
FROM SPOTIFY_SILVER_DB.SPOTIFY_SILVER_SCHEMA.STREAM_ACTIVITY_SILVER
GROUP BY
    user_id,
    artist_id,
    song_id,
    listening_time,
    device_type,
    subscription_type,
    subscription_category,
    is_liked,
    is_skipped;



