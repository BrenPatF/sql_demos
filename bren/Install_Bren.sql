@..\bren\InitSpool Install_Bren
/***************************************************************************************************
GitHub Project: sql_demos - Brendan's repo for interesting SQL
                https://github.com/BrenPatF/sql_demos

Author:         Brendan Furey, 11 November 2017
Description:    Installation script for library schema, bren, for the sql_demos GitHub project for
                the common objects

***************************************************************************************************/

REM Run this script from schema bren to create the common objects

PROMPT Common tables creation
PROMPT ======================

PROMPT Create table log_headers
DROP TABLE log_lines
/
DROP TABLE log_headers
/
CREATE TABLE log_headers (
        id                      INTEGER NOT NULL,
        description             VARCHAR2(500),
        creation_date           TIMESTAMP,
        CONSTRAINT hdr_pk       PRIMARY KEY (id)
)
/
PROMPT Insert the default log header
INSERT INTO log_headers VALUES (0, 'Miscellaneous output', SYSTIMESTAMP)
/
CREATE OR REPLACE PUBLIC SYNONYM log_headers FOR log_headers
/
GRANT SELECT ON log_headers TO demo_user
/
DROP SEQUENCE log_headers_s
/
CREATE SEQUENCE log_headers_s START WITH 1
/
PROMPT Create table log_lines
CREATE TABLE log_lines (
        id                      INTEGER NOT NULL,
        log_header_id           INTEGER NOT NULL,
        group_text              VARCHAR2(100),
        line_text               VARCHAR2(4000),
        creation_date           TIMESTAMP,
        CONSTRAINT lin_pk       PRIMARY KEY (id, log_header_id),
        CONSTRAINT lin_hdr_fk   FOREIGN KEY (log_header_id) REFERENCES log_headers (id)
)
/
CREATE OR REPLACE PUBLIC SYNONYM log_lines FOR log_lines
/
GRANT SELECT ON log_lines TO demo_user
/
DROP SEQUENCE log_lines_s
/
CREATE SEQUENCE log_lines_s START WITH 1
/
PROMPT Create type L1_chr_arr
CREATE OR REPLACE TYPE L1_chr_arr IS VARRAY(32767) OF VARCHAR2(32767)
/
PROMPT Create type L1_num_arr
CREATE OR REPLACE TYPE L1_num_arr IS VARRAY(32767) OF NUMBER
/
PROMPT Packages creation
PROMPT =================

PROMPT Create package Utils
@Utils.pks
@Utils.pkb

PROMPT Create package Timer_Set
@Timer_Set.pks
@Timer_Set.pkb

CREATE OR REPLACE PUBLIC SYNONYM Utils FOR Utils
/
CREATE OR REPLACE PUBLIC SYNONYM Timer_Set FOR Timer_Set
/
CREATE OR REPLACE PUBLIC SYNONYM L1_num_arr FOR L1_num_arr
/
GRANT EXECUTE ON L1_num_arr TO bal_num_part
/
GRANT EXECUTE ON Utils TO fan_foot, tsp, bal_num_part
/
GRANT EXECUTE ON Timer_Set TO fan_foot
/
@..\bren\EndSpool
