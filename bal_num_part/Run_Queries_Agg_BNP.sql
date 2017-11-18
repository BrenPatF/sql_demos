/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting SQL
                 https://github.com/BrenPatF/sql_demos

Author:          Brendan Furey, 17 November 2017
Description:     Called by the driving scripts to run the SQL; log the execution plans; print 
                 the logging results

Further details: 'SQL for the Balanced Number Partitioning Problem'
                 http://aprogrammerwrites.eu/?p=803

***************************************************************************************************/
BEGIN
  Utils.Clear_Log;
  Utils.g_debug_level := 0;
END;
/
VAR N_BINS NUMBER
BEGIN
  :N_BINS := &1;
END;
/
PROMPT Running for N_BINS value of...
PRINT :N_BINS
SET TIMING ON

PROMPT Queries
COLUMN item_name FORMAT A15
PROMPT POS 3 bins
WITH items_desc AS (
    SELECT item_name, item_value, 
           Mod (Row_Number () OVER (ORDER BY item_value DESC), :N_BINS) + 1 bin
      FROM items
), all_rows AS (
    SELECT item_name, bin, item_value, Sum (item_value) OVER (PARTITION BY bin) bin_total
      FROM items_desc
)
SELECT  /*+ gather_plan_statistics XPOS */ 
       bin, Sum (item_value) bin_total, Max (item_value) - Min (item_value) bin_int_diff,
       Max (Sum (item_value)) OVER () - Min (Sum (item_value)) OVER () bin_ext_diff
  FROM all_rows
GROUP BY bin
ORDER BY bin 
/ 
EXECUTE Utils.Write_Plan (p_sql_marker => 'XPOS');

PROMPT PLF Items_Binned
WITH all_rows AS (
    SELECT item_name, bin, item_value, Sum (item_value) OVER (PARTITION BY bin) bin_value
      FROM TABLE (Bin_Fit.Items_Binned (
                         CURSOR (SELECT item_name, item_value FROM items ORDER BY item_value DESC), 
                         :N_BINS))
)
SELECT  /*+ gather_plan_statistics XPOS */ 
       bin, Sum (item_value) bin_total, Max (item_value) - Min (item_value) bin_int_diff,
       Max (Sum (item_value)) OVER () - Min (Sum (item_value)) OVER () bin_ext_diff
  FROM all_rows
GROUP BY bin
ORDER BY bin 
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'XPLF');

PROMPT RSF
WITH bins AS (
       SELECT LEVEL bin, :N_BINS n_bins FROM DUAL CONNECT BY LEVEL <= :N_BINS
), items_desc AS (
       SELECT item_name, item_value, Row_Number () OVER (ORDER BY item_value DESC) rn
         FROM items
), rsf (bin, item_name, item_value, bin_value, lev, bin_rank, n_bins) AS (
SELECT b.bin,
       i.item_name, 
       i.item_value, 
       i.item_value,
       1,
       b.n_bins - i.rn + 1,
       b.n_bins
  FROM bins b
  JOIN items_desc i
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
  JOIN items_desc i
    ON i.rn = r.bin_rank + r.lev * r.n_bins
), all_rows AS (
    SELECT r.item_name,
           r.bin, r.item_value, r.bin_value
      FROM rsf r
)
SELECT  /*+ gather_plan_statistics XPOS */ 
       bin, Sum (item_value) bin_total, Max (item_value) - Min (item_value) bin_int_diff,
       Max (Sum (item_value)) OVER () - Min (Sum (item_value)) OVER () bin_ext_diff
  FROM all_rows
GROUP BY bin
ORDER BY bin 
/ 
EXECUTE Utils.Write_Plan (p_sql_marker => 'XRSF_D');
PROMPT Insert into temp table items_desc_temp
INSERT INTO items_desc_temp
SELECT /*+ gather_plan_statistics XINS */
       item_id, item_name, item_value, Row_Number () OVER (ORDER BY item_value DESC) rn
  FROM items;
EXECUTE Utils.Write_Plan (p_sql_marker => 'XINS');

PROMPT RSF with temporary table
WITH bins AS (
       SELECT LEVEL bin, :N_BINS n_bins FROM DUAL CONNECT BY LEVEL <= :N_BINS
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
), all_rows AS (
    SELECT  /*+ gather_plan_statistics XRSF_T */ 
           item_name, bin, item_value, bin_value
      FROM rsf
)
SELECT  /*+ gather_plan_statistics XPOS */ 
       bin, Sum (item_value) bin_total, Max (item_value) - Min (item_value) bin_int_diff,
       Max (Sum (item_value)) OVER () - Min (Sum (item_value)) OVER () bin_ext_diff
  FROM all_rows
GROUP BY bin
ORDER BY bin 
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'XRSF_T');

PROMPT COMMIT to delete temp table items_desc_temp
COMMIT
/
PROMPT MOD with both Stew Ashton changes: removing measure from rule, and inline view
WITH all_rows AS (
    SELECT item_name, bin, item_value, Max (bin_value) OVER (PARTITION BY bin) bin_value
      FROM (
    SELECT * FROM items
      MODEL 
        DIMENSION BY (Row_Number() OVER (ORDER BY item_value DESC) rn)
        MEASURES (item_name, 
                  item_value,
                  Row_Number() OVER (ORDER BY item_value DESC) bin,
                  item_value bin_value,
                  Row_Number() OVER (ORDER BY item_value DESC) rn_m,
                  0 min_bin,
                  Count(*) OVER () - :N_BINS - 1 n_iters
        )
        RULES ITERATE(100000) UNTIL (ITERATION_NUMBER >= n_iters[1]) (
          min_bin[1] = Min(rn_m) KEEP (DENSE_RANK FIRST ORDER BY bin_value)[rn <= :N_BINS],
          bin[ITERATION_NUMBER + :N_BINS + 1] = min_bin[1],
          bin_value[min_bin[1]] = bin_value[CV()] + Nvl (item_value[ITERATION_NUMBER + :N_BINS + 1], 0)
        )
    )
     WHERE item_name IS NOT NULL
)
SELECT  /*+ gather_plan_statistics XPOS */ 
       bin, Sum (item_value) bin_total, Max (item_value) - Min (item_value) bin_int_diff,
       Max (Sum (item_value)) OVER () - Min (Sum (item_value)) OVER () bin_ext_diff
  FROM all_rows
GROUP BY bin
ORDER BY bin 
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'XMOD');
SET TIMING OFF
@..\bren\L_Log_Default
