SET NAMES utf8;
SET sql_log_bin = 0;


DROP DATABASE IF EXISTS sys_helper;

CREATE DATABASE IF NOT EXISTS sys_helper;
ALTER DATABASE sys_helper DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE 'utf8_general_ci';

USE sys_helper;

DROP FUNCTION IF EXISTS format_bytes;

DELIMITER $$

CREATE FUNCTION format_bytes(bytes BIGINT)
  RETURNS VARCHAR(16) DETERMINISTIC
BEGIN
  IF bytes IS NULL THEN RETURN NULL;
  ELSEIF bytes >= 1125899906842624 THEN RETURN CONCAT(ROUND(bytes / 1125899906842624, 2), ' PiB');
  ELSEIF bytes >= 1099511627776 THEN RETURN CONCAT(ROUND(bytes / 1099511627776, 2), ' TiB');
  ELSEIF bytes >= 1073741824 THEN RETURN CONCAT(ROUND(bytes / 1073741824, 2), ' GiB');
  ELSEIF bytes >= 1048576 THEN RETURN CONCAT(ROUND(bytes / 1048576, 2), ' MiB');
  ELSEIF bytes >= 1024 THEN RETURN CONCAT(ROUND(bytes / 1024, 2), ' KiB');
  ELSE RETURN CONCAT(bytes, ' bytes');
  END IF;
END $$

DELIMITER ;

/* View: innodb_buffer_statistics_by_table
 * 
 * Summarizes the output of the INFORMATION_SCHEMA.INNODB_BUFFER_PAGE 
 * table, aggregating by schema and table name
 *
 */

DROP VIEW IF EXISTS innodb_buffer_statistics_by_table;

CREATE VIEW innodb_buffer_statistics_by_table AS
SELECT IF(LOCATE('.', ibp.table_name) = 0, 'InnoDB System', REPLACE(SUBSTRING_INDEX(ibp.table_name, '.', 1), '`', '')) AS object_schema,
       REPLACE(SUBSTRING_INDEX(ibp.table_name, '.', -1), '`', '') AS object_name,
       format_bytes(SUM(IF(ibp.compressed_size = 0, 16384, compressed_size))) AS innodb_buffer_allocated,
       format_bytes(SUM(ibp.data_size)) AS innodb_buffer_data,
       COUNT(ibp.page_number) AS innodb_buffer_pages,
       COUNT(IF(ibp.is_hashed = 'YES', 1, 0)) AS innodb_buffer_pages_hashed,
       COUNT(IF(ibp.is_old = 'YES', 1, 0)) AS innodb_buffer_pages_old,
       ROUND(SUM(ibp.number_records)/COUNT(DISTINCT ibp.index_name)) AS innodb_buffer_rows_cached 
  FROM information_schema.innodb_buffer_page ibp 
 WHERE table_name IS NOT NULL
 GROUP BY object_schema, object_name
 ORDER BY SUM(IF(ibp.compressed_size = 0, 16384, compressed_size)) DESC;


CREATE OR REPLACE VIEW version AS SELECT '1.0.1';

/*
 * Function: format_bytes()
 * 
 * Takes a raw bytes value, and converts it to a human readable form
 *
 * Parameters
 *   bytes: The raw bytes value to convert
 *
 * mysql> select format_bytes(2348723492723746);
 * +--------------------------------+
 * | format_bytes(2348723492723746) |
 * +--------------------------------+
 * | 2.09 PiB                       |
 * +--------------------------------+
 * 1 row in set (0.00 sec)
 * 
 * mysql> select format_bytes(2348723492723);
 * +-----------------------------+
 * | format_bytes(2348723492723) |
 * +-----------------------------+
 * | 2.14 TiB                    |
 * +-----------------------------+
 * 1 row in set (0.00 sec)
 * 
 * mysql> select format_bytes(23487234);
 * +------------------------+
 * | format_bytes(23487234) |
 * +------------------------+
 * | 22.40 MiB              |
 * +------------------------+
 * 1 row in set (0.00 sec)
 */




/*
 * Function: format_time()
 * 
 * Takes a raw picoseconds value, and converts it to a human readable form.
 * Picoseconds are the precision that all latency values are printed in 
 * within MySQL's Performance Schema.
 *
 * Parameters
 *   picoseconds: The raw picoseconds value to convert
 *
 * mysql> select format_time(342342342342345);
 * +------------------------------+
 * | format_time(342342342342345) |
 * +------------------------------+
 * | 00:05:42                     |
 * +------------------------------+
 * 1 row in set (0.00 sec)
 * 
 * mysql> select format_time(342342342);
 * +------------------------+
 * | format_time(342342342) |
 * +------------------------+
 * | 342.34 µs              |
 * +------------------------+
 * 1 row in set (0.00 sec)
 * 
 * mysql> select format_time(34234);
 * +--------------------+
 * | format_time(34234) |
 * +--------------------+
 * | 34.23 ns           |
 * +--------------------+
 * 1 row in set (0.00 sec)
 * 
 * mysql> select format_time(342);
 * +------------------+
 * | format_time(342) |
 * +------------------+
 * | 342 ps           |
 * +------------------+
 * 1 row in set (0.00 sec)
 */

DROP FUNCTION IF EXISTS format_time;

DELIMITER $$

CREATE FUNCTION format_time(picoseconds BIGINT UNSIGNED)
  RETURNS VARCHAR(16) CHARSET UTF8 DETERMINISTIC
BEGIN
  IF picoseconds IS NULL THEN RETURN NULL;
  ELSEIF picoseconds >= 3600000000000000 THEN RETURN CONCAT(ROUND(picoseconds / 3600000000000000, 2), 'h');
  ELSEIF picoseconds >= 60000000000000 THEN RETURN SEC_TO_TIME(ROUND(picoseconds / 1000000000000, 2));
  ELSEIF picoseconds >= 1000000000000 THEN RETURN CONCAT(ROUND(picoseconds / 1000000000000, 2), ' s');
  ELSEIF picoseconds >= 1000000000 THEN RETURN CONCAT(ROUND(picoseconds / 1000000000, 2), ' ms');
  ELSEIF picoseconds >= 1000000 THEN RETURN CONCAT(ROUND(picoseconds / 1000000, 2), ' us');
  ELSEIF picoseconds >= 1000 THEN RETURN CONCAT(ROUND(picoseconds / 1000, 2), ' ns');
  ELSE RETURN CONCAT(picoseconds, ' ps');
  END IF;
END $$

DELIMITER ;

/*
 * Function: format_path()
 * 
 * Takes a raw path value, and strips out the datadir or tmpdir
 * replacing with @@datadir and @@tmpdir respectively. 
 *
 * Also normalizes the paths across operating systems, so backslashes
 * on Windows are converted to forward slashes
 *
 * Parameters
 *   path: The raw file path value to format
 *
 * mysql> select @@datadir;
 * +-----------------------------------------------+
 * | @@datadir                                     |
 * +-----------------------------------------------+
 * | /Users/mark/sandboxes/SmallTree/AMaster/data/ |
 * +-----------------------------------------------+
 * 1 row in set (0.06 sec)
 * 
 * mysql> select format_path('/Users/mark/sandboxes/SmallTree/AMaster/data/mysql/proc.MYD');
 * +----------------------------------------------------------------------------+
 * | format_path('/Users/mark/sandboxes/SmallTree/AMaster/data/mysql/proc.MYD') |
 * +----------------------------------------------------------------------------+
 * | @@datadir/mysql/proc.MYD                                                   |
 * +----------------------------------------------------------------------------+
 * 1 row in set (0.03 sec)
 */

DROP FUNCTION IF EXISTS format_path;

DELIMITER $$

CREATE FUNCTION format_path(path VARCHAR(260))
  RETURNS VARCHAR(260) CHARSET UTF8 DETERMINISTIC
BEGIN
  DECLARE v_path VARCHAR(260);

  /* OSX hides /private/ in variables, but Performance Schema does not */
  IF path LIKE '/private/%' 
  THEN SET v_path = REPLACE(path, '/private', '');
  ELSE SET v_path = path;
  END IF;

  IF v_path IS NULL THEN RETURN NULL;
  ELSEIF v_path LIKE CONCAT(@@global.datadir, '%') ESCAPE '|' THEN 
    RETURN REPLACE(REPLACE(REPLACE(v_path, @@global.datadir, '@@datadir/'), '\\\\', ''), '\\', '/');
  ELSEIF v_path LIKE CONCAT(@@global.tmpdir, '%') ESCAPE '|' THEN 
    RETURN REPLACE(REPLACE(REPLACE(v_path, @@global.tmpdir, '@@tmpdir/'), '\\\\', ''), '\\', '/');
  ELSE RETURN v_path;
  END IF;
END$$

DELIMITER ;

/*
 * Function: extract_schema_from_file_name()
 * 
 * Takes a raw file path, and extracts the schema name from it
 *
 * Parameters
 *   path: The raw file name value to extract the schema name from
 */

DROP FUNCTION IF EXISTS extract_schema_from_file_name;

DELIMITER $$

CREATE FUNCTION extract_schema_from_file_name(path VARCHAR(512))
  RETURNS VARCHAR(512) DETERMINISTIC
  RETURN SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(path, '\\', '/'), '/', -2), '/', 1)
$$

DELIMITER ;

/*
 * Function: extract_table_from_file_name()
 * 
 * Takes a raw file path, and extracts the table name from it
 *
 * Parameters
 *   path: The raw file name value to extract the table name from
 */

DROP FUNCTION IF EXISTS extract_table_from_file_name;

DELIMITER $$

CREATE FUNCTION extract_table_from_file_name(path VARCHAR(512))
  RETURNS VARCHAR(512) DETERMINISTIC
  RETURN SUBSTRING_INDEX(REPLACE(SUBSTRING_INDEX(REPLACE(path, '\\', '/'), '/', -1), '@0024', '$'), '.', 1);
$$

DELIMITER ;

/*
 * Function: format_statement()
 * 
 * Formats a normalized statement with a truncated string if > 64 characters long
 *
 * Parameters
 *   filename: The raw file name value to extract the table name from
 */

DROP FUNCTION IF EXISTS format_statement;

DELIMITER $$

CREATE FUNCTION format_statement(statement LONGTEXT)
  RETURNS VARCHAR(65) DETERMINISTIC
BEGIN
  IF LENGTH(statement) > 64 THEN RETURN REPLACE(CONCAT(LEFT(statement, 30), ' ... ', RIGHT(statement, 30)), '\n', ' ');
  ELSE RETURN REPLACE(statement, '\n', ' ');
  END IF;
END $$

DELIMITER ;

/*
 * View: latest_file_io
 *
 * Latest file IO, by file / thread
 *
 * Versions: 5.5+
 *
 * mysql> select * from latest_file_io limit 10;
 * +----------------------+----------------------------------------+------------+-----------+-----------+
 * | thread               | file                                   | latency    | operation | requested |
 * +----------------------+----------------------------------------+------------+-----------+-----------+
 * | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 9.26 µs    | write     | 124 bytes |
 * | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 4.00 µs    | write     | 2 bytes   |
 * | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 56.34 µs   | close     | NULL      |
 * | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYD             | 53.93 µs   | close     | NULL      |
 * | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 104.05 ms  | delete    | NULL      |
 * | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYD             | 661.18 µs  | delete    | NULL      |
 * | msandbox@localhost:1 | @@datadir/Cerberus.log                 | 35.99 ms   | write     | 57 bytes  |
 * | msandbox@localhost:1 | @@datadir/sys_helper/latest_file_io.frm | 7.40 µs    | stat      | NULL      |
 * | msandbox@localhost:1 | @@datadir/sys_helper/latest_file_io.frm | 9.81 µs    | open      | NULL      |
 * | msandbox@localhost:1 | @@datadir/sys_helper/latest_file_io.frm | 16.06 µs   | read      | 3.17 KiB  |
 * +----------------------+----------------------------------------+------------+-----------+-----------+
 * 10 rows in set (0.05 sec)
 */

DROP VIEW IF EXISTS latest_file_io;

CREATE VIEW latest_file_io AS
SELECT IF(id IS NULL, 
             CONCAT(SUBSTRING_INDEX(name, '/', -1), ':', thread_id), 
             CONCAT(user, '@', host, ':', id)
          ) thread, 
       format_path(object_name) file, 
       format_time(timer_wait) AS latency, 
       operation, 
       format_bytes(number_of_bytes) AS requested
  FROM performance_schema.events_waits_history_long 
  JOIN performance_schema.threads USING (thread_id)
  LEFT JOIN information_schema.processlist ON processlist_id = id
 WHERE object_name IS NOT NULL
   AND event_name LIKE 'wait/io/file/%'
 ORDER BY timer_start;

/*
 * View: top_global_waits_by_latency
 *
 * Lists the top wait events by their total latency, ignoring idle (this may be very large)
 *
 * mysql> select * from top_global_waits_by_latency limit 5;
 * +--------------------------------------+--------------+---------------+-------------+-------------+
 * | event                                | total_events | total_latency | avg_latency | max_latency |
 * +--------------------------------------+--------------+---------------+-------------+-------------+
 * | wait/io/file/myisam/dfile            |   3623719744 | 00:47:49.09   | 791.70 ns   | 312.96 ms   |
 * | wait/io/table/sql/handler            |     69114944 | 00:44:30.74   | 38.64 us    | 879.49 ms   |
 * | wait/io/file/innodb/innodb_log_file  |     28100261 | 00:37:42.12   | 80.50 us    | 476.00 ms   |
 * | wait/io/socket/sql/client_connection |    200704863 | 00:18:37.81   | 5.57 us     | 1.27 s      |
 * | wait/io/file/innodb/innodb_data_file |      2829403 | 00:08:12.89   | 174.20 us   | 455.22 ms   |
 * +--------------------------------------+--------------+---------------+-------------+-------------+
 * 
 * Versions: 5.5+
 */

DROP VIEW IF EXISTS top_global_waits_by_latency;

CREATE VIEW top_global_waits_by_latency AS
SELECT event_name AS event,
       count_star AS total_events,
       format_time(sum_timer_wait) AS total_latency,
       format_time(avg_timer_wait) AS avg_latency,
       format_time(max_timer_wait) AS max_latency
  FROM performance_schema.events_waits_summary_global_by_event_name
 WHERE event_name != 'idle'
 ORDER BY sum_timer_wait DESC;

/*
 * View: top_global_consumers_by_avg_latency
 * 
 * Lists the top wait classes by average latency, ignoring idle (this may be very large)
 * 
 * Versions: 5.5+
 *
 * mysql> select * from top_global_consumers_by_avg_latency where event_class != 'idle';
 * +-------------------+--------------+---------------+-------------+-------------+-------------+
 * | event_class       | total_events | total_latency | min_latency | avg_latency | max_latency |
 * +-------------------+--------------+---------------+-------------+-------------+-------------+
 * | wait/io/file      |       543123 | 44.60 s       | 19.44 ns    | 82.11 µs    | 4.21 s      |
 * | wait/io/table     |        22002 | 766.60 ms     | 148.72 ns   | 34.84 µs    | 44.97 ms    |
 * | wait/io/socket    |        79613 | 967.17 ms     | 0 ps        | 12.15 µs    | 27.10 ms    |
 * | wait/lock/table   |        35409 | 18.68 ms      | 65.45 ns    | 527.51 ns   | 969.88 µs   |
 * | wait/synch/rwlock |        37935 | 4.61 ms       | 21.38 ns    | 121.61 ns   | 34.65 µs    |
 * | wait/synch/mutex  |       390622 | 18.60 ms      | 19.44 ns    | 47.61 ns    | 10.32 µs    |
 * +-------------------+--------------+---------------+-------------+-------------+-------------+
 *
 * (Example from 5.6.6)
 */

DROP VIEW IF EXISTS top_global_consumers_by_avg_latency;

CREATE VIEW top_global_consumers_by_avg_latency AS
SELECT SUBSTRING_INDEX(event_name,'/', 3) event_class,
       SUM(COUNT_STAR) total_events,
       format_time(CAST(SUM(sum_timer_wait) AS UNSIGNED)) total_latency,
       format_time(MIN(min_timer_wait)) min_latency,
       format_time(SUM(sum_timer_wait) / SUM(COUNT_STAR)) avg_latency,
       format_time(CAST(MAX(max_timer_wait) AS UNSIGNED)) max_latency
  FROM performance_schema.events_waits_summary_global_by_event_name
 WHERE sum_timer_wait > 0
 GROUP BY event_class
 ORDER BY SUM(sum_timer_wait) / SUM(COUNT_STAR) DESC;

/*
 * View: top_global_consumers_by_total_latency
 * 
 * Lists the top wait classes by total latency, ignoring idle (this may be very large)
 * 
 * Versions: 5.5+
 *
 * mysql> select * from top_global_consumers_by_total_latency where event_class != 'idle';
 * +-------------------+--------------+---------------+-------------+-------------+-------------+
 * | event_class       | total_events | total_latency | min_latency | avg_latency | max_latency |
 * +-------------------+--------------+---------------+-------------+-------------+-------------+
 * | wait/io/file      |       550470 | 46.01 s       | 19.44 ns    | 83.58 µs    | 4.21 s      |
 * | wait/io/socket    |       228833 | 2.71 s        | 0 ps        | 11.86 µs    | 29.93 ms    |
 * | wait/io/table     |        64063 | 1.89 s        | 99.79 ns    | 29.43 µs    | 68.07 ms    |
 * | wait/lock/table   |        76029 | 47.19 ms      | 65.45 ns    | 620.74 ns   | 969.88 µs   |
 * | wait/synch/mutex  |       635925 | 34.93 ms      | 19.44 ns    | 54.93 ns    | 107.70 µs   |
 * | wait/synch/rwlock |        61287 | 7.62 ms       | 21.38 ns    | 124.37 ns   | 34.65 µs    |
 * +-------------------+--------------+---------------+-------------+-------------+-------------+
 *
 * (Example from 5.6.6)
 */

DROP VIEW IF EXISTS top_global_consumers_by_total_latency;

CREATE VIEW top_global_consumers_by_total_latency AS
SELECT SUBSTRING_INDEX(event_name,'/', 3) event_class, 
       SUM(COUNT_STAR) total_events,
       format_time(SUM(sum_timer_wait)) total_latency,
       format_time(MIN(min_timer_wait)) min_latency,
       format_time(SUM(sum_timer_wait) / SUM(COUNT_STAR)) avg_latency,
       format_time(MAX(max_timer_wait)) max_latency
  FROM performance_schema.events_waits_summary_global_by_event_name
 WHERE sum_timer_wait > 0
   AND event_name != 'idle'
 GROUP BY SUBSTRING_INDEX(event_name,'/', 3) 
 ORDER BY SUM(sum_timer_wait) DESC;

/*
 * View: top_global_io_consumers_by_latency
 *
 * Show the top global IO consumers by latency, ignoring idle (this may be very large)
 *
 * Versions: 5.5+
 *
 * mysql> select * from top_global_io_consumers_by_latency;
 * +--------------------+------------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+
 * | event_name         | count_star | total_latency | min_latency | avg_latency | max_latency | count_read | total_read | avg_read  | count_write | total_written | avg_written |
 * +--------------------+------------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+
 * | sql/dbopt          |     328812 | 26.93 s       | 2.06 µs     | 81.90 µs    | 178.71 ms   |          0 | 0 bytes    | 0 bytes   |           9 | 585 bytes     | 65 bytes    |
 * | sql/FRM            |      57837 | 8.39 s        | 19.44 ns    | 145.13 µs   | 336.71 ms   |       8009 | 2.60 MiB   | 341 bytes |       14675 | 2.91 MiB      | 208 bytes   |
 * | sql/binlog         |        190 | 6.79 s        | 1.56 µs     | 35.76 ms    | 4.21 s      |         52 | 60.54 KiB  | 1.16 KiB  |           0 | 0 bytes       | 0 bytes     |
 * | sql/ERRMSG         |          5 | 2.03 s        | 8.61 µs     | 405.40 ms   | 2.03 s      |          3 | 51.82 KiB  | 17.27 KiB |           0 | 0 bytes       | 0 bytes     |
 * | myisam/dfile       |     163681 | 983.13 ms     | 379.08 ns   | 6.01 µs     | 22.06 ms    |      68721 | 127.23 MiB | 1.90 KiB  |     1011613 | 121.45 MiB    | 126 bytes   |
 * | sql/file_parser    |        419 | 601.37 ms     | 1.96 µs     | 1.44 ms     | 37.14 ms    |         66 | 42.01 KiB  | 652 bytes |          64 | 226.98 KiB    | 3.55 KiB    |
 * | myisam/kfile       |       1775 | 375.13 ms     | 1.02 µs     | 211.34 µs   | 35.15 ms    |      54034 | 9.97 MiB   | 193 bytes |      428001 | 12.39 MiB     | 30 bytes    |
 * | sql/global_ddl_log |        164 | 75.96 ms      | 5.72 µs     | 463.19 µs   | 7.43 ms     |         20 | 80.00 KiB  | 4.00 KiB  |          76 | 304.00 KiB    | 4.00 KiB    |
 * | sql/partition      |         81 | 18.87 ms      | 888.08 ns   | 232.92 µs   | 4.67 ms     |         66 | 2.75 KiB   | 43 bytes  |           8 | 288 bytes     | 36 bytes    |
 * | sql/misc           |         23 | 2.73 ms       | 65.14 µs    | 118.50 µs   | 255.31 µs   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
 * | sql/relaylog       |          7 | 1.18 ms       | 838.84 ns   | 168.30 µs   | 892.70 µs   |          0 | 0 bytes    | 0 bytes   |           1 | 120 bytes     | 120 bytes   |
 * | sql/binlog_index   |          5 | 593.47 µs     | 1.07 µs     | 118.69 µs   | 535.90 µs   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
 * | sql/pid            |          3 | 220.55 µs     | 29.29 µs    | 73.52 µs    | 143.11 µs   |          0 | 0 bytes    | 0 bytes   |           1 | 5 bytes       | 5 bytes     |
 * | mysys/charset      |          3 | 196.52 µs     | 17.61 µs    | 65.51 µs    | 137.33 µs   |          1 | 17.83 KiB  | 17.83 KiB |           0 | 0 bytes       | 0 bytes     |
 * | mysys/cnf          |          5 | 171.61 µs     | 303.26 ns   | 34.32 µs    | 115.21 µs   |          3 | 56 bytes   | 19 bytes  |           0 | 0 bytes       | 0 bytes     |
 * | sql/casetest       |          1 | 121.19 µs     | 121.19 µs   | 121.19 µs   | 121.19 µs   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
 * +--------------------+------------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+
 *
 * (Example from 5.6.6)
 */

DROP VIEW IF EXISTS top_global_io_consumers_by_latency;

