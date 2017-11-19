/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting SQL
                 https://github.com/BrenPatF/sql_demos

Author:         Brendan Furey, 19 November 2017
Description:    Called by the driving scripts to run the SQL queries for the shortest_path schema.
                This script implements ideas in the second post below, for the datasets mentioned
                there. It takes two parameters, for the starting node and the maximum level

Further details: 'SQL for Shortest Path Problems'
                 http://aprogrammerwrites.eu/?p=1391

                 'SQL for Shortest Path Problems 2: A Branch and Bound Approach'
                 http://aprogrammerwrites.eu/?p=1415

***************************************************************************************************/
DEFINE SRC=&1
DEFINE LEVMAX=&2
BEGIN
  Utils.Clear_Log;
  Utils.g_debug_level := 0;
END;
/
COLUMN path     FORMAT A80
COLUMN node     FORMAT A30
COLUMN lp       FORMAT A2
COLUMN lev      FORMAT 990
COLUMN maxlev   FORMAT 999990
COLUMN intnod   FORMAT 999990
COLUMN intmax   FORMAT 999990
SET TIMING ON

PROMPT BPF Approximate Solution - SP_RSFONE
WITH paths (node, path, lev, rn) AS (
SELECT a.dst, To_Char(a.dst), 1, 1
  FROM arcs_v a
WHERE a.src = &SRC
 UNION ALL
SELECT  a.dst,
        p.path || ',' || a.dst,
        p.lev + 1,
        Row_Number () OVER (PARTITION BY a.dst ORDER BY a.dst)
  FROM paths p
  JOIN arcs_v a
    ON a.src = p.node
 WHERE p.rn = 1
   AND p.lev < &LEVMAX
)  SEARCH DEPTH FIRST BY node SET line_no
CYCLE node SET lp TO '*' DEFAULT ' '
SELECT /*+ GATHER_PLAN_STATISTICS SP_RSFONE */
       Substr (LPad ('.', 1 + 2 * (Max (lev) KEEP (DENSE_RANK FIRST ORDER BY lev) - 1), '.') || node, 2) node,
       Max (lev) KEEP (DENSE_RANK FIRST ORDER BY lev) lev,
       Max (Max (lev) KEEP (DENSE_RANK FIRST ORDER BY lev)) OVER () maxlev,
       Max (lev) intnod,
       Max (Max (lev)) OVER () intmax,
       Max (path) KEEP (DENSE_RANK FIRST ORDER BY lev) path,
       Max (lp) KEEP (DENSE_RANK FIRST ORDER BY lev) lp
  FROM paths
 GROUP BY node
 ORDER BY Max (line_no) KEEP (DENSE_RANK FIRST ORDER BY lev)
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'SP_RSFONE');

PROMPT BPF Exact solution - SP_RSFTWO
WITH paths_0 (node, path, lev, rn) /* SP_RSFTWO */ AS (
SELECT a.dst, To_Char(a.dst), 1, 1
  FROM arcs_v a
 WHERE a.src = &SRC
 UNION ALL
SELECT a.dst,
       p.path || ',' || a.dst,
       p.lev + 1,
       Row_Number () OVER (PARTITION BY a.dst ORDER BY a.dst)
  FROM paths_0 p
  JOIN arcs_v a
    ON a.src = p.node
 WHERE p.rn = 1
   AND p.lev < &LEVMAX
) CYCLE node SET lp TO '*' DEFAULT ' '
, approx_best_paths AS (
SELECT node,
       Max (lev) KEEP (DENSE_RANK FIRST ORDER BY lev) lev
  FROM paths_0
 GROUP BY node
), paths (node, path, lev, rn) AS (
SELECT a.dst, To_Char(a.dst), 1, 1
  FROM arcs_v a
WHERE a.src = &SRC
 UNION ALL
SELECT a.dst,
        p.path || ',' || a.dst,
        p.lev + 1,
        Row_Number () OVER (PARTITION BY a.dst ORDER BY a.dst)
  FROM paths p
  JOIN arcs_v a
    ON a.src = p.node
  LEFT JOIN approx_best_paths b
    ON b.node = a.dst
 WHERE p.rn = 1
   AND p.lev < Nvl (b.lev, 1000000)
)  SEARCH DEPTH FIRST BY node SET line_no CYCLE node SET lp TO '*' DEFAULT ' '
SELECT /*+ GATHER_PLAN_STATISTICS */
       Substr (LPad ('.', 1 + 2 * (Max (lev) KEEP (DENSE_RANK FIRST ORDER BY lev) - 1), '.') || node, 2) node,
       Max (lev) KEEP (DENSE_RANK FIRST ORDER BY lev) lev,
       Max (Max (lev) KEEP (DENSE_RANK FIRST ORDER BY lev)) OVER () maxlev,
       Max (lev) intnod,
       Max (Max (lev)) OVER () intmax,
       Max (path) KEEP (DENSE_RANK FIRST ORDER BY lev) path,
       Max (lp) KEEP (DENSE_RANK FIRST ORDER BY lev) lp
  FROM paths
 GROUP BY node
 ORDER BY Max (line_no) KEEP (DENSE_RANK FIRST ORDER BY lev)
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'SP_RSFTWO');

