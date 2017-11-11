# sql_demos - Brendan's repo for interesting problems and solutions in SQL

This project stores the SQL code for solutions to interesting problems I have looked at on my blog,
or elsewhere. It includes installation scripts with object creation and data setup, and scripts to
run the SQL on the included datasets.

The idea is that anyone with the pre-requisites should be able to reproduce my results within a few 
minutes of downloading the repo.

The installation scripts will create a common objects schema, bren, and a separate schema for each
problem, of which there is only one at present, fan_foot. The SYS and bren objects are in the folder
bren, with the problem-specific scripts in a separate folder for each one.

Links to blog or other sources:

1. 'SQL for the Fantasy Football Knapsack Problem'
   http://aprogrammerwrites.eu/?p=878

Pre-requisites
==============
In order to install this project you need to have SYS access to an Oracle database, along with a 
suitable database server directory to use for loading data via external tables.

Install steps
=============
	
1. Update the logon script SYS.bat for your own credentials for the SYS schema
2. Update the logon scripts bren.bat and fan_foot.bat with your own connect string
3. Update Install_SYS.sql with the name of an input directory on your database server that
can be used for external tables to read from, and place the stats.txt file there (from 
db_server_input)
4. Run Install_SYS.sql in SYS schema from SQL*Plus, or other SQL client, to set up the bren
common schema, and the problem-specific schemas (currently just fan_foot)
5. Run Install_bren.sql in bren schema to create the bren schema common objects
6. Run Install_fan_foot.sql in fan_foot schema to create the fan_foot schema objects
7. Run Main_Bra.sql and Main_Eng.sql driving scripts to run the SQL on the two datasets using
pure SQL and a pipelined function solution