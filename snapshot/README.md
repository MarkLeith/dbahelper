#Snapshot creation scripts for performance schema
#contributed by Justin Swanhart 

To create the creates_XX.sql file use an INFORMATION_SCHEMA query:

    select concat('CREATE TABLE psmv.', table_name, ' (ts datetime(6), server_id int unsigned) as select * from  performance_schema.', table_name, ';') 
      from information_schema.tables 
     where table_schema='performance_schema' 
      into outfile '/tmp/creates_56.sql';

Then generate the event script using the provided php (just redirect output to the desired event script name):
    php make_collect_snapshot_event.php > collect_snapshot_event_56.php
