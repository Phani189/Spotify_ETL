--Change Default Role to Security Admin
USE ROLE SECURITYADMIN;

--Granting warehouse permissions to 
GRANT USAGE ON WAREHOUSE python_etl_wh TO ROLE python_access_role;

--Granting database and schema permissions to the role
GRANT USAGE ON DATABASE SPOTIFY_BRONZE_DB TO ROLE python_access_role;

GRANT USAGE ON SCHEMA SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA TO ROLE python_access_role;

--Granting permissions on objects in the schema
GRANT INSERT, SELECT ON ALL TABLES IN SCHEMA SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA TO ROLE python_access_role;

GRANT USAGE,READ ON STAGE SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.SPOTIFY_BRONZE_STAGE  TO ROLE python_access_role;
GRANT USAGE ON FILE FORMAT SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA.SPOTIFY_BRONZE_FILE_FORMAT  TO ROLE python_access_role;

--Granting permissions on pipes in the schema
GRANT OPERATE, MONITOR ON ALL PIPES IN SCHEMA SPOTIFY_BRONZE_DB.SPOTIFY_BRONZE_SCHEMA TO ROLE python_access_role;

