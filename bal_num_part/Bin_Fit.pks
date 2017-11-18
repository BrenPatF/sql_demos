/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting SQL
                 https://github.com/BrenPatF/sql_demos

Author:          Brendan Furey, 17 November 2017
Description:     Package spec for the pipelined function solution

Further details: 'SQL for the Balanced Number Partitioning Problem'
                 http://aprogrammerwrites.eu/?p=803

***************************************************************************************************/
CREATE OR REPLACE PACKAGE Bin_Fit AS

TYPE bin_fit_rec_type IS RECORD (item_name VARCHAR2(100), item_value NUMBER, bin NUMBER);
TYPE bin_fit_list_type IS VARRAY(1000) OF bin_fit_rec_type;

TYPE bin_fit_cur_rec_type IS RECORD (item_name VARCHAR2(100), item_value NUMBER);
TYPE bin_fit_cur_type IS REF CURSOR RETURN bin_fit_cur_rec_type;

FUNCTION Items_Binned (x_items_cur bin_fit_cur_type, p_n_bins PLS_INTEGER) RETURN bin_fit_list_type PIPELINED;
FUNCTION Items_Binned_RSF (x_items_cur bin_fit_cur_type, p_n_bins PLS_INTEGER) RETURN bin_fit_list_type PIPELINED;

END Bin_Fit;
/
SHO ERR
