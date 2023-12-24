# TPC-DI
Recreated TPC-DI Benchmarking Test using PostgreSQL and Python


TO REPLICATE:

1- Data Generation using TPC-DI tools
2-Use SQLSchemaGen file to create the staging area's tables
3-Run FinwireFiles.py to convert various finwire files
4- Run WarehouseTables.sql to create the warehouse tables
5- Run transformations.sql for the historical load
