CREATE OR REPLACE PACKAGE BODY Multi IS
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

/***************************************************************************************************

Split_String: Splits a string holding container-item lists into a stream of container-item pairs

***************************************************************************************************/
FUNCTION Split_String (p_string     VARCHAR2) -- input string
                       RETURN       con_itm_list_type PIPELINED IS -- list of container-item pairs

  l_pos_colon_1           PLS_INTEGER := 1;
  l_pos_colon_2           PLS_INTEGER;
  l_pos_comma_1           PLS_INTEGER;
  l_pos_comma_2           PLS_INTEGER;
  l_con                   PLS_INTEGER;
  l_itm                   PLS_INTEGER;

BEGIN

  LOOP

    l_pos_colon_2 := Instr (p_string, ':', l_pos_colon_1 + 1, 1);
    EXIT WHEN l_pos_colon_2 = 0;

    l_con := To_Number (Substr (p_string, l_pos_colon_1 + 1, l_pos_colon_2 - l_pos_colon_1 - 1));
    l_pos_colon_1 := Instr (p_string, ':', l_pos_colon_2 + 1, 1);
    l_pos_comma_1 := l_pos_colon_2 + 1;

    LOOP

      l_pos_comma_2 := Instr (p_string, ',', l_pos_comma_1 + 1, 1);
      EXIT WHEN l_pos_comma_2 = 0 OR l_pos_comma_2 > l_pos_colon_1;

      l_itm := To_Number (Substr (p_string, l_pos_comma_1 + 1, l_pos_comma_2 - l_pos_comma_1 - 1));
      PIPE ROW (con_itm_type (l_con, l_itm));
      l_pos_comma_1 := l_pos_comma_2;
 
    END LOOP;

  END LOOP;

END Split_String;

END Multi;
/
SHO ERR
