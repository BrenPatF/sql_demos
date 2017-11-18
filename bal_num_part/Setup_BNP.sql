PROMPT Create items table...
DROP SEQUENCE items_s
/
CREATE SEQUENCE items_s START WITH 1
/
DROP TABLE items
/
CREATE TABLE items (
   item_id    INTEGER PRIMARY KEY,  
   item_name  VARCHAR2(30) NOT NULL,  
   item_value NUMBER(8) NOT NULL  
   )
/
PROMPT Create temp table items_desc_temp ON COMMIT DELETE ROWS and index
DROP TABLE items_desc_temp
/
CREATE GLOBAL TEMPORARY TABLE items_desc_temp (
   item_id    INTEGER,
   item_name  VARCHAR2(30) NOT NULL,  
   item_value NUMBER(8) NOT NULL,
   rn         NUMBER
)
ON COMMIT DELETE ROWS
/
CREATE INDEX items_desc_temp_N1 ON items_desc_temp (rn)
/
