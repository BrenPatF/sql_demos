/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting SQL
                 https://github.com/BrenPatF/sql_demos

Author:          Brendan Furey, 25 May 2013
Description:     Package body for the pipelined function solution

Further details: 'SQL for the Balanced Number Partitioning Problem', May 2013
                 http://aprogrammerwrites.eu/?p=803
***************************************************************************************************/

CREATE OR REPLACE PACKAGE BODY Bin_Fit AS

c_big_value                 CONSTANT NUMBER := 1000000000000;
TYPE bin_fit_cur_list_type  IS VARRAY(100) OF bin_fit_cur_rec_type;

/***************************************************************************************************

Items_Binned: Entry point function returning best solutions found

***************************************************************************************************/
FUNCTION Items_Binned (x_items_cur      bin_fit_cur_type, -- items cursor
                       p_n_bins         PLS_INTEGER)      -- number of bins
                       RETURN           bin_fit_list_type -- item record list
                       PIPELINED IS

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

END Bin_Fit;
/
SHO ERR