CREATE VIEW top_global_io_consumers_by_latency AS
SELECT SUBSTRING_INDEX(event_name, '/', -2) event_name,
       ewsgben.count_star,
       format_time(ewsgben.sum_timer_wait) total_latency,
       format_time(ewsgben.min_timer_wait) min_latency,
       format_time(ewsgben.avg_timer_wait) avg_latency,
       format_time(ewsgben.max_timer_wait) max_latency,
       count_read,
       format_bytes(sum_number_of_bytes_read) total_read,
       format_bytes(IFNULL(sum_number_of_bytes_read / count_read, 0)) avg_read,
       count_write,
       format_bytes(sum_number_of_bytes_write) total_written,
       format_bytes(IFNULL(sum_number_of_bytes_write / count_write, 0)) avg_written
  FROM performance_schema.events_waits_summary_global_by_event_name AS ewsgben
  JOIN performance_schema.file_summary_by_event_name AS fsben USING (event_name) 
 WHERE event_name LIKE 'wait/io/file/%'
   AND ewsgben.count_star > 0
 ORDER BY ewsgben.sum_timer_wait DESC;

/*
 * View: top_global_io_consumers_by_bytes_usage
 *
 * Show the top global IO consumer classes by bytes usage
 *
 * Versions: 5.5+
 *
 * mysql> select * from top_global_io_consumers_by_bytes_usage;
 * +--------------------+------------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+-----------------+
 * | event_name         | count_star | total_latency | min_latency | avg_latency | max_latency | count_read | total_read | avg_read  | count_write | total_written | avg_written | total_requested |
 * +--------------------+------------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+-----------------+
 * | myisam/dfile       |     163681 | 983.13 ms     | 379.08 ns   | 6.01 µs     | 22.06 ms    |      68737 | 127.31 MiB | 1.90 KiB  |     1012221 | 121.52 MiB    | 126 bytes   | 248.83 MiB      |
 * | myisam/kfile       |       1775 | 375.13 ms     | 1.02 µs     | 211.34 µs   | 35.15 ms    |      54066 | 9.97 MiB   | 193 bytes |      428257 | 12.40 MiB     | 30 bytes    | 22.37 MiB       |
 * | sql/FRM            |      57889 | 8.40 s        | 19.44 ns    | 145.05 µs   | 336.71 ms   |       8009 | 2.60 MiB   | 341 bytes |       14675 | 2.91 MiB      | 208 bytes   | 5.51 MiB        |
 * | sql/global_ddl_log |        164 | 75.96 ms      | 5.72 µs     | 463.19 µs   | 7.43 ms     |         20 | 80.00 KiB  | 4.00 KiB  |          76 | 304.00 KiB    | 4.00 KiB    | 384.00 KiB      |
 * | sql/file_parser    |        419 | 601.37 ms     | 1.96 µs     | 1.44 ms     | 37.14 ms    |         66 | 42.01 KiB  | 652 bytes |          64 | 226.98 KiB    | 3.55 KiB    | 268.99 KiB      |
 * | sql/binlog         |        190 | 6.79 s        | 1.56 µs     | 35.76 ms    | 4.21 s      |         52 | 60.54 KiB  | 1.16 KiB  |           0 | 0 bytes       | 0 bytes     | 60.54 KiB       |
 * | sql/ERRMSG         |          5 | 2.03 s        | 8.61 µs     | 405.40 ms   | 2.03 s      |          3 | 51.82 KiB  | 17.27 KiB |           0 | 0 bytes       | 0 bytes     | 51.82 KiB       |
 * | mysys/charset      |          3 | 196.52 µs     | 17.61 µs    | 65.51 µs    | 137.33 µs   |          1 | 17.83 KiB  | 17.83 KiB |           0 | 0 bytes       | 0 bytes     | 17.83 KiB       |
 * | sql/partition      |         81 | 18.87 ms      | 888.08 ns   | 232.92 µs   | 4.67 ms     |         66 | 2.75 KiB   | 43 bytes  |           8 | 288 bytes     | 36 bytes    | 3.04 KiB        |
 * | sql/dbopt          |     329166 | 26.95 s       | 2.06 µs     | 81.89 µs    | 178.71 ms   |          0 | 0 bytes    | 0 bytes   |           9 | 585 bytes     | 65 bytes    | 585 bytes       |
 * | sql/relaylog       |          7 | 1.18 ms       | 838.84 ns   | 168.30 µs   | 892.70 µs   |          0 | 0 bytes    | 0 bytes   |           1 | 120 bytes     | 120 bytes   | 120 bytes       |
 * | mysys/cnf          |          5 | 171.61 µs     | 303.26 ns   | 34.32 µs    | 115.21 µs   |          3 | 56 bytes   | 19 bytes  |           0 | 0 bytes       | 0 bytes     | 56 bytes        |
 * | sql/pid            |          3 | 220.55 µs     | 29.29 µs    | 73.52 µs    | 143.11 µs   |          0 | 0 bytes    | 0 bytes   |           1 | 5 bytes       | 5 bytes     | 5 bytes         |
 * | sql/casetest       |          1 | 121.19 µs     | 121.19 µs   | 121.19 µs   | 121.19 µs   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     | 0 bytes         |
 * | sql/binlog_index   |          5 | 593.47 µs     | 1.07 µs     | 118.69 µs   | 535.90 µs   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     | 0 bytes         |
 * | sql/misc           |         23 | 2.73 ms       | 65.14 µs    | 118.50 µs   | 255.31 µs   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     | 0 bytes         |
 * +--------------------+------------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+-----------------+
 *
 * (Example from 5.6.6)
 */

DROP VIEW IF EXISTS top_global_io_consumers_by_bytes_usage;

CREATE VIEW top_global_io_consumers_by_bytes_usage AS
SELECT SUBSTRING_INDEX(event_name, '/', -2) event_name,
       ewsgben.count_star,
       format_time(ewsgben.sum_timer_wait) total_latency,
       format_time(ewsgben.min_timer_wait) min_latency,
       format_time(ewsgben.avg_timer_wait) avg_latency,
       format_time(ewsgben.max_timer_wait) max_latency,
       count_read,
       format_bytes(sum_number_of_bytes_read) total_read,
       format_bytes(IF(count_read > 0, sum_number_of_bytes_read / count_read, 0)) avg_read,
       count_write,
       format_bytes(sum_number_of_bytes_write) total_written,
       format_bytes(IF(count_write > 0, sum_number_of_bytes_write / count_write, 0)) avg_written,
       format_bytes(sum_number_of_bytes_write + sum_number_of_bytes_read) total_requested
  FROM performance_schema.events_waits_summary_global_by_event_name AS ewsgben
  JOIN performance_schema.file_summary_by_event_name AS fsben USING (event_name) 
 WHERE event_name LIKE 'wait/io/file/%' 
   AND ewsgben.count_star > 0
 ORDER BY sum_number_of_bytes_write + sum_number_of_bytes_read DESC;

/*
 * View: top_io_by_file
 *
 * Show the top global IO consumers by bytes usage by file
 *
 * Versions: 5.5+
 *
 * mysql> select * from top_io_by_file limit 10;
 * +-------------------------------------------------+------------+------------+-----------+-------------+---------------+-----------+------------+-----------+
 * | file                                            | count_read | total_read | avg_read  | count_write | total_written | avg_write | total      | write_pct |
 * +-------------------------------------------------+------------+------------+-----------+-------------+---------------+-----------+------------+-----------+
 * | @@datadir/mysql/user.MYD                        |      44829 | 21.61 MiB  | 505 bytes |           0 | 0 bytes       | 0 bytes   | 21.61 MiB  |      0.00 |
 * | @@datadir/mem/#sql-82c_2e.frm                   |       1932 | 562.54 KiB | 298 bytes |        5547 | 591.51 KiB    | 109 bytes | 1.13 MiB   |     51.26 |
 * | @@datadir/mem/#sql-82c_42.frm                   |        952 | 488.38 KiB | 525 bytes |        1415 | 560.55 KiB    | 406 bytes | 1.02 MiB   |     53.44 |
 * | @@datadir/mysql/proc.MYD                        |        633 | 291.77 KiB | 472 bytes |         227 | 167.51 KiB    | 756 bytes | 459.28 KiB |     36.47 |
 * | @@datadir/ddl_log.log                           |         20 | 80.00 KiB  | 4.00 KiB  |          76 | 304.00 KiB    | 4.00 KiB  | 384.00 KiB |     79.17 |
 * | @@datadir/mem/statement_explain_data.frm        |         23 | 176.76 KiB | 7.69 KiB  |          53 | 118.91 KiB    | 2.24 KiB  | 295.67 KiB |     40.22 |
 * | @@datadir/mem/inventory_instance_attributes.frm |         29 | 121.47 KiB | 4.19 KiB  |          42 | 62.35 KiB     | 1.48 KiB  | 183.82 KiB |     33.92 |
 * | @@datadir/mem/rule_eval_result_vars.frm         |         15 | 61.27 KiB  | 4.08 KiB  |          28 | 62.63 KiB     | 2.24 KiB  | 123.89 KiB |     50.55 |
 * | @@datadir/subjects.frm                          |         16 | 49.39 KiB  | 3.09 KiB  |          31 | 52.69 KiB     | 1.70 KiB  | 102.08 KiB |     51.61 |
 * | @@datadir/mem/statement_data.frm                |          8 | 33.02 KiB  | 4.13 KiB  |          35 | 69.01 KiB     | 1.97 KiB  | 102.04 KiB |     67.64 |
 * +-------------------------------------------------+------------+------------+-----------+-------------+---------------+-----------+------------+-----------+
 */

DROP VIEW IF EXISTS top_io_by_file;

CREATE VIEW top_io_by_file AS
SELECT format_path(file_name) AS file, 
       count_read, 
       format_bytes(sum_number_of_bytes_read) AS total_read,
       format_bytes(IF(count_read > 0, sum_number_of_bytes_read / count_read, 0)) avg_read,
       count_write, 
       format_bytes(sum_number_of_bytes_write) AS total_written,
       format_bytes(IF(count_write > 0, sum_number_of_bytes_write / count_write, 0)) avg_written,
       format_bytes(sum_number_of_bytes_read + sum_number_of_bytes_write) AS total, 
       IFNULL(ROUND(100-((sum_number_of_bytes_read/(sum_number_of_bytes_read+sum_number_of_bytes_write))*100), 2), 0.00) AS write_pct 
  FROM performance_schema.file_summary_by_instance
 ORDER BY sum_number_of_bytes_read + sum_number_of_bytes_write DESC;

/*
 * View: top_io_by_thread
 *
 * Show the top IO consumers by thread, ordered by total latency
 *
 * Versions: 5.5+
 *
 * mysql> select * from top_io_by_thread;
 * +----------------------+------------+---------------+-------------+-------------+-------------+-----------+----------------+
 * | user                 | count_star | total_latency | min_latency | avg_latency | max_latency | thread_id | processlist_id |
 * +----------------------+------------+---------------+-------------+-------------+-------------+-----------+----------------+
 * | main                 |       1248 | 8.92 s        | 303.26 ns   | 34.29 ms    | 4.21 s      |         1 |           NULL |
 * | root@localhost:58511 |       3404 | 4.92 s        | 442.91 ns   | 910.57 µs   | 193.99 ms   |        47 |             26 |
 * | root@localhost:59479 |      22985 | 3.33 s        | 417.31 ns   | 135.05 µs   | 23.93 ms    |       121 |            100 |
 * | manager              |        651 | 40.68 ms      | 6.71 µs     | 62.46 µs    | 5.43 ms     |        20 |           NULL |
 * +----------------------+------------+---------------+-------------+-------------+-------------+-----------+----------------+
 *
 * (Example taken from 5.6.6)
 */

DROP VIEW IF EXISTS top_io_by_thread;

CREATE VIEW top_io_by_thread AS
SELECT IF(id IS NULL, 
             SUBSTRING_INDEX(name, '/', -1), 
             CONCAT(user, '@', host)
          ) user, 
       SUM(count_star) count_star,
       format_time(SUM(sum_timer_wait)) total_latency,
       format_time(MIN(min_timer_wait)) min_latency,
       format_time(AVG(avg_timer_wait)) avg_latency,
       format_time(MAX(max_timer_wait)) max_latency,
       thread_id,
       id AS processlist_id
  FROM performance_schema.events_waits_summary_by_thread_by_event_name 
  LEFT JOIN performance_schema.threads USING (thread_id) 
  LEFT JOIN information_schema.processlist ON processlist_id = id
 WHERE event_name LIKE 'wait/io/file/%'
   AND sum_timer_wait > 0
 GROUP BY thread_id
 ORDER BY SUM(sum_timer_wait) DESC;

/*
 * View: top_tables_by_latency
 *
 * Lists the top tables by total latency recorded with Table IO
 *
 * Versions: 5.6.5+
 */

DROP VIEW IF EXISTS top_tables_by_latency;

CREATE VIEW top_tables_by_latency AS
SELECT object_schema AS db_name,
       object_name AS table_name,
       count_star AS total_events,
       format_time(sum_timer_wait) AS total_latency,
       format_time(avg_timer_wait) AS avg_latency,
       format_time(max_timer_wait) AS max_latency
  FROM performance_schema.objects_summary_global_by_type
 ORDER BY sum_timer_wait DESC;

/*
 * View: statement_analysis
 *
 * Lists a normalized statement view with aggregated statistics,
 * mimics the MySQL Enterprise Monitor Query Analysis view,
 * ordered by the total execution time per normalized statement
 *
 * Versions: 5.6.5+
 * 
 * mysql> select * from statement_analysis where query IS NOT NULL limit 10;
 * +-------------------------------------------------------------------+-----------+------------+-----------+------------+---------------+-------------+-------------+-----------+---------------+--------------+----------------------------------+
 * | query                                                             | full_scan | exec_count | err_count | warn_count | total_latency | max_latency | avg_latency | rows_sent | rows_sent_avg | rows_scanned | digest                           |
 * +-------------------------------------------------------------------+-----------+------------+-----------+------------+---------------+-------------+-------------+-----------+---------------+--------------+----------------------------------+
 * | COMMIT                                                            |           |      14477 |         0 |          0 | 2.68 s        | 319.99 ms   | 185.07 µs   |         0 |             0 |            0 | 08467ba5a1c5748b32cd7518509ef9a9 |
 * | SELECT `maptimeser0_` . `id` A ...  `maptimeser0_` . `hash` = ?   |           |       2190 |         0 |          0 | 399.22 ms     | 12.85 ms    | 182.09 µs   |      2190 |             1 |         2190 | a39256afecc105bb49acb266134f00be |
 * | SELECT `environmen0_` . `hid`  ... 393_0_` , `environmen0_` . ... |           |        996 |         0 |          0 | 347.44 ms     | 8.91 ms     | 348.61 µs   |       996 |             1 |          996 | ecea708cfd3d0909be4dedf676798e56 |
 * | SELECT `mysqlserve0_` . `hid`  ... , `mysqlserve0_` . `os` AS ... | *         |       1080 |         0 |          0 | 337.56 ms     | 6.49 ms     | 312.53 µs   |      1572 |             1 |         1572 | e9eac5233c5cb73ecb2e336283da0f55 |
 * | SELECT `this_` . `instance_att ... his_` . `attribute_id` = ? )   |           |       1070 |         0 |          0 | 201.62 ms     | 2.01 ms     | 188.38 µs   |         2 |             0 |            2 | 971dc9b0e9a864b40b1218ecf00ec66d |
 * | SELECT `identityna0_` . `id` A ... RE `identityna0_` . `id` = ?   |           |       1074 |         0 |          0 | 158.70 ms     | 7.43 ms     | 147.66 µs   |         0 |             0 |            0 | 0c55d5168c602404fdcd414ced10e2ee |
 * | SELECT `mysqlserve2_` . `hid`  ... ` WHERE `agent0_` . `id` = ?   | *         |        518 |         0 |          0 | 143.75 ms     | 2.65 ms     | 277.43 µs   |      1036 |             2 |         2072 | 3a0b0da99b4faaceb4ce7ecea64cd2ed |
 * | SELECT `agent0_` . `hid` AS `h ... ventory` . `Agent` `agent0_`   | *         |        510 |         0 |          0 | 115.21 ms     | 3.50 ms     | 225.79 µs   |       510 |             1 |          510 | 0d705eeb9f631f35f08bb828a995e0b8 |
 * | SELECT `network_in2_` . `hid`  ... WHERE `network0_` . `id` = ?   |           |        522 |         0 |          0 | 98.86 ms      | 422.11 µs   | 189.37 µs   |       108 |             0 |          216 | dc23c65f7d6201455c9da09214ca8bc9 |
 * | SELECT `network0_` . `hid` AS  ... 21_394_0_` , `network0_` . ... |           |        522 |         0 |          0 | 89.75 ms      | 374.44 µs   | 171.82 µs   |       522 |             1 |          522 | 759bfff4b6c0155fe043a5ad38c4a9f0 |
 * +-------------------------------------------------------------------+-----------+------------+-----------+------------+---------------+-------------+-------------+-----------+---------------+--------------+----------------------------------+
 *
 * (Example from 5.6.6)
 */

DROP VIEW IF EXISTS statement_analysis;

CREATE VIEW statement_analysis AS
SELECT format_statement(DIGEST_TEXT) AS query,
       IF(SUM_NO_GOOD_INDEX_USED > 0 OR SUM_NO_INDEX_USED > 0, '*', '') AS full_scan,
       COUNT_STAR AS exec_count,
       SUM_ERRORS AS err_count,
       SUM_WARNINGS AS warn_count,
       format_time(SUM_TIMER_WAIT) AS total_latency,
       format_time(MAX_TIMER_WAIT) AS max_latency,
       format_time(AVG_TIMER_WAIT) AS avg_latency,
       SUM_ROWS_SENT AS rows_sent,
       ROUND(SUM_ROWS_SENT / COUNT_STAR) AS rows_sent_avg,
       SUM_ROWS_EXAMINED AS rows_scanned,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
ORDER BY SUM_TIMER_WAIT DESC;

/*
 * View: digest_avg_latency_by_avg_us
 *
 * Helper view for digest_95th_percentile_by_avg_us
 *
 * Versions: 5.6.5+
 */
DROP VIEW IF EXISTS digest_avg_latency_by_avg_us;

CREATE VIEW digest_avg_latency_by_avg_us AS
SELECT COUNT(*) cnt, 
       ROUND(avg_timer_wait/1000000) AS avg_us
  FROM performance_schema.events_statements_summary_by_digest
 GROUP BY avg_us;

/*
 * View: digest_95th_percentile_by_avg_us
 *
 * List the 95th percentile runtime, for all statements
 *
 * Versions: 5.6.5+
 *
 * mysql> select * from digest_95th_percentile_by_avg_us;
 * +--------+------------+
 * | avg_us | percentile |
 * +--------+------------+
 * |    964 |     0.9525 |
 * +--------+------------+
 */
DROP VIEW IF EXISTS digest_95th_percentile_by_avg_us;

CREATE VIEW digest_95th_percentile_by_avg_us AS
SELECT s2.avg_us avg_us,
       SUM(s1.cnt)/(SELECT COUNT(*) FROM performance_schema.events_statements_summary_by_digest) percentile
  FROM digest_avg_latency_by_avg_us AS s1
  JOIN digest_avg_latency_by_avg_us AS s2
    ON s1.avg_us <= s2.avg_us
 GROUP BY s2.avg_us
HAVING percentile > 0.95
 ORDER BY percentile
 LIMIT 1;

/*
 * View: statements_with_runtimes_in_95th_percentile
 *
 * List all statements who's average runtime, in microseconds, is in the top 95th percentile.
 *
 * Versions: 5.6.5+
 *
 * mysql> select * from statements_with_runtimes_in_95th_percentile where query not like 'show%';
 * +-------------------------------------------------------------------+-----------+------------+-----------+------------+---------------+-------------+-------------+-----------+---------------+--------------+----------------------------------+
 * | query                                                             | full_scan | exec_count | err_count | warn_count | total_latency | max_latency | avg_latency | rows_sent | rows_sent_avg | rows_scanned | digest                           |
 * +-------------------------------------------------------------------+-----------+------------+-----------+------------+---------------+-------------+-------------+-----------+---------------+--------------+----------------------------------+
 * | SELECT plugin_name FROM inform ... tus = ? ORDER BY plugin_name   | *         |        169 |         0 |          0 | 2.37 s        | 64.45 ms    | 14.03 ms    |      4394 |            26 |        10816 | 23234b56a0b1f1e350bf51bef3050747 |
 * | SELECT `this_` . `target` AS ` ... D `this_` . `timestamp` <= ?   |           |        118 |         0 |          0 | 170.08 ms     | 5.68 ms     | 1.44 ms     |     13582 |           115 |        13582 | 34694223091aee1380c565076b7dfece |
 * | SELECT CAST ( SUM_NUMBER_OF_BY ... WHERE EVENT_NAME = ? LIMIT ?   | *         |        566 |         0 |          0 | 779.56 ms     | 2.93 ms     | 1.38 ms     |       342 |             1 |        17286 | 58d34495d29ad818e68c859e778b0dcb |
 * | SELECT `this_` . `target` AS ` ... D `this_` . `timestamp` <= ?   |           |        118 |         0 |          0 | 153.35 ms     | 3.06 ms     | 1.30 ms     |     13228 |           112 |        13228 | b816579565d5a2882cb8bd496193dc00 |
 * | SELECT `this_` . `target` AS ` ... D `this_` . `timestamp` <= ?   |           |        118 |         0 |          0 | 143.31 ms     | 4.57 ms     | 1.21 ms     |     13646 |           116 |        13646 | 27ff8681eb2c8cf999233e7507b439fe |
 * | SELECT `this_` . `target` AS ` ... D `this_` . `timestamp` <= ?   |           |        118 |         0 |          0 | 143.04 ms     | 7.22 ms     | 1.21 ms     |     13584 |           115 |        13584 | 10b863f20e83dcd9c7782dac249acbb0 |
 * | SELECT `this_` . `target` AS ` ... D `this_` . `timestamp` <= ?   |           |        118 |         0 |          0 | 137.46 ms     | 16.73 ms    | 1.16 ms     |     13922 |           118 |        13922 | 351ebc26af6babb67570843bcc97f6b0 |
 * | UPDATE `mem30__inventory` . `R ... mestamp` = ? WHERE `hid` = ?   |           |        114 |         0 |          0 | 127.64 ms     | 30.33 ms    | 1.12 ms     |         0 |             0 |          114 | f4ecf2aebe212e7ed250a0602d86c389 |
 * | UPDATE `mem30__inventory` . `I ... ` = ? , `hasOldBlocksTime` ... |           |         56 |         0 |          0 | 61.05 ms      | 16.41 ms    | 1.09 ms     |         0 |             0 |           56 | cdc78c70d83c505c5708847ba810d035 |
 * | SELECT `this_` . `target` AS ` ... D `this_` . `timestamp` <= ?   |           |        118 |         0 |          0 | 121.76 ms     | 1.95 ms     | 1.03 ms     |     13936 |           118 |        13936 | 20f97c53c2a59f5eadc06b2fa90fbe75 |
 * | UPDATE `mem30__inventory` . `M ... mpileOs` = ? WHERE `hid` = ?   |           |        114 |         0 |          0 | 114.16 ms     | 22.34 ms    | 1.00 ms     |         0 |             0 |          114 | c5d4a65f3f308f4869807e730739af6d |
 * | CALL `dc_string_insert` (...)                                     |           |         80 |         0 |          0 | 79.89 ms      | 2.62 ms     | 998.50 ┬╡s  |         0 |             0 |          240 | 93eb9cab8ced45cf3b98400e8803f8af |
 * | SELECT `this_` . `target` AS ` ... D `this_` . `timestamp` <= ?   |           |        118 |         0 |          0 | 116.19 ms     | 1.32 ms     | 984.60 ┬╡s  |     13484 |           114 |        13484 | bd23afed9a41367591e2b71dac76f334 |
 * +-------------------------------------------------------------------+-----------+------------+-----------+------------+---------------+-------------+-------------+-----------+---------------+--------------+----------------------------------+
 *
 * (Example from 5.6.6)
 */

