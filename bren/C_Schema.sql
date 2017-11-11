/***************************************************************************************************

Author:      Brendan Furey
Description: Script for SYS schema to create the new schema for Brendan's SQL demos

Further details: 
                 http://aprogrammerwrites.eu/?p=

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        04-May-2016 1.0   Created
Brendan Furey        11-Sep-2016 1.1   Directory

***************************************************************************************************/
REM
REM Run this script from sys schema to create new schema for Brendan's SQL demos
REM

DEFINE DEMO_USER=&1

CREATE USER &DEMO_USER IDENTIFIED BY &DEMO_USER
DEFAULT TABLESPACE "USERS"
TEMPORARY TABLESPACE "TEMP";

-- SYSTEM PRIVILEGES
GRANT CREATE SESSION TO &DEMO_USER ;
GRANT ALTER SESSION TO &DEMO_USER ;
GRANT CREATE TABLE TO &DEMO_USER ;
GRANT CREATE TYPE TO &DEMO_USER ;
GRANT CREATE PUBLIC SYNONYM TO &DEMO_USER ;
GRANT CREATE SYNONYM TO &DEMO_USER ;
GRANT CREATE SEQUENCE TO &DEMO_USER ;
GRANT CREATE VIEW TO &DEMO_USER ;
GRANT UNLIMITED TABLESPACE TO &DEMO_USER ;
GRANT CREATE PROCEDURE TO &DEMO_USER ;
