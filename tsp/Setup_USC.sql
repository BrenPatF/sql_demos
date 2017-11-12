PROMPT Create usca312 tables...
DROP SEQUENCE towns_usc_s
/
CREATE SEQUENCE towns_usc_s START WITH 1
/
DROP TABLE distances_usc 
/
DROP TABLE towns_usc
/
CREATE TABLE towns_usc (
       id            INTEGER PRIMARY KEY,
       name          VARCHAR2(30),
       x             NUMBER,
       y             NUMBER
)
/
CREATE TABLE distances_usc (
       id     INTEGER PRIMARY KEY,
       a      INTEGER,
       b      INTEGER,
       dst    NUMBER,
       CONSTRAINT distance_usc_uk UNIQUE (a, b),
       CONSTRAINT dst_twn_usc_a_fk FOREIGN KEY (a) REFERENCES towns_usc (id),
       CONSTRAINT dst_twn_usc_b_fk FOREIGN KEY (b) REFERENCES towns_usc (id)
)
/
DROP TABLE towns_ext
/
CREATE TABLE towns_ext (
        name           VARCHAR2(30)
)
ORGANIZATION EXTERNAL (
	TYPE			oracle_loader
	DEFAULT DIRECTORY	input_dir
	ACCESS PARAMETERS
	(
              RECORDS DELIMITED BY NEWLINE SKIP 1
		FIELDS TERMINATED BY '\t'
		MISSING FIELD VALUES ARE NULL
	)
	LOCATION ('usca312_name_data.txt')
)
/
DROP TABLE xy_ext
/
CREATE TABLE xy_ext (
        x           NUMBER,
        y           NUMBER
)
ORGANIZATION EXTERNAL (
	TYPE			oracle_loader
	DEFAULT DIRECTORY	input_dir
	ACCESS PARAMETERS
	(
              RECORDS DELIMITED BY NEWLINE SKIP 1
		FIELDS TERMINATED BY '\t'
		MISSING FIELD VALUES ARE NULL
	)
	LOCATION ('usca312_xy_data.txt')
)
/
DROP SEQUENCE towns_usc_s
/
CREATE SEQUENCE towns_usc_s START WITH 1
/
INSERT INTO towns_usc
SELECT towns_usc_s.NEXTVAL, name, NULL, NULL FROM towns_ext
/
DROP SEQUENCE towns_usc_s
/
CREATE SEQUENCE towns_usc_s START WITH 1
/
DROP TABLE xy
/
CREATE TABLE xy (
       id            INTEGER PRIMARY KEY,
       x             NUMBER,
       y             NUMBER
)
/
INSERT INTO xy
SELECT towns_usc_s.NEXTVAL, x, y FROM xy_ext
/
UPDATE towns_usc t SET (t.x, t.y) = (SELECT xy.x, xy.y FROM xy WHERE xy.id = t.id)
/
INSERT INTO distances_usc
WITH dist AS (
SELECT a.id a, b.id b, 
       SQRT ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)) dst
  FROM xy a
  JOIN xy b
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
COLUMN name FORMAT A30
COLUMN a FORMAT 990
COLUMN b FORMAT 990
PROMPT Towns
SELECT id, name, x, y
  FROM towns_usc
   ORDER BY 1
/
PROMPT Distances count
SELECT Count(*)
  FROM distances_usc d
  JOIN towns_usc t_a
    ON t_a.id = d.a
  JOIN towns_usc t_b
    ON t_b.id = d.b
/
