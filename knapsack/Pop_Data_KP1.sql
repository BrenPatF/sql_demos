DECLARE

  i     PLS_INTEGER := 0;
  PROCEDURE Add_Item (p_weight PLS_INTEGER, p_profit PLS_INTEGER) IS
  BEGIN
    i := i + 1;
    INSERT INTO items VALUES (i, p_weight, p_profit);
  END Add_Item;
BEGIN
  DELETE items;
  Add_Item (3, 10);
  Add_Item (4, 20);
  Add_Item (5, 30);
  Add_Item (6, 40);

END;
/

PROMPT Input Data
SELECT id, item_weight, Sum (item_weight) OVER (ORDER BY id) r_sum_weight, item_profit, Sum (item_profit) OVER (ORDER BY id) r_sum_profit
  FROM items
 ORDER BY id
/
EXECUTE DBMS_Stats.Gather_Schema_Stats(ownname => 'KNAPSACK');
