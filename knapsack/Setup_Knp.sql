PROMPT Create Single- and Multi-Container Knapsack tables...
PROMPT Table items
DROP TABLE items
/
CREATE TABLE items (
        id                NUMBER PRIMARY KEY,
        item_weight       NUMBER,
        item_profit       NUMBER
)
/
PROMPT Table containers
DROP TABLE containers
/
CREATE TABLE containers (
        id                NUMBER PRIMARY KEY,
        name              VARCHAR2(30),
        max_weight        NUMBER
)
/
DROP TYPE con_itm_list_type
/
CREATE OR REPLACE TYPE con_itm_type AS OBJECT (con_id NUMBER, itm_id NUMBER)
/
CREATE TYPE con_itm_list_type AS VARRAY(100) OF con_itm_type
/
