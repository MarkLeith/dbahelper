/*
 * Procedure: collation_fixer()
 *
 * Fix collation for all tables of a database .
 *
 * Example command line:
 *    CALL ps_helper.collation_fixer(dbname, utf8_persian_ci)
 *
 *
 * Parameters
 *   dbname  : The database name
 *   collation   : The name of collation you want to convert
 *
 * Versions: 5.5+
 *
 * Parts contributed by Arash Shams
 */

DELIMITER $$
DROP PROCEDURE IF EXISTS collationfixer $$

CREATE PROCEDURE collationfixer (in db_name varchar(100), in col_name varchar(100))

BEGIN
	DECLARE finish INT DEFAULT 0;
	DECLARE tab varchar(100);
	DECLARE cur_tables CURSOR FOR select table_name from information_schema.tables WHERE table_schema = db_name and table_type = 'base table';
	DECLARE continue HANDLER FOR NOT found SET finish = 1;
	IF NOT EXISTS (select collation_name from information_schema.collations where collation_name = col_name) THEN
			SET finish = 1;
	END IF;
	OPEN cur_tables;
	colfixer: LOOP
		FETCH cur_tables INTO tab;
		IF finish = 1 THEN
			LEAVE colfixer;
		END IF;
		SET @sql = CONCAT('alter table ', tab,' convert to character set utf8 collate ', col_name);
		PREPARE stmt FROM @sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
	END LOOP;
		CLOSE cur_tables;
END; $$
DELIMITER ;
