/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting SQL
                 https://github.com/BrenPatF/sql_demos

Author:         Brendan Furey, 4 May 2015
Description:    Called by the driving scripts to run the SQL queries for the shortest_path schema.
                This script implements ideas in the first post below, for the datasets mentioned
                there.

Further details: 'SQL for Shortest Path Problems'
                 http://aprogrammerwrites.eu/?p=1391

                 'SQL for Shortest Path Problems 2: A Branch and Bound Approach'
                 http://aprogrammerwrites.eu/?p=1415
***************************************************************************************************/

BEGIN
  Utils.Clear_Log;
  Utils.g_debug_level := 0;
END;
/
COLUMN path FORMAT A30
COLUMN node FORMAT A22
COLUMN p_id FORMAT A4
BREAK ON tot_profit ON tot_price ON rnk ON position_id
SET TIMING ON
VAR SRC VARCHAR2(10)
EXEC :SRC := 'A'

PROMPT Solution from A to other nodes
WITH paths (node, path, cost, rnk, lev) AS (
SELECT a.dst, a.src || ',' || a.dst, a.distance, 1, 1
  FROM arcs_v a
WHERE a.src = :SRC
 UNION ALL
SELECT a.dst, 
        p.path || ',' || a.dst, 
        p.cost + a.distance, 
        Rank () OVER (PARTITION BY a.dst ORDER BY p.cost + a.distance),
        p.lev + 1
  FROM paths p
  JOIN arcs_v a
    ON a.src = p.node
   AND p.rnk = 1
)  SEARCH DEPTH FIRST BY node SET line_no
CYCLE node SET lp TO '*' DEFAULT ' '
, paths_ranked AS (
SELECT lev, node, path, cost, Rank () OVER (PARTITION BY node ORDER BY cost) rnk_t, lp, line_no
  FROM paths
  WHERE rnk = 1
)
SELECT /*+ gather_plan_statistics AJA */ LPad (node, 1 + 2* (lev - 1), '.') node, lev, path, cost, lp
  FROM paths_ranked
  WHERE rnk_t = 1
  ORDER BY line_no
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'AJA');
PROMPT Solution - all intermediate, depth first
WITH paths (node, path, cost, rnk, lev) AS (
SELECT a.dst, a.src || ',' || a.dst, a.distance, 1, 1
  FROM arcs_v a
WHERE a.src = :SRC
 UNION ALL
SELECT a.dst, 
        p.path || ',' || a.dst, 
        p.cost + a.distance, 
        Rank () OVER (PARTITION BY a.dst ORDER BY p.cost + a.distance),
        p.lev + 1
  FROM paths p
  JOIN arcs_v a
    ON a.src = p.node
   AND p.rnk = 1
)  SEARCH DEPTH FIRST BY node SET line_no
CYCLE node SET lp TO '*' DEFAULT ' '
, paths_ranked AS (
SELECT lev, node, path, cost, Rank () OVER (PARTITION BY node ORDER BY cost) rnk_t, rnk, lp, line_no
  FROM paths
)
SELECT LPad (node, 1 + 2* (lev - 1), '.') node, lev, path, cost, rnk_t, rnk, lp
  FROM paths_ranked
  ORDER BY line_no
/
PROMPT Solution -  all intermediate, breadth first
WITH paths (node, path, cost, rnk, lev) AS (
SELECT a.dst, a.src || ',' || a.dst, a.distance, 1, 1
  FROM arcs_v a
WHERE a.src = :SRC
 UNION ALL
SELECT a.dst, 
        p.path || ',' || a.dst, 
        p.cost + a.distance, 
        Rank () OVER (PARTITION BY a.dst ORDER BY p.cost + a.distance),
        p.lev + 1
  FROM paths p
  JOIN arcs_v a
    ON a.src = p.node
   AND p.rnk = 1
)  SEARCH BREADTH FIRST BY node SET line_no
CYCLE node SET lp TO '*' DEFAULT ' '
, paths_ranked AS (
SELECT lev, node, path, cost, Rank () OVER (PARTITION BY node ORDER BY cost) rnk_t, rnk, lp, line_no
  FROM paths
)
SELECT LPad (node, 1 + 2* (lev - 1), '.') node, lev, path, cost, rnk_t, rnk, lp
  FROM paths_ranked
  ORDER BY line_no
/
PROMPT All solutions
WITH paths (node, path, cost, rnk, lev) AS (
SELECT a.dst, a.src || ',' || a.dst, a.distance, 1, 1
  FROM arcs_v a
WHERE a.src = :SRC
 UNION ALL
SELECT a.dst, 
        p.path || ',' || a.dst, 
        p.cost + a.distance, 
        Rank () OVER (PARTITION BY a.dst ORDER BY p.cost + a.distance),
        p.lev + 1
  FROM paths p
  JOIN arcs_v a
    ON a.src = p.node
)  SEARCH DEPTH FIRST BY node SET line_no
CYCLE node SET lp TO '*' DEFAULT ' '
, paths_ranked AS (
SELECT lev, node, path, cost, Rank () OVER (PARTITION BY node ORDER BY cost) rnk_t, rnk, lp, line_no
  FROM paths
)
SELECT LPad (node, 1 + 2* (lev - 1), '.') node, lev, path, cost, rnk_t, rnk, lp
  FROM paths_ranked
  ORDER BY line_no
/
EXEC :SRC := 'J'

PROMPT Solution from J to other nodes
WITH paths (node, path, cost, rnk, lev) AS (
SELECT a.dst, a.src || ',' || a.dst, a.distance, 1, 1
  FROM arcs_v a
WHERE a.src = :SRC
 UNION ALL
SELECT a.dst, 
        p.path || ',' || a.dst, 
        p.cost + a.distance, 
        Rank () OVER (PARTITION BY a.dst ORDER BY p.cost + a.distance),
        p.lev + 1
  FROM paths p
  JOIN arcs_v a
    ON a.src = p.node
   AND p.rnk = 1
)  SEARCH DEPTH FIRST BY node SET line_no
CYCLE node SET lp TO '*' DEFAULT ' '
, paths_ranked AS (
SELECT lev, node, path, cost, Rank () OVER (PARTITION BY node ORDER BY cost) rnk_t, lp, line_no
  FROM paths
  WHERE rnk = 1
)
SELECT LPad (node, 1 + 2* (lev - 1), '.') node, lev, path, cost, lp
  FROM paths_ranked
  WHERE rnk_t = 1
  ORDER BY line_no
/
SET TIMING OFF
@..\bren\L_Log_Default
