@..\bren\InitSpool Main_Big_BNP
/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting SQL
                 https://github.com/BrenPatF/sql_demos

Author:          Brendan Furey, 17 November 2017
Description:     Driving script for the Balanced Number Partitioning Problem with the larger data 
                 set: Sets bind variables; calls Run_Queries_Agg_BNP.sql (aggregate queries)

Further details: 'SQL for the Balanced Number Partitioning Problem', May 2013
                 http://aprogrammerwrites.eu/?p=803
***************************************************************************************************/

@Pop_Data_BNP 10000
@Run_Queries_Agg_BNP 3
@..\bren\EndSpool