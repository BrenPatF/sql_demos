CREATE OR REPLACE PACKAGE Item_Cats AS
/**************************************************************************************************
GitHub Project: sql_demos - Brendan's repo for interesting problems and solutions in SQL
                https://github.com/BrenPatF/sql_demos

Author:         Brendan Furey, 7 July 2013
Description:    Brendan's pipelined function solution for the knapsack problem with one container,
                and items having categories with validity bands, as described at
                http://aprogrammerwrites.eu/?p=878 (SQL for the Fantasy Football Knapsack Problem)

***************************************************************************************************/
TYPE sol_detail_rec_type IS RECORD (
        set_id                  NUMBER,
        item_id                 VARCHAR2(100),
        sol_price               NUMBER,
        sol_profit              NUMBER
        );
TYPE sol_detail_list_type IS VARRAY(100) OF sol_detail_rec_type;

FUNCTION Best_N_Sets (  p_keep_size     PLS_INTEGER, 
                        p_max_calls     PLS_INTEGER, 
                        p_n_size        PLS_INTEGER, 
                        p_max_price     PLS_INTEGER, 
                        p_cat_cur       SYS_REFCURSOR, 
                        p_item_cur      SYS_REFCURSOR) RETURN sol_detail_list_type PIPELINED;

END Item_Cats;
/
SHO ERR
