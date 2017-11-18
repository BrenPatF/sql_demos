/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting SQL
                 https://github.com/BrenPatF/sql_demos

Author:          Brendan Furey, 17 November 2017
Description:     Package body for the pipelined function solution

Further details: 'SQL for the Balanced Number Partitioning Problem'
                 http://aprogrammerwrites.eu/?p=803

***************************************************************************************************/
CREATE OR REPLACE PACKAGE BODY Bin_Fit AS

c_big_value                 CONSTANT NUMBER := 1000000000000;
TYPE bin_fit_cur_list_type  IS VARRAY(100) OF bin_fit_cur_rec_type;

FUNCTION Items_Binned (x_items_cur bin_fit_cur_type, p_n_bins PLS_INTEGER) RETURN bin_fit_list_type PIPELINED IS

  l_min_bin                 PLS_INTEGER := 1;
  l_min_bin_val             NUMBER;
  l_bins                    L1_num_arr := L1_num_arr();
  l_bin_fit_cur_rec         bin_fit_cur_rec_type;
  l_bin_fit_rec             bin_fit_rec_type;
  l_bin_fit_cur_list        bin_fit_cur_list_type;

BEGIN

  l_bins.Extend (p_n_bins);
  FOR i IN 1..p_n_bins LOOP
    l_bins(i) := 0;
  END LOOP;

  LOOP

    FETCH x_items_cur BULK COLLECT INTO l_bin_fit_cur_list LIMIT 100;
    EXIT WHEN l_bin_fit_cur_list.COUNT = 0;

    FOR j IN 1..l_bin_fit_cur_list.COUNT LOOP

      l_bin_fit_rec.item_name := l_bin_fit_cur_list(j).item_name;
      l_bin_fit_rec.item_value := l_bin_fit_cur_list(j).item_value;
      l_bin_fit_rec.bin := l_min_bin;

      PIPE ROW (l_bin_fit_rec);
      l_bins(l_min_bin) := l_bins(l_min_bin) + l_bin_fit_cur_list(j).item_value;

      l_min_bin_val := c_big_value;
      FOR i IN 1..p_n_bins LOOP

        IF l_bins(i) < l_min_bin_val THEN
          l_min_bin := i;
          l_min_bin_val := l_bins(i);
        END IF;

      END LOOP;

    END LOOP;

  END LOOP;

END Items_Binned;

FUNCTION Items_Binned_RSF (x_items_cur bin_fit_cur_type, p_n_bins PLS_INTEGER) RETURN bin_fit_list_type PIPELINED IS

  l_min_bin                 PLS_INTEGER := 1;
  l_min_bin_val             NUMBER;
  l_bins                    L1_num_arr := L1_num_arr();
  l_bin_fit_cur_rec         bin_fit_cur_rec_type;
  l_bin_fit_rec             bin_fit_rec_type;
  l_bin_fit_cur_list        bin_fit_cur_list_type;

  CURSOR c_rsf IS
  WITH bins AS (
       SELECT LEVEL bin, p_n_bins n_bins FROM DUAL CONNECT BY LEVEL <= p_n_bins
  ), rsf (bin, item_name, item_value, bin_value, lev, bin_rank, n_bins) AS (
  SELECT b.bin,
       i.item_name, 
       i.item_value, 
       i.item_value,
       1,
       b.n_bins - i.rn + 1,
       b.n_bins
    FROM bins b
    JOIN items_desc_temp i
      ON i.rn = b.bin
   UNION ALL
  SELECT r.bin,
       i.item_name, 
       i.item_value, 
       r.bin_value + i.item_value,
       r.lev + 1,
       Row_Number () OVER (ORDER BY r.bin_value + i.item_value),
       r.n_bins
    FROM rsf r
    JOIN items_desc_temp i
      ON i.rn = r.bin_rank + r.lev * r.n_bins
  )
  SELECT
       item_name, 
       bin, 
       item_value
    FROM rsf r
   ORDER BY item_value DESC;
  PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

  INSERT INTO items_desc_temp
  SELECT item_id, item_name, item_value, Row_Number () OVER (ORDER BY item_value DESC) rn
    FROM items;

  FOR r_rsf IN c_rsf LOOP

    l_bin_fit_rec.item_name := r_rsf.item_name;
    l_bin_fit_rec.item_value := r_rsf.item_value;
    l_bin_fit_rec.bin := r_rsf.bin;

    COMMIT;
    PIPE ROW (l_bin_fit_rec);

  END LOOP;
  COMMIT;

END Items_Binned_RSF;

END Bin_Fit;
/
SHO ERR
