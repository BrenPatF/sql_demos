/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting SQL
                 https://github.com/BrenPatF/sql_demos

Author:          Brendan Furey, 22 June 2013
Description:     Called by the driving scripts to run the two SQLs (direct and pipelined function);
                 log the execution plans; print the logging results

Further details: 'SQL for the Fantasy Football Knapsack Problem', June 2013
                 http://aprogrammerwrites.eu/?p=878
***************************************************************************************************/

BEGIN
  Utils.Clear_Log;
  Utils.g_debug_level := 0;
END;
/
COLUMN path FORMAT A30
COLUMN node FORMAT A10
COLUMN p_id FORMAT A4
BREAK ON tot_profit ON tot_price ON rnk ON position_id
SET TIMING ON
PROMPT Top ten solutions for direct recursive query
WITH  /* FF_QRY */ position_counts AS (
SELECT Min (CASE WHEN id != 'AL' THEN id END) min_id,
       Max (CASE id WHEN 'AL' THEN min_players END) team_size
  FROM positions
), pos_runs AS (
SELECT id, Sum (CASE WHEN id != 'AL' THEN min_players END) OVER (ORDER BY id DESC) num_remain, min_players, max_players
  FROM positions
), players_ranked AS (
SELECT id,
       position_id,
       price,
       avg_points,
       appearances,
       Row_Number() OVER (ORDER BY position_id, avg_points DESC) rnk,
       Min (price) OVER () min_price
  FROM players
), rsf (path_rnk, nxt_id, lev, tot_price, tot_profit, pos_id, n_pos, team_size, min_players, pos_path, path) AS (
SELECT 0, 0, 0, 0, 0, 'AL', 0, c.team_size, 0, CAST (NULL AS VARCHAR2(400)) pos_path, CAST (NULL AS VARCHAR2(400)) path
  FROM position_counts c
 UNION ALL
SELECT Row_Number() OVER (PARTITION BY r.pos_path || p.position_id ORDER BY r.tot_profit + p.avg_points DESC),
       p.rnk,
       r.lev + 1,
       r.tot_price + p.price,
       r.tot_profit + p.avg_points,
       p.position_id,
       CASE p.position_id WHEN r.pos_id THEN r.n_pos + 1 ELSE 1 END,
       r.team_size,
       m1.min_players,
       r.pos_path || p.position_id,
       r.path || LPad (p.id, 3, '0')
  FROM rsf r
  JOIN players_ranked p
    ON p.rnk > r.nxt_id
  JOIN pos_runs m1
    ON m1.id = p.position_id
   AND CASE p.position_id WHEN r.pos_id THEN r.n_pos + 1 ELSE 1 END <= m1.max_players
   AND r.team_size - r.lev - 1 >= m1.num_remain - CASE p.position_id WHEN r.pos_id THEN r.n_pos + 1 ELSE 1 END
   AND (r.lev = 0 OR p.position_id = r.pos_id OR r.n_pos >= r.min_players)
 WHERE r.tot_price + p.price + (r.team_size - r.lev - 1) * p.min_price <= :MAX_PRICE
   AND r.path_rnk < :KEEP_NUM
   AND r.lev < r.team_size
)-- SEARCH DEPTH FIRST BY nxt_id SET line_no
, paths_ranked AS (
SELECT tot_price,
       tot_profit,
       team_size,
       Row_Number () OVER (ORDER BY tot_profit DESC, tot_price) r_profit,
       path
  FROM rsf
 WHERE lev = team_size
), top_ten_paths AS (
SELECT tot_price,
       tot_profit,
       r_profit,
       path,
       player_index
  FROM paths_ranked
  CROSS JOIN (SELECT LEVEL player_index FROM position_counts CONNECT BY LEVEL <= team_size)
 WHERE r_profit <= 10
), top_ten_teams AS (
SELECT tot_price,
       tot_profit,
       r_profit,
       path,
       player_index,
       Substr (path, (player_index - 1) * 3 + 1, 3) player_id
  FROM top_ten_paths
)
SELECT /*+ gather_plan_statistics */  t.tot_profit,
       t.tot_price,
       t.r_profit rnk,
       p.position_id,
       t.player_id p_id,
       p.player_name,
       p.club_name,
       p.price,
       p.avg_points
  FROM top_ten_teams t
  JOIN players p
    ON p.id = t.player_id
ORDER BY t.tot_profit DESC, t.tot_price, t.path, p.position_id, t.player_index
/
SET TIMING OFF
EXECUTE Utils.Write_Plan (p_sql_marker => 'FF_QRY');
COLUMN club_name FORMAT A15
COLUMN player_name FORMAT A20
COLUMN item_id FORMAT A10
BREAK ON sol_profit ON sol_price ON rnk ON position_id
SET TIMING ON
PROMPT Top ten solutions for query calling pipelined function...
SELECT  /*+ gather_plan_statistics FF_PLF */
       t.sol_profit, 
       t.sol_price,
       Dense_Rank() OVER (ORDER BY t.sol_profit DESC, t.sol_price) RNK,
       p.position_id,
       t.item_id, 
       p.player_name,
       p.club_name,
       p.price,
       p.avg_points
  FROM TABLE (Item_Cats.Best_N_Sets (
                  p_keep_size => :KEEP_NUM, 
                  p_max_calls => 10000000,
                  p_n_size => 10, 
                  p_max_price => :MAX_PRICE,
                  p_cat_cur => CURSOR (
                      SELECT id, min_players, max_players
                        FROM positions
                       ORDER BY CASE WHEN id != 'AL' THEN 0 END, id
                      ), 
                  p_item_cur => CURSOR (
                      SELECT id, price, avg_points, position_id
                        FROM players
                       ORDER BY position_id, avg_points DESC
                      )
             )) t
  JOIN players p
    ON p.id = t.item_id
  ORDER BY t.sol_profit DESC, t.sol_price, p.position_id, t.item_id
/
SET TIMING OFF
EXECUTE Utils.Write_Plan (p_sql_marker => 'FF_PLF');
@..\bren\L_Log_Default
