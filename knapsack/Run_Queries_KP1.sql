/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting SQL
                 https://github.com/BrenPatF/sql_demos

Author:          Brendan Furey, 1 January 2013
Description:     Called by the driving scripts to run the SQLs for the single knapsack problem;
                 log the execution plans; print the logging results

Further details: 'A Simple SQL Solution for the Knapsack Problem (SKP-1)', January 2013
                 http://aprogrammerwrites.eu/?p=560
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
PROMPT Tree
WITH /* XTREE */ rsf (nxt_id, lev, tot_weight, tot_profit, path) AS (
SELECT id nxt_id, 0 lev, item_weight tot_weight, item_profit tot_profit, To_Char (id) path
  FROM items
 UNION ALL
SELECT n.id, 
       r.lev + 1, 
       r.tot_weight + n.item_weight,
       r.tot_profit + n.item_profit,
       r.path || ',' || To_Char (n.id)
  FROM rsf r
  JOIN items n
    ON n.id > r.nxt_id
   AND r.tot_weight + n.item_weight <= 9
) SEARCH DEPTH FIRST BY nxt_id SET line_no
SELECT  /*+ gather_plan_statistics */
       LPad (To_Char(nxt_id), lev + 1, '*') node,tot_weight, tot_profit, 
       CASE WHEN lev >= Lead (lev, 1, lev) OVER (ORDER BY line_no) THEN 'Y' END is_leaf,
       path
  FROM rsf
 ORDER BY line_no
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'XTREE');

PROMPT Best combinations - RSF with RANK
WITH /* XRNK */ rsf (nxt_id, lev, tot_weight, tot_profit, path) AS (
SELECT id, 0, item_weight, item_profit, To_Char (id)
  FROM items
 UNION ALL
SELECT n.id, 
       r.lev + 1, 
       r.tot_weight + n.item_weight,
       r.tot_profit + n.item_profit,
       r.path || ',' || To_Char (n.id)
  FROM rsf r
  JOIN items n
    ON n.id > r.nxt_id
   AND r.tot_weight + n.item_weight <= 9
) SEARCH DEPTH FIRST BY nxt_id SET line_no
, leaves_marked AS (
SELECT  tot_weight, tot_profit, path, lev,
        CASE WHEN lev >= Lead (lev) OVER (ORDER BY line_no) THEN 'Y' END is_leaf,
        Count(*) OVER () n_recs_tot
  FROM rsf
), all_leaves AS (
SELECT tot_weight, tot_profit, path, 
        Dense_Rank () OVER (ORDER BY tot_profit DESC) rnk_profit,
        lev,
        n_recs_tot,
        Count(CASE WHEN is_leaf = 'Y' THEN 1 END) OVER () n_recs_leaf
  FROM leaves_marked
 WHERE is_leaf = 'Y'
)
SELECT  /*+ gather_plan_statistics */
       tot_weight, tot_profit, path, lev + 1 n_items,
       n_recs_tot,
       n_recs_leaf
  FROM all_leaves
 WHERE rnk_profit = 1
 ORDER BY tot_profit DESC
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'XRNK');

PROMPT Best combinations - RSF with KEEP
WITH /* XKEE */  rsf (nxt_id, lev, tot_weight, tot_profit, path) AS (
SELECT id, 0, item_weight, item_profit, To_Char (id)
  FROM items
 UNION ALL
SELECT n.id, 
       r.lev + 1, 
       r.tot_weight + n.item_weight,
       r.tot_profit + n.item_profit,
       r.path || ',' || To_Char (n.id)
  FROM rsf r
  JOIN items n
    ON n.id > r.nxt_id
   AND r.tot_weight + n.item_weight <= 9
) SEARCH DEPTH FIRST BY nxt_id SET line_no
, leaves_marked AS (
SELECT  tot_weight, tot_profit, path, lev,
        CASE WHEN lev >= Lead (lev) OVER (ORDER BY line_no) THEN 'Y' END is_leaf
  FROM rsf
)
SELECT /*+ gather_plan_statistics */
       Max (tot_weight) KEEP (DENSE_RANK LAST ORDER BY tot_profit) tot_weight,
       Max (tot_profit) KEEP (DENSE_RANK LAST ORDER BY tot_profit) tot_profit,
       Max (lev) KEEP (DENSE_RANK LAST ORDER BY tot_profit) + 1 n_items,
       Max (path) KEEP (DENSE_RANK LAST ORDER BY tot_profit) path
  FROM leaves_marked
 WHERE is_leaf = 'Y'
 ORDER BY 1 DESC
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'XKEE');

