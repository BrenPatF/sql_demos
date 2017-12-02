CREATE OR REPLACE PACKAGE BODY Packing_Hash_PLF IS
/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting SQL
                 https://github.com/BrenPatF/sql_demos

Author:          Brendan Furey, 1 January 2013
Description:     Brendan's pipelined function solution for the knapsack problem with one container.
                 Note that it reads the items from a view, and takes limit as parameter. This 
                 version uses an associative array for the solutions, which can facilitate ordering
                 in PL/SQL

Further details: 'A Simple SQL Solution for the Knapsack Problem (SKP-1)', January 2013
                 http://aprogrammerwrites.eu/?p=560
***************************************************************************************************/

/***************************************************************************************************

Best_Fits: Entry point function returning solutions found as strings, format: 
            'Solution 1 (profit P, weight w) : item_1, item_2' etc.

***************************************************************************************************/
FUNCTION Best_Fits (p_weight_limit  NUMBER)               -- weight limit
                    RETURN          SYS.ODCIVarchar2List  -- list of solutions
                    PIPELINED IS

  TYPE item_type IS RECORD (
                        item_id                 PLS_INTEGER,
                        item_index_parent       PLS_INTEGER,
                        weight_to_node          NUMBER);
  TYPE item_tree_type IS        TABLE OF item_type;
  TYPE leaf_hash_type IS        TABLE OF SYS.ODCINumberList INDEX BY PLS_INTEGER; -- NUMBER unsupported

  g_leaf_hash                   leaf_hash_type;
  g_timer                       PLS_INTEGER := Timer_Set.Construct ('Pipelined Recursion');

  i                             PLS_INTEGER := 0;
  j                             PLS_INTEGER := 0;
  g_item_tree                   item_tree_type;
  g_item                        item_type;
  l_weight                      PLS_INTEGER;
  l_weight_new                  PLS_INTEGER;
  l_hash_key                    VARCHAR2(12);
  l_profit                      PLS_INTEGER;
  l_sol                         VARCHAR2(4000);
  l_sol_cnt                     PLS_INTEGER := 0;

  /***************************************************************************************************

  Add_Node: Called by Do_One_Level to add a node to the item tree, returning tree size

  ***************************************************************************************************/
  FUNCTION Add_Node (  p_item_id               PLS_INTEGER,   -- item id
                       p_item_index_parent     PLS_INTEGER,   -- parent item index
                       p_weight_to_node        NUMBER)        -- weight to node
                       RETURN                  PLS_INTEGER IS -- tree size
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

  /***************************************************************************************************

  Do_One_Level: Called by main block to do one level of recursion, using cursor over items with id
                > than that of input item

  ***************************************************************************************************/
  PROCEDURE Do_One_Level (p_tree_index  PLS_INTEGER,    -- tree index
                          p_item_id     PLS_INTEGER,    -- item id
                          p_tot_weight  PLS_INTEGER,    -- total weight
                          p_tot_profit  PLS_INTEGER) IS -- total profit

    CURSOR c_nxt IS
    SELECT id, item_weight, item_profit
      FROM items
     WHERE id > p_item_id
       AND item_weight + p_tot_weight <= p_weight_limit;
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
    l_weight := g_item_tree (j).weight_to_node;
    l_sol := NULL;
    WHILE j != 0 LOOP

      l_sol := l_sol || g_item_tree (j).item_id || ', ';
      j :=  g_item_tree (j).item_index_parent;

    END LOOP;
    l_sol_cnt := l_sol_cnt + 1;
    PIPE ROW ('Solution ' || l_sol_cnt || ' (profit ' || l_profit || ', weight ' || l_weight || ') : ' || RTrim (l_sol, ', '));

  END LOOP;

  Timer_Set.Increment_Time (g_timer,  'Write output');
  Timer_Set.Write_Times (g_timer);

END Best_Fits;

END Packing_Hash_PLF;
/