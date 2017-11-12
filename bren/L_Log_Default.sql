/***************************************************************************************************
GitHub Project: sql_demos - Brendan's repo for interesting SQL
                https://github.com/BrenPatF/sql_demos

Description: Simple script to select the lines from Brendan's logging framework table for the default
             header, which has log_header_id = 0

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        05-Nov-2016 1.0   Created

***************************************************************************************************/
COLUMN text FORMAT A200
COLUMN "Time" FORMAT A8
SET LINES 230
SET PAGES 10000
SELECT line_text text
  FROM log_lines
 WHERE log_header_id = 0
 ORDER BY id
/