PROMPT BPF Exact Solution - SP_GTTRSF_I - Insert approximate to GTT
INSERT INTO approx_min_levs
WITH paths_0 (node, path, lev, rn) /* SP_GTTRSF_I */ AS (
SELECT a.dst, To_Char(a.dst), 1, 1
  FROM arcs_v a
WHERE a.src = &SRC
 UNION ALL
SELECT  a.dst,
        p.path || ',' || a.dst,
        p.lev + 1,
        Row_Number () OVER (PARTITION BY a.dst ORDER BY a.dst)
  FROM paths_0 p
  JOIN arcs_v a
    ON a.src = p.node
 WHERE p.rn = 1
   AND p.lev < &LEVMAX
) CYCLE node SET lp TO '*' DEFAULT ' '
SELECT  /*+ GATHER_PLAN_STATISTICS */
       node,
       Max (lev) KEEP (DENSE_RANK FIRST ORDER BY lev) lev
  FROM paths_0
 GROUP BY node
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'SP_GTTRSF_I');

PROMPT BPF Exact solution - SP_GTTRSF_Q - Query
WITH paths (node, path, lev, rn) AS /* SP_GTTRSF_Q */ (
SELECT a.dst, To_Char(a.dst), 1, 1
  FROM arcs_v a
WHERE a.src = &SRC
 UNION ALL
SELECT a.dst,
        p.path || ',' || a.dst,
        p.lev + 1,
        Row_Number () OVER (PARTITION BY a.dst ORDER BY a.dst)
  FROM paths p
  JOIN arcs_v a
    ON a.src = p.node
  LEFT JOIN approx_min_levs b
    ON b.node = a.dst
 WHERE p.rn = 1
   AND p.lev < Nvl (b.lev, 1000000)
)  SEARCH DEPTH FIRST BY node SET line_no CYCLE node SET lp TO '*' DEFAULT ' '
SELECT /*+ GATHER_PLAN_STATISTICS */
       Substr (LPad ('.', 1 + 2 * (Max (lev) KEEP (DENSE_RANK FIRST ORDER BY lev) - 1), '.') || node, 2) node,
       Max (lev) KEEP (DENSE_RANK FIRST ORDER BY lev) lev,
       Max (Max (lev) KEEP (DENSE_RANK FIRST ORDER BY lev)) OVER () maxlev,
       Max (lev) intnod,
       Max (Max (lev)) OVER () intmax,
       Max (path) KEEP (DENSE_RANK FIRST ORDER BY lev) path,
       Max (lp) KEEP (DENSE_RANK FIRST ORDER BY lev) lp
  FROM paths
 GROUP BY node
 ORDER BY Max (line_no) KEEP (DENSE_RANK FIRST ORDER BY lev)
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'SP_GTTRSF_Q');

SET TIMING OFF
@..\bren\L_Log_Default
