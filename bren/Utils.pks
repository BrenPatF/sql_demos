CREATE OR REPLACE PACKAGE Utils AS
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
Brendan Furey        11-Nov-2017 1.1   Reduced version for sql_demos

***************************************************************************************************/

c_list_end_marker       CONSTANT VARCHAR2(30) := 'LIST_END_MARKER';
g_list_delimiter                 VARCHAR2(30) := '|';
c_time_fmt              CONSTANT VARCHAR2(30) := 'HH24:MI:SS';
c_datetime_fmt          CONSTANT VARCHAR2(30) := 'DD Mon RRRR ' || c_time_fmt;
c_fld_delim             CONSTANT VARCHAR2(30) := '  ';

FUNCTION Create_Log (p_description VARCHAR2 DEFAULT NULL) RETURN PLS_INTEGER;
PROCEDURE Clear_Log (p_log_header_id PLS_INTEGER DEFAULT 0);
PROCEDURE Reset_Log (p_log_header_id PLS_INTEGER DEFAULT 0);
PROCEDURE Write_Log (p_text             VARCHAR2,
                     p_indent_level     PLS_INTEGER DEFAULT 0,
                     p_group_text       VARCHAR2 DEFAULT NULL);
PROCEDURE Write_Other_Error (p_package VARCHAR2 DEFAULT NULL, p_proc VARCHAR2 DEFAULT NULL, p_group_text VARCHAR2 DEFAULT NULL);
FUNCTION Get_Seconds (p_interval INTERVAL DAY TO SECOND) RETURN NUMBER;
PROCEDURE Heading (p_head VARCHAR2, p_indent_level PLS_INTEGER DEFAULT 0, p_group_text VARCHAR2 DEFAULT NULL);
PROCEDURE Pr_List_As_Line (p_val_lis L1_chr_arr, p_len_lis L1_num_arr, p_indent_level PLS_INTEGER DEFAULT 0, p_save_line BOOLEAN DEFAULT FALSE);
PROCEDURE Reprint_Line;
PROCEDURE Col_Headers (p_val_lis L1_chr_arr, p_len_lis L1_num_arr, p_indent_level PLS_INTEGER DEFAULT 0);

PROCEDURE Write_Plan (p_sql_marker VARCHAR2, p_group_text VARCHAR2 DEFAULT NULL, p_add_outline BOOLEAN DEFAULT FALSE);

g_debug_level           PLS_INTEGER := 1;
g_line_size             PLS_INTEGER := 180;
g_group_text            VARCHAR2(30);

END Utils;
/
SHOW ERROR


