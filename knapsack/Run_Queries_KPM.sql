/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting SQL
                 https://github.com/BrenPatF/sql_demos

Author:          Brendan Furey, 20 January 2013
Description:     Called by the driving scripts to run the SQLs for the multiple knapsack problem; 
                 log the execution plans; print the logging results

Further details: 'An SQL Solution for the Multiple Knapsack Problem (SKP-m)', January 2013
                 http://aprogrammerwrites.eu/?p=635
***************************************************************************************************/

BEGIN
  Utils.Clear_Log;
  Utils.g_debug_level := 0;
END;
/
COLUMN itm_path FORMAT A30
COLUMN path FORMAT A30
COLUMN node FORMAT A10
COLUMN p_id FORMAT A4
COLUMN itm_id FORMAT A4
COLUMN con_itm_set FORMAT A10
COLUMN con_itm_path FORMAT A20

BREAK ON tot_profit ON tot_price ON rnk ON position_id
SET TIMING ON
PROMPT Tree
BREAK ON con_id ON max_weight
WITH /* XTRE */ rsf_itm (con_id, max_weight, itm_id, lev, tot_weight, tot_profit, path) AS (
SELECT c.id, 
       c.max_weight,
       i.id,
       0,
       i.item_weight,
       i.item_profit, 
       ',' || i.id || ','
  FROM items i
  JOIN containers c
    ON i.item_weight <= c.max_weight
 UNION ALL
SELECT r.con_id,
       r.max_weight,
       i.id, 
       r.lev + 1, 
       r.tot_weight + i.item_weight,
       r.tot_profit + i.item_profit,
       r.path || i.id || ','
  FROM rsf_itm r
  JOIN items i
    ON i.id > r.itm_id
   AND r.tot_weight + i.item_weight <= r.max_weight
 ORDER BY 1, 2
) SEARCH DEPTH FIRST BY con_id, itm_id SET line_no
SELECT  /*+ gather_plan_statistics */
       con_id,
       max_weight,
       LPad (To_Char(itm_id), 2*lev + 1, ' ') itm_id, 
       path itm_path,
       tot_weight, tot_profit
  FROM rsf_itm
 ORDER BY line_no
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'XTRE');

BREAK ON sol_id ON s_wt ON s_pr ON c_id ON c_name ON m_wt ON c_wt
PROMPT Solution with path tree
WITH /* XTR2 */ rsf_itm (con_id, max_weight, itm_id, tot_weight, tot_profit, path) AS (
SELECT c.id, 
       c.max_weight,
       i.id, 
       i.item_weight,
       i.item_profit, 
       ',' || i.id || ','
  FROM items i
  JOIN containers c
    ON i.item_weight <= c.max_weight
 UNION ALL
SELECT r.con_id,
       r.max_weight,
       i.id, 
       r.tot_weight + i.item_weight,
       r.tot_profit + i.item_profit,
       r.path || i.id || ','
  FROM rsf_itm r
  JOIN items i
    ON i.id > r.itm_id
   AND r.tot_weight + i.item_weight <= r.max_weight
)
, rsf_con (con_id, con_itm_set, con_itm_path, lev, tot_weight, tot_profit) AS (
SELECT con_id,
       ':' || con_id || ':' || path,
       ':' || con_id || ':' || path,
       0,
       tot_weight,
       tot_profit
  FROM rsf_itm
 UNION ALL
SELECT r_i.con_id,
       ':' || r_i.con_id || ':' || r_i.path,
       r_c.con_itm_path ||  ':' || r_i.con_id || ':' || r_i.path,
       r_c.lev + 1, 
       r_c.tot_weight + r_i.tot_weight,
       r_c.tot_profit + r_i.tot_profit
  FROM rsf_con r_c
  JOIN rsf_itm r_i
    ON r_i.con_id > r_c.con_id
 WHERE RegExp_Instr (r_c.con_itm_path || r_i.path, ',(\d+),.*?,\1,') = 0
) SEARCH DEPTH FIRST BY con_id SET line_no
SELECT /*+ gather_plan_statistics */
       LPad (' ', 2*lev, ' ') || con_itm_set con_itm_set,
       con_itm_path,
       tot_weight, tot_profit
  FROM rsf_con
 ORDER BY line_no
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'XTR2');

