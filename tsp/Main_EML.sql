@..\bren\InitSpool Main_EML
/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting problems and solutions in SQL
                 https://github.com/BrenPatF/sql_demos

Author:          Brendan Furey, 12 November 2017
Description:     Driving script for the England dataset: Creates the view; sets bind variables;
                 calls Run_Queries.sql

Further details: 'SQL for the Travelling Salesman Problem'
                 http://aprogrammerwrites.eu/?p=896

***************************************************************************************************/
PROMPT Point view at EML tables and set EML bind variables
CREATE OR REPLACE VIEW towns AS
SELECT id,    
       name,  
       x,     
       y     
  FROM towns_eml
/
CREATE OR REPLACE VIEW distances AS
SELECT id,    
       a,
       b,
       dst
  FROM distances_eml
/
START Run_Queries 1 5 5 1
@..\bren\EndSpool