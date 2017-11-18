CREATE OR REPLACE PACKAGE BODY Item_Cats AS
/**************************************************************************************************
GitHub Project: sql_demos - Brendan's repo for interesting SQL
                https://github.com/BrenPatF/sql_demos

Author:         Brendan Furey, 7 July 2013
Description:    Brendan's pipelined function solution for the knapsack problem with one container,
                and items having categories with validity bands, as described at
                http://aprogrammerwrites.eu/?p=878 (SQL for the Fantasy Football Knapsack Problem)

                There may be an issue related to package state not being fully reset when called 
                multiple times in a session
***************************************************************************************************/

c_cat_all           CONSTANT VARCHAR2(3) := 'AL';
c_hash_renew_point  CONSTANT PLS_INTEGER := 1000;
--
-- Bulk collect array types
--
TYPE cat_rec_type IS RECORD (
        id                      VARCHAR2(3),
        min_items               PLS_INTEGER,
        max_items               PLS_INTEGER
        );
TYPE cat_list_type IS VARRAY(100) OF cat_rec_type;

TYPE item_cat_rec_type IS RECORD (
        id                      VARCHAR2(10),
        price                   PLS_INTEGER,
        profit                  PLS_INTEGER,
        cat_id                  VARCHAR2(3)
        );
TYPE item_cat_list_type IS VARRAY(1000) OF item_cat_rec_type;

TYPE chr_hash_type IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(30);
--
-- Input data LOL types
--
TYPE num_range_rec_type IS RECORD (
        item_beg                PLS_INTEGER,
        item_end                PLS_INTEGER
        );
TYPE num_range_list_type IS VARRAY(1000) OF num_range_rec_type;
TYPE num_list_type IS VARRAY(100) OF PLS_INTEGER;
--
-- Solution types
--
TYPE id_list_type IS VARRAY(1000) OF VARCHAR2(10);
TYPE sol_rec_type IS RECORD (                       -- trial solution and record in retained array
        item_list               id_list_type,
        price                   PLS_INTEGER,
        profit                  PLS_INTEGER
        );
TYPE sol_list_type IS VARRAY(100) OF sol_rec_type;  -- retained solutions

TYPE int_hash_type IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;

g_keep_size                 PLS_INTEGER;
g_max_calls                 PLS_INTEGER;
g_n_size                    PLS_INTEGER;
g_max_price                 PLS_INTEGER;

g_cat_hash                  chr_hash_type;
g_item_range_list           num_range_list_type := num_range_list_type();
g_hash_buffer               int_hash_type;
g_profit_hash               int_hash_type;
g_trial_sol                 sol_rec_type;
g_sol_list                  sol_list_type := sol_list_type();
g_cat_list                  cat_list_type;
g_item_cat_list             item_cat_list_type;

g_n_cats                    PLS_INTEGER;
g_n_items                   PLS_INTEGER;
g_set_size                  PLS_INTEGER;
g_nth_profit                PLS_INTEGER := 0;
g_min_item_price            PLS_INTEGER := 1000000;
g_max_item_profit           PLS_INTEGER := 0;
g_min_price_togo            num_list_type := num_list_type();
g_max_profit_togo           num_list_type := num_list_type();
g_timer                     PLS_INTEGER;
g_n_recursive_calls         PLS_INTEGER := 0;
g_n_sols                    PLS_INTEGER := 0;

PROCEDURE Write_Log (p_line VARCHAR2, p_debug_level PLS_INTEGER DEFAULT 0) IS
BEGIN

  IF Utils.g_debug_level >= p_debug_level THEN
    Utils.Write_Log (p_line);
  END IF;

END Write_Log;

FUNCTION Dedup_Hash (p_card PLS_INTEGER, p_key PLS_INTEGER, p_hash int_hash_type) RETURN PLS_INTEGER IS
  l_trial_key       PLS_INTEGER := p_card * p_key;
BEGIN

  LOOP

    IF p_hash.EXISTS (l_trial_key) THEN
      l_trial_key := l_trial_key + 1;
    ELSE
      EXIT;
    END IF;

  END LOOP;
  RETURN l_trial_key;

