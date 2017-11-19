# sql_demos - Brendan's repo for interesting SQL

This project stores the SQL code for solutions to interesting problems I have looked at on my blog,
or elsewhere. It includes installation scripts with object creation and data setup, and scripts to
run the SQL on the included datasets.

The idea is that anyone with the pre-requisites should be able to reproduce my results within a few 
minutes of downloading the repo.

The installation scripts will create a common objects schema, bren, and a separate schema for each
problem, of which there are three at present, bal_num_part, fan_foot and tsp. The SYS and bren 
objects are in the folder bren, with the problem-specific scripts in a separate folder for each one.

Links to blog or other sources:

1. fan_foot: 'SQL for the Fantasy Football Knapsack Problem'
   http://aprogrammerwrites.eu/?p=878
2. tsp: 'SQL for the Travelling Salesman Problem'
   http://aprogrammerwrites.eu/?p=896
3. bal_num_part: 'SQL for the Balanced Number Partitioning Problem'
   http://aprogrammerwrites.eu/?p=803
4. shortest_path: 'SQL for Shortest Path Problems'
   http://aprogrammerwrites.eu/?p=1391
   'SQL for Shortest Path Problems 2: A Branch and Bound Approach'
   http://aprogrammerwrites.eu/?p=1415

Pre-requisites
==============
In order to install this project you need to have SYS access to an Oracle database, minimum version
11.2, along with a suitable database server directory to use for loading data via external tables.

Install steps
=============
	
1. Update the logon script SYS.bat for your own credentials for the SYS schema
2. Update the logon scripts bren.bat, bal_num_part.bat, fan_foot.bat, tsp.bat with your own connect
string
3. Update Install_SYS.sql with the name of an input directory on your database server that
can be used for external tables to read from, and place all the files in db_server_input there
4. Run Install_SYS.sql in SYS schema from SQL*Plus, or other SQL client, to set up the bren
common schema, and the problem-specific schemas
5. Run Install_bren.sql in bren schema to create the bren schema common objects
6. Run Install_Bal_Num_Part.sql in bal_num_part schema to create the bal_num_part schema objects
7. Run Install_fan_foot.sql in fan_foot schema to create the fan_foot schema objects
8. Run Install_Shortest_Path.sql in shortest_path schema to create the shortest_path schema objects
9. Run Install_tsp.sql in tsp schema to create the tsp schema objects
10. Run Main_*.sql as desired in the specific schemas to run the SQL for the different datasets and
get execution plans and results logs. For example, for fan_foot: Main_Bra.sql and Main_Eng.sql are
the driving scripts

Video
=====
The installation is demonstrated in a short video (8 minutes). As it is 170MB in size I placed it in a
shared Microsoft One-Drive location:
https://1drv.ms/v/s!AtGOr6YOZ-yVh_1a6_g7XwX0TTBTgA