DROP VIEW IF EXISTS statements_with_runtimes_in_95th_percentile;

CREATE VIEW statements_with_runtimes_in_95th_percentile AS
SELECT format_statement(DIGEST_TEXT) AS query,
       IF(SUM_NO_GOOD_INDEX_USED > 0 OR SUM_NO_INDEX_USED > 0, '*', '') AS full_scan,
       COUNT_STAR AS exec_count,
       SUM_ERRORS AS err_count,
       SUM_WARNINGS AS warn_count,
       format_time(SUM_TIMER_WAIT) AS total_latency,
       format_time(MAX_TIMER_WAIT) AS max_latency,
       format_time(AVG_TIMER_WAIT) AS avg_latency,
       SUM_ROWS_SENT AS rows_sent,
       ROUND(SUM_ROWS_SENT / COUNT_STAR) AS rows_sent_avg,
       SUM_ROWS_EXAMINED AS rows_scanned,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest stmts
  JOIN digest_95th_percentile_by_avg_us AS top_percentile
    ON ROUND(stmts.avg_timer_wait/1000000) >= top_percentile.avg_us
 ORDER BY AVG_TIMER_WAIT DESC;

/*
 * View: statements_with_temp_tables
 *
 * Lists all normalized statements that use temporary tables
 * ordered by number of on disk temporary tables descending first, 
 * then by the number of memory tables
 *
 * Versions: 5.6.5+
 *
 * mysql> select * from statement_analysis where query like 'select%' limit 5;
 * +-------------------------------------------------------------------+------------+-------------------+-----------------+--------------------------+------------------------+----------------------------------+
 * | query                                                             | exec_count | memory_tmp_tables | disk_tmp_tables | avg_tmp_tables_per_query | tmp_tables_to_disk_pct | digest                           |
 * +-------------------------------------------------------------------+------------+-------------------+-----------------+--------------------------+------------------------+----------------------------------+
 * | SELECT DISTINCTROW `hibalarm0_ ... testeval2_` . `alarm_id` = ... |          5 |                15 |               5 |                        3 |                     33 | ad6024cfc2db562ae268b25e65ef27c0 |
 * | SELECT DISTINCTROW `hibalarm0_ ... testeval2_` . `alarm_id` = ... |          2 |                 6 |               2 |                        3 |                     33 | 4aac3ab9521a432ff03313a69cfcc58f |
 * | SELECT SQL_CALC_FOUND_ROWS `st ...  , MIN ( `min_exec_time` ) ... |          1 |                 3 |               1 |                        3 |                     33 | c6df6711da3d1a26bc136dc8b354f6eb |
 * | SELECT COUNT ( DISTINCTROW `hi ... `hibevalres4_` . `time` DESC   |          5 |                15 |               0 |                        3 |                      0 | 12e0392402780424c736c9555bcc9703 |
 * | SELECT `hibrulesch1_` . `insta ... ` , `hibevalres2_` . `level`   |          5 |                 5 |               0 |                        1 |                      0 | a12cabd32d1507c758c71478075f5290 |
 * +-------------------------------------------------------------------+------------+-------------------+-----------------+--------------------------+------------------------+----------------------------------+
 *
 * (Example from 5.6.6)
 */

DROP VIEW IF EXISTS statements_with_temp_tables;

CREATE VIEW statements_with_temp_tables AS
SELECT format_statement(DIGEST_TEXT) AS query,
       COUNT_STAR AS exec_count,
       SUM_CREATED_TMP_TABLES AS memory_tmp_tables,
       SUM_CREATED_TMP_DISK_TABLES AS disk_tmp_tables,
       ROUND(SUM_CREATED_TMP_TABLES / COUNT_STAR) AS avg_tmp_tables_per_query,
       ROUND((SUM_CREATED_TMP_DISK_TABLES / SUM_CREATED_TMP_TABLES) * 100) AS tmp_tables_to_disk_pct,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
 WHERE SUM_CREATED_TMP_TABLES > 0
ORDER BY SUM_CREATED_TMP_DISK_TABLES DESC, SUM_CREATED_TMP_TABLES DESC;

/*
 * View: statements_with_sorting
 *
 * List all normalized statements that have done sorts,
 * ordered by sort_merge_passes, sort_scans and sort_rows, all descending
 * 
 * Versions 5.6.5+
 *
 * mysql> select * from sys_helper.statements_with_sorting;
 * +-------------------------------------------------------------------+------------+-------------------+-----------------+-------------------+------------------+-------------+-----------------+----------------------------------+
 * | query                                                             | exec_count | sort_merge_passes | avg_sort_merges | sorts_using_scans | sort_using_range | rows_sorted | avg_rows_sorted | digest                           |
 * +-------------------------------------------------------------------+------------+-------------------+-----------------+-------------------+------------------+-------------+-----------------+----------------------------------+
 * | SELECT * FROM sys_helper . statements_with_sorting                 |          7 |                 0 |               0 |                 7 |                0 |          31 |               4 | 635d19e3e652972b3267ada0bf9c7b36 |
 * | SELECT * FROM statement_analysis                                  |          4 |                 0 |               0 |                 4 |                0 |          89 |              22 | 10f918a1a410f4fa0fc2602cff02deb7 |
 * | SELECT table_schema , SUM ( da ... tables GROUP BY table_schema   |          2 |                 0 |               0 |                 2 |                0 |          24 |              12 | 27fecd44f0bf5c0fc4e46f547083a09d |
 * | SELECT * FROM statements_with_sorting                             |          2 |                 0 |               0 |                 2 |                0 |           3 |               2 | dc117dd0eb81394322e3d4144a997ffc |
 * +-------------------------------------------------------------------+------------+-------------------+-----------------+-------------------+------------------+-------------+-----------------+----------------------------------+
 */

DROP VIEW IF EXISTS statements_with_sorting;

CREATE VIEW statements_with_sorting AS
SELECT format_statement(DIGEST_TEXT) AS query,
       COUNT_STAR AS exec_count,
       SUM_SORT_MERGE_PASSES AS sort_merge_passes,
       ROUND(SUM_SORT_MERGE_PASSES / COUNT_STAR) AS avg_sort_merges,
       SUM_SORT_SCAN AS sorts_using_scans,
       SUM_SORT_RANGE AS sort_using_range,
       SUM_SORT_ROWS AS rows_sorted,
       ROUND(SUM_SORT_ROWS / COUNT_STAR) AS avg_rows_sorted,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
 WHERE SUM_SORT_ROWS > 0
 ORDER BY SUM_SORT_MERGE_PASSES DESC, SUM_SORT_SCAN DESC, SUM_SORT_ROWS DESC;


/*
 * View: statements_with_full_table_scans
 *
 * Lists all normalized statements that use have done a full table scan
 * ordered by number the percentage of times a full scan was done,
 * then by the number of times the statement executed
 *
 * Versions: 5.6.5+
 *
 * mysql> select * from statements_with_full_table_scans limit 5;
 * +-------------------------------------------------------------------+------------+-------------------+-----------------+--------------------------+------------------------+----------------------------------+
 * | query                                                             | exec_count | memory_tmp_tables | disk_tmp_tables | avg_tmp_tables_per_query | tmp_tables_to_disk_pct | digest                           |
 * +-------------------------------------------------------------------+------------+-------------------+-----------------+--------------------------+------------------------+----------------------------------+
 * | SELECT DISTINCTROW `hibalarm0_ ... testeval2_` . `alarm_id` = ... |          5 |                15 |               5 |                        3 |                     33 | ad6024cfc2db562ae268b25e65ef27c0 |
 * | SELECT DISTINCTROW `hibalarm0_ ... testeval2_` . `alarm_id` = ... |          2 |                 6 |               2 |                        3 |                     33 | 4aac3ab9521a432ff03313a69cfcc58f |
 * | SELECT SQL_CALC_FOUND_ROWS `st ...  , MIN ( `min_exec_time` ) ... |          1 |                 3 |               1 |                        3 |                     33 | c6df6711da3d1a26bc136dc8b354f6eb |
 * | SELECT COUNT ( DISTINCTROW `hi ... `hibevalres4_` . `time` DESC   |          5 |                15 |               0 |                        3 |                      0 | 12e0392402780424c736c9555bcc9703 |
 * | SELECT `hibrulesch1_` . `insta ... ` , `hibevalres2_` . `level`   |          5 |                 5 |               0 |                        1 |                      0 | a12cabd32d1507c758c71478075f5290 |
 * +-------------------------------------------------------------------+------------+-------------------+-----------------+--------------------------+------------------------+----------------------------------+
 *
 * (Example from 5.6.6)
 */

DROP VIEW IF EXISTS statements_with_full_table_scans;

CREATE VIEW statements_with_full_table_scans AS
SELECT format_statement(DIGEST_TEXT) AS query,
       COUNT_STAR AS exec_count,
       SUM_NO_INDEX_USED AS no_index_used_count,
       SUM_NO_GOOD_INDEX_USED AS no_good_index_used_count,
       ROUND((SUM_NO_INDEX_USED / COUNT_STAR) * 100) no_index_used_pct,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
 WHERE SUM_NO_INDEX_USED > 0
    OR SUM_NO_GOOD_INDEX_USED > 0
ORDER BY no_index_used_pct DESC, exec_count DESC;

/*
 * View: statements_with_errors_or_warnings
 *
 * List all normalized statements that have raised errors or warnings.
 * 
 * Versions 5.6.5+
 *
 * mysql> select * from statements_with_errors_or_warnings;
 * +-------------------------------------------------------------------+------------+--------+-----------+----------+-------------+----------------------------------+
 * | query                                                             | exec_count | errors | error_pct | warnings | warning_pct | digest                           |
 * +-------------------------------------------------------------------+------------+--------+-----------+----------+-------------+----------------------------------+
 * | CREATE PROCEDURE currently_ena ... w_instruments BOOLEAN DEFAULT  |          2 |      2 |  100.0000 |        0 |      0.0000 | ad6024cfc2db562ae268b25e65ef27c0 |
 * | CREATE PROCEDURE currently_ena ... ents WHERE enabled = ? ; END   |          2 |      1 |   50.0000 |        0 |      0.0000 | 4aac3ab9521a432ff03313a69cfcc58f |
 * | CREATE PROCEDURE currently_enabled ( BOOLEAN show_instruments     |          1 |      1 |  100.0000 |        0 |      0.0000 | c6df6711da3d1a26bc136dc8b354f6eb |
 * | CREATE PROCEDURE disable_backg ... d = ? WHERE TYPE = ? ; END IF  |          1 |      1 |  100.0000 |        0 |      0.0000 | 12e0392402780424c736c9555bcc9703 |
 * | DROP PROCEDURE IF EXISTS currently_enabled                        |         12 |      0 |    0.0000 |        6 |     50.0000 | 44cc7e655d08f430e0dd8f3110ed816c |
 * | DROP PROCEDURE IF EXISTS disable_background_threads               |          3 |      0 |    0.0000 |        2 |     66.6667 | 0153b7158dae80672bda6181c73f172c |
 * | CREATE SCHEMA IF NOT EXISTS sys_helper                             |          2 |      0 |    0.0000 |        1 |     50.0000 | a12cabd32d1507c758c71478075f5290 |
 * +-------------------------------------------------------------------+------------+--------+-----------+----------+-------------+----------------------------------+
 */

DROP VIEW IF EXISTS statements_with_errors_or_warnings;

CREATE VIEW statements_with_errors_or_warnings AS
SELECT format_statement(DIGEST_TEXT) AS query,
       COUNT_STAR AS exec_count,
       SUM_ERRORS AS errors,
       (SUM_ERRORS / COUNT_STAR) * 100 as error_pct,
       SUM_WARNINGS AS warnings,
       (SUM_WARNINGS / COUNT_STAR) * 100 as warning_pct,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
 WHERE SUM_ERRORS > 0
    OR SUM_WARNINGS > 0
ORDER BY SUM_ERRORS DESC, SUM_WARNINGS DESC;

/* 
 * View: schema_table_statistics
 *
 * Mimic TABLE_STATISTICS from Google et al ordered by the total wait time descending
 *
 * Versions: 5.6.2+
 *
 * mysql> select * from schema_table_statistics limit 1\G
 * *************************** 1. row ***************************
 *                  table_schema: mem
 *                    table_name: mysqlserver
 *                  rows_fetched: 27087
 *                 fetch_latency: 442.72 ms
 *                 rows_inserted: 2
 *                insert_latency: 185.04 µs 
 *                  rows_updated: 5096
 *                update_latency: 1.39 s
 *                  rows_deleted: 0
 *                delete_latency: 0 ps
 *              io_read_requests: 2565
 *                 io_read_bytes: 1121627
 *               io_read_latency: 10.07 ms
 *             io_write_requests: 1691
 *                io_write_bytes: 128383
 *              io_write_latency: 14.17 ms
 *              io_misc_requests: 2698
 *               io_misc_latency: 433.66 ms
 * 
 * (Example from 5.6.6)
 */ 
 
DROP VIEW IF EXISTS schema_table_statistics;

CREATE VIEW schema_table_statistics AS 
SELECT pst.object_schema AS table_schema,
       pst.object_name AS table_name,
       pst.count_fetch AS rows_fetched,
       format_time(pst.sum_timer_fetch) AS fetch_latency,
       pst.count_insert AS rows_inserted,
       format_time(pst.sum_timer_insert) AS insert_latency,
       pst.count_update AS rows_updated,
       format_time(pst.sum_timer_update) AS update_latency,
       pst.count_delete AS rows_deleted,
       format_time(pst.sum_timer_delete) AS delete_latency,
       SUM(fsbi.count_read) AS io_read_requests,
       format_bytes(SUM(fsbi.sum_number_of_bytes_read)) AS io_read,
       format_time(SUM(fsbi.sum_timer_read)) AS io_read_latency,
       SUM(fsbi.count_write) AS io_write_requests,
       format_bytes(SUM(fsbi.sum_number_of_bytes_write)) AS io_write,
       format_time(SUM(fsbi.sum_timer_write)) AS io_write_latency,
       SUM(fsbi.count_misc) AS io_misc_requests,
       format_time(SUM(fsbi.sum_timer_misc)) AS io_misc_latency
  FROM performance_schema.table_io_waits_summary_by_table AS pst
  LEFT JOIN performance_schema.file_summary_by_instance AS fsbi
    ON pst.object_schema = extract_schema_from_file_name(fsbi.file_name)
   AND pst.object_name = extract_table_from_file_name(fsbi.file_name)
 GROUP BY pst.object_schema, pst.object_name
 ORDER BY pst.sum_timer_wait DESC;

/* 
 * View: schema_table_statistics_with_buffer
 *
 * Mimic TABLE_STATISTICS from Google et al
 * However, order by the total wait time descending, and add in more statistics
 * such as caching stats for the InnoDB buffer pool with InnoDB tables
 *
 * Versions: 5.6.2+
 *
 * mysql> select * from schema_table_statistics_with_buffer limit 1\G
 * *************************** 1. row ***************************
 *                  table_schema: mem
 *                    table_name: mysqlserver
 *                  rows_fetched: 27087
 *                 fetch_latency: 442.72 ms
 *                 rows_inserted: 2
 *                insert_latency: 185.04 µs 
 *                  rows_updated: 5096
 *                update_latency: 1.39 s
 *                  rows_deleted: 0
 *                delete_latency: 0 ps
 *              io_read_requests: 2565
 *                 io_read_bytes: 1121627
 *               io_read_latency: 10.07 ms
 *             io_write_requests: 1691
 *                io_write_bytes: 128383
 *              io_write_latency: 14.17 ms
 *              io_misc_requests: 2698
 *               io_misc_latency: 433.66 ms
 *           innodb_buffer_pages: 19
 *    innodb_buffer_pages_hashed: 19
 *       innodb_buffer_pages_old: 19
 * innodb_buffer_bytes_allocated: 311296
 *      innodb_buffer_bytes_data: 1924
 *     innodb_buffer_rows_cached: 2
 * 
 * (Example from 5.6.6)
 */ 
 
DROP VIEW IF EXISTS schema_table_statistics_with_buffer;

CREATE VIEW schema_table_statistics_with_buffer AS 
SELECT pst.object_schema AS table_schema,
       pst.object_name AS table_name,
       pst.count_fetch AS rows_fetched,
       format_time(pst.sum_timer_fetch) AS fetch_latency,
       pst.count_insert AS rows_inserted,
       format_time(pst.sum_timer_insert) AS insert_latency,
       pst.count_update AS rows_updated,
       format_time(pst.sum_timer_update) AS update_latency,
       pst.count_delete AS rows_deleted,
       format_time(pst.sum_timer_delete) AS delete_latency,
       SUM(fsbi.count_read) AS io_read_requests,
       format_bytes(SUM(fsbi.sum_number_of_bytes_read)) AS io_read,
       format_time(SUM(fsbi.sum_timer_read)) AS io_read_latency,
       SUM(fsbi.count_write) AS io_write_requests,
       format_bytes(SUM(fsbi.sum_number_of_bytes_write)) AS io_write,
       format_time(SUM(fsbi.sum_timer_write)) AS io_write_latency,
       SUM(fsbi.count_misc) AS io_misc_requests,
       format_time(SUM(fsbi.sum_timer_misc)) AS io_misc_latency,
       ibp.innodb_buffer_allocated,
       ibp.innodb_buffer_data,
       ibp.innodb_buffer_pages,
       ibp.innodb_buffer_pages_hashed,
       ibp.innodb_buffer_pages_old,
       ibp.innodb_buffer_rows_cached
  FROM performance_schema.table_io_waits_summary_by_table AS pst
  LEFT JOIN performance_schema.file_summary_by_instance AS fsbi
    ON pst.object_schema = extract_schema_from_file_name(fsbi.file_name)
   AND pst.object_name = extract_table_from_file_name(fsbi.file_name)
  LEFT JOIN sys_helper.innodb_buffer_statistics_by_table AS ibp
    ON pst.object_schema = ibp.object_schema
   AND pst.object_name = ibp.object_name
 GROUP BY pst.object_schema, pst.object_name
 ORDER BY pst.sum_timer_wait DESC;
 
/*
 * View: schema_index_statistics
 *
 * Mimic INDEX_STATISTICS from Google et al
 * However, order by the total wait time descending - top indexes are most contended
 *
 * Versions: 5.6.2+
 *
 * mysql> select * from schema_index_statistics limit 10;
 * +------------------+-------------+------------+---------------+----------------+---------------+----------------+--------------+----------------+--------------+----------------+
 * | table_schema     | table_name  | index_name | rows_selected | select_latency | rows_inserted | insert_latency | rows_updated | update_latency | rows_deleted | delete_latency |
 * +------------------+-------------+------------+---------------+----------------+---------------+----------------+--------------+----------------+--------------+----------------+
 * | mem              | mysqlserver | PRIMARY    |          6208 | 108.27 ms      |             0 | 0 ps           |         5470 | 1.47 s         |            0 | 0 ps           |
 * | mem              | innodb      | PRIMARY    |          4666 | 76.27 ms       |             0 | 0 ps           |         4454 | 571.47 ms      |            0 | 0 ps           |
 * | mem              | connection  | PRIMARY    |          1064 | 20.98 ms       |             0 | 0 ps           |         1064 | 457.30 ms      |            0 | 0 ps           |
 * | mem              | environment | PRIMARY    |          5566 | 151.17 ms      |             0 | 0 ps           |          694 | 252.57 ms      |            0 | 0 ps           |
 * | mem              | querycache  | PRIMARY    |          1698 | 27.99 ms       |             0 | 0 ps           |         1698 | 371.72 ms      |            0 | 0 ps           |
 * | mem              | mysqlserver | id         |         19984 | 342.09 ms      |             0 | 0 ps           |            0 | 0 ps           |            0 | 0 ps           |
 * | mem              | network     | PRIMARY    |         12601 | 145.69 ms      |             0 | 0 ps           |         9790 | 176.48 ms      |            0 | 0 ps           |
 * | mem              | network     | id         |         17419 | 308.82 ms      |             0 | 0 ps           |            0 | 0 ps           |            0 | 0 ps           |
 * | mem              | myisam      | PRIMARY    |           638 | 13.93 ms       |             0 | 0 ps           |          638 | 243.92 ms      |            0 | 0 ps           |
 * | mem              | os          | PRIMARY    |           801 | 16.59 ms       |             0 | 0 ps           |          608 | 186.98 ms      |            0 | 0 ps           |
 * +------------------+-------------+------------+---------------+----------------+---------------+----------------+--------------+----------------+--------------+----------------+
 *
 * (Example from 5.6.6)
 */

DROP VIEW IF EXISTS schema_index_statistics;

CREATE VIEW schema_index_statistics AS
SELECT OBJECT_SCHEMA AS table_schema,
       OBJECT_NAME AS table_name,
       INDEX_NAME as index_name,
       COUNT_FETCH AS rows_selected,
       format_time(SUM_TIMER_FETCH) AS select_latency,
       COUNT_INSERT AS rows_inserted,
       format_time(SUM_TIMER_INSERT) AS insert_latency,
       COUNT_UPDATE AS rows_updated,
       format_time(SUM_TIMER_UPDATE) AS update_latency,
       COUNT_DELETE AS rows_deleted,
       format_time(SUM_TIMER_INSERT) AS delete_latency
  FROM performance_schema.table_io_waits_summary_by_index_usage
 WHERE index_name IS NOT NULL
 ORDER BY sum_timer_wait DESC;

/* 
 * View: schema_unused_indexes
 * 
 * Find indexes that have had no events against them (and hence, no usage)
 *
 * Versions: 5.6.2+
 *
 * mysql> select * from schema_unused_indexes;
 * +---------------------------+-------------------------------+--------------------------------------------------------+
 * | object_schema             | object_name                   | index_name                                             |
 * +---------------------------+-------------------------------+--------------------------------------------------------+
 * | mem                       | dc_p_double                   | PRIMARY                                                |
 * | mem                       | dc_p_double                   | end_time                                               |
 * | mem                       | dc_p_long                     | PRIMARY                                                |
 * | mem                       | dc_p_long                     | end_time                                               |
 * | mem                       | dc_p_string                   | begin_time                                             |
 * | mem                       | dc_p_string                   | end_time                                               |
 * ...
 */