END Dedup_Hash;

PROCEDURE Pop_Arrays (p_cat_cur SYS_REFCURSOR, p_item_cur SYS_REFCURSOR) IS
  n_cat                     PLS_INTEGER := 0;
  l_price                   PLS_INTEGER;
  l_profit                  PLS_INTEGER;

  l_last_cat                VARCHAR2(30) := '???';

  l_item_price_hash         int_hash_type;
  l_item_profit_hash        int_hash_type;

BEGIN

  FETCH p_cat_cur BULK COLLECT INTO g_cat_list;
  CLOSE p_cat_cur;
  Write_Log ('Collected ' || g_cat_list.COUNT || ' cats');

  FETCH p_item_cur BULK COLLECT INTO g_item_cat_list;
  CLOSE p_item_cur;
  Write_Log ('Collected ' || g_item_cat_list.COUNT || ' items');


  Write_Log (g_n_cats || ' cats');

  g_n_cats := g_cat_list.COUNT - 1;
  g_item_range_list.EXTEND (g_n_cats);
  FOR i IN 1..g_cat_list.COUNT LOOP

    IF g_cat_list(i).id = c_cat_all THEN
      g_set_size := g_cat_list(i).min_items;
    ELSE
      g_cat_hash (g_cat_list(i).id) := i;
    END IF;

  END LOOP;
  g_cat_list.TRIM;

  FOR i IN 1..g_item_cat_list.COUNT LOOP

    IF g_item_cat_list(i).price < g_min_item_price THEN
      g_min_item_price := g_item_cat_list(i).price;
    END IF;

    IF g_item_cat_list(i).profit > g_max_item_profit THEN
      g_max_item_profit := g_item_cat_list(i).profit;
    END IF;
    l_item_price_hash (Dedup_Hash (p_card => g_item_cat_list.COUNT, p_key => g_item_cat_list(i).price, p_hash => l_item_price_hash)) := i;
    l_item_profit_hash (Dedup_Hash (p_card => g_item_cat_list.COUNT, p_key => g_item_cat_list(i).profit, p_hash => l_item_profit_hash)) := i;

    IF g_item_cat_list(i).cat_id != l_last_cat THEN
--
-- Cat has changed, so reset the itm number to zero, and assign the list of items 
--  for previous cat
--
      n_cat := n_cat + 1;
      g_item_range_list (n_cat).item_beg := i;
      IF i > 1 THEN
        g_item_range_list (n_cat - 1).item_end := i - 1;
      END IF;
      l_last_cat := g_item_cat_list(i).cat_id;

    END IF;

  END LOOP;

  g_n_items := g_item_cat_list.COUNT;
  g_item_range_list (g_n_cats).item_end := g_n_items;
  g_min_price_togo.EXTEND (g_set_size);
  g_max_profit_togo.EXTEND (g_set_size);
  l_price := l_item_price_hash.FIRST;
  l_profit := l_item_profit_hash.LAST;
  Write_Log ('Hash first price min / profit max ' || l_price || ' / ' || l_profit);
  g_min_price_togo (g_set_size) := 0;
  g_max_profit_togo (g_set_size) := 0;

  FOR i IN 1..g_set_size - 1 LOOP

    g_min_price_togo (g_set_size - i) := g_min_price_togo (g_set_size - i + 1) + l_price / g_item_cat_list.COUNT;
    g_max_profit_togo (g_set_size - i) := g_max_profit_togo (g_set_size - i + 1) + l_profit / g_item_cat_list.COUNT;

    l_price := l_item_price_hash.NEXT (l_price);
    l_profit := l_item_profit_hash.PRIOR (l_profit);
    Write_Log ((g_set_size - i) || ': price min / profit max ' || g_min_price_togo (g_set_size - i) || ' / ' || g_max_profit_togo (g_set_size - i));

  END LOOP;

  Write_Log ('Price min / profit max ' || g_min_item_price || ' / ' || g_max_item_profit);
  FOR i IN 1..g_n_cats LOOP

    Utils.Write_Log ('Cat ' || i || ' : ' || g_cat_list(i).id || ' - ' || g_cat_list(i).min_items || ' - ' || g_cat_list(i).max_items || ' - ' || g_item_range_list(i).item_beg || ' - ' || g_item_range_list(i).item_end);

  END LOOP;

  g_sol_list.EXTEND (g_n_size);
  FOR i IN 1..g_n_size LOOP
    g_profit_hash (i) := i;
  END LOOP;
  g_nth_profit := g_profit_hash.FIRST;
  g_trial_sol.price := 0;
  g_trial_sol.profit := 0;

