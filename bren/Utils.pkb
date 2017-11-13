CREATE OR REPLACE PACKAGE BODY Utils AS
/***************************************************************************************************
GitHub Project: sql_demos - Brendan's repo for interesting SQL
                https://github.com/BrenPatF/sql_demos

Description: This package contains general utility procedures. It was published initially with two
             other utility packages for the articles linked in the link below:

                 Utils_TT:  Utility procedures for Brendan's TRAPIT API testing framework
                 Timer_Set: Code timing utility

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

             This version strips out everything not required for the new GitHub project sql_demos,
             which is mainly: logging, pretty printing and execution plan capture

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        08-May-2016 1.0   Initial for first article
Brendan Furey        11-Nov-2016 1.1   Reduced version for sql_demos

***************************************************************************************************/

c_lines                 CONSTANT VARCHAR2(1000) := '--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------';
c_equals                CONSTANT VARCHAR2(1000) := '=======================================================================================================================================================================================================';
c_in_dir                CONSTANT VARCHAR2(30) := 'INPUT_DIR';

g_log_header_id         PLS_INTEGER := 0;
g_line_lis              L1_chr_arr;
g_line_printed          VARCHAR2(32767);
g_indent_level          PLS_INTEGER := 0;

/***************************************************************************************************

Reset_Log: Logging procedure, resets global header id

***************************************************************************************************/
PROCEDURE Reset_Log (p_log_header_id PLS_INTEGER DEFAULT 0) IS -- log header id
BEGIN

  g_log_header_id := p_log_header_id;

END Reset_Log;

/***************************************************************************************************

Clear_Log: Logging procedure, clears log lines for header id

***************************************************************************************************/
PROCEDURE Clear_Log (p_log_header_id PLS_INTEGER DEFAULT 0) IS -- log header id
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

  DELETE log_lines WHERE log_header_id = p_log_header_id;
  IF p_log_header_id > 0 THEN
    DELETE log_headers WHERE id = p_log_header_id;
  END IF;
  COMMIT;

END Clear_Log;

/***************************************************************************************************

Create_Log: Logging procedure, creates log header, returning its id

***************************************************************************************************/
FUNCTION Create_Log (p_description VARCHAR2 DEFAULT NULL) -- log description
                        RETURN PLS_INTEGER IS             -- log header id
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

  INSERT INTO log_headers (
        id,
        description,
        creation_date
  ) VALUES (
        log_headers_s.NEXTVAL,
        p_description,
        SYSTIMESTAMP)
  RETURNING id INTO g_log_header_id;
  COMMIT;
  RETURN g_log_header_id;

END Create_Log;

/***************************************************************************************************

Write_Log: Logging procedure, writes log line for header stored in global

***************************************************************************************************/
PROCEDURE Write_Log (p_text             VARCHAR2,                 -- line to write
                     p_indent_level     PLS_INTEGER DEFAULT 0,    -- indent level
                     p_group_text       VARCHAR2 DEFAULT NULL) IS -- group text
  PRAGMA AUTONOMOUS_TRANSACTION;
  c_spaces              CONSTANT VARCHAR2(100) := '                                                  ';
  c_indent_amount       CONSTANT PLS_INTEGER := 4;
  l_indent                       VARCHAR2(20) := Substr (c_spaces, 1, p_indent_level * c_indent_amount);
  l_line_text                    VARCHAR2(4000) := Substr (l_indent || p_text, 1, 4000);
BEGIN

  IF p_group_text IS NOT NULL THEN
    g_group_text := p_group_text;
  END IF;

  INSERT INTO log_lines (
        id,
        log_header_id,
        group_text,
        line_text,
        creation_date
  ) VALUES (
        log_lines_s.NEXTVAL,
        g_log_header_id,
        g_group_text,
        l_line_text,
        SYSTIMESTAMP);
  COMMIT;

END Write_Log;

/***************************************************************************************************

Write_Other_Error: Write the SQL error and backtrace to log, called from WHEN OTHERS

***************************************************************************************************/
PROCEDURE Write_Other_Error (p_package          VARCHAR2 DEFAULT NULL,    -- package name
                             p_proc             VARCHAR2 DEFAULT NULL,    -- procedure name
                             p_group_text       VARCHAR2 DEFAULT NULL) IS -- group text
BEGIN

  Write_Log (p_text =>  'Others error in ' || p_package || '(' || p_proc || '): ' || SQLERRM || ': ' || DBMS_Utility.Format_Error_Backtrace, p_group_text => p_group_text );

END Write_Other_Error;

/***************************************************************************************************

Get_Seconds: Simple function to get the seconds as a number from an interval

***************************************************************************************************/
FUNCTION Get_Seconds (p_interval INTERVAL DAY TO SECOND) -- time intervale
                        RETURN NUMBER IS                 -- time in seconds
BEGIN

  RETURN EXTRACT (SECOND FROM p_interval) + 60 * EXTRACT (MINUTE FROM p_interval) + 3600 * EXTRACT (HOUR FROM p_interval);

END Get_Seconds;

/***************************************************************************************************

Heading: Write a string as a heading with double underlining

***************************************************************************************************/
PROCEDURE Heading (p_head       VARCHAR2,                 -- heading string
                   p_indent_level PLS_INTEGER DEFAULT 0,  -- indent level
                   p_group_text VARCHAR2 DEFAULT NULL) IS -- group text

  l_under       VARCHAR2(500) := Substr (c_equals, 1, Length (p_head));