PROMPT PL/SQL Recursion
DECLARE

  TYPE item_type IS RECORD (
                        item_id                 PLS_INTEGER,
                        item_index_parent       PLS_INTEGER,
                        weight_to_node          PLS_INTEGER);
  TYPE item_tree_type IS        TABLE OF item_type;
  TYPE leaf_hash_type IS        TABLE OF SYS.ODCINumberList INDEX BY PLS_INTEGER; -- NUMBER unsupported

  g_leaf_hash                   leaf_hash_type;

  c_weight_limit    CONSTANT    PLS_INTEGER := 9;
  i                             PLS_INTEGER := 0;
  j                             PLS_INTEGER := 0;
  g_item_tree                   item_tree_type;
  g_item                        item_type;
  l_weight                      PLS_INTEGER;
  l_profit                      PLS_INTEGER;
  l_sol                         VARCHAR2(4000);
  l_sol_cnt                     PLS_INTEGER := 0;
  g_timer                       PLS_INTEGER := Timer_Set.Construct ('Anon Recursion');

  FUNCTION Add_Node (  p_item_id               PLS_INTEGER,
                       p_item_index_parent     PLS_INTEGER, 
                       p_weight_to_node        PLS_INTEGER) RETURN PLS_INTEGER IS
  BEGIN

    g_item.item_id := p_item_id;
    g_item.item_index_parent := p_item_index_parent;
    g_item.weight_to_node := p_weight_to_node;
    IF g_item_tree IS NULL THEN

      g_item_tree := item_tree_type (g_item);

    ELSE

      g_item_tree.Extend;
      g_item_tree (g_item_tree.COUNT) := g_item;

    END IF;
    RETURN g_item_tree.COUNT;

  END Add_Node;

  PROCEDURE Do_One_Level (p_tree_index PLS_INTEGER, p_item_id PLS_INTEGER, p_tot_weight PLS_INTEGER, p_tot_profit PLS_INTEGER) IS

    CURSOR c_nxt IS
    SELECT id, item_weight, item_profit
      FROM items
     WHERE id > p_item_id
       AND item_weight + p_tot_weight <= c_weight_limit;
    l_is_leaf           BOOLEAN := TRUE;
    l_index_list        SYS.ODCINumberList;

  BEGIN

    FOR r_nxt IN c_nxt LOOP
      Timer_Set.Increment_Time (g_timer,  'Do_One_Level/r_nxt');

      l_is_leaf := FALSE;
      Do_One_Level (Add_Node (r_nxt.id, p_tree_index, r_nxt.item_weight + p_tot_weight), r_nxt.id, p_tot_weight + r_nxt.item_weight, p_tot_profit + r_nxt.item_profit);
      Timer_Set.Increment_Time (g_timer,  'Do_One_Level/Do_One_Level');

    END LOOP;

    IF l_is_leaf THEN

      IF g_leaf_hash.EXISTS (p_tot_profit) THEN

        l_index_list := g_leaf_hash (p_tot_profit);
        l_index_list.Extend;
        l_index_list (l_index_list.COUNT) := p_tree_index;
        g_leaf_hash (p_tot_profit) := l_index_list;

      ELSE

        g_leaf_hash (p_tot_profit) := SYS.ODCINumberList (p_tree_index);

      END IF;

    END IF;
    Timer_Set.Increment_Time (g_timer,  'Do_One_Level/leaves');

  END Do_One_Level;

BEGIN

  FOR r_itm IN (SELECT id, item_weight, item_profit FROM items) LOOP

    Timer_Set.Increment_Time (g_timer,  'Root fetches');
    Do_One_Level (Add_Node (r_itm.id, 0, r_itm.item_weight), r_itm.id, r_itm.item_weight, r_itm.item_profit);

  END LOOP;

  DBMS_Output.Put_Line (l_profit);
  l_profit := g_leaf_hash.LAST;

  FOR i IN 1..g_leaf_hash (l_profit).COUNT LOOP

    j := g_leaf_hash (l_profit)(i);
    l_sol := NULL;
    l_weight := g_item_tree (j).weight_to_node;
    WHILE j != 0 LOOP

      l_sol := l_sol || g_item_tree (j).item_id || ', ';
      j :=  g_item_tree (j).item_index_parent;

    END LOOP;
    l_sol_cnt := l_sol_cnt + 1;
    DBMS_Output.Put_Line ('Solution ' || l_sol_cnt || ' (profit ' || l_profit || ', weight ' || l_weight || ') : ' || RTrim (l_sol, ', '));

  END LOOP;

  Timer_Set.Increment_Time (g_timer,  'Write output');
  DBMS_Output.Put_Line ('Profit ' || l_profit || ' has ' || l_sol_cnt || ' solutions...');
  Timer_Set.Write_Times (g_timer);

END;
/
PROMPT Pipelined Function using nested table with linked varray (as in blog article)
COLUMN COLUMN_VALUE FORMAT A100
SELECT *
  FROM TABLE (Packing_PLF.Best_Fits (9))
/
PROMPT Pipelined Function using associative array
COLUMN COLUMN_VALUE FORMAT A100
SELECT *
  FROM TABLE (Packing_Hash_PLF.Best_Fits (9))
/
@..\bren\L_Log_Default
