@..\bren\InitSpool Main_Sml_BNP
/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting SQL
                 https://github.com/BrenPatF/sql_demos

Author:          Brendan Furey, 12 November 2017
Description:     Driving script for the Balanced Number Partitioning Problem with the smaller data 
                 set: Sets bind variables; calls Run_Queries_BNP.sql (detail queries)

Further details: 'SQL for the Balanced Number Partitioning Problem', May 2013
                 http://aprogrammerwrites.eu/?p=803
***************************************************************************************************/

@Pop_Data_BNP 100
@Run_Queries_BNP 3
@..\bren\EndSpool