BEGIN

  Write_Log (p_text => '', p_indent_level => p_indent_level, p_group_text => p_group_text);
  Write_Log (p_text => p_head, p_indent_level => p_indent_level);
  Write_Log (p_text => l_under, p_indent_level => p_indent_level);

END Heading;

/***************************************************************************************************

Pr_List_As_Line: Print a list of strings as one line, saving for reprinting later if desired,
                 separating fields by a 2-space delimiter; second list is numbers for lengths, with
                 -ve/+ve sign denoting right/left-justify

***************************************************************************************************/
PROCEDURE Pr_List_As_Line (p_val_lis            L1_chr_arr, -- token list
                           p_len_lis            L1_num_arr, -- length list
                           p_indent_level       PLS_INTEGER DEFAULT 0,
                           p_save_line BOOLEAN DEFAULT FALSE) IS  -- TRUE if to save in global
  l_line        VARCHAR2(32767);
  l_fld         VARCHAR2(32767);
  l_val         VARCHAR2(32767);
BEGIN

  FOR i IN 1..p_val_lis.COUNT LOOP

    l_val := Nvl (p_val_lis(i), ' ');
    IF p_len_lis(i) < 0 THEN
      l_fld := LPad (l_val, -p_len_lis(i));
    ELSE
      l_fld := RPad (l_val, p_len_lis(i));
    END IF;
    IF i = 1 THEN
      l_line := l_fld;
    ELSE
      l_line := l_line || c_fld_delim || l_fld;
    END IF;

  END LOOP;
  Write_Log (l_line, p_indent_level);
  IF p_save_line THEN
    g_line_printed := l_line;
    g_indent_level := p_indent_level;
  END IF;

END Pr_List_As_Line;

/***************************************************************************************************

Reprint_Line: Reprint the line previously printed by Pr_List_As_Line, stored in a global

***************************************************************************************************/
PROCEDURE Reprint_Line IS
BEGIN

  Write_Log (g_line_printed, g_indent_level);

END Reprint_Line;

/***************************************************************************************************

Col_Headers: Print a set of column headers, input as lists of values and length/justification's

***************************************************************************************************/
PROCEDURE Col_Headers (p_val_lis        L1_chr_arr,               -- list of headers
                       p_len_lis        L1_num_arr,               -- list of lengths
                       p_indent_level   PLS_INTEGER DEFAULT 0) IS -- indent level

  l_line_lis    L1_chr_arr := L1_chr_arr();

BEGIN

  g_line_lis := L1_chr_arr();
  g_line_lis.EXTEND (p_val_lis.COUNT);
  Write_Log (' ');
  Pr_List_As_Line (p_val_lis, p_len_lis, p_indent_level);

  FOR i IN 1..p_val_lis.COUNT LOOP

    g_line_lis (i) := c_lines;

  END LOOP;
  Pr_List_As_Line (g_line_lis, p_len_lis, p_indent_level, TRUE);

END Col_Headers;

/***************************************************************************************************

Get_SQL_Id: Given a marker string to match against in v$sql get the sql_id

***************************************************************************************************/
FUNCTION Get_SQL_Id  (p_sql_marker VARCHAR2)   -- marker string
                            RETURN VARCHAR2 IS -- sql id
  l_sql_id VARCHAR2(60);
BEGIN

  SELECT Max (sql_id) KEEP (DENSE_RANK LAST ORDER BY last_load_time)
    INTO l_sql_id
    FROM v$sql
   WHERE sql_text LIKE '%' || p_sql_marker || '%' AND sql_text NOT LIKE '%SQL_TEXT LIKE%' AND sql_text NOT LIKE 'BEGIN%';

  RETURN l_sql_id;

END Get_SQL_Id;

/***************************************************************************************************

Write_Plan: Given a marker string to match against in v$sql extract the execution plan via 
            DBMA_XPlan and insert it into the log table

***************************************************************************************************/
PROCEDURE Write_Plan (p_sql_marker  VARCHAR2,                 -- SQL marker string (include this in the SQL)
                      p_group_text  VARCHAR2 DEFAULT NULL,    -- optional log grouping
                      p_add_outline BOOLEAN DEFAULT FALSE) IS -- repeat the plan with outline added
  PRAGMA AUTONOMOUS_TRANSACTION;
  l_sql_id VARCHAR2(60) := Get_SQL_Id (p_sql_marker);
  PROCEDURE Ins_Plan (p_type VARCHAR2) IS
  BEGIN

    INSERT INTO log_lines (
           id,
           log_header_id,
           group_text,
           line_text,
           creation_date)
    SELECT log_lines_s.NEXTVAL,
           g_log_header_id,
           g_group_text, 
           plan_table_output, 
           SYSTIMESTAMP
      FROM TABLE (DBMS_XPlan.Display_Cursor (l_sql_id, NULL, p_type)
                 );
  END Ins_Plan;

BEGIN

  IF p_group_text IS NOT NULL THEN
    g_group_text := p_group_text;
  END IF;

  Ins_Plan ('ALLSTATS LAST');
  IF p_add_outline THEN

    Ins_Plan ('OUTLINE LAST');

  END IF;

  COMMIT;

END Write_Plan;

END Utils;
/
SHOW ERROR



