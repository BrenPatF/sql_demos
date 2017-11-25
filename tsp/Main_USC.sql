@..\bren\InitSpool Main_USC
/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting SQL
                 https://github.com/BrenPatF/sql_demos

Author:          Brendan Furey, 12 November 2017
Description:     Driving script for the US cities (USC) dataset for the travelling salesman problem:
                 Creates the view; calls Run_Queries_TSP.sql passing parameters

Further details: 'SQL for the Travelling Salesman Problem', July 2013
                 http://aprogrammerwrites.eu/?p=896
***************************************************************************************************/

PROMPT Point view at EML tables and set EML bind variables
CREATE OR REPLACE VIEW towns AS
SELECT id,    
       name,  
       x,     
       y     
  FROM towns_usc
/
CREATE OR REPLACE VIEW distances AS
SELECT id,    
       a,
       b,
       dst
  FROM distances_usc
/
START Run_Queries_TSP 1 2 2 1
@..\bren\EndSpool