DROP VIEW IF EXISTS schema_unused_indexes;
 
CREATE VIEW schema_unused_indexes AS
SELECT object_schema,
       object_name,
       index_name
  FROM performance_schema.table_io_waits_summary_by_index_usage 
 WHERE index_name IS NOT NULL
   AND count_star = 0
 ORDER BY object_schema, object_name;

/* 
 * View: schema_tables_with_full_table_scans
 *
 * Find tables that are being accessed by full table scans
 * ordering by the number of rows scanned descending
 *
 * Versions: 5.6.2+
 *
 * mysql> select * from schema_tables_with_full_table_scans limit 5;
 * +------------------+-------------------+-------------------+
 * | object_schema    | object_name       | rows_full_scanned |
 * +------------------+-------------------+-------------------+
 * | mem              | rule_alarms       |              1210 |
 * | mem30__advisors  | advisor_schedules |              1021 |
 * | mem30__inventory | agent             |               498 |
 * | mem              | dc_p_string       |               449 |
 * | mem30__inventory | mysqlserver       |               294 |
 * +------------------+-------------------+-------------------+
 */

DROP VIEW IF EXISTS schema_tables_with_full_table_scans;

CREATE VIEW schema_tables_with_full_table_scans AS
SELECT object_schema, 
       object_name,
       count_read AS rows_full_scanned
  FROM performance_schema.table_io_waits_summary_by_index_usage 
 WHERE index_name IS NULL
   AND count_read > 0
 ORDER BY count_read DESC;

/*
 * View: processlist_full
 *
 * A detailed non-blocking processlist view to replace 
 * [INFORMATION_SCHEMA. | SHOW FULL] PROCESSLIST
 *
 * Versions: 5.6.2+
 *
 * mysql> select * from processlist_full where conn_id is not null\G
 * ...
 * *************************** 8. row ***************************
 *                 thd_id: 12400
 *                conn_id: 12379
 *                   user: root@localhost
 *                     db: sys_helper
 *                command: Query
 *                  state: Copying to tmp table
 *                   time: 0
 *      current_statement: select * from processlist_full where conn_id is not null
 *         last_statement: NULL
 * last_statement_latency: NULL
 *           lock_latency: 1.00 ms
 *          rows_examined: 0
 *              rows_sent: 0
 *          rows_affected: 0
 *             tmp_tables: 1
 *        tmp_disk_tables: 0
 *              full_scan: YES
 *              last_wait: wait/synch/mutex/sql/THD::LOCK_thd_data
 *      last_wait_latency: 62.53 ns
 *                 source: sql_class.h:3843
 */
 
DROP VIEW IF EXISTS processlist_full;

CREATE VIEW processlist_full AS
SELECT pps.thread_id AS thd_id,
       pps.processlist_id AS conn_id,
       IF(pps.name = 'thread/sql/one_connection', 
          CONCAT(pps.processlist_user, '@', pps.processlist_host), 
          REPLACE(pps.name, 'thread/', '')) user,
       pps.processlist_db AS db,
       pps.processlist_command AS command,
       pps.processlist_state AS state,
       pps.processlist_time AS time,
       format_statement(pps.processlist_info) AS current_statement,
       IF(esc.timer_wait IS NOT NULL,
          format_statement(esc.sql_text),
          NULL) AS last_statement,
       IF(esc.timer_wait IS NOT NULL,
          format_time(esc.timer_wait),
          NULL) as last_statement_latency,
       format_time(esc.lock_time) AS lock_latency,
       esc.rows_examined,
       esc.rows_sent,
       esc.rows_affected,
       esc.created_tmp_tables AS tmp_tables,
       esc.created_tmp_disk_tables as tmp_disk_tables,
       IF(esc.no_good_index_used > 0 OR esc.no_index_used > 0, 
          'YES', 'NO') AS full_scan,
       ewc.event_name AS last_wait,
       IF(ewc.timer_wait IS NULL AND ewc.event_name IS NOT NULL, 
          'Still Waiting', 
          format_time(ewc.timer_wait)) last_wait_latency,
       ewc.source
  FROM performance_schema.threads AS pps
  LEFT JOIN performance_schema.events_waits_current AS ewc USING (thread_id)
  LEFT JOIN performance_schema.events_statements_current as esc USING (thread_id)
ORDER BY pps.processlist_time DESC, last_wait_latency DESC;

/*
 * View: top_users_by_statement_latency
 *
 * Versions: 5.6.3+
 */

DROP VIEW IF EXISTS top_users_by_statement_latency;

CREATE VIEW top_users_by_statement_latency AS
SELECT user,
       SUM(count_star) AS total_statements,
       format_time(SUM(sum_timer_wait)) AS total_latency,
       format_time(SUM(sum_timer_wait) / SUM(count_star)) AS avg_latency
  FROM performance_schema.events_statements_summary_by_user_by_event_name
 WHERE user IS NOT NULL
 GROUP BY user
 ORDER BY SUM(sum_timer_wait) DESC
 LIMIT 5;

/*
 * View: user_summary_by_stages
 *
 * Versions: 5.6.3+
 */

DROP VIEW IF EXISTS user_summary_by_stages;

CREATE VIEW user_summary_by_stages AS
SELECT user, event_name,
       count_star AS count,
       format_time(sum_timer_wait) AS wait_sum, 
       format_time(avg_timer_wait) AS wait_avg 
  FROM performance_schema.events_stages_summary_by_user_by_event_name
 WHERE user IS NOT NULL 
   AND sum_timer_wait != 0 
 ORDER BY user, sum_timer_wait DESC;

/*
 * View: user_summary_by_statement_type
 *
 * Versions: 5.6.3+
 */

DROP VIEW IF EXISTS user_summary_by_statement_type;

CREATE VIEW user_summary_by_statement_type AS
SELECT user,
       SUBSTRING_INDEX(event_name, '/', -1) AS statement,
       count_star AS count,
       format_time(sum_timer_wait) AS total_latency,
       format_time(max_timer_wait) AS max_latency,
       format_time(sum_lock_time) AS lock_latency,
       sum_rows_sent AS rows_sent,
       sum_rows_examined AS rows_examined,
       sum_rows_affected AS rows_affected,
       sum_no_index_used + sum_no_good_index_used AS full_scans
  FROM performance_schema.events_statements_summary_by_user_by_event_name
 WHERE user IS NOT NULL
   AND sum_timer_wait != 0
 ORDER BY user, sum_timer_wait DESC;

/*
 * View: check_lost_instrumentation
 * 
 * Used to check whether Performance Schema is not able to monitor
 * all runtime data - only returns variables that have lost instruments
 *
 * Versions: 5.5+
 */

DROP VIEW IF EXISTS check_lost_instrumentation;

CREATE VIEW check_lost_instrumentation AS
SELECT variable_name, variable_value
  FROM information_schema.global_status
 WHERE variable_name LIKE 'perf%lost'
   AND variable_value > 0;

/* View: innodb_buffer_statistics_by_schema
 * 
 * Summarizes the output of the INFORMATION_SCHEMA.INNODB_BUFFER_PAGE 
 * table, aggregating by schema
 *
 */

DROP VIEW IF EXISTS innodb_buffer_statistics_by_schema;

CREATE VIEW innodb_buffer_statistics_by_schema AS
SELECT IF(LOCATE('.', ibp.table_name) = 0, 'InnoDB System', REPLACE(SUBSTRING_INDEX(ibp.table_name, '.', 1), '`', '')) AS object_schema,
       format_bytes(SUM(IF(ibp.compressed_size = 0, 16384, compressed_size))) AS innodb_buffer_allocated,
       format_bytes(SUM(ibp.data_size)) AS innodb_buffer_data,
       COUNT(ibp.page_number) AS innodb_buffer_pages,
       COUNT(IF(ibp.is_hashed = 'YES', 1, 0)) AS innodb_buffer_pages_hashed,
       COUNT(IF(ibp.is_old = 'YES', 1, 0)) AS innodb_buffer_pages_old,
       ROUND(SUM(ibp.number_records)/COUNT(DISTINCT ibp.index_name)) AS innodb_buffer_rows_cached 
  FROM information_schema.innodb_buffer_page ibp 
 WHERE table_name IS NOT NULL
 GROUP BY object_schema
 ORDER BY SUM(IF(ibp.compressed_size = 0, 16384, compressed_size)) DESC;

/*
 * Procedure: only_enable()
 *
 * Only enable a certain form of wait event
 *
 * Parameters
 *   pattern: A LIKE pattern match of events to leave enabled
 *
 * Versions: 5.5+
 */

DROP PROCEDURE IF EXISTS only_enable;

DELIMITER $$

CREATE PROCEDURE only_enable(IN pattern VARCHAR(128))
    COMMENT 'Parameters: pattern (varchar(128))'
BEGIN
    UPDATE performance_schema.setup_instruments
       SET enabled = IF(name LIKE pattern, 'YES', 'NO'),
           timed = IF(name LIKE pattern, 'YES', 'NO');
END$$

DELIMITER ;

/*
 * Procedure: disable_current_thread()
 *
 * Disable performance_schema instrumentation for the current thread
 *
 * Example: CALL disable_current_thread();
 *
 * Versions: 5.6.2+
 */

DROP PROCEDURE IF EXISTS disable_current_thread;

DELIMITER $$

CREATE PROCEDURE disable_current_thread()
BEGIN
    UPDATE performance_schema.threads
       SET instrumented = 'NO'
     WHERE processlist_id = CONNECTION_ID();
END$$

DELIMITER ;

/*
 * Procedure: enable_current_thread()
 *
 * Enable performance_schema instrumentation for the current thread
 *
 * Example: CALL enable_current_thread();
 *
 * Versions: 5.6.2+
 */

DROP PROCEDURE IF EXISTS enable_current_thread;

DELIMITER $$

CREATE PROCEDURE enable_current_thread()
BEGIN
     UPDATE performance_schema.threads
        SET instrumented = 'YES'
      WHERE processlist_id = CONNECTION_ID();
END$$

DELIMITER ;

/*
 * Procedure: disable_background_threads()
 *
 * Disable performance_schema instrumentation for all background threads
 *
 * Example: CALL disable_background_threads();
 *
 * Versions: 5.6.2+
 */

DROP PROCEDURE IF EXISTS disable_background_threads;

DELIMITER $$

CREATE PROCEDURE disable_background_threads()
BEGIN
    UPDATE performance_schema.threads
       SET instrumented = 'NO'
     WHERE type = 'BACKGROUND';
END$$

DELIMITER ;

/*
 * Procedure: enable_background_threads()
 *
 * Enable performance_schema instrumentation for all background threads
 *
 * Example: CALL enable_background_threads();
 *
 * Versions: 5.6.2+
 */

DROP PROCEDURE IF EXISTS enable_background_threads;

DELIMITER $$

CREATE PROCEDURE enable_background_threads()
BEGIN
    UPDATE performance_schema.threads
       SET instrumented = 'YES'
     WHERE type = 'BACKGROUND';
END$$

DELIMITER ;

/*
 * Procedure: currently_enabled()
 *
 * Show all enabled events / consumers
 *
 * Parameters
 *   show_instruments: Whether to show instrument configuration as well
 *   show_threads: Whether to show threads that are currently enabled
 *
 * Versions: 5.5+
 *
 * mysql> call currently_enabled(TRUE, TRUE);
 * +----------------------------+
 * | performance_schema_enabled |
 * +----------------------------+
 * |                          1 |
 * +----------------------------+
 * 1 row in set (0.00 sec)
 * 
 * +---------------+
 * | enabled_users |
 * +---------------+
 * | '%'@'%'       |
 * +---------------+
 * 1 row in set (0.01 sec)
 * 
 * +----------------------+---------+-------+
 * | objects              | enabled | timed |
 * +----------------------+---------+-------+
 * | mysql.%              | NO      | NO    |
 * | performance_schema.% | NO      | NO    |
 * | information_schema.% | NO      | NO    |
 * | %.%                  | YES     | YES   |
 * +----------------------+---------+-------+
 * 4 rows in set (0.01 sec)
 * 
 * +---------------------------+
 * | enabled_consumers         |
 * +---------------------------+
 * | events_statements_current |
 * | global_instrumentation    |
 * | thread_instrumentation    |
 * | statements_digest         |
 * +---------------------------+
 * 4 rows in set (0.05 sec)
 * 
 * +--------------------------+-------------+
 * | enabled_threads          | thread_type |
 * +--------------------------+-------------+
 * | innodb/srv_master_thread | BACKGROUND  |
 * | root@localhost           | FOREGROUND  |
 * | root@localhost           | FOREGROUND  |
 * | root@localhost           | FOREGROUND  |
 * | root@localhost           | FOREGROUND  |
 * +--------------------------+-------------+
 * 5 rows in set (0.03 sec)
 * 
 * +-------------------------------------+-------+
 * | enabled_instruments                 | timed |
 * +-------------------------------------+-------+
 * | wait/io/file/sql/map                | YES   |
 * | wait/io/file/sql/binlog             | YES   |
 * ...
 * | statement/com/Error                 | YES   |
 * | statement/com/                      | YES   |
 * | idle                                | YES   |
 * +-------------------------------------+-------+
 * 210 rows in set (0.08 sec)
 * 
 * Query OK, 0 rows affected (0.89 sec)
 * 
 */

DROP PROCEDURE IF EXISTS currently_enabled;

DELIMITER $$

CREATE PROCEDURE currently_enabled(IN show_instruments BOOLEAN, IN show_threads BOOLEAN)
    COMMENT 'Parameters: show_instruments (boolean), show_threads (boolean)'
BEGIN
    SELECT @@performance_schema AS performance_schema_enabled;

    SELECT CONCAT('\'', host, '\'@\'', user, '\'') AS enabled_users
      FROM performance_schema.setup_actors;

    SELECT CONCAT(object_schema, '.', object_name) AS objects,
           enabled,
           timed
      FROM performance_schema.setup_objects;

    SELECT name AS enabled_consumers
      FROM performance_schema.setup_consumers
     WHERE enabled = 'YES';

    IF (show_threads) THEN
        SELECT IF(name = 'thread/sql/one_connection', 
                  CONCAT(processlist_user, '@', processlist_host), 
                  REPLACE(name, 'thread/', '')) AS enabled_threads,
        TYPE AS thread_type
          FROM performance_schema.threads
         WHERE INSTRUMENTED = 'YES';
    END IF;

    IF (show_instruments) THEN
        SELECT name AS enabled_instruments,
               timed
          FROM performance_schema.setup_instruments
         WHERE enabled = 'YES';
    END IF;
END$$

DELIMITER ;

/*
 * Procedure: truncate_all()
 *
 * Truncates all summary tables, to reset all performance schema statistics
 *
 * Parameters
 *   verbose: Whether to print each TRUNCATE statement before running
 *
 * Versions: 5.5+
 */

DROP PROCEDURE IF EXISTS truncate_all;

DELIMITER $$

CREATE PROCEDURE truncate_all(IN verbose BOOLEAN)
    COMMENT 'Parameters: verbose (boolean)'
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_ps_table VARCHAR(64);
    DECLARE ps_tables CURSOR FOR
        SELECT table_name 
          FROM INFORMATION_SCHEMA.TABLES 
         WHERE table_schema = 'performance_schema' 
           AND (table_name LIKE '%summary%' 
           OR table_name LIKE '%history%');
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    SET @log_bin := @@sql_log_bin;
    SET sql_log_bin = 0;

    OPEN ps_tables;

    ps_tables_loop: LOOP
        FETCH ps_tables INTO v_ps_table;
        IF v_done THEN
          LEAVE ps_tables_loop;
        END IF;

        SET @truncate_stmt := CONCAT('TRUNCATE TABLE performance_schema.', v_ps_table);
        IF verbose THEN
            SELECT CONCAT('Running: ', @truncate_stmt) AS status;
        END IF;

        PREPARE truncate_stmt FROM @truncate_stmt;
        EXECUTE truncate_stmt;
        DEALLOCATE PREPARE truncate_stmt;

    END LOOP;

    CLOSE ps_tables;

    SET sql_log_bin = @log_bin;

END$$

DELIMITER ;

/* 
 * Procedure: dump_thread_stack()
 *
 * Dumps all data within performance_schema for an instrumented thread
 * to create a DOT formatted graph file. 
 * Each resultset returned from the procedure should be used for a complete graph
 *
 * Example command line:
 *   mysql -u root -BN -e "CALL sys_helper.dump_thread_stack(33,1)" > /tmp/stack.dot
 * 
 * After this dot file is generated, load in to a graphing package such as Graphviz
 *
 * Parameters
 *   thd_id: The thread that you would like a stack trace for
 *   debug:  Whether you would like to include file:lineno in the graph
 *
 * Versions: 5.6.3+
 */

DROP PROCEDURE IF EXISTS dump_thread_stack;

DELIMITER $$

CREATE PROCEDURE dump_thread_stack(IN thd_id INT, IN debug BOOLEAN)
    COMMENT 'Parameters: thd_id (int), debug (boolean)'
BEGIN

    /* Do not track the current thread, it will kill the stack */
    CALL disable_current_thread();

    /* Print headers for a .dot file */
    SELECT 'digraph events { rankdir=LR; nodesep=0.10;';
    SELECT CONCAT('// Stack created: ', NOW());
    SELECT CONCAT('// MySQL version: ', VERSION());
    SELECT CONCAT('// MySQL user: ', CURRENT_USER());

    /* Select the entire stack of events */
    SELECT CONCAT(IF(nesting_event_id IS NOT NULL, CONCAT(nesting_event_id, ' -> '), ''), 
                  event_id, '; ', event_id, ' [label="',
                  /* Convert from picoseconds to microseconds */
                  '(',ROUND(timer_wait/1000000, 2),'μ) ',
                  IF (event_name NOT LIKE 'wait/io%', 
                      SUBSTRING_INDEX(event_name, '/', -2), 
                      IF (event_name NOT LIKE 'wait/io/file%' OR event_name NOT LIKE 'wait/io/socket%',
                          SUBSTRING_INDEX(event_name, '/', -4),
                          event_name)
                      ),
                  /* Always dump the extra wait information gathered for statements */
                  IF (event_name LIKE 'statement/%', IFNULL(CONCAT('\n', wait_info), ''), ''),
                  /* If debug is enabled, add the file:lineno information for waits */
                  IF (debug AND event_name LIKE 'wait%', wait_info, ''),
                  '", ', 
                  /* Depending on the type of event, style appropriately */
                  CASE WHEN event_name LIKE 'wait/io/file%' THEN 
                         'shape=box, style=filled, color=red'
                       WHEN event_name LIKE 'wait/io/table%' THEN 
                         'shape=box, style=filled, color=green'
                       WHEN event_name LIKE 'wait/io/socket%' THEN
                         'shape=box, style=filled, color=yellow'
                       WHEN event_name LIKE 'wait/synch/mutex%' THEN
                         'style=filled, color=lightskyblue'
                       WHEN event_name LIKE 'wait/synch/cond%' THEN
                         'style=filled, color=darkseagreen3'
                       WHEN event_name LIKE 'wait/synch/rwlock%' THEN
                         'style=filled, color=orchid'
                       WHEN event_name LIKE 'wait/lock%' THEN
                         'shape=box, style=filled, color=tan'
                       WHEN event_name LIKE 'statement/%' THEN
                         CONCAT('shape=box, style=bold',
                                /* Style statements depending on COM vs SQL */
                                CASE WHEN event_name LIKE 'statement/com/%' THEN
                                       ' style=filled, color=darkseagreen'
                                     ELSE
                                       /* Use long query time from the server to
                                          flag long running statements in red */
                                       IF((timer_wait/1000000000000) > @@long_query_time, 
                                          ' style=filled, color=red', 
                                          ' style=filled, color=lightblue')
                                     END)
                       WHEN event_name LIKE 'stage/%' THEN
                         'style=filled, color=slategray3'
                       /* IDLE events are on their own, call attention to them */
                       WHEN event_name LIKE '%idle%' THEN
                         'shape=box, style=filled, color=firebrick3'
                       ELSE '' END,
                   '];') event
      FROM (
           /* Select all statements, with the extra tracing information available */
           (SELECT thread_id, event_id, event_name, timer_wait, timer_start, nesting_event_id, 
                   CONCAT(sql_text, '\n',
                          'errors: ', errors, '\n',
                          'warnings: ', warnings, '\n',
                          'lock time: ', ROUND(lock_time/1000000, 2),'μ\n',
                          'rows affected: ', rows_affected, '\n',
                          'rows sent: ', rows_sent, '\n',
                          'rows examined: ', rows_examined, '\n',
                          'tmp tables: ', created_tmp_tables, '\n',
                          'tmp disk tables: ', created_tmp_disk_tables, '\n'
                          'select scan: ', select_scan, '\n',
                          'select full join: ', select_full_join, '\n',
                          'select full range join: ', select_full_range_join, '\n',
                          'select range: ', select_range, '\n',
                          'select range check: ', select_range_check, '\n', 
                          'sort merge passes: ', sort_merge_passes, '\n',
                          'sort rows: ', sort_rows, '\n',
                          'sort range: ', sort_range, '\n',
                          'sort scan: ', sort_scan, '\n',
                          'no index used: ', IF(no_index_used, 'TRUE', 'FALSE'), '\n',
                          'no good index used: ', IF(no_good_index_used, 'TRUE', 'FALSE'), '\n'
                          ) AS wait_info
              FROM performance_schema.events_statements_history_long)
           UNION
           /* Select all stages */
           (SELECT thread_id, event_id, event_name, timer_wait, timer_start, nesting_event_id, null AS wait_info
              FROM performance_schema.events_stages_history_long) 
           UNION 
           /* Select all events, adding information appropriate to the event */
           (SELECT thread_id, event_id, 
                   CONCAT(event_name, 
                          IF(event_name NOT LIKE 'wait/synch/mutex%', IFNULL(CONCAT(' - ', operation), ''), ''), 
                          IF(number_of_bytes IS NOT NULL, CONCAT(' ', number_of_bytes, ' bytes'), ''),
                          IF(event_name LIKE 'wait/io/file%', '\n', ''),
                          IF(object_schema IS NOT NULL, CONCAT('\nObject: ', object_schema, '.'), ''), 
                          IF(object_name IS NOT NULL, 
                             IF (event_name LIKE 'wait/io/socket%',
                                 /* Print the socket if used, else the IP:port as reported */
                                 CONCAT('\n', IF (object_name LIKE ':0%', @@socket, object_name)),
                                 object_name),
                             ''),
                          IF(index_name IS NOT NULL, CONCAT(' Index: ', index_name), ''), '\n'
                          ) AS event_name,
                   timer_wait, timer_start, nesting_event_id, source AS wait_info
              FROM performance_schema.events_waits_history_long)) events 
     WHERE thread_id = thd_id
     ORDER BY event_id;
     
     SELECT '}';
    
END$$

DELIMITER ;

