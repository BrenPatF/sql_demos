PROMPT Create brightkite tables...
DROP TABLE arcs_brightkite
/
CREATE TABLE arcs_brightkite (
        src              NUMBER NOT NULL,
        dst              NUMBER NOT NULL,
        CONSTRAINT arcs_brightkite_pk PRIMARY KEY (src, dst)
)
/
DROP TABLE arcs_brightkite_ext
/
CREATE TABLE arcs_brightkite_ext (
        src              NUMBER,
        dst              NUMBER
)
ORGANIZATION EXTERNAL (
	TYPE			    oracle_loader
	DEFAULT DIRECTORY	input_dir
	ACCESS PARAMETERS
	(
		FIELDS TERMINATED BY ','
		MISSING FIELD VALUES ARE NULL
	)
	LOCATION ('Brightkite_edges.csv')
)
/
INSERT INTO arcs_brightkite SELECT * FROM arcs_brightkite_ext
/
