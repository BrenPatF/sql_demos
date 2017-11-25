CREATE OR REPLACE PACKAGE Multi IS
/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting SQL
                 https://github.com/BrenPatF/sql_demos

Author:          Brendan Furey, 20 January 2013
Description:     Pipelined function that is used as part of a larger query in one of the solutions
                 for the knapsack problem with multiple containers. It's a simple function that
                 splits a string holding container-item lists into a stream of container-item pairs.
                 The format of the input string is :con:,item1,item2, possibly repeated multiple 
                 times with a final ':' terminating, eg: ':1:,1,3,:2:,2,4,:'

Further details: 'An SQL Solution for the Multiple Knapsack Problem (SKP-m)', January 2013
                 http://aprogrammerwrites.eu/?p=635
***************************************************************************************************/

FUNCTION Split_String (p_string VARCHAR2) RETURN con_itm_list_type PIPELINED;

END Multi;
/
SHO ERR