/* 
 * Procedure: analyze_statement_digest()
 *
 * Parameters
 *   digest_in:   The statement digest identifier you would like to analyze
 *   runtime:     The number of seconds to run analysis for (defaults to a minute)
 *   interval_in: The interval (in seconds, may be fractional) at which to try
 *                and take snapshots (defaults to a second)
 *   start_fresh: Whether to TRUNCATE the events_statements_history_long and
 *                events_stages_history_long tables before starting (default false)
 *   auto_enable: Whether to automatically turn on required consumers (default false)
 *
 * Versions: 5.6.3+
 *
 * mysql> call analyze_statement_digest('891ec6860f98ba46d89dd20b0c03652c', 10, 0.1, true, true);
 * +--------------------+
 * | SUMMARY STATISTICS |
 * +--------------------+
 * | SUMMARY STATISTICS |
 * +--------------------+
 * 1 row in set (9.11 sec)
 * 
 * +------------+-----------+-----------+-----------+---------------+------------+------------+
 * | executions | exec_time | lock_time | rows_sent | rows_examined | tmp_tables | full_scans |
 * +------------+-----------+-----------+-----------+---------------+------------+------------+
 * |         21 | 4.11 ms   | 2.00 ms   |         0 |            21 |          0 |          0 |
 * +------------+-----------+-----------+-----------+---------------+------------+------------+
 * 1 row in set (9.11 sec)
 * 
 * +------------------------------------------+-------+-----------+
 * | event_name                               | count | latency   |
 * +------------------------------------------+-------+-----------+
 * | stage/sql/checking query cache for query |    16 | 724.37 µs |
 * | stage/sql/statistics                     |    16 | 546.92 µs |
 * | stage/sql/freeing items                  |    18 | 520.11 µs |
 * | stage/sql/init                           |    51 | 466.80 µs |
 * | stage/sql/Waiting for query cache lock   |    17 | 460.18 µs |
 * | stage/sql/Sending data                   |    16 | 164.54 µs |
 * | stage/sql/Opening tables                 |    18 | 162.22 µs |
 * | stage/sql/optimizing                     |    16 | 101.64 µs |
 * | stage/sql/updating                       |     1 | 75.48 µs  |
 * | stage/sql/System lock                    |    17 | 68.86 µs  |
 * | stage/sql/preparing                      |    16 | 62.90 µs  |
 * | stage/sql/closing tables                 |    18 | 37.08 µs  |
 * | stage/sql/query end                      |    18 | 22.51 µs  |
 * | stage/sql/checking permissions           |    17 | 20.86 µs  |
 * | stage/sql/end                            |    18 | 15.56 µs  |
 * | stage/sql/cleaning up                    |    18 | 11.92 µs  |
 * | stage/sql/executing                      |    16 | 6.95 µs   |
 * ------------------------------------------+-------+-----------+
 * 17 rows in set (9.12 sec)
 * 
 * +---------------------------+
 * | LONGEST RUNNING STATEMENT |
 * +---------------------------+
 * | LONGEST RUNNING STATEMENT |
 * +---------------------------+
 * 1 row in set (9.16 sec)
 * 
 * +-----------+-----------+-----------+-----------+---------------+------------+-----------+
 * | thread_id | exec_time | lock_time | rows_sent | rows_examined | tmp_tables | full_scan |
 * +-----------+-----------+-----------+-----------+---------------+------------+-----------+
 * |    166646 | 618.43 µs | 1.00 ms   |         0 |             1 |          0 |         0 |
 * +-----------+-----------+-----------+-----------+---------------+------------+-----------+
 * 1 row in set (9.16 sec)
 * 
 * // Truncated for clarity...
 * +-----------------------------------------------------------------+
 * | sql_text                                                        |
 * +-----------------------------------------------------------------+
 * | select hibeventhe0_.id as id1382_, hibeventhe0_.createdTime ... |
 * +-----------------------------------------------------------------+
 * 1 row in set (9.17 sec)
 * 
 * +------------------------------------------+-----------+
 * | event_name                               | latency   |
 * +------------------------------------------+-----------+
 * | stage/sql/init                           | 8.61 µs   |
 * | stage/sql/Waiting for query cache lock   | 453.23 µs |
 * | stage/sql/init                           | 331.07 ns |
 * | stage/sql/checking query cache for query | 43.04 µs  |
 * | stage/sql/checking permissions           | 1.32 µs   |
 * | stage/sql/Opening tables                 | 8.61 µs   |
 * | stage/sql/init                           | 16.22 µs  |
 * | stage/sql/System lock                    | 2.98 µs   |
 * | stage/sql/optimizing                     | 5.63 µs   |
 * | stage/sql/statistics                     | 30.13 µs  |
 * | stage/sql/preparing                      | 3.31 µs   |
 * | stage/sql/executing                      | 331.07 ns |
 * | stage/sql/Sending data                   | 9.60 µs   |
 * | stage/sql/end                            | 662.13 ns |
 * | stage/sql/query end                      | 993.20 ns |
 * | stage/sql/closing tables                 | 1.66 µs   |
 * | stage/sql/freeing items                  | 30.46 µs  |
 * | stage/sql/cleaning up                    | 662.13 ns |
 * +------------------------------------------+-----------+
 * 18 rows in set (9.23 sec)
 * 
 * +----+-------------+--------------+-------+---------------+-----------+---------+-------------+------+-------+
 * | id | select_type | table        | type  | possible_keys | key       | key_len | ref         | rows | Extra |
 * +----+-------------+--------------+-------+---------------+-----------+---------+-------------+------+-------+
 * |  1 | SIMPLE      | hibeventhe0_ | const | fixedTime     | fixedTime | 775     | const,const |    1 | NULL  |
 * +----+-------------+--------------+-------+---------------+-----------+---------+-------------+------+-------+
 * 1 row in set (9.27 sec)
 * 
 * Query OK, 0 rows affected (9.28 sec)
 * 
 */

DROP PROCEDURE IF EXISTS analyze_statement_digest;

DELIMITER $$

CREATE PROCEDURE analyze_statement_digest(IN digest_in VARCHAR(32), IN runtime INT, 
    IN interval_in DECIMAL(2,2), IN start_fresh BOOLEAN, IN auto_enable BOOLEAN)
    COMMENT "Parameters: digest_in (varchar(32)), runtime (int), interval_in (decimal(2,2)), start_fresh (boolean), auto_enable (boolean)"
BEGIN

    DECLARE v_start_fresh BOOLEAN DEFAULT false;
    DECLARE v_auto_enable BOOLEAN DEFAULT false;
    DECLARE v_runtime INT DEFAULT 0;
    DECLARE v_start INT DEFAULT 0;
    DECLARE v_found_stmts INT;

    /* Do not track the current thread, it will kill the stack */
    CALL disable_current_thread();

    DROP TEMPORARY TABLE IF EXISTS stmt_trace;
    CREATE TEMPORARY TABLE stmt_trace (
        thread_id BIGINT,
        timer_start BIGINT,
        event_id BIGINT,
        sql_text longtext,
        timer_wait BIGINT,
        lock_time BIGINT,
        errors BIGINT,
        mysql_errno BIGINT,
        rows_affected BIGINT,
        rows_examined BIGINT,
        created_tmp_tables BIGINT,
        created_tmp_disk_tables BIGINT,
        no_index_used BIGINT,
        PRIMARY KEY (thread_id, timer_start)
    );

    DROP TEMPORARY TABLE IF EXISTS stmt_stages;
    CREATE TEMPORARY TABLE stmt_stages (
       event_id BIGINT,
       stmt_id BIGINT,
       event_name VARCHAR(128),
       timer_wait BIGINT,
       PRIMARY KEY (event_id)
    );

    SET v_start_fresh = start_fresh;
    IF v_start_fresh THEN
        TRUNCATE TABLE performance_schema.events_statements_history_long;
        TRUNCATE TABLE performance_schema.events_stages_history_long;
    END IF;

    SET v_auto_enable = auto_enable;
    IF v_auto_enable THEN
        UPDATE performance_schema.setup_consumers
           SET enabled = 'YES'
         WHERE name IN (
               'global_instrumentation',
               'thread_instrumentation',
               'events_statements_current',
               'events_statements_history_long',
               'events_stages_current',
               'events_stages_history_long'
               );
    END IF;

    WHILE v_runtime < runtime DO
        SELECT UNIX_TIMESTAMP() INTO v_start;

        INSERT IGNORE INTO stmt_trace
        SELECT thread_id, timer_start, event_id, sql_text, timer_wait, lock_time, errors, mysql_errno, 
               rows_affected, rows_examined, created_tmp_tables, created_tmp_disk_tables, no_index_used
          FROM performance_schema.events_statements_history_long
        WHERE digest = digest_in;

        INSERT IGNORE INTO stmt_stages
        SELECT stages.event_id, stmt_trace.event_id,
               stages.event_name, stages.timer_wait
          FROM performance_schema.events_stages_history_long AS stages
          JOIN stmt_trace ON stages.nesting_event_id = stmt_trace.event_id;

        SELECT SLEEP(interval_in) INTO @sleep;
        SET v_runtime = v_runtime + (UNIX_TIMESTAMP() - v_start);
    END WHILE;

    SELECT "SUMMARY STATISTICS";

    SELECT COUNT(*) executions,
           format_time(SUM(timer_wait)) AS exec_time,
           format_time(SUM(lock_time)) AS lock_time,
           SUM(rows_affected) AS rows_sent,
           SUM(rows_examined) AS rows_examined,
           SUM(created_tmp_tables) AS tmp_tables,
           SUM(no_index_used) AS full_scans
      FROM stmt_trace;

    SELECT event_name,
           COUNT(*) as count,
           format_time(SUM(timer_wait)) as latency
      FROM stmt_stages
     GROUP BY event_name
     ORDER BY SUM(timer_wait) DESC;

    SELECT "LONGEST RUNNING STATEMENT";

    SELECT thread_id,
           format_time(timer_wait) AS exec_time,
           format_time(lock_time) AS lock_time,
           rows_affected AS rows_sent,
           rows_examined,
           created_tmp_tables AS tmp_tables,
           no_index_used AS full_scan
      FROM stmt_trace
     ORDER BY timer_wait DESC LIMIT 1;

    SELECT sql_text
      FROM stmt_trace
     ORDER BY timer_wait DESC LIMIT 1;

    SELECT sql_text, event_id INTO @sql, @sql_id
      FROM stmt_trace
    ORDER BY timer_wait DESC LIMIT 1;

    SELECT event_name,
           format_time(timer_wait) as latency
      FROM stmt_stages
     WHERE stmt_id = @sql_id
     ORDER BY event_id;

    DROP TEMPORARY TABLE stmt_trace;
    DROP TEMPORARY TABLE stmt_stages;

    SET @stmt := CONCAT("EXPLAIN ", @sql);
    PREPARE explain_stmt FROM @stmt;
    EXECUTE explain_stmt;
    DEALLOCATE PREPARE explain_stmt;

END$$

DELIMITER ;

SET sql_log_bin = 1;
-- Find all mutex contentions

/**
 * Function: is_consumer_enabled()
 * 
 * Return whether a consumer is enabled (taken the consumer hierarchy into consideration)
 *
 * Parameters
 *    in_consumer: The name of the consumer to test.
 *
 * mysql> SELECT is_consumer_enabled('events_stages_history');
 */
   CREATE 
  DEFINER='root'@'localhost'
 FUNCTION is_consumer_enabled(in_consumer varchar(64)) RETURNS enum('YES','NO', 'PARTIAL')
  COMMENT 'Returns whether the consumer is enabled taking the consumer hierarchy into consideration'
 LANGUAGE SQL DETERMINISTIC READS SQL DATA SQL SECURITY INVOKER
   RETURN (
      SELECT (CASE
                 WHEN c.NAME = 'global_instrumentation' THEN c.ENABLED
                 WHEN c.NAME = 'thread_instrumentation' THEN IF(cg.ENABLED = 'YES' AND c.ENABLED = 'YES', 'YES', 'NO')
                 WHEN c.NAME LIKE '%\_digest'           THEN IF(cg.ENABLED = 'YES' AND c.ENABLED = 'YES', 'YES', 'NO')
                 WHEN c.NAME LIKE '%\_current'          THEN IF(cg.ENABLED = 'YES' AND ct.ENABLED = 'YES' AND c.ENABLED = 'YES', 'YES', 'NO')
                 ELSE IF(cg.ENABLED = 'YES' AND ct.ENABLED = 'YES' AND c.ENABLED = 'YES'
                         AND ( SELECT cc.ENABLED FROM performance_schema.setup_consumers cc WHERE NAME = CONCAT(SUBSTRING_INDEX(c.NAME, '_', 2), '_current')
                             ) = 'YES', 'YES', 'NO')
              END) AS IsEnabled
        FROM performance_schema.setup_consumers c
             INNER JOIN performance_schema.setup_consumers cg
             INNER JOIN performance_schema.setup_consumers ct
       WHERE cg.NAME       = 'global_instrumentation'
             AND ct.NAME   = 'thread_instrumentation'
             AND c.NAME    = in_consumer
   );

/**
 * View: setup_consumers
 *
 * The performance_schema.setup_consumers with an additional column calculating the effective status.
 *
 * Versions: 5.5+
 *
 * mysql> SELECT * FROM setup_consumers;
 * +--------------------------------+---------+----------+
 * | NAME                           | ENABLED | COLLECTS |
 * +--------------------------------+---------+----------+
 * | events_stages_current          | YES     | YES      |
 * | events_stages_history          | YES     | YES      |
 * | events_stages_history_long     | YES     | YES      |
 * | events_statements_current      | NO      | NO       |
 * | events_statements_history      | YES     | NO       |
 * | events_statements_history_long | YES     | NO       |
 * | events_waits_current           | YES     | YES      |
 * | events_waits_history           | YES     | YES      |
 * | events_waits_history_long      | YES     | YES      |
 * | global_instrumentation         | YES     | YES      |
 * | thread_instrumentation         | YES     | YES      |
 * | statements_digest              | YES     | YES      |
 * +--------------------------------+---------+----------+
 * 12 rows in set (0.01 sec)
 */
CREATE OR REPLACE SQL SECURITY INVOKER VIEW setup_consumers AS
SELECT c.NAME, c.ENABLED,
       (CASE
           WHEN c.NAME = 'global_instrumentation' THEN c.ENABLED
           WHEN c.NAME = 'thread_instrumentation' THEN IF(cg.ENABLED = 'YES' AND c.ENABLED = 'YES', 'YES', 'NO')
           WHEN c.NAME LIKE '%\_digest'           THEN IF(cg.ENABLED = 'YES' AND c.ENABLED = 'YES', 'YES', 'NO')
           WHEN c.NAME LIKE '%\_current'          THEN IF(cg.ENABLED = 'YES' AND ct.ENABLED = 'YES' AND c.ENABLED = 'YES', 'YES', 'NO')
           ELSE IF(cg.ENABLED = 'YES' AND ct.ENABLED = 'YES' AND c.ENABLED = 'YES'
                   AND ( SELECT cc.ENABLED FROM performance_schema.setup_consumers cc WHERE NAME = CONCAT(SUBSTRING_INDEX(c.NAME, '_', 2), '_current')
                       ) = 'YES', 'YES', 'NO')
       END) AS COLLECTS
  FROM performance_schema.setup_consumers c
       INNER JOIN performance_schema.setup_consumers cg
       INNER JOIN performance_schema.setup_consumers ct
 WHERE cg.NAME       = 'global_instrumentation'
       AND ct.NAME   = 'thread_instrumentation'
;


/**
 * Function: substr_count()
 * 
 * A port of the PHP function substr_count() - see also http://php.net/manual/en/function.substr-count.php
 * Returns the number of times a substring is found on the input.
 * NOTES:
 * 
 *    - substr_count is using the MySQL convention of having a 1-based offset, so the two calls:
 * 
 *         PHP:   substr_count("a/b/c/d/e", "/", 2)
 *         MySQL: substr_count('a/b/c/d/e', '/', 3, NULL)
 *    
 *      are equivalent.
 *    - As MySQL stored functions do not support optional arguments, all arguments must be specified.
 *      To use the default value specify NULL or 0.
 *
 * Parameters
 *   in_haystack ...: The string to test against. Is a mediumtext.
 *   in_needle .....: The needle to search for. Is a varchar(255).
 *   in_offset .....: The first offset to start from. Is 1-based. Default value is 1 (i.e. beginning of line).
 *   in_length .....: The maximum length to search. Default is the length of the haystack string.
 *   
 * Returns
 *   An unsigned integer with the number of occurrences of the needle.
 *
 * mysql> SELECT substr_count('a/b/c/d/e', '/', 3, 5);
 * +--------------------------------------+
 * | substr_count('a/b/c/d/e', '/', 3, 5) |
 * +--------------------------------------+
 * |                                    2 |
 * +--------------------------------------+
 * 1 row in set (0.00 sec)
 */
DELIMITER //
   CREATE
 FUNCTION substr_count(in_haystack mediumtext, in_needle varchar(255), in_offset int unsigned, in_length int unsigned) RETURNS int unsigned
 LANGUAGE SQL DETERMINISTIC NO SQL SQL SECURITY INVOKER
   BEGIN
      IF ((in_offset IS NOT NULL AND in_offset > 0) OR (in_length IS NOT NULL AND in_length > 0)) THEN
         SET in_offset   = IF(in_offset IS NOT NULL AND in_offset > 0, in_offset, 1),
             in_length   = IF(in_length IS NOT NULL AND in_length > 0, in_length, CHAR_LENGTH(in_haystack)),
             in_haystack = SUBSTRING(in_haystack, in_offset, in_length);
      END IF;
      RETURN (CHAR_LENGTH(in_haystack) - CHAR_LENGTH(REPLACE(in_haystack,in_needle,''))) / CHAR_LENGTH(in_needle);
   END//

DELIMITER ;

/**
 * Function: substr_by_delim()
 * 
 * Returns the Nth element from a delimited string.
 *
 * Parameters
 *   in_set      ....: The delimited strintg. Is a mediumtext.
 *   in_delimiter ...: The string used as a delimiter. Is a varchar(255).
 *   in_pos     .....: The position of the element to return. Is 1-based. Negative values means extracting from the end.
 *   
 * Returns
 *   A mediumtext with the value of the element. NULL is returned if the delimiter is not found or the position is out
 *   of range.
 *
 * mysql> SELECT substr_by_delim('a,b,c,d,e', ',', 2);
 * +--------------------------------------+
 * | substr_by_delim('a,b,c,d,e', ',', 2) |
 * +--------------------------------------+
 * | b                                    |
 * +--------------------------------------+
 * 1 row in set (0.00 sec)
 * 
 * mysql> SELECT substr_by_delim('a,b,c,d,e', ',', -2);
 * +---------------------------------------+
 * | substr_by_delim('a,b,c,d,e', ',', -2) |
 * +---------------------------------------+
 * | d                                     |
 * +---------------------------------------+
 * 1 row in set (0.00 sec)
 * 
 * mysql> SELECT substr_by_delim('a||b||c||d||e', '||', 2);
 * +-------------------------------------------+
 * | substr_by_delim('a||b||c||d||e', '||', 2) |
 * +-------------------------------------------+
 * | b                                         |
 * +-------------------------------------------+
 * 1 row in set (0.00 sec)
 */
DELIMITER //
   CREATE
 FUNCTION substr_by_delim(in_set mediumtext, in_delimiter varchar(255), in_pos int) RETURNS mediumtext
  COMMENT 'Returns the Nth element from a delimited list.'
 LANGUAGE SQL DETERMINISTIC NO SQL SQL SECURITY INVOKER
    BEGIN
      DECLARE v_num_parts int unsigned DEFAULT 0;

      IF (in_pos < 0) THEN
         -- substr_count returns the number of delimiters, add 1 to get the number of parts
         SET v_num_parts = substr_count(in_set, in_delimiter, NULL, NULL) + 1;
         IF (v_num_parts >= ABS(in_pos)) THEN
            -- Add the requested position (which is negative, so is actually a subtraction)
            -- Add 1 as the position is 1 based.
            SET in_pos = v_num_parts + in_pos + 1;
         ELSE
            -- The requested position is out of range, so set in_pos to 0.
            SET in_pos = 0;
         END IF;
      END IF;
      IF (in_pos <= 0 OR in_pos IS NULL OR in_pos > substr_count(in_set, in_delimiter, 0, NULL)+1) THEN
         -- in_pos is not BETWEEN 1 AND #of elements.
         RETURN NULL;
      ELSE
         RETURN SUBSTRING_INDEX(SUBSTRING_INDEX(in_set, in_delimiter, in_pos), in_delimiter, -1);
      END IF;
   END//
DELIMITER ;


/**
 * Function: color()
 * 
 * Defines the color escape codes. Currently only bash color escape codes are supported.
 *
 * Parameters
 *   in_status .....: The status to get the color for.
 *   
 * Returns
 *   The bash color escape sequence.
 */
DELIMITER //
   CREATE
  DEFINER='root'@'localhost'
 FUNCTION color(in_status varchar(10)) RETURNS VARCHAR(12)
  COMMENT 'Returns ANSI colour escape sequences.'
 LANGUAGE SQL DETERMINISTIC NO SQL SQL SECURITY INVOKER
    BEGIN
      CASE in_status
         WHEN 'YES'      THEN RETURN '\\033[1;32m';
         WHEN 'PARTIAL'  THEN RETURN '\\033[1;33m';
         WHEN 'NO'       THEN RETURN '\\033[1;31m';
         ELSE                 RETURN '\\033[0m';
      END CASE;
    END//

DELIMITER ;


/**
 * Function: xmltree_get_name()
 * 
 * Determine the processed name including if necessary adding ascii encoding to show
 * whether the element is enabled.
 *
 * Parameters
 *   in_substr_split .....: If set, then the elements will be split using this string
 *                          to get the individual parts. E.g. wait/io/table/sql/handler
 *                          so only the part belonging to the level will actually be
 *                          printed. So in_substr_split = '/' and level 3 will display
 *                          "table".
 *   in_replace_needle ...: If set, a replace will be done against this needle in the
 *                          element names before including them in the output.
 *   in_replace_value ....: If a replace is done, the needle is replaced with this
 *                          value.
 *   in_color ............: Boolean, whether to use bash colors in the output.
 *   in_xml ..............: The XML with the definition of the tree.
 *   in_l ................: The number of the level the element is in.
 *   in_g ................: The number of the group the element is in.
 *   in_g ................: The number of the element.
 *   
 * Returns
 *   A text with the processed name formatted as requested.
 */
