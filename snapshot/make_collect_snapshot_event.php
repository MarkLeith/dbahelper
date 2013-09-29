<?php
/* 
Creates the MySQL event for snapshotting the P_S tables.

usage:
php make_collect_snapshot_event.php > collect_snapshot_event.sql

*/

$conn = mysql_connect('127.0.0.1','root') or die(mysql_error() . "\n");

$sql = "select table_name, count(*) cnt from information_schema.columns where table_schema='performance_schema' and table_name not like '%setup%' and table_name != 'session_variables' group by table_name order by count(*) desc";
$stmt = mysql_query($sql, $conn) or die(mysql_error() . "\n");

while( $row = mysql_fetch_assoc($stmt)) {
  $rows[] = $row;
}

if(empty($rows)) die("no rows!\n");
$maxcnt=$rows[0]['cnt'];

mysql_query('set group_concat_max_len=@@max_allowed_packet') or die(mysql_error() . "\n");
$sql = "";
$inserts = array();
foreach($rows as $row) {
  if ($sql !== "") $sql .= "\nUNION ALL\n";
  $sql2 = "select group_concat( concat(column_name, ' AS col', ordinal_position) order by ordinal_position ) from information_schema.columns where table_schema='performance_schema' and table_name='" . strtolower($row['table_name']) . "';";
  $stmt = mysql_query($sql2, $conn) or die(mysql_error() . "\n");
  $row2 = mysql_fetch_array($stmt);
  $sql .= "( SELECT now(6) as ts, @@server_id as server_id,'" . $row['table_name'] . "' as table_name," . $row2[0];
  for($z=$row['cnt']+1;$z<$maxcnt+1;++$z) {
    $sql .= ",null as col$z";
  }
  $sql .= " from performance_schema." . $row['table_name'] . " )";

  $inserts[$row['table_name']] = "INSERT INTO psmv." . $row['table_name'] . ' SELECT ts, server_id';
  for($z=1;$z<$row['cnt']+1;++$z) {
    $inserts[$row['table_name']] .= ", col$z";
  }
  $inserts[$row['table_name']] .= " FROM psmv.snapshot where table_name = '" . $row['table_name'] . "';\n";
}

echo "
use psmv;

DELIMITER ;;

DROP EVENT IF EXISTS snapshot_performance_schema;;

CREATE DEFINER=root@localhost EVENT snapshot_performance_schema
ON SCHEDULE
EVERY 30 SECOND
ON COMPLETION PRESERVE
ENABLE
COMMENT 'Collect global performance_schema information'
DO
BEGIN
  SET BINLOG_FORMAT=ROW; 
  SELECT GET_LOCK('ps_snapshot_lock',0) INTO @have_lock;
  IF @have_lock = 1 THEN
    START TRANSACTION;
";


$sql = "CREATE TEMPORARY TABLE psmv.snapshot ( key(table_name) ) as " . $sql . ";\n";
echo "    $sql";

foreach($inserts as $sql) {
  echo "    $sql";
}

echo "
    SELECT RELEASE_LOCK('ps_snapshot_lock');
    DROP TEMPORARY TABLE psmv.snapshot;
    COMMIT;
  END IF;
END;;
";


