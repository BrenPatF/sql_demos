@..\bren\InitSpool Main_AJ_Dir
/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting SQL
                 https://github.com/BrenPatF/sql_demos

Author:          Brendan Furey, 19 November 2017
Description:     Driving script for the AJ dataset (directed version): Creates the view; calls 
                 Run_Queries_AJ.sql (script implementing ideas in first post below)

Further details: 'SQL for Shortest Path Problems', April 2015
                 http://aprogrammerwrites.eu/?p=1391

                 'SQL for Shortest Path Problems 2: A Branch and Bound Approach', May 2015
                 http://aprogrammerwrites.eu/?p=1415
***************************************************************************************************/

PROMPT Point view at Directed table
CREATE OR REPLACE VIEW arcs_v AS
SELECT  src,
        dst,
        distance
  FROM arcs_aj_dir
/
@Run_Queries_AJ
@..\bren\EndSpool