DELIMITER //
   CREATE
 FUNCTION xmltree_get_name(in_substr_split char(1), in_replace_needle varchar(20), in_replace_value varchar(20),
                           in_color bool, in_xml mediumtext, in_l int unsigned, in_g int unsigned, in_e int unsigned
                          ) RETURNS TEXT
  COMMENT 'Returns the name to use in the setup trees without colour'
 LANGUAGE SQL DETERMINISTIC NO SQL SQL SECURITY INVOKER
   BEGIN
      DECLARE v_isenabled enum('YES','NO', 'PARTIAL') DEFAULT NULL;
      DECLARE v_name text DEFAULT NULL;
      DECLARE v_elem varchar(92) DEFAULT '';
      SET v_elem      = '//l[$in_l]/g[$in_g]/e[$in_e]',
          v_isenabled = CASE ExtractValue(in_xml, CONCAT(v_elem, '/@enabled'))
                           WHEN 'YES' THEN 'YES'
                           WHEN 'PARTIAL' THEN 'PARTIAL'
                           ELSE 'NO'
                        END,
          v_name      = IF(LENGTH(in_substr_split) > 0,
                           substr_by_delim(ExtractValue(in_xml, v_elem), in_substr_split, -1), 
                           ExtractValue(in_xml, v_elem)
                        ),
          v_name      = IF(
                           LENGTH(in_replace_needle) > 0 AND in_replace_value IS NOT NULL,
                           REPLACE(v_name, in_replace_needle, in_replace_value),
                           v_name
                        ),
          v_name      = IF(v_name = '', '(blank)', v_name),
          v_name      = IF(NOT in_color,
                           CASE v_isenabled
                              WHEN 'YES'     THEN CONCAT('<', v_name, '>')
                              WHEN 'PARTIAL' THEN CONCAT('[', v_name, ']')
                              ELSE v_name
                           END,
                           v_Name
                        );
      RETURN v_name;
    END//
DELIMITER ;


/**
 * Function: xmltree_dot_line()
 * 
 * Outputs a line defining an element and how it connects to the rest of the tree (i.e. what its parent is).
 *
 * Parameters
 *   in_parent ...........: The parent of the element (the unprocessed name).
 *   in_element ..........: The unprocessed name of the element.
 *   in_name .............: The level the parent is on.
 *   in_isenabled ........: Whether the element is enabled.
 *   in_orientation ......: Whether the output is in Left-Right or Top-Bottom direction.
 *   
 * Returns
 *   A text with the row for the dot formatted output.
 */
DELIMITER //
   CREATE
 FUNCTION xmltree_dot_line(
             in_parent varchar(64), in_element varchar(64), in_name varchar(64),
             in_isenabled enum('YES','NO', 'PARTIAL'), in_orientation enum('Left-Right', 'Top-Bottom')
          ) RETURNS text
  COMMENT 'Returns a line for a dot formatted file for a given element and its relation to its parent.'
 LANGUAGE SQL DETERMINISTIC NO SQL SQL SECURITY INVOKER
   BEGIN
      RETURN CONCAT(
                '   ',
                IF (in_parent <> '', CONCAT('"', in_parent, '" -> "', in_element, IF(in_orientation = 'Left-Right', '" [headport=w]; ', '" [headport=n]; ')), ''),
                CONCAT(
                   '"', in_element, '" [label="', in_name, '", style=bold style=filled, color=',
                   CASE in_isenabled
                      WHEN 'YES'     THEN 'green'
                      WHEN 'PARTIAL' THEN 'yellow'
                      ELSE 'red'
                   END,
                   '];'
                )
             );
   END//
DELIMITER ;


/**
 * Procedure: xmltree_shift_lines()
 * 
 * Shifts all children of in_parent in the inout_oxml XML with in_delta lines.
 *
 * Parameters
 *   inout_oxml ..........: The XML holding the definition of the output.
 *   in_parent ...........: The parent of the children to shift the line number of.
 *   in_parent_level .....: The level the parent is on.
 *   in_child_max_line ...: The maximum line number of the children to shift. Elements on the same level
 *                          as the children with a line number higher than in_child_max_line should also
 *                          be shifted.
 *   in_delta ............: The number of lines to shift the children.
 *   
 * Returns
 *   An updated inout_oxml through the parameter.
 */
DELIMITER //
   CREATE
PROCEDURE xmltree_shift_lines(INOUT inout_oxml mediumtext, IN in_parent text, IN in_parent_level int unsigned, IN in_child_max_line int unsigned, IN in_delta int unsigned)
  COMMENT 'Returns the xml with the children of in_parent shifted in_delta lines.'
 LANGUAGE SQL DETERMINISTIC NO SQL SQL SECURITY INVOKER
   BEGIN
      DECLARE v_num_children, v_child_line_old, v_child_line_new, v_num_children_children, v_i int unsigned DEFAULT 0;
      DECLARE v_level, v_start_tag, v_end_tag int unsigned DEFAULT 0;
      DECLARE v_child_element, v_child_xml text DEFAULT NULL;
      
      -- Shift the elements at the next level with higher line number than the maximum line number of the children of the element
      -- in_child_max_line is NULL if this should be skipped (should only be done for the first call)
      IF (in_child_max_line IS NOT NULL) THEN
         SET v_num_children = ExtractValue(inout_oxml, 'count(/e[@level=$in_parent_level+1 and @line>$in_child_max_line])'),
             v_i            = v_num_children;

         -- Going from last to first child ensure that when we shift the line numbers that we do not by accident create two children
         -- with the same line number
         WHILE (v_i > 0) DO
            SET v_level                 = ExtractValue(inout_oxml, '/e[@level=$in_parent_level+1 and @line>$in_child_max_line][$v_i]/@level'),
                v_child_line_old        = ExtractValue(inout_oxml, '/e[@level=$in_parent_level+1 and @line>$in_child_max_line][$v_i]/@line'),
                v_child_line_new        = v_child_line_old + in_delta,
                v_start_tag             = LOCATE(CONCAT('<e level="', v_level, '" line="', v_child_line_old), inout_oxml),
                v_end_tag               = LOCATE('<e ', inout_oxml, v_start_tag+1),
                v_end_tag               = IF(v_end_tag > 0, v_end_tag, CHAR_LENGTH(inout_oxml)+1), -- it's the last tag
                v_child_xml             = IF(v_start_tag > 0, SUBSTRING(inout_oxml, v_start_tag, (v_end_tag-v_start_tag)), ''),
                v_child_element         = ExtractValue(inout_oxml, '/e[@level=$in_parent_level+1 and @line>$in_child_max_line][$v_i]/@element'),
                v_num_children_children = ExtractValue(inout_oxml, 'count(/e[@parent=$v_child_element])'),
                v_child_xml             = REPLACE(v_child_xml, CONCAT(' line="', v_child_line_old, '"'), CONCAT(' line="', v_child_line_new, '"')),
                inout_oxml              = UpdateXML(inout_oxml, '/e[@level=$in_parent_level+1 and @line>$in_child_max_line][$v_i]', v_child_xml),
                v_i                     = v_i - 1;

            IF (v_num_children_children > 0) THEN
               CALL xmltree_shift_lines(inout_oxml, v_child_element, v_level, NULL, in_delta);
            END IF;
         END WHILE;
      END IF;

      -- First the children
      SET v_num_children = ExtractValue(inout_oxml, 'count(/e[@parent=$in_parent])'),
          v_i            = v_num_children;

      -- Going from last to first child ensure that when we shift the line numbers that we do not by accident create two children
      -- with the same line number
      WHILE (v_i > 0) DO
         SET v_level                 = ExtractValue(inout_oxml, '/e[@parent=$in_parent][$v_i]/@level'),
             v_child_line_old        = ExtractValue(inout_oxml, '/e[@parent=$in_parent][$v_i]/@line'),
             v_child_line_new        = v_child_line_old + in_delta,
             v_start_tag             = LOCATE(CONCAT('<e level="', v_level, '" line="', v_child_line_old), inout_oxml),
             v_end_tag               = LOCATE('<e ', inout_oxml, v_start_tag+1),
             v_end_tag               = IF(v_end_tag > 0, v_end_tag, CHAR_LENGTH(inout_oxml)+1), -- it's the last tag
             v_child_xml             = IF(v_start_tag > 0, SUBSTRING(inout_oxml, v_start_tag, (v_end_tag-v_start_tag)), ''),
             v_child_element         = ExtractValue(inout_oxml, '/e[@parent=$in_parent][$v_i]/@element'),
             v_num_children_children = ExtractValue(inout_oxml, 'count(/e[@parent=$v_child_element])'),
             v_child_xml             = REPLACE(v_child_xml, CONCAT(' line="', v_child_line_old, '"'), CONCAT(' line="', v_child_line_new, '"')),
             inout_oxml              = UpdateXML(inout_oxml, '/e[@parent=$in_parent][$v_i]', v_child_xml),
             v_i                     = v_i - 1;

         IF (v_num_children_children > 0) THEN
            CALL xmltree_shift_lines(inout_oxml, v_child_element, v_level, NULL, in_delta);
         END IF;
      END WHILE;

   END//
DELIMITER ;


/**
 * Function: xmltree_legend()
 * 
 * Returns the legend to be used together with the text versions of xmltrees.
 *
 * Parameters
 *   in_color ............: Boolean, whether to use bash colors in the output.
 *   
 * Returns
 *   A text with the legend.
 */
DELIMITER //
   CREATE
 FUNCTION xmltree_legend(in_color bool) RETURNS text
  COMMENT 'Returns the legend to display with an expanded XML tree.'
 LANGUAGE SQL DETERMINISTIC NO SQL SQL SECURITY INVOKER
   BEGIN
      DECLARE v_output text;

      SET v_output = 'Legend: ';
      IF (in_color) THEN
         SET v_output = CONCAT(
                           v_output,
                           color('YES'), 'Enabled', color('OFF'), ' - ',
                           color('PARTIAL'), 'Partially enabled', color('OFF'), ' - ',
                           color('NO'), 'Disabled', color('OFF')
                        );
      ELSE
         SET v_output = CONCAT(
                           v_output,
                           '<Enabled>', ' - ',
                           '[Partially enabled]', ' - ',
                           'Disabled'
                        );
      END IF;
      
      RETURN v_output;
   END//
DELIMITER ;


/**
 * Function: xmltree_leftright()
 * 
 * Convert an xml representation of the p_s settings into
 * a tree. The tree is from left to right (similar to rankdir=LR in the dot format).
 *
 * Parameters
 *   in_substr_split .....: If set, then the elements will be split using this string
 *                          to get the individual parts. E.g. wait/io/table/sql/handler
 *                          so only the part belonging to the level will actually be
 *                          printed. So in_substr_split = '/' and level 3 will display
 *                          "table".
 *   in_replace_needle ...: If set, a replace will be done against this needle in the
 *                          element names before including them in the output.
 *   in_replace_value ....: If a replace is done, the needle is replaced with this
 *                          value.
 *   in_color ............: Boolean, whether to use bash colors in the output.
 *   in_xml ..............: The XML with the definition of the tree.
 *   
 * Returns
 *   A mediumtext with the expanded tree.
 *
 * mysql> SELECT xmltree_leftright('', '', '', FALSE, '<consumers><l><g><e enabled="YES">global_instrumentation</e></g></l><l><g parent="global_instrumentation"><e enabled="YES">statements_digest</e><e enabled="YES">thread_instrumentation</e></g></l><l><g parent="thread_instrumentation"><e enabled="NO">events_stages_current</e><e enabled="YES">events_statements_current</e><e enabled="NO">events_waits_current</e></g></l><l><g parent="events_stages_current"><e enabled="NO">events_stages_history</e><e enabled="NO">events_stages_history_long</e></g><g parent="events_statements_current"><e enabled="NO">events_statements_history</e><e enabled="NO">events_statements_history_long</e></g><g parent="events_waits_current"><e enabled="NO">events_waits_history</e><e enabled="NO">events_waits_history_long</e></g></l></consumers>') AS 'Consumers'\G
 * *************************** 1. row ***************************
 * Consumers:
 *                           +--<statements_digest>
 *                           |                                                            +--events_stages_history
 *                           |                            +--events_stages_current--------+
 * <global_instrumentation>--+                            |                               +--events_stages_history_long
 *                           |                            |
 *                           |                            |                               +--events_statements_history
 *                           +--<thread_instrumentation>--+--<events_statements_current>--+
 *                                                        |                               +--events_statements_history_long
 *                                                        |
 *                                                        |                               +--events_waits_history
 *                                                        +--events_waits_current---------+
 *                                                                                        +--events_waits_history_long
 * 
 * Legend: <Enabled> - [Partially enabled] - Disabled
 * 1 row in set (0.01 sec)
 */
DELIMITER //
   CREATE
 FUNCTION xmltree_leftright(in_substr_split CHAR(1), in_replace_needle VARCHAR(20), in_replace_value VARCHAR(20),
                            in_color bool, in_xml mediumtext
          ) RETURNS mediumtext
  COMMENT 'Returns an expanded tree.'
 LANGUAGE SQL DETERMINISTIC NO SQL SQL SECURITY INVOKER
   BEGIN
      /*
         Variables:
            * v_isenabled                  : Whether the element is enabled.
            * v_l, v_g, v_e                : Counters for the level, group, and element.
            * v_maxwidth                   : The maximum width of an element.
            * v_line_num                   : The line number of an element in the output.
            * v_num_children               : The number of children of an element.
            * v_num_levels                 : The total number of levels in the tree.
            * v_num_groups                 : The total number of groups within the current level.
            * v_num_elements               : The total number of elements within the current group.
            * v_min_line                   : The tree is build from the deepest level up. v_min_line
                                             is the first line currently for the childs of the current
                                             element.
            * v_max_line                   : The tree is build from the deepest level up. v_max_line
                                             is the last line currently for the childs of the current
                                             element.
            * v_child                      : Counter when looping through the children to find v_min_line and v_max_line.
            * v_child_line                 : The line of the current child when looping through childs to
            *                                find v_min_line and v_max_line.
            * v_start_tag                  : Position of the start tag when picking out an element using SUBSTRING().
            * v_end_tag                    : Position of the end tag when picking out an element using SUBSTRING().
            * v_tmp                        : Temporary hold an element picked out using SUBSTRING().
            * v_total_max_line             : The total number of lines in the output.
            * v_output                     : The final output.
            * v_oxml                       : Intermediate xml with the location of each element set.
            * v_level_widths               : Intermediate xml with the maxwidth for each level.
            * v_child_prev                 : When putting the final output together. The first child with a lower line
                                             number.
            * v_child_next                 : When putting the final output together. The first child with a higher line
                                             number.
            * v_next_element               : Unprocessed name of the next element. Used together with v_child_prev.
            * v_prev_element               : Unprocessed name of the next element. Used together with v_child_next.
            * v_element                    : The unprocessed name of the element.
            * v_name                       : The processed name - without bash colour codes - of the element.
            * v_color_name                 : The processed name with bash colour codes if needed.
            * v_parent                     : The parent of the current element (the unprocessed name of the parent).
            * v_cell                       : While generating the final output, it holds the current cell (element with
                                             connectors, etc.).
            
            * v_l_path                     : xpath expression for finding levels.
            * v_g_path                     : xpath expression for finding all groups in a level.
            * v_e_path                     : xpath expression for finding all elements in a group.
            * v_group                      : xpath expression for finding a specific group.
            * v_elem                       : xpath expression for finding a specific element.
            * v_p_path                     : xpath expression for finding the parent element.

            * v_old_max_sp_recursion_depth : Recursion is required for shifting child levels while building the tree.
                                             So the SESSION max_sp_recursion_depth is changed to allow for the
                                             needed recursion depth and then reset at the end of the procedure.
            * v_vspacing                   : The spacing in the vertical direction between the elements.
            * v_hspacing                   : The spacing in the horizontal direction between levels of elements.
       */
      DECLARE v_isenabled enum('YES','NO', 'PARTIAL') DEFAULT NULL;
      DECLARE v_l, v_g, v_e, v_num_levels, v_num_groups, v_num_elements int unsigned DEFAULT 0;
      DECLARE v_maxwidth, v_line_num, v_num_children, v_start_tag, v_end_tag int unsigned DEFAULT 0;
      DECLARE v_min_line, v_max_line, v_child, v_child_line int unsigned DEFAULT 0;
      DECLARE v_total_max_line int unsigned DEFAULT 0;
      DECLARE v_output, v_oxml, v_level_widths mediumtext DEFAULT '';
      DECLARE v_child_prev, v_child_next varchar(90);
      DECLARE v_element, v_name, v_color_name, v_parent, v_next_element, v_prev_element, v_tmp, v_cell text DEFAULT NULL;
      DECLARE v_l_path, v_g_path, v_e_path, v_group, v_elem, v_p_path varchar(92) DEFAULT ''; -- xpaths
      DECLARE v_old_max_sp_recursion_depth tinyint unsigned DEFAULT 0;
      DECLARE v_vspacing tinyint unsigned DEFAULT 1;
      DECLARE v_hspacing tinyint unsigned DEFAULT 5;

      SET v_l_path       = '//l',
          v_g_path       = '//l[$v_l]/g',
          v_e_path       = '//l[$v_l]/g[$v_g]/e',
          v_group        = '//l[$v_l]/g[$v_g]',
          v_elem         = '//l[$v_l]/g[$v_g]/e[$v_e]',
          v_p_path       = '//l[$v_l+1]/g[@parent=$v_element]/e',
          v_oxml         = '',
          v_level_widths = '';

      -- Walk through the xml and determine on which lines each element will go
      SET v_num_levels   = ExtractValue(in_xml, CONCAT('count(', v_l_path, ')')),
          v_l            = v_num_levels;

      -- We may need a recursive call to xmltree_shift_children. This can at most be v_num_levels - 1 levels deep.
      SET v_old_max_sp_recursion_depth = @@max_sp_recursion_depth;
      SET SESSION max_sp_recursion_depth = v_num_levels - 1;
      WHILE (v_l > 0) DO
         -- Go through each element at the level
         SET v_num_groups    = ExtractValue(in_xml, CONCAT('count(', v_g_path, ')')),
             v_g             = 0,
             v_line_num      = 0,
             v_maxwidth      = 0;
         WHILE (v_g < v_num_groups) DO
            SET v_g              = v_g + 1,
                v_num_elements   = ExtractValue(in_xml, CONCAT('count(', v_e_path, ')')),
                v_parent         = ExtractValue(in_xml, CONCAT(v_group, '/@parent')),
                v_e              = 0;
            WHILE (v_e < v_num_elements) DO
               SET v_e            = v_e + 1,
                   v_element      = ExtractValue(in_xml, v_elem),
                   v_isenabled    = CASE ExtractValue(in_xml, CONCAT(v_elem, '/@enabled'))
                                       WHEN 'YES' THEN 'YES'
                                       WHEN 'PARTIAL' THEN 'PARTIAL'
                                       ELSE 'NO'
                                    END,
                   v_name         = xmltree_get_name(in_substr_split, in_replace_needle, in_replace_value, in_color, in_xml, v_l, v_g, v_e),
                   v_maxwidth     = GREATEST(v_maxwidth, CHAR_LENGTH(v_name)),
                   v_num_children = ExtractValue(in_xml, CONCAT('count(', v_p_path, ')'));

               IF (v_num_children = 0) THEN
                  SET v_line_num    = v_line_num + 1;
               ELSE
                  SET v_min_line = NULL,
                      v_max_line = 0,
                      v_child    = 0;

                  WHILE (v_child < v_num_children) DO
                     SET v_child      = v_child + 1,
                         v_child_line = ExtractValue(
                                           v_oxml,
                                           '/e[@parent=$v_element][$v_child]/@line'
                                        ),
                         v_min_line   = IF(v_min_line IS NULL, v_child_line, LEAST(v_min_line, v_child_line)),
                         v_max_line   = GREATEST(v_max_line, v_child_line);
                  END WHILE;
                  -- The minimum allowed line number is:
                  --    v_min_line must be at least v_vspacing below the v_line_num (+ 1 as v_line_num is the last used line)
                  IF (v_line_num + 1 > v_min_line) THEN
                     -- Push the child levels down
                     CALL xmltree_shift_lines(v_oxml, v_element, v_l, v_max_line, v_line_num - v_min_line + 1);
                     SET v_line_num = v_line_num + 1 + FLOOR((v_max_line-v_min_line)/2);
                  ELSE
                     SET v_line_num = v_min_line + FLOOR((v_max_line-v_min_line)/2);
                  END IF;
               END IF;

               SET v_oxml     = CONCAT(
                                   v_oxml,
                                   '<e',
                                   ' level="', v_l, '"',
                                   ' line="', v_line_num, '"',
                                   ' parent="', v_parent, '"',
                                   ' element="', v_element, '"',
                                   ' name="', v_name, '"',
                                   ' enabled="', v_isenabled, '"',
                                   '/>'
                                ),
                   v_line_num = v_line_num + v_vspacing;
            END WHILE;
         END WHILE;

         SET v_level_widths = CONCAT(v_level_widths, '<l level="', v_l, '" maxwidth="', v_maxwidth, '" />'),
             v_l            = v_l - 1;
      END WHILE;
      
      -- Find the largest line number
      -- Unfortunately ExtractValue(..., max(...)) doesn't work
      SET v_num_elements = ExtractValue(v_oxml, 'count(/e)'),
          v_e            = 0;
      WHILE (v_e < v_num_elements) DO
         SET v_e              = v_e + 1,
             v_total_max_line = GREATEST(v_total_max_line, ExtractValue(v_oxml, '/e[$v_e]/@line'));
      END WHILE;
      
      SET v_elem         = '/e[@level=$v_l and @line=$v_line_num]',
          in_xml         = NULL,
          v_line_num     = 0;
      WHILE (v_line_num < v_total_max_line) DO
         SET v_line_num = v_line_num + 1,
             v_l        = 0,
             v_output   = CONCAT(v_output, '\n');
         WHILE (v_l < v_num_levels) DO
            SET v_l             = v_l + 1,
                v_start_tag     = LOCATE(CONCAT('<e level="', v_l, '" line="', v_line_num, '"'), v_oxml),
                v_end_tag       = LOCATE('<e ', v_oxml, v_start_tag+1),
                v_end_tag       = IF(v_end_tag > 0, v_end_tag, CHAR_LENGTH(v_oxml)+1), -- If v_end_tag = 0, grap to the end of the line
                v_tmp           = IF(v_start_tag > 0, SUBSTRING(v_oxml, v_start_tag, (v_end_tag-v_start_tag)), ''),
                v_element       = ExtractValue(v_tmp, '/e/@element'),
                v_name          = ExtractValue(v_tmp, '/e/@name'),
                v_maxwidth      = ExtractValue(v_level_widths, '/l[@level=$v_l]/@maxwidth');
            IF (v_name <> '') THEN
               SET v_isenabled      = ExtractValue(v_tmp,'/e/@enabled'),
                   v_color_name     = IF(in_color, CONCAT(color(v_isenabled), v_name, color('OFF')), v_name),
                   v_child_prev     = 'count(/e[@level=$v_l+1 and @line<$v_line_num and @parent=$v_element][last()])',
                   v_child_next     = 'count(/e[@level=$v_l+1 and @line>$v_line_num and @parent=$v_element][1])';

               IF (LOCATE(CONCAT('<e level="', v_l+1, '" line="', v_line_num, '" parent="', v_element, '"'), v_oxml)) THEN
                  -- There's a child on the same line
                  SET v_cell = CONCAT(v_color_name, REPEAT('-', v_maxwidth-CHAR_LENGTH(v_name)), REPEAT('-', FLOOR(v_hspacing/2)), '+', REPEAT('-', v_hspacing-FLOOR(v_hspacing/2)-1));
               ELSEIF (LOCATE(CONCAT('<e level="', v_l+1, '" line="', v_line_num, '"'), v_oxml)) THEN
                  -- There's a child of another parent on the same line
                  SET v_cell = CONCAT(v_color_name, SPACE(v_maxwidth-CHAR_LENGTH(v_name) + FLOOR(v_hspacing/2)), '+', REPEAT('-', v_hspacing-FLOOR(v_hspacing/2)-1));
               ELSEIF (ExtractValue(v_oxml, v_child_prev)
                       OR ExtractValue(v_oxml, v_child_next)
                      ) THEN
                  -- There's a child of this element that is not on the same line
                  SET v_cell = CONCAT(v_color_name, REPEAT('-', v_maxwidth-CHAR_LENGTH(v_name)), REPEAT('-', FLOOR(v_hspacing/2)), '+', SPACE(v_hspacing-FLOOR(v_hspacing/2)-1));
               ELSE
                  -- This element is a leaf node
                  SET v_cell = CONCAT(v_color_name, SPACE(v_maxwidth-CHAR_LENGTH(v_name)+v_hspacing));
               END IF;
            ELSE
               SET v_next_element   = ExtractValue(v_oxml, '/e[@level=$v_l and @line>$v_line_num][1]/@element'),
                   v_prev_element   = ExtractValue(v_oxml, '/e[@level=$v_l and @line<$v_line_num][last()]/@element'),
                   v_child_prev     = 'count(/e[@level=$v_l+1 and @line<$v_line_num and @parent=$v_next_element][last()])',
                   v_child_next     = 'count(/e[@level=$v_l+1 and @line>$v_line_num and @parent=$v_prev_element][1])';

               IF (LOCATE(CONCAT('<e level="', v_l+1, '" line="', v_line_num, '"'), v_oxml)) THEN
                  -- There's a child on the same line
                  SET v_cell = CONCAT(SPACE(v_maxwidth+FLOOR(v_hspacing/2)), '+', REPEAT('-', v_hspacing-FLOOR(v_hspacing/2)-1));
               ELSEIF (ExtractValue(v_oxml, v_child_prev) OR ExtractValue(v_oxml, v_child_next)) THEN
                  -- There's a child of this element that is not on the same line
                  SET v_cell = CONCAT(SPACE(v_maxwidth+FLOOR(v_hspacing/2)), '|', SPACE(v_hspacing-FLOOR(v_hspacing/2)-1));
               ELSE
                  -- This is an empty cell
                  SET v_cell = SPACE(v_maxwidth + v_hspacing);
               END IF;
            END IF;
            SET v_output = CONCAT(v_output, v_cell);
         END WHILE;
         SET v_output = RTRIM(v_output);
      END WHILE;

      IF (CHAR_LENGTH(v_output) > 0) THEN
         SET v_output = CONCAT(v_output, '\n\n', xmltree_legend(in_color));
      END IF;

      SET SESSION max_sp_recursion_depth = v_old_max_sp_recursion_depth;
      RETURN v_output;
    END//
