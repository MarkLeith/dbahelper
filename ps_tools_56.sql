-- Find all mutex contentions

DROP DATABASE IF EXISTS ps_tools;
CREATE DATABASE ps_tools;
use ps_tools;

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
