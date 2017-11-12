PROMPT Create Emland tables...
DROP SEQUENCE towns_eml_s
/
CREATE SEQUENCE towns_eml_s START WITH 1
/
DROP TABLE distances_eml 
/
DROP TABLE towns_eml
/
CREATE TABLE towns_eml (
       id            INTEGER PRIMARY KEY,
       name          VARCHAR2(30),
       x             NUMBER,
       y             NUMBER
)
/
CREATE TABLE distances_eml (
       id     INTEGER PRIMARY KEY,
       a      INTEGER,
       b      INTEGER,
       dst    NUMBER,
       CONSTRAINT distance_eml_uk UNIQUE (a, b),
       CONSTRAINT dst_twn_eml_a_fk FOREIGN KEY (a) REFERENCES towns_eml (id),
       CONSTRAINT dst_twn_eml_b_fk FOREIGN KEY (b) REFERENCES towns_eml (id)
)
/
PROMPT Insert Emland data
DECLARE
  g_i INTEGER := 0;
  PROCEDURE Ins_Town (p_name VARCHAR2, p_x NUMBER, p_y NUMBER) IS
  BEGIN

    g_i := g_i + 1;
    INSERT INTO towns_eml VALUES (g_i, p_name, p_x, p_y);

  END Ins_Town;
BEGIN

  Ins_Town ('Left Floor', 0, 0);
  Ins_Town ('Left Peak', 1, 2);
  Ins_Town ('Midfield', 2, 1);
  Ins_Town ('Right Peak', 3, 2);
  Ins_Town ('Right Floor', 4, 0);

END;
/
INSERT INTO distances_eml
WITH dist AS (
SELECT a.id a, b.id b, 
       SQRT ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)) dst
  FROM towns_eml a
  JOIN towns_eml b
    ON b.id > a.id
), uni AS (
SELECT a, b, dst
  FROM dist
 UNION ALL
SELECT b, a, dst
  FROM dist
), pks AS (
SELECT a, b, dst, Row_Number() OVER (ORDER BY a, b) id
  FROM uni
)
SELECT id, a, b, dst
  FROM pks
/
COLUMN name FORMAT A15
COLUMN a FORMAT 990
COLUMN b FORMAT 990
PROMPT Towns
SELECT id, name, x, y
  FROM towns_eml
   ORDER BY 1
/
PROMPT Distances
BREAK ON a ON name_a
SELECT d.a, t_a.name name_a, d.b, t_b.name name_b, d.dst
  FROM distances_eml d
  JOIN towns_eml t_a
    ON t_a.id = d.a
  JOIN towns_eml t_b
    ON t_b.id = d.b
 ORDER BY 1, 3
/