PROMPT Solution with path
WITH /* XSTR */ rsf_itm (con_id, max_weight, itm_id, tot_weight, tot_profit, path) AS (
SELECT c.id, 
       c.max_weight,
       i.id, 
       i.item_weight,
       i.item_profit, 
       ',' || i.id || ','
  FROM items i
  JOIN containers c
    ON i.item_weight <= c.max_weight
 UNION ALL
SELECT r.con_id,
       r.max_weight,
       i.id, 
       r.tot_weight + i.item_weight,
       r.tot_profit + i.item_profit,
       r.path || i.id || ','
  FROM rsf_itm r
  JOIN items i
    ON i.id > r.itm_id
   AND r.tot_weight + i.item_weight <= r.max_weight
 ORDER BY 1, 2
)
, rsf_con (con_id, itm_path, lev, tot_weight, tot_profit) AS (
SELECT con_id,
       ':' || con_id || ':' || path,
       0,
       tot_weight,
       tot_profit
  FROM rsf_itm
 UNION ALL
SELECT r_i.con_id,
       r_c.itm_path ||  ':' || r_i.con_id || ':' || r_i.path,
       r_c.lev + 1, 
       r_c.tot_weight + r_i.tot_weight,
       r_c.tot_profit + r_i.tot_profit
  FROM rsf_con r_c
  JOIN rsf_itm r_i
    ON r_i.con_id > r_c.con_id
 WHERE RegExp_Instr (r_c.itm_path || r_i.path, ',(\d+),.*?,\1,') = 0
)
, paths_ranked AS (
SELECT itm_path || ':' itm_path, tot_weight, tot_profit, Rank () OVER (ORDER BY tot_profit DESC) rn,
       Row_Number () OVER (ORDER BY tot_profit DESC, tot_weight DESC) sol_id
  FROM rsf_con
)
SELECT /*+ gather_plan_statistics */
       sol_id, itm_path, tot_weight, tot_profit
  FROM paths_ranked p
 ORDER BY sol_id
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'XSTR');

PROMPT Solution with SQL and functions
WITH /* XFUN */ rsf_itm (con_id, max_weight, itm_id, tot_weight, tot_profit, path) AS (
SELECT c.id, 
       c.max_weight,
       i.id, 
       i.item_weight,
       i.item_profit, 
       ',' || i.id || ','
  FROM items i
  JOIN containers c
    ON i.item_weight <= c.max_weight
 UNION ALL
SELECT r.con_id,
       r.max_weight,
       i.id, 
       r.tot_weight + i.item_weight,
       r.tot_profit + i.item_profit,
       r.path || i.id || ','
  FROM rsf_itm r
  JOIN items i
    ON i.id > r.itm_id
   AND r.tot_weight + i.item_weight <= r.max_weight
 ORDER BY 1, 2
)
, rsf_con (con_id, itm_path, tot_weight, tot_profit) AS (
SELECT con_id,
       ':' || con_id || ':' || path,
       tot_weight,
       tot_profit
  FROM rsf_itm
 UNION ALL
SELECT r_i.con_id,
       r_c.itm_path ||  ':' || r_i.con_id || ':' || r_i.path,
       r_c.tot_weight + r_i.tot_weight,
       r_c.tot_profit + r_i.tot_profit
  FROM rsf_con r_c
  JOIN rsf_itm r_i
    ON r_i.con_id > r_c.con_id
 WHERE RegExp_Instr (r_c.itm_path || r_i.path, ',(\d+),.*?,\1,') = 0
)
, paths_ranked AS (
SELECT itm_path || ':' itm_path, tot_weight, tot_profit, Rank () OVER (ORDER BY tot_profit DESC) rn,
       Row_Number () OVER (ORDER BY tot_profit DESC, tot_weight DESC) sol_id
  FROM rsf_con
), itm_v AS (
SELECT s.con_id, s.itm_id, p.itm_path, p.tot_weight, p.tot_profit, p.sol_id
  FROM paths_ranked p
 CROSS JOIN TABLE (Multi.Split_String (p.itm_path)) s
 WHERE rn = 1
)
SELECT /*+ gather_plan_statistics */
       v.sol_id, 
       v.tot_weight s_wt, v.tot_profit s_pr, c.id c_id, c.name c_name, c.max_weight m_wt,
       Sum (i.item_weight) OVER (PARTITION BY v.sol_id, c.id) c_wt,
       i.id i_id, i.item_weight i_wt, i.item_profit i_pr
  FROM itm_v v
  JOIN containers c
    ON c.id = To_Number (v.con_id)
  JOIN items i
    ON i.id = To_Number (v.itm_id)
 ORDER BY sol_id, con_id, itm_id
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'XFUN');