END Pop_Arrays;

PROCEDURE Get_Best_Item_List (p_position PLS_INTEGER, p_item_index_beg PLS_INTEGER, p_item_index_end PLS_INTEGER, x_item_hash IN OUT NOCOPY int_hash_type) IS

PROCEDURE Check_Item (p_item_index PLS_INTEGER) IS

  l_item_rec         item_cat_rec_type := g_item_cat_list (p_item_index);
  l_item_list        num_list_type;
  Item_Failed        EXCEPTION;
  l_item_str         VARCHAR2(200) := LPad (l_item_rec.id, (p_position)*3, '.') || '-' || l_item_rec.cat_id  || '-' || l_item_rec.price  || '-' || l_item_rec.profit;

  FUNCTION Price_LB (p_position PLS_INTEGER) RETURN PLS_INTEGER IS
  BEGIN

    RETURN g_min_price_togo (p_position);
      
  END Price_LB;

  FUNCTION Profit_UB (p_position PLS_INTEGER) RETURN PLS_INTEGER IS
  BEGIN

    RETURN g_max_profit_togo (p_position);

  END Profit_UB;

BEGIN

  IF l_item_rec.price + g_trial_sol.price + Price_LB (p_position) > g_max_price THEN

    l_item_str := l_item_str || ' [price failed ' || (l_item_rec.price + g_trial_sol.price) || ']';
    IF (g_set_size - p_position) = 0 THEN
      Write_Log ('Solution fails with price of ' || (l_item_rec.price + g_trial_sol.price), 1);
    END IF;
    RAISE Item_Failed;
  END IF;

  IF l_item_rec.profit + g_trial_sol.profit + Profit_UB (p_position) <= g_nth_profit THEN
    l_item_str := l_item_str || ' [profit failed ' || (l_item_rec.profit + g_trial_sol.profit) || ', nth = ' || g_nth_profit || ']';
    IF (g_set_size - p_position) = 0 THEN
      Write_Log ('Solution fails with profit of ' || (l_item_rec.profit + g_trial_sol.profit), 1);
      g_n_sols := g_n_sols + 1;
    END IF;
    RAISE Item_Failed;
  END IF;

  x_item_hash (Dedup_Hash (p_card => g_keep_size, p_key => l_item_rec.profit + g_trial_sol.profit, p_hash => x_item_hash)) := p_item_index;

EXCEPTION

  WHEN Item_Failed THEN
    Write_Log (l_item_str, 2);
    
END Check_Item;

BEGIN

  FOR i IN p_item_index_beg..p_item_index_end LOOP

    Check_Item (i);

  END LOOP;

END Get_Best_Item_List;

PROCEDURE Add_Solution IS
  l_nth_index        PLS_INTEGER;
BEGIN

  g_n_sols := g_n_sols + 1;
  l_nth_index := g_profit_hash (g_profit_hash.FIRST);
  Write_Log ('Solution replaces in position ' || l_nth_index || ' profit is ' || g_trial_sol.profit || ' price is ' || g_trial_sol.price, 1);

  g_profit_hash.DELETE (g_profit_hash.FIRST);
  g_profit_hash (Dedup_Hash (p_card => g_n_size, p_key => g_trial_sol.profit, p_hash => g_profit_hash)) := l_nth_index;

  g_sol_list (l_nth_index) := g_trial_sol;
  g_nth_profit := g_profit_hash.FIRST / g_n_size;

  IF Mod (g_n_sols, c_hash_renew_point) = 0 THEN -- Not sur eif this works, but is intended to clear memory overhang
    g_hash_buffer :=  g_profit_hash;
    g_profit_hash :=  g_hash_buffer;
  END IF;

