@..\bren\InitSpool Main_Bra
/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting SQL
                 https://github.com/BrenPatF/sql_demos

Author:          Brendan Furey, 22 June 2013
Description:     Driving script for the Brazil dataset for the fantasy football problem: Creates the
                 view; sets bind variables; calls Run_Queries.sql

Further details: 'SQL for the Fantasy Football Knapsack Problem', June 2013
                 http://aprogrammerwrites.eu/?p=878
***************************************************************************************************/

PROMPT Point view at Brazil tables and set Brazil bind variables
CREATE OR REPLACE VIEW positions AS
SELECT  id,
        min_players,
        max_players
  FROM brazil_positions
/
DROP VIEW players
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
        club_name,
        player_name,
        position,
        price,
        avg_points,
        appearances
  FROM brazil_players
 WHERE avg_points > 0
/
VAR KEEP_NUM NUMBER
VAR MAX_PRICE NUMBER
BEGIN
  :KEEP_NUM := 40;
  :MAX_PRICE := 20000;
END;
/
START Run_Queries_FFT
@..\bren\EndSpool