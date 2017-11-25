TRUNCATE TABLE items
/
TRUNCATE TABLE containers
/
DECLARE

  PROCEDURE Add_Item (p_id PLS_INTEGER, p_weight PLS_INTEGER, p_profit PLS_INTEGER) IS
  BEGIN
    INSERT INTO items VALUES (p_id, p_weight, p_profit);
  END Add_Item;

  PROCEDURE Add_Cont (p_id PLS_INTEGER, p_max_weight PLS_INTEGER) IS
  BEGIN
    INSERT INTO containers VALUES (p_id, To_Char ('Con ') || p_id, p_max_weight);
  END Add_Cont;

BEGIN

  Add_Item (1, 3, 10);
  Add_Item (2, 4, 20);
  Add_Item (3, 5, 30);
  Add_Item (4, 6, 40);

  Add_Cont (1, 8);
  Add_Cont (2, 10);
  
END;
/

PROMPT Input Data - Items
SELECT id, item_weight, Sum (item_weight) OVER (ORDER BY id) r_sum_weight, item_profit, Sum (item_profit) OVER (ORDER BY id) r_sum_profit
  FROM items
 ORDER BY id
/
PROMPT Input Data - Containers
SELECT id, name, max_weight
  FROM containers
 ORDER BY id
/
EXECUTE DBMS_Stats.Gather_Schema_Stats(ownname => 'KNAPSACK');
