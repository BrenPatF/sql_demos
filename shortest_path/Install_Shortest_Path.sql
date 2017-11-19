@..\bren\InitSpool Install_Shortest_Path
/***************************************************************************************************
GitHub Project: sql_demos - Brendan's repo for interesting SQL
                https://github.com/BrenPatF/sql_demos

Author:         Brendan Furey, 19 November 2017
Description:    Installation script for shortest_path schema for the project. Schema shortest_path 
                is for the SQL problem described in the articles below. It creates and populates the
                tables used by the different example problems; gathers schema statistics.

Further details: 'SQL for Shortest Path Problems'
                 http://aprogrammerwrites.eu/?p=1391

                 'SQL for Shortest Path Problems 2: A Branch and Bound Approach'
                 http://aprogrammerwrites.eu/?p=1415

***************************************************************************************************/

@Setup_AJ
@Setup_Brightkite
@Setup_CA_GRQC

PROMPT Create GTT approx_min_levs
DROP TABLE approx_min_levs
/
CREATE GLOBAL TEMPORARY TABLE approx_min_levs (
    node    NUMBER NOT NULL,
    lev     NUMBER NOT NULL
) ON COMMIT DELETE ROWS
/
CREATE UNIQUE INDEX approx_min_levs_u1 ON approx_min_levs (node)
/
EXECUTE DBMS_Stats.Gather_Schema_Stats(ownname => 'SHORTEST_PATH');
@..\bren\EndSpool