END Add_Solution;

PROCEDURE Add_Item_To_Trial (p_position PLS_INTEGER, p_item_index PLS_INTEGER) IS

  l_item_rec          item_cat_rec_type := g_item_cat_list (p_item_index);

BEGIN

  g_trial_sol.price := g_trial_sol.price + l_item_rec.price;
  g_trial_sol.profit := g_trial_sol.profit + l_item_rec.profit;

  IF g_trial_sol.item_list IS NULL THEN
    g_trial_sol.item_list := id_list_type (l_item_rec.id);
  ELSE
    g_trial_sol.item_list.EXTEND;
    g_trial_sol.item_list (p_position) := l_item_rec.id;
  END IF;

  IF p_position = g_set_size THEN

    Add_Solution;

  END IF;
   
END Add_Item_To_Trial;

FUNCTION Try_Position (p_position PLS_INTEGER, p_n_curr_cat PLS_INTEGER, p_cat_index_beg PLS_INTEGER, p_item_index_beg PLS_INTEGER) RETURN BOOLEAN IS

  l_item_hash       int_hash_type;
  l_item_index      PLS_INTEGER;
  l_cat_index_beg   PLS_INTEGER := p_cat_index_beg;
  l_item_index_beg  PLS_INTEGER := p_item_index_beg;
  l_n_curr_cat      PLS_INTEGER := p_n_curr_cat;
  l_profit          PLS_INTEGER;
BEGIN

  g_n_recursive_calls := g_n_recursive_calls + 1;
  IF g_n_recursive_calls > g_max_calls THEN
    Write_Log (LPad ('*', p_position, '*') || 'Truncating search after ' || g_max_calls || ' recursive calls***');
    RETURN TRUE;
  END IF;

  IF p_n_curr_cat = g_cat_list (p_cat_index_beg).max_items THEN
-- 
-- passed in the cat we were on in last position
-- check max not passed, if so go to next cat and reset item range
--
    Write_Log ('Maxed Cat ' || p_cat_index_beg || ': ' || p_n_curr_cat || '-' || g_cat_list (p_cat_index_beg).max_items, 5);
    l_cat_index_beg := p_cat_index_beg + 1;
    IF l_cat_index_beg > g_n_cats THEN
      RETURN FALSE;
    END IF;
    l_item_index_beg := g_item_range_list (l_cat_index_beg).item_beg;
    l_n_curr_cat := 0;

  END IF;

  FOR j IN l_cat_index_beg..g_n_cats LOOP

    IF l_item_index_beg < g_item_range_list (j).item_beg THEN
      l_item_index_beg := g_item_range_list (j).item_beg;
    END IF;

    Write_Log ('Start Cat ' || j || ': ' || l_n_curr_cat || '-' || g_cat_list(j).min_items, 5);
    l_n_curr_cat := l_n_curr_cat + 1;
    l_item_hash.DELETE;
    Get_Best_Item_List (p_position => p_position, p_item_index_beg => l_item_index_beg, p_item_index_end => g_item_range_list(j).item_end, x_item_hash => l_item_hash);
    IF l_item_hash IS NOT NULL THEN

    l_profit := l_item_hash.LAST;
    FOR i IN 1..Least (g_keep_size, l_item_hash.COUNT) LOOP
      l_item_index := l_item_hash (l_profit);
      Write_Log (LPad (g_item_cat_list (l_item_index).id, (p_position)*3, '.') || '-' || g_item_cat_list (l_item_index).cat_id  || '-' || g_item_cat_list (l_item_index).price  || '-' || g_item_cat_list (l_item_index).profit, 1);
      Add_Item_To_Trial (p_position => p_position, p_item_index => l_item_index);
      IF p_position < g_set_size THEN

        IF Try_Position (p_position => p_position + 1, p_n_curr_cat => l_n_curr_cat, p_cat_index_beg => j, p_item_index_beg => l_item_index + 1) THEN RETURN TRUE; END IF;

      END IF;

      IF g_trial_sol.item_list IS NOT NULL AND g_trial_sol.item_list.COUNT = p_position THEN
        g_trial_sol.item_list.TRIM;
        g_trial_sol.price := g_trial_sol.price - g_item_cat_list (l_item_index).price;
        g_trial_sol.profit := g_trial_sol.profit - g_item_cat_list (l_item_index).profit;
      END IF;

      l_profit := l_item_hash.PRIOR (l_profit);

    END LOOP;

    ELSE
      Write_Log ('No items found');
    END IF;