PROMPT Solution with SQL and functions, with CARDINALITY hint
WITH /* XFNC */ rsf_itm (con_id, max_weight, itm_id, tot_weight, tot_profit, path) AS (
SELECT c.id, 
       c.max_weight,
       i.id, 
       i.item_weight,
       i.item_profit, 
       ',' || i.id || ','
  FROM items i
  JOIN containers c
    ON i.item_weight <= c.max_weight
 UNION ALL
SELECT r.con_id,
       r.max_weight,
       i.id, 
       r.tot_weight + i.item_weight,
       r.tot_profit + i.item_profit,
       r.path || i.id || ','
  FROM rsf_itm r
  JOIN items i
    ON i.id > r.itm_id
   AND r.tot_weight + i.item_weight <= r.max_weight
 ORDER BY 1, 2
)
, rsf_con (con_id, itm_path, tot_weight, tot_profit) AS (
SELECT con_id,
       ':' || con_id || ':' || path,
       tot_weight,
       tot_profit
  FROM rsf_itm
 UNION ALL
SELECT r_i.con_id,
       r_c.itm_path ||  ':' || r_i.con_id || ':' || r_i.path,
       r_c.tot_weight + r_i.tot_weight,
       r_c.tot_profit + r_i.tot_profit
  FROM rsf_con r_c
  JOIN rsf_itm r_i
    ON r_i.con_id > r_c.con_id
 WHERE RegExp_Instr (r_c.itm_path || r_i.path, ',(\d+),.*?,\1,') = 0
)
, paths_ranked AS (
SELECT itm_path || ':' itm_path, tot_weight, tot_profit, Rank () OVER (ORDER BY tot_profit DESC) rn,
       Row_Number () OVER (ORDER BY tot_profit DESC, tot_weight DESC) sol_id
  FROM rsf_con
), itm_v AS (
SELECT /*+ CARDINALITY (s 40) */
       s.con_id, s.itm_id, p.itm_path, p.tot_weight, p.tot_profit, p.sol_id
  FROM paths_ranked p
 CROSS JOIN TABLE (Multi.Split_String (p.itm_path)) s
 WHERE rn = 1
)
SELECT /*+ gather_plan_statistics */
       v.sol_id, 
       v.tot_weight s_wt, v.tot_profit s_pr, c.id c_id, c.name c_name, c.max_weight m_wt,
       Sum (i.item_weight) OVER (PARTITION BY v.sol_id, c.id) c_wt,
       i.id i_id, i.item_weight i_wt, i.item_profit i_pr
  FROM itm_v v
  JOIN containers c
    ON c.id = To_Number (v.con_id)
  JOIN items i
    ON i.id = To_Number (v.itm_id)
 ORDER BY sol_id, con_id, itm_id
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'XFNC');
@..\bren\L_Log_Default
