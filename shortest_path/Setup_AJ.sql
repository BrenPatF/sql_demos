PROMPT Create aj tables...
PROMPT Table arcs_aj_dir
DROP TABLE arcs_aj_dir
/
CREATE TABLE arcs_aj_dir (
        src              VARCHAR2(10) NOT NULL,
        dst              VARCHAR2(10) NOT NULL,
        distance         NUMBER(3,0) NOT NULL,
        CONSTRAINT arcs_aj_dir_pk PRIMARY KEY (src, dst)
)
/
PROMPT Table arcs_aj_undir
DROP TABLE arcs_aj_undir
/
CREATE TABLE arcs_aj_undir (
        src              VARCHAR2(10) NOT NULL,
        dst              VARCHAR2(10) NOT NULL,
        distance         NUMBER(3,0) NOT NULL,
        CONSTRAINT arcs_aj_undir_pk PRIMARY KEY (src, dst)
)
/
REM INSERTING into arcs_aj_dir

INSERT INTO arcs_aj_dir VALUES ('A','B',2);
INSERT INTO arcs_aj_dir VALUES ('A','C',4);
INSERT INTO arcs_aj_dir VALUES ('A','D',3);
INSERT INTO arcs_aj_dir VALUES ('B','E',7);
INSERT INTO arcs_aj_dir VALUES ('C','E',3);
INSERT INTO arcs_aj_dir VALUES ('D','E',4);
INSERT INTO arcs_aj_dir VALUES ('B','F',4);
INSERT INTO arcs_aj_dir VALUES ('C','F',2);
INSERT INTO arcs_aj_dir VALUES ('D','F',1);
INSERT INTO arcs_aj_dir VALUES ('B','G',6);
INSERT INTO arcs_aj_dir VALUES ('C','G',4);
INSERT INTO arcs_aj_dir VALUES ('D','G',5);
INSERT INTO arcs_aj_dir VALUES ('E','H',1);
INSERT INTO arcs_aj_dir VALUES ('F','H',6);
INSERT INTO arcs_aj_dir VALUES ('G','H',3);
INSERT INTO arcs_aj_dir VALUES ('E','I',4);
INSERT INTO arcs_aj_dir VALUES ('F','I',3);
INSERT INTO arcs_aj_dir VALUES ('G','I',3);
INSERT INTO arcs_aj_dir VALUES ('H','J',3);
INSERT INTO arcs_aj_dir VALUES ('I','J',4);

PROMPT arcs_aj_dir
SELECT src, dst, distance
  FROM arcs_aj_dir
 ORDER BY 1, 2, 3
/
PROMPT Nodes
SELECT src node
  FROM arcs_aj_dir
 UNION
SELECT dst
  FROM arcs_aj_dir
 ORDER BY 1
/
PROMPT Add arcs in both directions to arcs_undir
INSERT INTO arcs_aj_undir
SELECT src, dst, distance
  FROM arcs_aj_dir
UNION ALL
SELECT dst, src, distance
  FROM arcs_aj_dir
/
PROMPT arcs_aj_undir
SELECT src, dst, distance
  FROM arcs_aj_undir
 ORDER BY 1, 2, 3
/
