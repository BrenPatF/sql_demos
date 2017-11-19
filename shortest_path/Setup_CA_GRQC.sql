PROMPT Create ca_grqc tables...
DROP TABLE arcs_ca_grqc 
/
CREATE TABLE arcs_ca_grqc (
        src              NUMBER NOT NULL,
        dst              NUMBER NOT NULL,
        CONSTRAINT arcs_ca_grqc_pk PRIMARY KEY (src, dst)
)
/
DROP TABLE arcs_ca_grqc_ext
/
CREATE TABLE arcs_ca_grqc_ext (
        src              NUMBER,
        dst              NUMBER
)
ORGANIZATION EXTERNAL (
    TYPE                oracle_loader
    DEFAULT DIRECTORY   input_dir
    ACCESS PARAMETERS
    (
        FIELDS TERMINATED BY ','
        MISSING FIELD VALUES ARE NULL
    )
    LOCATION ('CA-GrQc.csv')
)
/
INSERT INTO arcs_ca_grqc SELECT * FROM arcs_ca_grqc_ext
/
