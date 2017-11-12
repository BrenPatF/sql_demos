@..\bren\InitSpool Install_TSP
/***************************************************************************************************
GitHub Project: sql_demos - Brendan's repo for interesting problems and solutions in SQL
                https://github.com/BrenPatF/sql_demos

Author:         Brendan Furey, 12 November 2017
Description:    Installation script for TSP schema for the project. Schema TSP is for the
                SQL problem described in the article below. It creates and populates the tables used
                by the two different example problems; gathers schema statistics

Further details: 'SQL for the Travelling Salesman Problem'
                 http://aprogrammerwrites.eu/?p=896

***************************************************************************************************/
@Setup_EML
@Setup_USC
EXECUTE DBMS_Stats.Gather_Schema_Stats(ownname => 'TSP');
@..\bren\EndSpool
