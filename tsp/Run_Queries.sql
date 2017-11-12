/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting problems and solutions in SQL
                 https://github.com/BrenPatF/sql_demos

Author:          Brendan Furey, 12 November 2017
Description:     Called by the driving scripts to run the SQL; log the execution plans; print 
                 the logging results

Further details: 'SQL for the Travelling Salesman Problem'
                 http://aprogrammerwrites.eu/?p=896

***************************************************************************************************/
BEGIN
  Utils.Clear_Log;
  Utils.g_debug_level := 0;
END;
/
VAR ROOT NUMBER
VAR KEEP_NUM_ROOT NUMBER
VAR KEEP_NUM NUMBER
VAR SIGN NUMBER
BEGIN
  :ROOT := &1;
  :KEEP_NUM_ROOT := &2;
  :KEEP_NUM := &3;
  :SIGN := &4;
END;
/
PROMPT Running for sign, root, keep root, keep values of...
PRINT :SIGN
PRINT :ROOT
PRINT :KEEP_NUM_ROOT
PRINT :KEEP_NUM
COLUMN root_leg FORMAT A12
BREAK ON root_leg ON path_rnk ON tot_dist
SET TIMING ON

PROMPT Top ten solutions for recursive query
WITH count_towns AS ( /* TSP_QRY */
SELECT Count(*) n_towns FROM towns
), dist_from_root AS (
SELECT a, b, dst, Row_Number () OVER (ORDER BY :SIGN * dst) rnk_by_dst, Count(*) OVER () + 1 n_towns
  FROM distances
 WHERE a = :ROOT
),  rsf (root_leg, path_rnk, nxt_id, lev, tot_price, path, n_towns) AS (
SELECT a || ' -> ' || b, 0, d.b, 1, d.dst, 
       CAST ('|' || LPad (:ROOT, 3, '0') || '|' || LPad (d.b, 3, '0') AS VARCHAR2(4000)) path,
       d.n_towns
  FROM dist_from_root d
 WHERE d.rnk_by_dst <= :KEEP_NUM_ROOT
 UNION ALL
SELECT r.root_leg,
       Row_Number() OVER (PARTITION BY r.root_leg ORDER BY :SIGN * (r.tot_price + d.dst)),
       d.b,
       r.lev + 1,
       r.tot_price + d.dst,
       r.path || '|' || LPad (d.b, 3, '0'),
       r.n_towns
  FROM rsf r
  JOIN distances d
    ON d.a = r.nxt_id
   AND r.path NOT LIKE '%' || '|' || LPad (d.b, 3, '0') || '%'
 WHERE r.path_rnk <= :KEEP_NUM
), top_n_paths AS (
SELECT root_leg,
       tot_price,
       path,
       path_rnk,
       town_index
  FROM rsf
  CROSS JOIN (SELECT LEVEL town_index FROM count_towns c CONNECT BY LEVEL <= c.n_towns)
 WHERE lev = n_towns - 1
   AND path_rnk <= :KEEP_NUM
), top_n_teams AS (
SELECT root_leg,
       tot_price,
       path,
       path_rnk,
       town_index,
       To_Number (Substr (path, (town_index - 1) * 4 + 2, 3)) town_id,
       Lag (To_Number (Substr (path, (town_index - 1) * 4 + 2, 3))) OVER (PARTITION BY root_leg, path_rnk ORDER BY town_index) town_id_prior
  FROM top_n_paths
)
SELECT /*+ gather_plan_statistics */
       top.root_leg,
       top.path_rnk,
       Round (top.tot_price, 2) tot_dist,
       top.town_id,
       twn.name,
       Round (dst.dst, 2) leg_dist,
       Round (Sum (dst.dst) OVER (PARTITION BY root_leg, path_rnk ORDER BY town_index), 2) cum_dist
  FROM top_n_teams top
  JOIN towns twn
    ON twn.id = top.town_id
  LEFT JOIN distances dst
    ON dst.a = top.town_id_prior
   AND dst.b = top.town_id
ORDER BY top.root_leg,
       top.path_rnk, top.town_index
/
SET TIMING OFF
EXECUTE Utils.Write_Plan (p_sql_marker => 'TSP_QRY');
@..\bren\L_Log_Default