DELIMITER ;


/**
 * Function: xmltree_topbottom()
 * 
 * Convert an xml representation of the p_s settings into
 * a tree. The tree is from up and down (similar to rankdir=UP in the dot format).
 *
 * Parameters
 *   in_substr_split .....: If set, then the elements will be split using this string
 *                          to get the individual parts. E.g. wait/io/table/sql/handler
 *                          so only the part belonging to the level will actually be
 *                          printed. So in_substr_split = '/' and level 3 will display
 *                          "table".
 *   in_replace_needle ...: If set, a replace will be done against this needle in the
 *                          element names before including them in the output.
 *   in_replace_value ....: If a replace is done, the needle is replaced with this
 *                          value.
 *   in_color ............: Boolean, whether to use bash colors in the output.
 *   in_xml ..............: The XML with the definition of the tree.
 *   
 * Returns
 *   A mediumtext with the expanded tree.
 *
 * mysql> SELECT xmltree_topbottom('', '', '', FALSE, '<consumers><l><g><e enabled="YES">global_instrumentation</e></g></l><l><g parent="global_instrumentation"><e enabled="YES">statements_digest</e><e enabled="YES">thread_instrumentation</e></g></l><l><g parent="thread_instrumentation"><e enabled="NO">events_stages_current</e><e enabled="YES">events_statements_current</e><e enabled="NO">events_waits_current</e></g></l><l><g parent="events_stages_current"><e enabled="NO">events_stages_history</e><e enabled="NO">events_stages_history_long</e></g><g parent="events_statements_current"><e enabled="NO">events_statements_history</e><e enabled="NO">events_statements_history_long</e></g><g parent="events_waits_current"><e enabled="NO">events_waits_history</e><e enabled="NO">events_waits_history_long</e></g></l></consumers>') AS 'Consumers'\G
 * *************************** 1. row ***************************
 * Consumers:
 *                                             <global_instrumentation>
 *                                                        |
 *               +----------------------------------------+----------------------------------------+
 *               |                                                                                 |
 *      <statements_digest>                                                             <thread_instrumentation>
 *                                                                                                 |
 *                               +-----------------------------------------------------------------+-----------------------------------------------------------------+
 *                               |                                                                 |                                                                 |
 *                     events_stages_current                                          <events_statements_current>                                           events_waits_current
 *                               |                                                                 |                                                                 |
 *               +---------------+----------------+                                +---------------+----------------+                                +---------------+----------------+
 *               |                                |                                |                                |                                |                                |
 *     events_stages_history          events_stages_history_long       events_statements_history      events_statements_history_long        events_waits_history          events_waits_history_long
 * 
 * Legend: <Enabled> - [Partially enabled] - Disabled
 * 1 row in set (0.01 sec)
 */
DELIMITER //
   CREATE
 FUNCTION xmltree_topbottom(
                         in_substr_split char(1), in_replace_needle varchar(20), in_replace_value varchar(20),
                         in_color bool, in_xml mediumtext
          ) RETURNS mediumtext
  COMMENT 'Returns an expanded tree.'
 LANGUAGE SQL DETERMINISTIC NO SQL SQL SECURITY INVOKER
   BEGIN
      DECLARE v_isenabled enum('YES','NO', 'PARTIAL') DEFAULT NULL;
      DECLARE v_l, v_g, v_e, v_maxwidth int unsigned DEFAULT 0;
      DECLARE v_num_levels, v_num_groups, v_num_elements, v_line_intersect, v_line2_length int unsigned DEFAULT 0;
      DECLARE v_l_path, v_g_path, v_e_path, v_group, v_elem varchar(90) DEFAULT '';
      DECLARE v_output, v_line, v_line_no_color, v_line1, v_line2, v_line3, v_offsets mediumtext DEFAULT '';
      DECLARE v_lpad, v_rpad, v_parent, v_name text DEFAULT NULL;
      DECLARE v_grp_offset, v_join_offset, v_join_space int unsigned DEFAULT 0;
      DECLARE v_offset, v_line_length, v_last_offset, v_first_offset int unsigned DEFAULT 0;
      DECLARE v_whitespace tinyint unsigned DEFAULT 3;

      SET v_l_path = '//l',
          v_g_path = '//l[$v_l]/g',
          v_e_path = '//l[$v_l]/g[$v_g]/e',
          v_group  = '//l[$v_l]/g[$v_g]',
          v_elem   = '//l[$v_l]/g[$v_g]/e[$v_e]';

      -- Find the max width of any element
      SET v_num_levels = ExtractValue(in_xml, CONCAT('count(', v_l_path, ')')),
          v_l          = 0;
      WHILE (v_l < v_num_levels) DO
         SET v_l          = v_l + 1,
             v_num_groups = ExtractValue(in_xml, CONCAT('count(', v_g_path, ')')),
             v_g          = 0;
         WHILE (v_g < v_num_groups) DO
            SET v_g              = v_g + 1,
                v_num_elements   = ExtractValue(in_xml, CONCAT('count(', v_e_path, ')')),
                v_e              = 0;
            WHILE (v_e < v_num_elements) DO
               SET v_e         = v_e + 1,
                   v_name      = xmltree_get_name(in_substr_split, in_replace_needle, in_replace_value, in_color, in_xml, v_l, v_g, v_e),
                   v_maxwidth  = GREATEST(v_maxwidth, CHAR_LENGTH(v_name));
            END WHILE;
         END WHILE;
      END WHILE;

      -- Find the offsets
      SET v_l = v_num_levels;
      WHILE (v_l > 0) DO
         -- Go through each element at the level
         SET v_num_groups    = ExtractValue(in_xml, CONCAT('count(', v_g_path, ')')),
             v_g             = 0,
             v_line_no_color = '';
         WHILE (v_g < v_num_groups) DO
            SET v_g              = v_g + 1,
                v_num_elements   = ExtractValue(in_xml, CONCAT('count(', v_e_path, ')')),
                v_parent         = ExtractValue(in_xml, CONCAT(v_group, '/@parent')),
                v_e              = 0,
                v_first_offset   = 0,
                v_last_offset    = 0;
            WHILE (v_e < v_num_elements) DO
               SET v_e             = v_e + 1,
                   v_name          = xmltree_get_name(in_substr_split, in_replace_needle, in_replace_value, in_color, in_xml, v_l, v_g, v_e),
                   v_grp_offset    = ExtractValue(v_offsets, CONCAT('/group[@level="', (v_l+1), '" and @name="', ExtractValue(in_xml, v_elem), '"]/@offset')),
                   v_line_length   = CHAR_LENGTH(v_line_no_color),
                   v_offset        = IF(v_grp_offset > v_line_length, v_grp_offset-v_line_length, 0),
                   v_lpad          = SPACE(FLOOR((v_maxwidth-CHAR_LENGTH(v_name))/2)),
                   v_rpad          = SPACE(CEIL((v_maxwidth-CHAR_LENGTH(v_name))/2)),
                   v_line_no_color = CONCAT(
                                        v_line_no_color,
                                        SPACE(v_offset),
                                        IF(v_line_length > 0 AND v_grp_offset = 0, SPACE(v_whitespace), ''),
                                        v_lpad,
                                        v_name,
                                        v_rpad
                                     );
               IF (v_e = 1) THEN
                  SET v_first_offset = GREATEST(v_grp_offset, v_line_length) + IF(v_line_length > 0 AND v_grp_offset = 0, v_whitespace, 0);
               END IF;
               IF (v_e = v_num_elements) THEN
                  SET v_last_offset  = GREATEST(v_grp_offset, v_line_length) + IF(v_line_length > 0 AND v_grp_offset = 0, v_whitespace, 0);
               END IF;
            END WHILE;
            SET v_offsets = CONCAT(
                               v_offsets,
                               '<group ',
                                  'level="', v_l, '" ',
                                  'name="', v_parent, '" ',
                                  'first_offset="', v_first_offset, '" ',
                                  'last_offset="', v_last_offset, '" ',
                                  'offset="', v_first_offset+FLOOR((v_last_offset-v_first_offset)/2), '" ',
                               '/>'
                            );
         END WHILE;
         
         SET v_l = v_l - 1;
      END WHILE;

      -- Create the output
      SET v_l = v_num_levels;
      WHILE (v_l > 0) DO
         -- Go through each element at the level
         SET v_num_groups    = ExtractValue(in_xml, CONCAT('count(', v_g_path, ')')),
             v_g             = 0,
             v_line          = '',
             v_line_no_color = '',
             v_line1         = '',
             v_line2         = '',
             v_line3         = '';
         WHILE (v_g < v_num_groups) DO
            SET v_g              = v_g + 1,
                v_num_elements   = ExtractValue(in_xml, CONCAT('count(', v_e_path, ')')),
                v_parent         = ExtractValue(in_xml, CONCAT(v_group, '/@parent')),
                v_e              = 0;
            WHILE (v_e < v_num_elements) DO
               SET v_e             = v_e + 1,
                   v_name          = xmltree_get_name(in_substr_split, in_replace_needle, in_replace_value, in_color, in_xml, v_l, v_g, v_e),
                   v_isenabled    = CASE ExtractValue(in_xml, CONCAT(v_elem, '/@enabled'))
                                       WHEN 'YES' THEN 'YES'
                                       WHEN 'PARTIAL' THEN 'PARTIAL'
                                       ELSE 'NO'
                                    END,
                   v_grp_offset    = ExtractValue(v_offsets, CONCAT('/group[@level="', (v_l+1), '" and @name="', ExtractValue(in_xml, v_elem), '"]/@offset')),
                   v_line_length   = CHAR_LENGTH(v_line_no_color),
                   v_offset        = IF(v_grp_offset > v_line_length, v_grp_offset-v_line_length, 0),
                   v_lpad          = SPACE(FLOOR((v_maxwidth-CHAR_LENGTH(v_name))/2)),
                   v_rpad          = SPACE(CEIL((v_maxwidth-CHAR_LENGTH(v_name))/2)),
                   v_line1         = CONCAT(
                                        v_line1,
                                        SPACE(v_line_length-CHAR_LENGTH(v_line1)+v_offset),
                                        IF(v_line_length > 0 AND v_grp_offset = 0, SPACE(v_whitespace), ''),
                                        SPACE(FLOOR((v_maxwidth-1)/2)),
                                        '|'
                                     ),
                   v_join_offset   = ExtractValue(v_offsets, CONCAT('/group[@level=$v_l and @name=$v_parent]/@offset')) + FLOOR((v_maxwidth-1)/2),
                   v_join_space    = IF(
                                        v_join_offset >= CHAR_LENGTH(v_line3),
                                        v_join_offset-CHAR_LENGTH(v_line3),
                                        0
                                       ),
                   v_line3         = CONCAT(v_line3, SPACE(v_join_space)),
                   v_line3         = IF(
                                        v_join_offset = CHAR_LENGTH(v_line3),
                                        CONCAT(v_line3, '|'),
                                        v_line3
                                     ),
                   v_line_no_color = CONCAT(
                                        v_line_no_color,
                                        SPACE(v_offset),
                                        IF(v_line_length > 0 AND v_grp_offset = 0, SPACE(v_whitespace), ''),
                                        v_lpad,
                                        v_name,
                                        v_rpad
                                     ),
                   v_line          = CONCAT(
                                        v_line,
                                        SPACE(v_offset),
                                        IF(v_line_length > 0 AND v_grp_offset = 0, SPACE(v_whitespace), ''),
                                        v_lpad,
                                        IF(in_color, CONCAT(color(v_isenabled), v_name, color('OFF')), v_name),
                                        v_rpad
                                     );

               /*
                  Create the line that connects the |s for the children and the parent.
                  The following variables are used:
                       v_line_intersect : Where an | exists for either a child or a parent.
                       v_line2_length   : The current lenght of v_line2
                       v_first_offset   : The first location of a + for v_line2 for the current parent and children.
                       v_last_offset    : The last location of a + for v_line2 for the current parent and children.
                */
               SET v_line_length    = CHAR_LENGTH(v_line_no_color),
                   v_line2_length   = CHAR_LENGTH(v_line2),
                   v_line_intersect = CHAR_LENGTH(v_line1)-1,
                   v_line2_length   = CHAR_LENGTH(v_line2),
                   v_first_offset   = ExtractValue(v_offsets, CONCAT('/group[@level="', (v_l), '" and @name="', v_parent, '"]/@first_offset'))
                                      + FLOOR((v_maxwidth-1)/2),
                   v_last_offset    = ExtractValue(v_offsets, CONCAT('/group[@level="', (v_l), '" and @name="', v_parent, '"]/@last_offset'))
                                      + FLOOR((v_maxwidth-1)/2);
               WHILE (v_line2_length < v_line_length) DO
                  IF (v_line2_length = v_line_intersect) THEN
                     -- Connect down to child (element)
                     SET v_line2 = CONCAT(v_line2, '+');
                  ELSEIF (v_line2_length = v_join_offset) THEN
                     -- Connect up to parent
                     SET v_line2 = CONCAT(v_line2, '+');
                  ELSEIF (v_line2_length BETWEEN v_first_offset AND v_last_offset) THEN
                     SET v_join_space = GREATEST(
                                           LEAST(
                                              IF(v_line_intersect > v_line2_length, v_line_intersect, v_last_offset),
                                              IF(v_join_offset > v_line2_length, v_join_offset, v_last_offset),
                                              v_line_length
                                           ) - v_line2_length,
                                           1
                                        );
                     SET v_line2 = CONCAT(v_line2, REPEAT('-', v_join_space));
                  ELSE
                     -- Add spaces until the next time a + or a - can occur
                     -- Wrap a GREATEST(..., v_line2_length) around v_line_intersect and v_first_offset
                     -- as these may be before the current position.
                     -- Add at leats one space
                     SET v_join_space = GREATEST(
                                           LEAST(
                                              IF(v_line_intersect > v_line2_length, v_line_intersect, GREATEST(v_last_offset, v_line_length)),
                                              IF(v_join_offset > v_line2_length, v_join_offset, GREATEST(v_last_offset, v_line_length)),
                                              v_line_length
                                           ) - v_line2_length,
                                           1
                                        );
                     SET v_line2 = CONCAT(v_line2, SPACE(v_join_space));
                  END IF;
                  SET v_line2_length = CHAR_LENGTH(v_line2);
               END WHILE;
            END WHILE;
         END WHILE;

         SET v_output = CONCAT(
                           IF(v_l > 1, CONCAT(RTRIM(v_line3), '\n', RTRIM(v_line2), '\n', RTRIM(v_line1), '\n'), ''),
                           RTRIM(v_line),
                           IF(LENGTH(v_output) > 0, '\n', ''),
                           v_output
                        );
         
         SET v_l = v_l - 1;
      END WHILE;

      IF (CHAR_LENGTH(v_output) > 0) THEN
         SET v_output = CONCAT(v_output, '\n\n', xmltree_legend(in_color));
      END IF;

      RETURN CONCAT('\n', v_output);
    END//
DELIMITER ;


/**
 * Function: xmltree_dot()
 * 
 * Convert an xml representation of the p_s settings into a tree using the dot format.
 *
 * Parameters
 *   in_substr_split .....: If set, then the elements will be split using this string
 *                          to get the individual parts. E.g. wait/io/table/sql/handler
 *                          so only the part belonging to the level will actually be
 *                          printed. So in_substr_split = '/' and level 3 will display
 *                          "table".
 *   in_replace_needle ...: If set, a replace will be done against this needle in the
 *                          element names before including them in the output.
 *   in_replace_value ....: If a replace is done, the needle is replaced with this
 *                          value.
 *   in_orientation ......: Whether to use the Left-Right or Top-Bottom direction.
 *   in_xml ..............: The XML with the definition of the tree.
 *   
 * Returns
 *   A mediumtext with the dot file.
 */
DELIMITER //
   CREATE
 FUNCTION xmltree_dot(
                      in_substr_split char(1), in_replace_needle varchar(20), in_replace_value varchar(20),
                      in_orientation enum('Left-Right', 'Top-Bottom'), in_xml mediumtext
          ) RETURNS mediumtext
  COMMENT 'Returns the dot formatted tree.'
 LANGUAGE SQL DETERMINISTIC NO SQL SQL SECURITY INVOKER
   BEGIN
      DECLARE v_isenabled enum('YES','NO', 'PARTIAL') DEFAULT NULL;
      DECLARE v_error varchar(100) DEFAULT '';
      DECLARE v_l, v_g, v_e int unsigned DEFAULT 0;
      DECLARE v_num_levels, v_num_groups, v_num_elements int unsigned DEFAULT 0;
      DECLARE v_l_path, v_g_path, v_e_path, v_group, v_elem varchar(90) DEFAULT '';
      DECLARE v_parent, v_name, v_element text DEFAULT NULL;
      DECLARE v_output mediumtext DEFAULT '';

      SET v_l_path = '//l',
          v_g_path = '//l[$v_l]/g',
          v_e_path = '//l[$v_l]/g[$v_g]/e',
          v_group  = '//l[$v_l]/g[$v_g]',
          v_elem   = '//l[$v_l]/g[$v_g]/e[$v_e]';
      
      IF (in_orientation NOT IN ('Top-Bottom', 'Left-Right')) THEN
         SET v_error = 'Unknown orientation. Use ''Top-Bottom'' or ''Left-Right''';
         SIGNAL SQLSTATE 'HY000'
            SET MESSAGE_TEXT = 'Unknown orientation. Use ''Top-Bottom'' or ''Left-Right''',
                MYSQL_ERRNO  = 1644;
      END IF;

      /* Print headers for a .dot file */
      SET v_output = CONCAT(
                        'digraph events { rankdir=', IF(in_orientation = 'Top-Bottom', 'TB', 'LR'), '; nodesep=0.10;\n',
                        '   // Tree created: ', NOW(), '\n',
                        '   // MySQL version: ', VERSION(), '\n',
                        '   // MySQL hostname: ', @@hostname, '\n',
                        '   // MySQL port: ', @@port, '\n',
                        '   // MySQL socket: ', @@socket, '\n',
                        '   // MySQL user: ', CURRENT_USER(), '\n'
                     );

      SET v_num_levels = ExtractValue(in_xml, CONCAT('count(', v_l_path, ')')),
          v_l          = 0;
      WHILE (v_l < v_num_levels) DO
         SET v_l          = v_l + 1,
             v_num_groups = ExtractValue(in_xml, CONCAT('count(', v_g_path, ')')),
             v_g          = 0;
         WHILE (v_g < v_num_groups) DO
            SET v_g              = v_g + 1,
                v_num_elements   = ExtractValue(in_xml, CONCAT('count(', v_e_path, ')')),
                v_parent         = ExtractValue(in_xml, CONCAT(v_group, '/@parent')),
                v_e              = 0;
            WHILE (v_e < v_num_elements) DO
               SET v_e         = v_e + 1,
                   v_element   = ExtractValue(in_xml, v_elem),
                   v_name      = xmltree_get_name(in_substr_split, in_replace_needle, in_replace_value, TRUE, in_xml, v_l, v_g, v_e),
                   v_isenabled = CASE ExtractValue(in_xml, CONCAT(v_elem, '/@enabled'))
                                    WHEN 'YES' THEN 'YES'
                                    WHEN 'PARTIAL' THEN 'PARTIAL'
                                    ELSE 'NO'
                                 END,
                   v_output    = CONCAT(v_output, xmltree_dot_line(v_parent, v_element, v_name, v_isenabled, in_orientation), '\n');
            END WHILE;
         END WHILE;
      END WHILE;

      SET v_output = concat(v_output, '}');
      RETURN v_output;
   END//
DELIMITER ;