-- 
--  Don't look at any more cats if we are not past the minimum for the current one at this position
--
    Write_Log ('Cat ' || j || ': ' || l_n_curr_cat || '-' || g_cat_list(j).min_items, 5);
    IF l_n_curr_cat <= g_cat_list(j).min_items THEN
      EXIT;
    END IF;

    l_n_curr_cat := 0;

  END LOOP;
  RETURN FALSE;

END Try_Position;

PROCEDURE Write_Sols IS
  l_profit    PLS_INTEGER;
  l_index     PLS_INTEGER;
BEGIN

  l_profit := g_profit_hash.LAST;
  IF l_profit <= g_n_size THEN
    Write_Log ('No solution found');
  END IF;
  WHILE l_profit IS NOT NULL LOOP

    l_index := g_profit_hash (l_profit);
    Write_Log ('Profit = ' || g_sol_list(l_index).profit || ', price = ' || g_sol_list(l_index).price || ' items...');
    l_profit := g_profit_hash.PRIOR (l_profit);

    IF l_profit > g_n_size THEN

      FOR i IN 1..g_sol_list(l_index).item_list.COUNT LOOP

        Write_Log ('... ' || g_sol_list(l_index).item_list(i)); 

      END LOOP;

    END IF;

  END LOOP;

END Write_Sols;

FUNCTION Best_N_Sets (  p_keep_size     PLS_INTEGER, 
                        p_max_calls     PLS_INTEGER, 
                        p_n_size        PLS_INTEGER, 
                        p_max_price     PLS_INTEGER, 
                        p_cat_cur       SYS_REFCURSOR, 
                        p_item_cur      SYS_REFCURSOR) RETURN sol_detail_list_type PIPELINED IS

  l_sol_detail_rec          sol_detail_rec_type;
  l_position                PLS_INTEGER := 1;
  l_timer                   PLS_INTEGER := Timer_Set.Construct ('Best_N_Sets');
BEGIN
  g_timer := Timer_Set.Construct ('Try_Position');

  g_keep_size := p_keep_size; g_max_calls := p_max_calls; g_n_size := p_n_size; g_max_price := p_max_price;

  Pop_Arrays (p_cat_cur, p_item_cur);

  Timer_Set.Increment_Time (l_timer, 'Pop_Arrays');
  IF Try_Position (p_position => 1, p_n_curr_cat => 0, p_cat_index_beg => 1, p_item_index_beg => 1) THEN NULL; END IF;
  Timer_Set.Increment_Time (l_timer, 'Try_Position');

  Write_Sols;
  Timer_Set.Increment_Time (l_timer, 'Write_Sols');

  FOR i IN 1..g_n_size LOOP

    l_sol_detail_rec.set_id := i;
    l_sol_detail_rec.sol_price := g_sol_list(i).price;
    l_sol_detail_rec.sol_profit := g_sol_list(i).profit;

    IF g_sol_list(i).item_list IS NOT NULL THEN

      FOR j IN 1..g_sol_list(i).item_list.COUNT LOOP

        l_sol_detail_rec.item_id := g_sol_list(i).item_list(j);
        PIPE ROW (l_sol_detail_rec);

      END LOOP;

    END IF;

  END LOOP;
  Timer_Set.Increment_Time (l_timer, 'Pipe');
  Write_Log (g_n_sols || ' solutions found in ' || g_n_recursive_calls || ' recursive calls');
  Timer_Set.Write_Times (l_timer);
  Timer_Set.Write_Times (g_timer);
  RETURN;

END Best_N_Sets;

END Item_Cats;
/
SHO ERR
