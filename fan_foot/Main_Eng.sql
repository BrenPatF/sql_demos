@..\bren\InitSpool Main_Eng
/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting SQL
                 https://github.com/BrenPatF/sql_demos

Author:          Brendan Furey, 22 June 2013
Description:     Driving script for the England dataset for the fantasy football problem: Creates
                 the view; sets bind variables; calls Run_Queries.sql

Further details: 'SQL for the Fantasy Football Knapsack Problem', June 2013
                 http://aprogrammerwrites.eu/?p=878
***************************************************************************************************/

PROMPT Point view at England tables and set England bind variables
CREATE OR REPLACE VIEW positions AS
SELECT  id,
        min_players,
        max_players
  FROM epl_positions
/
CREATE OR REPLACE VIEW players (
        id,
        club_name,
        player_name,
        position_id,
        price,
        avg_points,
        appearances
) AS
SELECT  id,
        team_name,
        first_name || ' ' || last_name,
        position,
        value,
        points,
        appearances
  FROM epl_players
 WHERE points > 0
/
VAR KEEP_NUM NUMBER
VAR MAX_PRICE NUMBER
BEGIN
  :KEEP_NUM := 40;
  :MAX_PRICE := 900;
END;
/
START Run_Queries_FFT
@..\bren\EndSpool