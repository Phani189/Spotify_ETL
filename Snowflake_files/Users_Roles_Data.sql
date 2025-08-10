--Change Default Role to System Admin
USE ROLE SYSADMIN;
--Warehouse: python_etl_wh(for all Data loading from stages to tables)
CREATE WAREHOUSE IF NOT EXISTS python_etl_wh
WAREHOUSE_SIZE = 'SMALL'
AUTO_SUSPEND = 60
AUTO_RESUME = TRUE
INITIALLY_SUSPENDED = TRUE;

--Change Default Role to SECURITY Admin
USE ROLE SECURITYADMIN;
-- 1. Create Role
CREATE ROLE IF NOT EXISTS python_access_role;

-- 2. Create User
CREATE USER IF NOT EXISTS python_user_login
PASSWORD = 'Phanipyload@66' 
DEFAULT_ROLE = python_access_role
DEFAULT_WAREHOUSE = python_etl_wh
COMMENT = 'User for Python ETL operations'
MUST_CHANGE_PASSWORD = FALSE;

-- 3. Assign Role to User
GRANT ROLE python_loader_role TO USER python_user;