/**
 * Function: is_account_enabled()
 * 
 * Determines whether instrumentation of an account is enabled.
 *
 * Parameters
 *   in_host .....: The hostname of the account to check.
 *   in_user .....: The username of the account to check.
 *   
 * Returns
 *   An enum whether the account is enabled or not.
 *
 * mysql> SELECT is_account_enabled('localhost', 'root');
 * +-----------------------------------------+
 * | is_account_enabled('localhost', 'root') |
 * +-----------------------------------------+
 * | YES                                     |
 * +-----------------------------------------+
 * 1 row in set (0.00 sec)
 */
   CREATE
  DEFINER='root'@'localhost'
 FUNCTION is_account_enabled(in_host VARCHAR(60), in_user VARCHAR(16)) RETURNS enum('YES','NO', 'PARTIAL')
  COMMENT 'Returns whether a user account is enabled.'
 LANGUAGE SQL DETERMINISTIC READS SQL DATA SQL SECURITY INVOKER
    RETURN IF(EXISTS(SELECT 1
                       FROM performance_schema.setup_actors
                      WHERE     (`HOST` = '%' OR `HOST` = in_host)
                            AND (`USER` = '%' OR `USER` = in_user)
                    ),
              'YES', 'NO'
           );


/**
 * View: accounts_enabled
 *
 * For each display whether the view is enabled.
 *
 */
CREATE OR REPLACE SQL SECURITY INVOKER VIEW accounts_enabled AS
SELECT `User`, `Host`, is_account_enabled(Host, User) AS 'Enabled'
  FROM mysql.user;


/**
 * Procedure: setup_tree_instruments()
 * 
 * Display a tree of the p_s instruments and whether they are enabled or not.
 * When selecting from setup_instruments, ' I/O ' is replaced with ' I{||}O ' to
 * remove the disambiguaty of whether a / is a path separator or in I/O. In the
 * output functions, the reverse replacement will be made.
 * 
 * Currently a maximum of 10 levels are supported - as of 5.6.11 no instruments have more than 5 parts.
 *
 * Parameters
 *   in_format ........: The format to display the three in. Supported formats are:
 *                          * Text: Left-Right
 *                          * Dot: Left-Right
 *                          * Dot: Top-Bottom
 *   in_color .........: Whether to output with bash colors. Only applicable for text formats.
 *   in_type ..........: Whether to display ENABLED or TIMED.
 *   in_onlyenabled ...: Only include enabled instruments.
 *   in_filter ........: A regex for filtering. Empty or NULL includes all instruments.
 *   
 * Outputs
 *   The tree of the instruments.
 */
DELIMITER //
   CREATE
  DEFINER='root'@'localhost'
PROCEDURE setup_tree_instruments(
             IN in_format enum('Text: Left-Right', 'Dot: Left-Right', 'Dot: Top-Bottom'),
             IN in_color bool, IN in_type enum('Enabled', 'Timed'), IN in_onlyenabled bool,
             IN in_filter varchar(128)
          )
  COMMENT 'Prints the instruments and whether they are enabled in the performance_schema.'
 LANGUAGE SQL DETERMINISTIC READS SQL DATA SQL SECURITY INVOKER
   BEGIN
      DECLARE v_xml mediumtext DEFAULT '';
      DECLARE v_error varchar(100) DEFAULT '';
      DECLARE v_num_enabled, v_num_timed, v_num_total int unsigned DEFAULT 0;
      DECLARE v_isenabled enum('YES','NO', 'PARTIAL') DEFAULT NULL;
      DECLARE v_current_level, v_level tinyint UNSIGNED DEFAULT 0;
      DECLARE v_part, v_parent, v_current_parent varchar(128) DEFAULT NULL;
      DECLARE v_done, v_include bool DEFAULT FALSE;
      DECLARE c_instruments CURSOR FOR
         SELECT DISTINCT SUBSTRING_INDEX(REPLACE(i.NAME, ' I/O ', ' I{||}O '), '/', a.i) AS Part,
                a.i AS Level, SUM(IF(i.ENABLED = 'YES', 1, 0)) AS NumEnabled,
                SUM(IF(i.TIMED = 'YES', 1, 0)) AS NumTimed, COUNT(*) AS NumTotal
           FROM (SELECT 1 AS i UNION SELECT 2 AS i UNION SELECT 3 AS i UNION SELECT 4 AS i UNION SELECT  5 AS i UNION
                 SELECT 6 AS i UNION SELECT 7 AS i UNION SELECT 8 AS i UNION SELECT 9 AS i UNION SELECT 10 AS i) a
                INNER JOIN performance_schema.setup_instruments i ON
                      substr_count(REPLACE(i.NAME, ' I/O ', ' I{||}O '), '/', 0, NULL) >= (a.i-1)
          GROUP BY a.i, Part
          ORDER BY a.i, Part;
           
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

      IF (in_format NOT IN ('Text: Left-Right', 'Dot: Left-Right', 'Dot: Top-Bottom')) THEN
         SET v_error = 'Unknown format. Use ''Text: Left-Right'', ''Dot: Left-Right'' or ''Dot: Top-Bottom''';
         SIGNAL SQLSTATE 'HY000'
            SET MESSAGE_TEXT = v_error,
                MYSQL_ERRNO  = 1644;
      END IF;

      IF (in_type NOT IN ('Enabled', 'Timed')) THEN
         SET v_error = 'Unknown type. Use ''Enabled'' or ''Timed''';
         SIGNAL SQLSTATE 'HY000'
            SET MESSAGE_TEXT = v_error,
                MYSQL_ERRNO  = 1644;
      END IF;

      SET v_done           = 0,
          v_current_level  = 0,
          v_current_parent = NULL,
          v_xml            = '<instruments>';

      OPEN c_instruments;
      c_instruments_loop: LOOP
         FETCH c_instruments INTO v_part, v_level, v_num_enabled, v_num_timed, v_num_total;
         IF v_done THEN
            LEAVE c_instruments_loop;
         END IF;

         IF (in_type = 'Enabled') THEN
            SET v_isenabled = CASE
                                 WHEN v_num_enabled = 0 THEN 'NO'
                                 WHEN v_num_enabled = v_num_total THEN 'YES'
                                 ELSE 'PARTIAL'
                              END;
         ELSE
            SET v_isenabled = CASE
                                 WHEN v_num_timed = 0 THEN 'NO'
                                 WHEN v_num_timed = v_num_total THEN 'YES'
                                 ELSE 'PARTIAL'
                              END;
         END IF;

         SET v_parent = SUBSTRING_INDEX(v_part, '/', v_level-1);

         IF (in_onlyenabled AND v_isenabled NOT IN ('YES', 'PARTIAL')) THEN
            SET v_include = 0;
         ELSEIF (in_filter IS NULL OR in_filter IN ('', '.*')) THEN
            SET v_include = 1;
         ELSE
            SET v_include = EXISTS(
               SELECT 1
                 FROM performance_schema.setup_instruments
                WHERE     NAME REGEXP in_filter
                      AND SUBSTRING_INDEX(REPLACE(NAME, ' I/O ', ' I{||}O '), '/', v_level) = v_part
            );
         END IF;

         IF (v_include) THEN
            IF (v_current_parent IS NOT NULL AND v_current_parent <> v_parent) THEN
               SET v_xml = CONCAT(v_xml, '</g>');
            END IF;
            IF (v_current_level <> v_level) THEN
               IF (v_current_level > 0) THEN
                  SET v_xml = CONCAT(v_xml, '</l>');
               END IF;
               SET v_xml = CONCAT(v_xml, '<l>'),
                  v_current_level  = v_level,
                  v_current_parent = NULL;
               
            END IF;
            IF (v_current_parent IS NULL OR v_current_parent <> v_parent) THEN
               SET v_xml = CONCAT(v_xml, '<g', IF(v_parent <> '', CONCAT(' parent="', v_parent, '"'), ''), '>'),
                  v_current_parent = v_parent;
            END IF;
            
            SET v_xml = CONCAT(
                           v_xml,
                           '<e',
                           ' enabled="', v_isenabled, '"',
                           '>',
                           v_part,
                           '</e>'
                        );
         END IF;
      END LOOP c_instruments_loop;
      CLOSE c_instruments;
      
      SET v_xml = CONCAT(v_xml, '</g></l></instruments>');

      CASE in_format
         WHEN 'Text: Left-Right' THEN
            SELECT xmltree_leftright('/', ' I{||}O ', ' I/O ', in_color, v_xml) AS 'Instruments';
         WHEN 'Dot: Left-Right'  THEN
            SELECT xmltree_dot('/', ' I{||}O ', ' I/O ', SUBSTRING(in_format, 6), v_xml) AS 'Instruments';
         WHEN 'Dot: Top-Bottom' THEN
            SELECT xmltree_dot('/', ' I{||}O ', ' I/O ', SUBSTRING(in_format, 6), v_xml) AS 'Instruments';
      END CASE;
   END//

DELIMITER ;


/**
 * Procedure: setup_tree_actors_by_host()
 * 
 * Display a tree of the actors groubed by host.
 *
 * Parameters
 *   in_format ....: The format to display the three in. Supported formats are:
 *                      * Text: Left-Right
 *                      * Dot: Left-Right
 *                      * Dot: Top-Bottom
 *   in_color .....: Whether to output with bash colors. Only applicable for text formats.
 *   
 * Outputs
 *   The tree of the instruments.
 */
DELIMITER //
   CREATE
  DEFINER='root'@'localhost'
PROCEDURE setup_tree_actors_by_host(IN in_format enum('Text: Left-Right', 'Dot: Left-Right', 'Dot: Top-Bottom'), IN in_color bool)
  COMMENT 'Prints the user accounts and whether they are enabled in the performance_schema.'
 LANGUAGE SQL DETERMINISTIC READS SQL DATA SQL SECURITY INVOKER
   BEGIN
      DECLARE v_xml mediumtext DEFAULT '';
      DECLARE v_error varchar(100) DEFAULT '';
      DECLARE v_isenabled enum('YES','NO', 'PARTIAL') DEFAULT NULL;
      DECLARE v_current_host, v_host varchar(60) DEFAULT NULL;
      DECLARE v_user varchar(16) DEFAULT NULL;
      DECLARE v_num_hosts, v_num_isenabled int unsigned DEFAULT 0;
      DECLARE v_done bool DEFAULT FALSE;
      DECLARE c_hosts CURSOR FOR
         SELECT Host, COUNT(*) AS 'Count',
                SUM(IF(is_account_enabled(Host, User) = 'YES', 1, 0)) AS NumEnabled
           FROM mysql.user
          GROUP BY user.Host
          ORDER BY user.Host;
      DECLARE c_users CURSOR FOR
         SELECT Host, User, is_account_enabled(Host, User) AS IsEnabled FROM mysql.user ORDER BY Host, User;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

      IF (in_format NOT IN ('Text: Left-Right', 'Dot: Left-Right', 'Dot: Top-Bottom')) THEN
         SET v_error = 'Unknown format. Use ''Text: Left-Right'', ''Dot: Left-Right'' or ''Dot: Top-Bottom''';
         SIGNAL SQLSTATE 'HY000'
            SET MESSAGE_TEXT = v_error,
                MYSQL_ERRNO  = 1644;
      END IF;

      SET v_xml            = '<accounts><l><g>';

      OPEN c_hosts;
      c_hosts_loop: LOOP
         FETCH c_hosts INTO v_host, v_num_hosts, v_num_isenabled;
         IF v_done THEN
            LEAVE c_hosts_loop;
         END IF;

         SET v_xml = CONCAT(
                        v_xml,
                        '<e',
                        CASE
                             WHEN v_num_hosts = v_num_isenabled THEN ' enabled="YES"'
                             WHEN v_num_isenabled > 0           THEN ' enabled="PARTIAL"'
                             ELSE                                    ' enabled="NO"'
                        END,
                        '>',
                        v_host,
                        '</e>'
                     );
      END LOOP c_hosts_loop;
      CLOSE c_hosts;

      SET v_done           = 0,
          v_current_host   = NULL,
          v_xml = CONCAT(v_xml, '</g></l><l>');

      OPEN c_users;
      c_users_loop: LOOP
         FETCH c_users INTO v_host, v_user, v_isenabled;
         IF v_done THEN
            LEAVE c_users_loop;
         END IF;

         IF (v_current_host IS NULL OR v_current_host <> v_host) THEN
            IF (v_current_host IS NOT NULL) THEN
               SET v_xml = CONCAT(v_xml, '</g>');
            END IF;
            
            SET v_xml = CONCAT(v_xml, '<g parent="', v_host, '"', '>'),
                v_current_host = v_host;
         END IF;
         
         SET v_xml = CONCAT(
                        v_xml,
                        '<e', 
                        IF(v_isenabled = 'YES', ' enabled="YES"', ' enabled="NO"'),
                        IF(in_color, IF(v_isenabled = 'YES', ' color="enabled"', ' color="disabled"'), ''),
                        '>',
                        v_user,
                        '</e>'
                     );
      END LOOP c_users_loop;
      CLOSE c_users;
      
      SET v_xml = CONCAT(v_xml, '</g></l></accounts>');

      CASE in_format
         WHEN 'Text: Left-Right' THEN
            SELECT xmltree_leftright('', '', '', in_color, v_xml) AS 'Consumers';
         WHEN 'Dot: Left-Right'  THEN
            SELECT xmltree_dot('', '', '', SUBSTRING(in_format, 6), v_xml) AS 'Consumers';
         WHEN 'Dot: Top-Bottom' THEN
            SELECT xmltree_dot('', '', '', SUBSTRING(in_format, 6), v_xml) AS 'Consumers';
      END CASE;
   END//

DELIMITER ;


/**
 * Procedure: setup_tree_actors_by_host()
 * 
 * Display a tree of the actors groubed by host.
 *
 * Parameters
 *   in_format ....: The format to display the three in. Supported formats are:
 *                      * Text: Left-Right
 *                      * Dot: Left-Right
 *                      * Dot: Top-Bottom
 *   in_color .....: Whether to output with bash colors. Only applicable for text formats.
 *   
 * Outputs
 *   The tree of the instruments.
 */
DELIMITER //
   CREATE
  DEFINER='root'@'localhost'
PROCEDURE setup_tree_actors_by_user(IN in_format enum('Text: Left-Right', 'Dot: Left-Right', 'Dot: Top-Bottom'), IN in_color bool)
  COMMENT 'Prints the user accounts and whether they are enabled in the performance_schema.'
 LANGUAGE SQL DETERMINISTIC READS SQL DATA SQL SECURITY INVOKER
   BEGIN
      DECLARE v_xml mediumtext DEFAULT '';
      DECLARE v_error varchar(100) DEFAULT '';
      DECLARE v_isenabled enum('YES','NO', 'PARTIAL') DEFAULT NULL;
      DECLARE v_host varchar(60) DEFAULT NULL;
      DECLARE v_current_user, v_user varchar(16) DEFAULT NULL;
      DECLARE v_num_users, v_num_isenabled int unsigned DEFAULT 0;
      DECLARE v_done bool DEFAULT FALSE;
      DECLARE c_users CURSOR FOR
         SELECT User, COUNT(*) AS 'Count',
                SUM(IF(is_account_enabled(Host, User) = 'YES', 1, 0)) AS NumEnabled
           FROM mysql.user
          GROUP BY user.User
          ORDER BY user.User;
      DECLARE c_hosts CURSOR FOR
         SELECT Host, User, is_account_enabled(Host, User) AS IsEnabled FROM mysql.user ORDER BY User, Host;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

      SET v_xml            = '<accounts><l><g>';

      IF (in_format NOT IN ('Text: Left-Right', 'Dot: Left-Right', 'Dot: Top-Bottom')) THEN
         SET v_error = 'Unknown format. Use ''Text: Left-Right'', ''Dot: Left-Right'' or ''Dot: Top-Bottom''';
         SIGNAL SQLSTATE 'HY000'
            SET MESSAGE_TEXT = v_error,
                MYSQL_ERRNO  = 1644;
      END IF;

      OPEN c_users;
      c_users_loop: LOOP
         FETCH c_users INTO v_user, v_num_users, v_num_isenabled;
         IF v_done THEN
            LEAVE c_users_loop;
         END IF;

         SET v_xml = CONCAT(
                        v_xml,
                        '<e',
                        CASE
                             WHEN v_num_users = v_num_isenabled THEN ' enabled="YES"'
                             WHEN v_num_isenabled > 0           THEN ' enabled="PARTIAL"'
                             ELSE                                    ' enabled="NO"'
                        END,
                        '>',
                        v_user,
                        '</e>'
                     );
      END LOOP c_users_loop;
      CLOSE c_users;

      SET v_done           = 0,
          v_current_user   = NULL,
          v_xml = CONCAT(v_xml, '</g></l><l>');

      OPEN c_hosts;
      c_hosts_loop: LOOP
         FETCH c_hosts INTO v_host, v_user, v_isenabled;
         IF v_done THEN
            LEAVE c_hosts_loop;
         END IF;

         IF (v_current_user IS NULL OR v_current_user <> v_user) THEN
            IF (v_current_user IS NOT NULL) THEN
               SET v_xml = CONCAT(v_xml, '</g>');
            END IF;
            
            SET v_xml = CONCAT(v_xml, '<g parent="', v_user, '"', '>'),
                v_current_user = v_user;
         END IF;
         
         SET v_xml = CONCAT(
                        v_xml,
                        '<e', 
                        IF(v_isenabled = 'YES', ' enabled="YES"', ' enabled="NO"'),
                        IF(in_color, IF(v_isenabled = 'YES', ' color="enabled"', ' color="disabled"'), ''),
                        '>',
                        v_host,
                        '</e>'
                     );
      END LOOP c_hosts_loop;
      CLOSE c_hosts;
      
      SET v_xml = CONCAT(v_xml, '</g></l></accounts>');

      CASE in_format
         WHEN 'Text: Left-Right' THEN
            SELECT xmltree_leftright('', '', '', in_color, v_xml) AS 'Consumers';
         WHEN 'Dot: Left-Right'  THEN
            SELECT xmltree_dot('', '', '', SUBSTRING(in_format, 6), v_xml) AS 'Consumers';
         WHEN 'Dot: Top-Bottom' THEN
            SELECT xmltree_dot('', '', '', SUBSTRING(in_format, 6), v_xml) AS 'Consumers';
      END CASE;
   END//

DELIMITER ;


/**
 * Procedure: setup_tree_consumers()
 * 
 * Display a tree of the p_s consumers and whether they are enabled or not.
 *
 * Parameters
 *   in_format ....: The format to display the three in. Supported formats are:
 *                      * Text: Left-Right
 *                      * Text: Top-Bottom
 *                      * Dot: Left-Right
 *                      * Dot: Top-Bottom
 *   in_color .....: Whether to output with bash colors. Only applicable for text formats.
 *   
 * Outputs
 *   The tree of the instruments.
 */
DELIMITER //
   CREATE
  DEFINER='root'@'localhost'
PROCEDURE setup_tree_consumers(
             IN in_format enum('Text: Left-Right', 'Text: Top-Bottom', 'Dot: Left-Right', 'Dot: Top-Bottom'),
             IN in_color bool
          )
  COMMENT 'Prints the consumers hierarchy with information whether each consumer is effectively enabled.'
 LANGUAGE SQL DETERMINISTIC READS SQL DATA SQL SECURITY INVOKER
   BEGIN
      DECLARE v_done bool DEFAULT FALSE;
      DECLARE v_error varchar(100) DEFAULT '';
      DECLARE v_isenabled enum('YES','NO', 'PARTIAL') DEFAULT NULL;
      DECLARE v_current_level, v_level tinyint DEFAULT 0;
      DECLARE v_current_parent, v_parent, v_consumer varchar(64) DEFAULT NULL;
      DECLARE v_xml mediumtext DEFAULT '';
      DECLARE c_consumers CURSOR FOR
          SELECT CASE
                    WHEN NAME = 'global_instrumentation'                         THEN 1
                    WHEN NAME IN ('thread_instrumentation', 'statements_digest') THEN 2
                    WHEN NAME LIKE '%\_current'                                  THEN 3
                    ELSE                                                              4
                 END AS 'Level',
                 CASE
                    WHEN NAME = 'global_instrumentation' THEN ''
                    WHEN NAME = 'thread_instrumentation' THEN 'global_instrumentation'
                    WHEN NAME LIKE '%\_digest'           THEN 'global_instrumentation'
                    WHEN NAME LIKE '%\_current'          THEN 'thread_instrumentation'
                    ELSE CONCAT(SUBSTRING_INDEX(NAME, '_history', 1), '_current')
                END AS 'Parent',
                NAME AS 'Consumer',
                is_consumer_enabled(NAME) AS IsEnabled
            FROM performance_schema.setup_consumers
           ORDER BY LEVEL ASC, Parent ASC, NAME ASC;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

      IF (in_format NOT IN ('Text: Left-Right', 'Text: Top-Bottom', 'Dot: Left-Right', 'Dot: Top-Bottom')) THEN
         SET v_error = 'Unknown format. Use ''Text: Left-Right'', ''Text: Top-Bottom'', ''Dot: Left-Right'' or ''Dot: Top-Bottom''';
         SIGNAL SQLSTATE 'HY000'
            SET MESSAGE_TEXT = v_error,
                MYSQL_ERRNO  = 1644;
      END IF;
      SET v_done           = 0,
          v_current_level  = 0,
          v_current_parent = NULL,
          v_xml            = '<consumers>';

      OPEN c_consumers;
      c_consumers_loop: LOOP
         FETCH c_consumers INTO v_level, v_parent, v_consumer, v_isenabled;
         IF v_done THEN
            LEAVE c_consumers_loop;
         END IF;

         IF (v_current_parent IS NOT NULL AND v_current_parent <> v_parent) THEN
            SET v_xml = CONCAT(v_xml, '</g>');
         END IF;
         IF (v_current_level <> v_level) THEN
            IF (v_current_level > 0) THEN
               SET v_xml = CONCAT(v_xml, '</l>');
            END IF;
            SET v_xml = CONCAT(v_xml, '<l>'),
                v_current_level  = v_level,
                v_current_parent = NULL;
            
         END IF;
         IF (v_current_parent IS NULL OR v_current_parent <> v_parent) THEN
            SET v_xml = CONCAT(v_xml, '<g', IF(v_parent <> '', CONCAT(' parent="', v_parent, '"'), ''), '>'),
                v_current_parent = v_parent;
         END IF;
         
         SET v_xml = CONCAT(
                        v_xml,
                        '<e',
                        ' enabled="', v_isenabled, '"',
                        '>',
                        v_consumer,
                        '</e>'
                     );
      END LOOP;

      CLOSE c_consumers;
      SET v_xml = CONCAT(v_xml, '</g></l></consumers>');

      CASE in_format
         WHEN 'Text: Left-Right' THEN
            SELECT xmltree_leftright('', '', '', in_color, v_xml) AS 'Consumers';
         WHEN 'Text: Top-Bottom' THEN
            SELECT xmltree_topbottom('', '', '', in_color, v_xml) AS 'Consumers';
         WHEN 'Dot: Left-Right'  THEN
            SELECT xmltree_dot('', '', '', SUBSTRING(in_format, 6), v_xml) AS 'Consumers';
         WHEN 'Dot: Top-Bottom' THEN
            SELECT xmltree_dot('', '', '', SUBSTRING(in_format, 6), v_xml) AS 'Consumers';
      END CASE;
   END//

DELIMITER ;

