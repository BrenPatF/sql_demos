CREATE OR REPLACE PACKAGE Timer_Set AS
/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting problems and solutions in SQL
                 https://github.com/BrenPatF/sql_demos

Description: This package contains procedures to facilitate PL/SQL code timing. An initial version
             was published on Scribd in 2010, followed by updates to 2012. I copied the Scribd
             article to my blog for easier access recently:

                 'Code Timing and Object Orientation and Zombies'
                 http://aprogrammerwrites.eu/?p=1632

             v1.2 was published with two other utility packages for the articles linked in the link
             below:

                 Utils:    General utilities
                 UT_Utils: Utility procedures for Brendan's database unit testing framework

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        22-Nov-2010 1.0   Initial version
Brendan Furey        25-Sep-2012 1.1   Final Scribd version
Brendan Furey        08-May-2016 1.2   Factored out 'pretty printing' into general utility Utils
Brendan Furey        21-May-2016 1.3   Type name changed

***************************************************************************************************/

c_timer_total       CONSTANT VARCHAR2(30) := 'Total';
TYPE timer_stat_rec IS RECORD (timer_set_name VARCHAR2(100), ela_secs NUMBER, cpu_secs NUMBER, calls PLS_INTEGER);

FUNCTION Construct (p_timer_set_name VARCHAR2) RETURN PLS_INTEGER;
PROCEDURE Init_Time (p_timer_set_ind PLS_INTEGER);
PROCEDURE Destroy (p_timer_set_ind PLS_INTEGER);
PROCEDURE Increment_Time (p_timer_set_ind PLS_INTEGER, p_timer_name VARCHAR2);
FUNCTION Get_Timer_Stats (p_timer_set_ind PLS_INTEGER, p_timer_name VARCHAR2 DEFAULT c_timer_total) RETURN timer_stat_rec;
FUNCTION Timer_Avg_Ela_MS (p_timer_set_ind PLS_INTEGER, p_timer_name VARCHAR2) RETURN PLS_INTEGER;
PROCEDURE Write_Times (p_timer_set_ind PLS_INTEGER);
PROCEDURE Summary_Times;

END Timer_Set;
/
SHOW ERROR

