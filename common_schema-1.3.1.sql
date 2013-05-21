--
-- common_schema: DBA's framework for MySQL
--

--
-- HOW TO INSTALL
-- =======================================
-- This file is a SQL source file. To install it, you should execute it on your MySQL server.
--
-- Choose either:
-- 
-- - Within MySQL, issue:
-- mysql> SOURCE '/path/to/common_schema.sql';
-- 
-- - From shell, execute:
-- bash$ mysql < /path/to/common_schema.sql
-- 
-- - Use your favorite MySQL GUI editor, copy+paste file content, execute.
-- 
-- To verify install, execute:
-- SHOW DATABASES LIKE 'common_schema';
-- SELECT * FROM common_schema.status;
--

-- 
-- REQUIREMENTS
-- =======================================
-- 
-- On some MySQL versions a stack size of 256K is required (though may work for 192K as well).
-- 256K is the default stack size as of 5.5.
-- You should review/edit the following in your MySQL config file; change will only take
-- place after MySQL restart
--
-- [mysqld]
-- thread_stack = 256K
--
--

-- LICENSE
-- =======================================
-- Released under the BSD license
--
-- Copyright (c) 2011 - 2012, Shlomi Noach
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
--
--     * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
--     * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
--     * Neither the name of the organization nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--


--
-- Generate schema
--

-- Uncomment if you want a clean build:
-- DROP DATABASE IF EXISTS common_schema;

CREATE DATABASE IF NOT EXISTS common_schema;
ALTER DATABASE common_schema DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE 'utf8_general_ci';

USE common_schema;

set @@group_concat_max_len = 1048576;
set @current_sql_mode := @@sql_mode;
set @@sql_mode = REPLACE(REPLACE(@@sql_mode, 'ANSI_QUOTES', ''), ',,', ',');

-- To be updated during installation process:
set @common_schema_innodb_plugin_expected := 0;
set @common_schema_innodb_plugin_installed := 0;
set @common_schema_percona_server_expected := 0;
set @common_schema_percona_server_installed := 0;

DROP TABLE IF EXISTS _known_thread_states;

CREATE TABLE _known_thread_states (
  state varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  state_type enum('replication_sql_thread', 'replication_io_thread', 'unknown') DEFAULT NULL,
  PRIMARY KEY (state),
  KEY (state_type)
) ENGINE=InnoDB ;

--
-- The 'Waiting for slave mutex on exit' state appears on both SQL and I/O states,
-- and signifies waiting for slave mutex while stopping replication.
-- We will simply consider both to indicate "no replication", so we don't list the
-- state in our known replication states.
--

--
-- Replication SQL thread states
--
INSERT INTO _known_thread_states VALUES ('Waiting for the next event in relay log', 'replication_sql_thread');
INSERT INTO _known_thread_states VALUES ('Reading event from the relay log', 'replication_sql_thread');
INSERT INTO _known_thread_states VALUES ('Making temp file', 'replication_sql_thread');
INSERT INTO _known_thread_states VALUES ('Slave has read all relay log; waiting for the slave I/O thread to update it', 'replication_sql_thread');
INSERT INTO _known_thread_states VALUES ('Waiting until MASTER_DELAY seconds after master executed event', 'replication_sql_thread');
INSERT INTO _known_thread_states VALUES ('Has read all relay log; waiting for the slave I/O thread to update it', 'replication_sql_thread');

--
-- Replication I/O thread states
--
INSERT INTO _known_thread_states VALUES ('Waiting for an event from Coordinator', 'replication_io_thread');
INSERT INTO _known_thread_states VALUES ('Waiting for master update', 'replication_io_thread');
INSERT INTO _known_thread_states VALUES ('Connecting to master ', 'replication_io_thread');
INSERT INTO _known_thread_states VALUES ('Checking master version', 'replication_io_thread');
INSERT INTO _known_thread_states VALUES ('Registering slave on master', 'replication_io_thread');
INSERT INTO _known_thread_states VALUES ('Requesting binlog dump', 'replication_io_thread');
INSERT INTO _known_thread_states VALUES ('Waiting to reconnect after a failed binlog dump request', 'replication_io_thread');
INSERT INTO _known_thread_states VALUES ('Reconnecting after a failed binlog dump request', 'replication_io_thread');
INSERT INTO _known_thread_states VALUES ('Waiting for master to send event', 'replication_io_thread');
INSERT INTO _known_thread_states VALUES ('Queueing master event to the relay log', 'replication_io_thread');
INSERT INTO _known_thread_states VALUES ('Waiting to reconnect after a failed master event read', 'replication_io_thread');
INSERT INTO _known_thread_states VALUES ('Reconnecting after a failed master event read', 'replication_io_thread');
INSERT INTO _known_thread_states VALUES ('Waiting for the slave SQL thread to free enough relay log space', 'replication_io_thread');

DROP TABLE IF EXISTS _named_scripts;

CREATE TABLE _named_scripts (
  script_name varchar(64) CHARACTER SET ascii NOT NULL,
  script_text text charset utf8 DEFAULT NULL,
  PRIMARY KEY (script_name)
) ENGINE=InnoDB ;

DROP TABLE IF EXISTS _script_statements;

CREATE TABLE _script_statements (
  statement varchar(16) CHARACTER SET ascii NOT NULL,
  statement_type enum('sql', 'script', 'script,sql', 'unknown') DEFAULT NULL,
  PRIMARY KEY (statement)
) ENGINE=InnoDB ;

--
-- SQL statements
--
INSERT INTO _script_statements VALUES ('alter', 'sql');
INSERT INTO _script_statements VALUES ('analyze', 'sql');
INSERT INTO _script_statements VALUES ('binlog', 'sql');
INSERT INTO _script_statements VALUES ('cache', 'sql');
INSERT INTO _script_statements VALUES ('call', 'sql');
INSERT INTO _script_statements VALUES ('change', 'sql');
INSERT INTO _script_statements VALUES ('check', 'sql');
INSERT INTO _script_statements VALUES ('checksum', 'sql');
INSERT INTO _script_statements VALUES ('create ', 'sql');
INSERT INTO _script_statements VALUES ('delete', 'sql');
INSERT INTO _script_statements VALUES ('do', 'sql');
INSERT INTO _script_statements VALUES ('drop', 'sql');
INSERT INTO _script_statements VALUES ('drop user', 'sql');
INSERT INTO _script_statements VALUES ('flush', 'sql');
INSERT INTO _script_statements VALUES ('grant', 'sql');
INSERT INTO _script_statements VALUES ('handler', 'sql');
INSERT INTO _script_statements VALUES ('insert', 'sql');
INSERT INTO _script_statements VALUES ('kill', 'sql');
INSERT INTO _script_statements VALUES ('load', 'sql');
INSERT INTO _script_statements VALUES ('lock', 'sql');
INSERT INTO _script_statements VALUES ('optimize', 'sql');
INSERT INTO _script_statements VALUES ('purge', 'sql');
INSERT INTO _script_statements VALUES ('rename', 'sql');
INSERT INTO _script_statements VALUES ('repair', 'sql');
INSERT INTO _script_statements VALUES ('replace', 'sql');
INSERT INTO _script_statements VALUES ('reset', 'sql');
INSERT INTO _script_statements VALUES ('revoke', 'sql');
INSERT INTO _script_statements VALUES ('savepoint', 'sql');
INSERT INTO _script_statements VALUES ('select', 'sql');
INSERT INTO _script_statements VALUES ('set', 'sql');
INSERT INTO _script_statements VALUES ('show', 'sql');
INSERT INTO _script_statements VALUES ('stop ', 'sql');
INSERT INTO _script_statements VALUES ('truncate', 'sql');
INSERT INTO _script_statements VALUES ('unlock', 'sql');
INSERT INTO _script_statements VALUES ('update', 'sql');

--
-- Script statements
--
INSERT INTO _script_statements VALUES ('echo', 'script');
INSERT INTO _script_statements VALUES ('eval', 'script');
INSERT INTO _script_statements VALUES ('pass', 'script');
INSERT INTO _script_statements VALUES ('sleep', 'script');
INSERT INTO _script_statements VALUES ('throttle', 'script');
INSERT INTO _script_statements VALUES ('throw', 'script');
INSERT INTO _script_statements VALUES ('var', 'script');
INSERT INTO _script_statements VALUES ('input', 'script');
INSERT INTO _script_statements VALUES ('report', 'script');
INSERT INTO _script_statements VALUES ('begin', 'script');
INSERT INTO _script_statements VALUES ('commit', 'script');
INSERT INTO _script_statements VALUES ('rollback', 'script');

--
-- Both SQL and Script statements (ambiguous resolve)
--
INSERT INTO _script_statements VALUES ('start', 'script,sql');
-- 
-- Metadata: information about this project
-- 
DROP TABLE IF EXISTS help_content;

CREATE TABLE help_content (
  topic VARCHAR(32) CHARSET ascii NOT NULL,
  help_message TEXT CHARSET utf8 NOT NULL,
  PRIMARY KEY (topic)
)
;
-- 
-- Metadata: information about this project
-- 
DROP TABLE IF EXISTS metadata;

CREATE TABLE metadata (
  `attribute_name` VARCHAR(64) CHARSET ascii NOT NULL,
  `attribute_value` VARCHAR(2048) CHARSET utf8 NOT NULL,
  PRIMARY KEY (`attribute_name`)
)
;

--
-- 
--
INSERT INTO metadata (attribute_name, attribute_value) VALUES
  ('author', 'Shlomi Noach'),
  ('author_url', 'http://code.openark.org/blog/shlomi-noach'),
  ('install_success', false),
  ('install_time', NOW()),
  ('install_sql_mode', @@sql_mode),
  ('install_mysql_version', VERSION()),
  ('base_components_installed', false),
  ('innodb_plugin_components_installed', false),
  ('percona_server_components_installed', false),
  ('license_type', 'New BSD'),
  ('license', '
Copyright (c) 2011 - 2012, Shlomi Noach
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the organization nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

'),
  ('project_name', 'common_schema'),
  ('project_home', 'http://code.google.com/p/common-schema/'),
  ('project_repository', 'https://common-schema.googlecode.com/svn/trunk/'),
  ('project_repository_type', 'svn'),
  ('revision', '437'),
  ('version', '1.3.1')
;  
-- 
-- Utility table: unsigned integers, [0..4095]
-- 
DROP TABLE IF EXISTS numbers;

CREATE TABLE numbers (
  `n` smallint unsigned NOT NULL,
  PRIMARY KEY (`n`)
)
;

--
-- Populate numbers table, values range [0...4095]
--
INSERT IGNORE INTO numbers (n) SELECT
  @counter := @counter+1 AS counter 
FROM
  (
    SELECT 
      NULL
    FROM
      INFORMATION_SCHEMA.SESSION_VARIABLES
    LIMIT 64
  ) AS select1,
  (
    SELECT 
      NULL
    FROM
      INFORMATION_SCHEMA.SESSION_VARIABLES
    LIMIT 64
  ) AS select2,
  (
    SELECT 
      @counter := -1
    FROM
      DUAL
  ) AS select_counter
;

delimiter //

set names utf8
//

drop procedure if exists _get_sql_dependencies_internal
//

create procedure _get_sql_dependencies_internal(
    IN p_sql               TEXT charset utf8
,   IN p_default_schema    VARCHAR(64) charset utf8
,   IN return_result_set   TINYINT UNSIGNED
,   OUT result_success      TINYINT UNSIGNED
)
DETERMINISTIC

my_main: begin
    declare v_from, v_old_from int unsigned;
    declare v_token text charset utf8;
    declare v_level int unsigned default 0;
    declare v_state varchar(32) charset utf8;
    declare v_scan_state varchar(32) charset utf8 default 'start';
    declare v_schema_name, v_object_name, v_object_type, v_definer, v_action varchar(64) charset utf8 default null;
    declare v_error_message text charset utf8 default '';

    set @old_autocommit = @@autocommit
    ,   autocommit = off
    ;
  my_error: begin
    
    declare exit handler for 1339
        set v_error_message = concat('case not defined for state: "', v_scan_state, '" ("', v_state, '")');
    declare exit handler for 1265
        set v_error_message = concat('not valid for enum ', v_token);

    set result_success := 1;
        
    drop temporary table if exists _sql_dependencies;
    create temporary table if not exists _sql_dependencies(
        id              int unsigned auto_increment primary key
    ,   start           int unsigned
    ,   action          enum('alter', 'call', 'create', 'delete', 'drop', 'insert', 'replace', 'select', 'truncate', 'update')
    ,   object_type     enum('event', 'function', 'index', 'procedure', 'table', 'trigger', 'view')
    ,   schema_name     varchar(64)
    ,   object_name     varchar(64)
    );
    
    my_loop: repeat 
        set v_old_from = v_from;
        call _get_sql_token(p_sql, v_from, v_level, v_token, 'sql', v_state);
        set v_token = v_token collate utf8_general_ci;
        if v_state in ('whitespace', 'single line comment', 'multi line comment') then
            iterate my_loop;
        elseif v_state = 'statement delimiter' then
            if v_scan_state = 'expect dot' then
                insert 
                into _sql_dependencies (start, schema_name, object_name, object_type, action) 
                values (v_from, v_schema_name, v_object_name, v_object_type, v_action);
            end if;
            set v_scan_state = 'start'
            ,   v_action = null;
        end if;
        if @debug_get_sql_dependencies then
            select v_scan_state, v_from, v_token, v_state;
        end if;

        case v_scan_state
            when 'start' then
                set v_schema_name = p_default_schema, v_object_name = null, v_object_type = null, v_definer = null;
                if v_state = 'alpha' then
                    if v_token in ('alter', 'call', 'create', 'delete', 'drop', 'insert', 'replace', 'select', 'truncate') then
                        set v_action = lower(v_token) collate utf8_general_ci
                        ,   v_scan_state = v_action
                        ;
                    elseif v_token in ('update') then
                        set v_action = lower(v_token) collate utf8_general_ci
                        ,   v_scan_state = 'expect table'
                        ;
                    elseif v_token in ('join', 'from') then
                        set v_scan_state = 'expect table';
                    end if;
                end if;
            when 'select' then
                set v_scan_state = 'expect from';
                set v_action = 'select';
            when 'insert' then
                set v_scan_state = 'expect table';
            when 'update' then
                set v_scan_state = 'expect table';
            when 'delete' then
                set v_scan_state = 'expect table';
            when 'expect from' then
                if v_state = 'alpha' and v_token = 'from' then
                    set v_scan_state = 'expect table';
                end if;
            when 'call' then
                set v_object_type = 'procedure'
                ,   v_object_name = v_token
                ,   v_scan_state = 'expect dot'
                ;
            when 'alter' then
                if v_state = 'alpha' then
                    if v_token in ('database', 'event', 'function', 'procedure', 'schema', 'server', 'table', 'tablespace', 'view') then
                        set v_object_type = v_token
                        ,   v_scan_state = 'expect identifier1';
                    elseif v_token = 'logfile' then
                        set v_scan_state = 'expect logfile group';
                    elseif v_token in ('online', 'offline', 'ignore') then
                        set v_scan_state = 'expect object type';
                    elseif v_token = 'definer' then
                        set v_scan_state = 'definer';
                    else 
                        set v_error_message = concat('"', v_token, '" is not a valid object type for alter ', v_scan_state);
                        leave my_error;
                    end if;
                else
                    set v_error_message = concat('expected alpha ', v_scan_state);
                    leave my_error;
                end if;
            when 'create' then
                if v_state = 'alpha' then
					if v_token in ('database', 'event', 'function', 'procedure', 'schema', 'server', 'table', 'tablespace', 'view') then
                        set v_object_type = v_token
                        ,   v_scan_state = 'expect identifier1';
                    end if;
                else
                    set v_error_message = concat('expected alpha ', v_scan_state);
                    leave my_error;
                end if;
            when 'drop' then
                if v_state = 'alpha' then
                    if v_token in ('database', 'event', 'function', 'procedure', 'schema', 'server', 'table', 'tablespace', 'view') then
                        set v_object_type = v_token
                        ,   v_scan_state = 'expect identifier1';
                    end if;
                else
                    set v_error_message = concat('expected alpha ', v_scan_state);
                    leave my_error;
                end if;
            when 'expect logfile group' then
                if v_state = 'alpha' and v_token = 'group' then
                    set v_object_type = 'logfile group'
                    ,   v_scan_state = 'expect identifier2';
                else 
                    set v_error_message = concat('expected group keyword');
                    leave my_error;
                end if;
            when 'expect definer user' then
                if v_state in ('alpha') and v_token = 'CURRENT_USER' then 
                    set v_scan_state = 'expect object type';
                elseif v_state = 'string'  then
                    set v_scan_state = 'expect definer host';
                else
                    set v_error_message = concat('expected alpha or alphanum', v_scan_state);
                    leave my_error;
                end if;
            when 'expect definer host' then
                if v_state = 'user-defined variable' then
                    set v_scan_state = 'expect object type';
                else
                    set v_error_message = concat('expected hostname, not ', v_state);
                    leave my_error;
                end if;
            when 'definer' then
                if v_state = 'equals' then
                    set v_scan_state = 'expect definer user';
                else
                    set v_error_message = concat('expected equals in state', v_scan_state);
                    leave my_error;
                end if;            
            when 'expect create or replace' then
                if v_state = 'alpha' and v_token = 'replace' then
                    set v_scan_state = 'expect object type';
                else
                    set v_error_message = concat('expected replace in state', v_scan_state);
                    leave my_error;
                end if;
            when 'expect object type' then
                if  v_state = 'alpha' then
                    if v_token in ('event', 'function', 'index', 'procedure', 'schema', 'table', 'trigger', 'view') then
                        set v_object_type = v_token
                        ,   v_scan_state = 'expect identifier1'
                        ;                    
                    elseif v_token = 'definer' then
                        set v_scan_state = 'definer';
                    elseif v_token = 'or' then
                        set v_scan_state = 'expect create or replace';
                    elseif v_token = 'temporary' then
                        set v_scan_state = 'expect object type';
                    else
                        set v_error_message = concat('invalid object type ', v_token);
                        leave my_error;
                    end if;
                else
                    set v_error_message = concat('expected alpha in state ', v_scan_state);
                    leave my_error;
                end if;
            when 'expect identifier1' then
                if v_state = 'quoted identifier' then
                    set v_object_name = substr(v_token, 2, character_length(v_token) - 2);                    
                elseif v_state in ('alpha', 'alphanum') then
                    if v_token not in ('if', 'not', 'exists') then
                        set v_object_name = v_token;
                        set v_scan_state = 'expect dot';
                    end if;
                else
                    set v_error_message = concat('expected identifier ', v_scan_state);
                    leave my_error;
                end if;
            when 'expect identifier2' then
                if v_state in ('quoted identifier', 'alpha', 'alphanum') then
                    set v_schema_name = v_object_name;
                    if v_state = 'quoted identifier' then
                        set v_object_name = substr(v_token, 2, character_length(v_token) - 2)
                        ;
                    elseif v_state in ('alpha', 'alphanum') then
                        set v_object_name = v_token;
                    end if;
                    
                    insert 
                    into _sql_dependencies (start, schema_name, object_name, object_type, action) 
                    values (v_from, v_schema_name, v_object_name, v_object_type, v_action);

                    if v_object_type = 'table' or v_object_type = 'view' then 
                        set v_scan_state = 'expect join';
                    else 
                        set v_scan_state = 'start';
                    end if;
                else
                    set v_error_message = concat('expected identifier ', v_scan_state);
                    leave my_error;
                end if;
            when 'expect dot' then
                if v_state = 'dot' then
                    set v_scan_state = 'expect identifier2';
                else
                    insert 
                    into _sql_dependencies (start, schema_name, object_name, object_type, action) 
                    values (v_from,v_schema_name, v_object_name, v_object_type, v_action);
                    
                    if v_object_type = 'table' or v_object_type = 'view' then 
                        if  (v_state = 'alpha' and v_token in ('into', 'where', 'group', 'having', 'order', 'limit'))
                        or  v_action != 'select'
                        then
                            set v_scan_state = 'start';
                        elseif v_state = 'comma' then
                            set v_scan_state = 'expect table';
                        else
                            set v_scan_state = 'expect join';
                        end if;
                    else 
                        set v_scan_state = 'start';
                    end if;
                end if;
            when 'expect join' then
                if v_state = 'alpha' then
                    if v_token = 'join' then
                        set v_scan_state = 'expect table';
                    elseif v_token = 'on' then
                        set v_scan_state = 'expect join';
                    elseif v_token = 'select' then
                        set v_scan_state = 'select';
                    elseif v_token in ('into', 'where', 'group', 'having', 'order', 'limit') then
                        set v_scan_state = 'start';
                    end if;
                elseif v_state = 'comma' then 
                    set v_scan_state = 'expect table';
                end if;
            when 'expect table' then
                set v_object_type = 'table';
                case 
                    when v_state = 'quoted identifier' then
                        set v_object_name = substr(v_token, 2, character_length(v_token) - 2)
                        ,   v_scan_state = 'expect dot'
                        ;
                    when v_state = 'alpha' and v_token in ('low_priority', 'delayed', 'high_priority', 'ignore', 'into') 
                    or   v_token = '(' 
                    then
                        do null;
                    when v_state = 'alpha' and v_token = 'select' then 
                        set v_scan_state = 'select';
                    when v_state in ('alpha', 'alphanum') then
                        set v_object_name = v_token
                        ,   v_scan_state = 'expect dot'
                        ;
                    else
                        set v_error_message = concat('unexpected state ', v_scan_state, ' (', v_state,')');
                        do null;
                end case;
            when 'expect identifier' then
                if v_state in ('quoted identifier', 'alpha', 'alphanum') then
                    set v_schema_name = v_object_name;
                    if v_state = 'quoted identifier' then
                        set v_object_name = substr(v_token, 2, character_length(v_token) - 2);
                    else
                        set v_object_name = v_token;
                    end if;
                    insert 
                    into _sql_dependencies (start, schema_name, object_name, object_type, action) 
                    values (v_from, v_schema_name, v_object_name, v_object_type, v_action) 
                    ;
                end if;
                set v_scan_state = 'start';
            else 
                set v_error_message = concat('unexpected state ', v_scan_state);
                leave my_error;
        end case;
    until 
        v_old_from = v_from
    end repeat;

    commit;
    set autocommit = @old_autocommit;
    
    if return_result_set then
      select distinct schema_name, object_name, object_type, action
      from _sql_dependencies
      order by schema_name, object_name, object_type, action
      ;
    end if;
    leave my_main;
  end;
  set result_success := 0;
  if return_result_set then
    select concat('Error: ', v_error_message) error;
  end if;
end;
//

delimiter ;

delimiter //

set names utf8
//

drop procedure if exists get_event_dependencies
//

create procedure get_event_dependencies (
    IN p_event_schema VARCHAR(64) CHARSET utf8 
,   IN p_event_name VARCHAR(64) CHARSET utf8
)
DETERMINISTIC
READS SQL DATA

begin
    declare v_event_definition longtext charset utf8;
    declare exit handler for not found
        select concat('Event `', p_event_schema, '`.`', p_event_name, '` not found.') error
    ; 
    
    select  body
    into    v_event_definition
    from    mysql.event
    where   db      = p_event_schema
    and     name    = p_event_name;

    call get_sql_dependencies(v_event_definition, p_event_schema);
end
//

delimiter ;
delimiter //

set names utf8
//

drop procedure if exists get_routine_dependencies
//

create procedure get_routine_dependencies (
    IN p_routine_schema VARCHAR(64) CHARSET utf8 
,   IN p_routine_name VARCHAR(64) CHARSET utf8
)
DETERMINISTIC
READS SQL DATA

begin
    declare v_routine_definition longtext charset utf8;
    declare exit handler for not found
        select concat('Routine `', p_routine_schema, '`.`', p_routine_name, '` not found.') error
    ; 
    
    select  body
    into    v_routine_definition
    from    mysql.proc
    where   db      = p_routine_schema
    and     name    = p_routine_name;

    call get_sql_dependencies(v_routine_definition, p_routine_schema);
end
//

delimiter ;


delimiter //

set names utf8
//

drop procedure if exists get_sql_dependencies
//

create procedure get_sql_dependencies(
    IN p_sql               TEXT charset utf8
,   IN p_default_schema    VARCHAR(64) charset utf8
)
DETERMINISTIC

my_main: begin
	call _get_sql_dependencies_internal(p_sql, p_default_schema, 1, @_common_schema_result_success);
end;
//

delimiter ;

delimiter //

set names utf8
//

drop procedure if exists get_view_dependencies
//

create procedure get_view_dependencies (
    IN p_table_schema VARCHAR(64) CHARSET utf8
,   IN p_table_name VARCHAR(64) CHARSET utf8
)
DETERMINISTIC
READS SQL DATA

begin
    declare v_view_definition longtext charset utf8;
    declare exit handler for not found
        select concat('View `', p_table_schema, '`.`', p_table_name, '` not found.') error
    ; 
    
    select  view_definition
    into    v_view_definition
    from    information_schema.views
    where   table_schema = p_table_schema
    and     table_name = p_table_name;

    call get_sql_dependencies(v_view_definition, p_table_schema);
end
//

delimiter ;
--
-- 
-- A synonym for the foreach() routine
-- 

DELIMITER $$

DROP PROCEDURE IF EXISTS `$` $$
CREATE PROCEDURE `$`(collection TEXT CHARSET utf8, execute_queries TEXT CHARSET utf8) 
MODIFIES SQL DATA
SQL SECURITY INVOKER
COMMENT 'Invoke queries per element of given collection'

begin
  call foreach(collection, execute_queries);
end $$

DELIMITER ;
-- 
-- Returns 1 when given input starts with SELECT, 0 otherwise
-- 
-- This is heuristic only, and is used to diagnose input to various routines.
-- 
-- Example:
--
-- SELECT _is_select_query('SELECT 3 FROM DUAL');
-- Returns: 1
--

DELIMITER $$

DROP FUNCTION IF EXISTS _is_select_query $$
CREATE FUNCTION _is_select_query(input LONGTEXT CHARSET utf8) RETURNS TINYINT UNSIGNED
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Returns 1 when given input starts with SELECT'

BEGIN
  RETURN (LOCATE('select', LOWER(trim_wspace(input))) = 1);
END $$

DELIMITER ;
-- 
-- Return a 64 bit CRC of given input, as unsigned big integer.
-- 
-- This code is based on the idea presented in the book
-- High Performance MySQL, 2nd Edition, By Baron Schwartz et al., published by O'REILLY
-- 
-- Example:
--
-- SELECT crc64('mysql');
-- Returns: 9350511318824990686
--

DELIMITER $$

DROP FUNCTION IF EXISTS crc64 $$
CREATE FUNCTION crc64(data LONGTEXT CHARSET utf8) RETURNS BIGINT UNSIGNED 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Return a 64 bit CRC of given input, as unsigned big integer'

BEGIN
  RETURN CONV(LEFT(MD5(data), 16), 16, 10);
END $$

DELIMITER ;
--
-- Evaluates the queries generated by a given query.
-- Given query is expected to be a SQL generating query. That is, it is expected to produce,
-- when invoked, a single text column consisting of SQL queries (each row may contain one or mroe queries).
-- The eval() procedure will invoke said query, and then invoke (evaluate) any of the resulting queries.
-- Invoker of this procedure must have the CREATE TEMPORARY TABLES privilege, as well as any privilege 
-- required for evaluating implied queries.
-- 
-- This procedure calls upon exec(), which means it will:
-- - skip executing empty queries (whitespace only)
-- - Avoid executing queries when @common_schema_dryrun is set (queries merely printed)
-- - Include verbose message when @common_schema_verbose is set
-- - Set @common_schema_rowcount to reflect the last executed query's ROW_COUNT(). 
--
-- Example:
--
-- CALL eval('select concat(\'KILL \',id) from information_schema.processlist where user=\'unwanted\'');
--

DELIMITER $$

DROP PROCEDURE IF EXISTS eval $$
CREATE PROCEDURE eval(sql_query TEXT CHARSET utf8) 
MODIFIES SQL DATA
SQL SECURITY INVOKER
COMMENT 'Evaluates queries resulting from given query'

begin
  DROP TEMPORARY TABLE IF EXISTS _tmp_eval_queries;
  CREATE TEMPORARY TABLE _tmp_eval_queries (query TEXT CHARSET utf8);
  set @q := CONCAT('INSERT INTO _tmp_eval_queries ', sql_query);  
  call exec_single(@q);
  
  begin	
    declare current_query TEXT CHARSET utf8 DEFAULT NULL;
    declare done INT DEFAULT 0;
    declare eval_cursor cursor for SELECT query FROM _tmp_eval_queries;
    declare continue handler for NOT FOUND SET done = 1;
    
    open eval_cursor;
    read_loop: loop
      fetch eval_cursor into current_query;
      if done then
        leave read_loop;
      end if;
      set @execute_query := current_query;
      call exec(@execute_query);
    end loop;

    close eval_cursor;
  end;
  
  DROP TEMPORARY TABLE IF EXISTS _tmp_eval_queries;
end $$

DELIMITER ;
--
-- Executes a given query or semicolon delimited list of queries
-- Input to this procedure is either:
-- - A single query 
-- - A list of queries, separated by semicolon (;), possibly ending with a semicolon. 
--
-- This procedure calls upon exec_single(), which means it will:
-- - skip empty queries (whitespace only)
-- - Avoid executing query when @common_schema_dryrun is set (query is merely printed)
-- - Include verbose message when @common_schema_verbose is set
-- - Set @common_schema_rowcount to reflect the query's ROW_COUNT(). In case of multiple queries,
--   the value represents the ROW_COUNT() of last query.
--
-- Examples:
--
-- CALL exec('UPDATE world.City SET Population = Population + 1 WHERE Name =\'Paris\'');
-- CALL exec('CREATE TABLE world.City2 LIKE world.City; INSERT INTO world.City2 SELECT * FROM world.City;');
--

DELIMITER $$

DROP PROCEDURE IF EXISTS exec $$
CREATE PROCEDURE exec(IN execute_queries TEXT CHARSET utf8) 
MODIFIES SQL DATA
SQL SECURITY INVOKER
COMMENT ''

begin
  declare num_query_tokens, queries_loop_counter INT UNSIGNED DEFAULT 0;
  declare single_query TEXT CHARSET utf8; 
  
  -- There may be multiple statements
  set execute_queries := _retokenized_queries(execute_queries);
  set num_query_tokens := @common_schema_retokenized_count;
  set queries_loop_counter := 0;
  while queries_loop_counter < num_query_tokens do
    set single_query := split_token(execute_queries, @common_schema_retokenized_delimiter, queries_loop_counter + 1);
    call exec_single(single_query);
    set queries_loop_counter := queries_loop_counter + 1;
  end while;    
end $$

DELIMITER ;
--
-- Executes queries from given file, residing on server
-- Given file is expected to contain SQL statements.
-- This procedure behaves in a similar manner to SOURCE; however it works on the server
-- whereas SOURCE is a client command and loads the file from the client's host.
--
-- Examples:
--
-- call exec_file('/tmp/tables_update.sql');
--

DELIMITER $$

DROP PROCEDURE IF EXISTS exec_file $$
CREATE PROCEDURE exec_file(IN file_name TEXT CHARSET utf8) 
MODIFIES SQL DATA
SQL SECURITY INVOKER
COMMENT 'Executes queries from given file'

begin
  call exec(LOAD_FILE(file_name));	
end $$


DELIMITER ;
--
-- Executes a given query.
-- Given a query, this procedure executes it. Essentially, is uses dynamic SQL to invoke
-- the query.
-- The procedure will do the following:
-- - skip any operation when query is empty (whitespace only)
-- - Avoid executing query when @common_schema_dryrun is set (query is merely printed)
-- - Include verbose message when @common_schema_verbose is set
-- - Set @common_schema_rowcount to reflect the query's ROW_COUNT()
--
-- Example:
--
-- CALL exec_single('UPDATE world.City SET Population = Population + 1 WHERE Name =\'Paris\'');
--

DELIMITER $$

DROP PROCEDURE IF EXISTS exec_single $$
CREATE PROCEDURE exec_single(IN execute_query TEXT CHARSET utf8) 
MODIFIES SQL DATA
SQL SECURITY INVOKER
COMMENT ''

_proc_body: begin
  set @_execute_query := trim_wspace(execute_query);
  if CHAR_LENGTH(@_execute_query) = 0 then
    -- An empty statement
    -- This can happen as result of splitting by semicolon ';'
    leave _proc_body;
  end if;

  set @common_schema_rowcount := NULL;
  
  if @common_schema_dryrun IS TRUE then
    SELECT @_execute_query AS 'exec_single: @common_schema_dryrun';
  else
    if @common_schema_verbose IS TRUE then
	  SELECT @_execute_query AS 'exec_single: @common_schema_verbose';
    end if;
  
    PREPARE st FROM @_execute_query;
    EXECUTE st;
    set @common_schema_rowcount := ROW_COUNT(), @common_schema_found_rows := FOUND_ROWS();
    DEALLOCATE PREPARE st;    
  end if;
end $$

DELIMITER ;
--
-- Invoke queries on each element of given collection.
--
-- This procedure will iterate a given collection. The collection is one of several
-- supported types as described below. For each element in the collection, the routine
-- invokes the given set (one or more) of queries.
--
-- Queries may relate to the particular element at hand, by using placeholders, in similar approach
-- to that used by regular expressions or the awk program.
-- 
-- foreach() supports the following collection types:
-- - Query: the collection is the rowset. An element is a single row.
-- - Numbers range: e.g. '1970:2038'
-- - Two dimentional numbers range: e.g. '-20:20,1970:2038'
-- - Constants set: e.g. '{red, green, blue}'
-- - 'schema': iterate all schemata
-- - 'schema like ...': iterate schemata whose name is like the given text
-- - 'schema ~ ...': iterate schemata whose name matches the given text
-- - 'table like ...': iterate tables whose name is like the given text
-- - 'table ~ ...': iterate tables whose name matches the given text
-- - 'table in schema_name': iterate tables in a given schema
-- 
-- Placeholders vary according to collection type:
-- - Query: ${1} - ${9}
-- - Numbers range: ${1}
-- - Two dimentional numbers range: ${1}, ${2}
-- - Constants set: ${1}
-- - 'schema': ${1} == ${schema}
-- - 'schema like ...': ${1} == ${schema}
-- - 'schema ~ ...': ${1} == ${schema}
-- - 'table like ...': ${1} == ${table}, ${2} == ${schema}
-- - 'table ~ ...': ${1} == ${table}, ${2} == ${schema}
-- - 'table in schema_name': ${1} == ${table}, ${2} == ${schema}
-- All types support the ${NR} placeholder (row number, similar to awk)
-- 

DELIMITER $$

DROP PROCEDURE IF EXISTS foreach $$
CREATE PROCEDURE foreach(collection TEXT CHARSET utf8, execute_queries TEXT CHARSET utf8) 
MODIFIES SQL DATA
SQL SECURITY INVOKER
COMMENT 'Invoke queries per element of given collection'

main_body: begin  
  if collection IS NULL then
    leave main_body;
  end if;
  if execute_queries IS NULL then
    leave main_body;
  end if;
  
  call _foreach(collection, execute_queries, NULL, NULL, NULL, @_common_schema_dummy, NULL, NULL, NULL, @_common_schema_dummy);
end $$

DELIMITER ;
-- 
-- 
-- 

DELIMITER $$

DROP PROCEDURE IF EXISTS query_checksum $$
CREATE PROCEDURE query_checksum(in query TEXT CHARSET utf8) 
READS SQL DATA
SQL SECURITY INVOKER
COMMENT 'Checksum resultset of given query (max 9 columns)'

begin
  -- The following is now the constant 9.
  declare sql_query_num_columns TINYINT UNSIGNED DEFAULT 9;
  declare result_checksum CHAR(40) CHARSET ascii DEFAULT '';
  
  set @query_checksum_result := NULL;
  if not _is_select_query(query) then
    call throw('query_checksum input must be SELECT query');
  end if;

  DROP TEMPORARY TABLE IF EXISTS _tmp_query_checksum;
    
  call _wrap_select_list_columns(query, sql_query_num_columns, @common_schema_error);
  set @_common_schema_checkum_temporary_query := CONCAT('CREATE TEMPORARY TABLE _tmp_query_checksum ', query);

  PREPARE st FROM @_common_schema_checkum_temporary_query;
  EXECUTE st;
  DEALLOCATE PREPARE st;
    
  -- execute sql_query and iterate
  begin	
    declare col1, col2, col3, col4, col5, col6, col7, col8, col9 VARCHAR(4096) CHARSET utf8;
    declare done INT DEFAULT 0;
    declare query_cursor cursor for SELECT * FROM _tmp_query_checksum;
    declare continue handler for NOT FOUND set done = 1;
          
    open query_cursor;
    read_loop: loop
      fetch query_cursor into col1, col2, col3, col4, col5, col6, col7, col8, col9;
      if done then
        leave read_loop;
      end if;
      set result_checksum := MD5(CONCAT(result_checksum, '\0', IFNULL(col1, '\0')));
      set result_checksum := MD5(CONCAT(result_checksum, '\0', IFNULL(col2, '\0')));
      set result_checksum := MD5(CONCAT(result_checksum, '\0', IFNULL(col3, '\0')));
      set result_checksum := MD5(CONCAT(result_checksum, '\0', IFNULL(col4, '\0')));
      set result_checksum := MD5(CONCAT(result_checksum, '\0', IFNULL(col5, '\0')));
      set result_checksum := MD5(CONCAT(result_checksum, '\0', IFNULL(col6, '\0')));
      set result_checksum := MD5(CONCAT(result_checksum, '\0', IFNULL(col7, '\0')));
      set result_checksum := MD5(CONCAT(result_checksum, '\0', IFNULL(col8, '\0')));
      set result_checksum := MD5(CONCAT(result_checksum, '\0', IFNULL(col9, '\0')));
    end loop;
    close query_cursor;
  end; 
    
  DROP TEMPORARY TABLE IF EXISTS _tmp_query_checksum;
  
  SELECT (@query_checksum_result := result_checksum) AS `checksum`;
end $$

DELIMITER ;
-- 
-- Generate random hash string
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS random_hash $$
CREATE FUNCTION random_hash() RETURNS CHAR(40) CHARSET ascii 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Generate random hash string'

begin
	declare result CHAR(40) CHARSET ascii;
	select 
	  SHA1(
	    CONCAT_WS(',', @@server_id, SYSDATE(), RAND(), GROUP_CONCAT(VARIABLE_VALUE))
	  )
	from
	  INFORMATION_SCHEMA.GLOBAL_STATUS
	into result;
	return result;
end $$

DELIMITER ;
--
-- Repeatedly executes given query or queries until some condition holds.
--
-- The procedure accpets:
--
-- - interval_seconds: sleep time between executions. 
--   First sleep occurs after first execution of query or queries.
--   Value of 0 or NULL indicate no sleep
-- - execute_queries: query or queries, in similar format as that of exec()
-- - stop_condition: one of the following:
--   - NULL: no stop condition; repeat infinitely
--   - 0: repeat until no rows are affected by query
--   - n (positive number): limit by number of iterations
--   - Simple time format: limit by total accumulating runtime. 
--     Time units are seconds, minutes, hours. Examples: '15s', '3m', '2h'
--   - A SELECT query returning a single boolean condition.
--  
-- This procedure uses exec() which means it will:
-- - skip empty queries (whitespace only)
-- - Avoid executing query when @common_schema_dryrun is set (query is merely printed)
-- - Include verbose message when @common_schema_verbose is set
--
-- Examples:
--
-- CALL repeat_exec(3, 'DELETE FROM world.Country WHERE Continent != \'Africa\' LIMIT 10', 0); 
-- CALL repeat_exec(60, 'FLUSH LOGS', '30m'); 
--

DELIMITER $$

DROP PROCEDURE IF EXISTS repeat_exec $$
CREATE PROCEDURE repeat_exec(interval_seconds DOUBLE, execute_queries TEXT CHARSET utf8, stop_condition TEXT CHARSET utf8) 
MODIFIES SQL DATA
SQL SECURITY INVOKER
COMMENT ''

_proc_body: begin
  declare repeat_complete TINYINT UNSIGNED DEFAULT 0;
  declare num_iterations INT UNSIGNED DEFAULT 0;
  declare stop_iterations INT UNSIGNED DEFAULT NULL;
  declare stop_seconds INT UNSIGNED DEFAULT NULL;
  declare start_timestamp TIMESTAMP DEFAULT NOW();
  declare stop_condition_type enum('invalid', 'no_limit', 'no_affected', 'iterations', 'time', 'query') DEFAULT 'invalid';
  
  if stop_condition IS NULL then
    set stop_condition_type := 'no_limit';
  elseif stop_condition = '0' then
    set stop_condition_type := 'no_affected';
  elseif stop_condition rlike '^[0-9]+$' then
    set stop_iterations := CAST(stop_condition AS UNSIGNED INTEGER);
    set stop_condition_type := 'iterations';
  elseif CHAR_LENGTH(stop_condition) <= 16 then
    -- the above only avoids raising an error on very long texts
    set stop_seconds := shorttime_to_seconds(stop_condition);
    if stop_seconds IS NOT NULL then
      set stop_condition_type := 'time';
    end if;
  elseif _is_select_query(stop_condition) then
    set stop_condition_type := 'query';
    set @repeat_exec_stop_condition_query := CONCAT('SELECT (', stop_condition, ') INTO @repeat_exec_query_condition');
  end if;

  if stop_condition_type = 'invalid' then
    -- An empty statement
    -- This can happen as result of splitting by semicolon ';'
    set @common_schema_error := 'repeat_exec: invalid stop_condition';
    leave _proc_body;
  end if;
  
  repeat
    set num_iterations := num_iterations + 1;
    set @_execute_queries := REPLACE(execute_queries, '${NR}', num_iterations);
    call exec(@_execute_queries);
    
    if stop_condition_type = 'no_limit' then
      -- no limitation; the following is just a placeholder
      set repeat_complete := 0;
    elseif stop_condition_type = 'no_affected' then
      if @common_schema_rowcount = 0 then
        set repeat_complete := 1;
      end if;
    elseif stop_condition_type = 'time' then
      if TIMESTAMPDIFF(SECOND, start_timestamp, SYSDATE()) >= stop_seconds then 
	    set repeat_complete := 1;
	  end if;
    elseif stop_condition_type = 'iterations' then
      if num_iterations >= stop_iterations then
        set repeat_complete := 1;
      end if;
    elseif stop_condition_type = 'query' then
      PREPARE st FROM @repeat_exec_stop_condition_query;
      EXECUTE st;
      DEALLOCATE PREPARE st;
      if @repeat_exec_query_condition then
        set repeat_complete := 1;
      end if;
    end if;
    
    if repeat_complete = 0 then
      if IFNULL(interval_seconds, 0) > 0 then
        DO SLEEP(interval_seconds);
      end if;
    end if;
  until repeat_complete
  end repeat;
end $$

DELIMITER ;
-- 
-- Return the number of seconds represented by the given short form
-- 
-- - shorttime: a string representing a time length. It is a number followed by a time ebbreviation, 
--   one of 's', 'm', 'h', standing for seconds, minutes, hours respectively.
--   Examples: '15s', '3m', '2h' 
-- 
-- The function returns NULL on invalid input: any input which is not in short-time format,
-- including plain numbers (to emphasize: the input '12' is invalid)
--
-- Example:
--
-- SELECT shorttime_to_seconds('2h');
-- Returns: 7200
--

DELIMITER $$

DROP FUNCTION IF EXISTS shorttime_to_seconds $$
CREATE FUNCTION shorttime_to_seconds(shorttime VARCHAR(16) CHARSET ascii) RETURNS INT UNSIGNED 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Return a 64 bit CRC of given input, as unsigned big integer'

begin
  declare numeric_value INT UNSIGNED DEFAULT NULL;
  
  if shorttime is NULL then
    return NULL;
  end if;
  if not shorttime rlike '^[0-9]+[smh]$' then
    return NULL;
  end if;

  set numeric_value := CAST(LEFT(shorttime, CHAR_LENGTH(shorttime) - 1) AS UNSIGNED);
  case RIGHT(shorttime, 1)
    when 's' then set numeric_value := numeric_value*1;
    when 'm' then set numeric_value := numeric_value*60;
    when 'h' then set numeric_value := numeric_value*60*60;
  end case;
  return numeric_value;
end $$

DELIMITER ;
delimiter //

set names utf8
//

drop procedure if exists throw;
//

create procedure throw(error_message VARCHAR(1024) CHARSET utf8)
comment 'Raise an error'
language SQL
deterministic
no sql
sql security invoker
begin
  declare error_statement VARCHAR(1500) CHARSET utf8;

  set @common_schema_error := error_message;
  set error_statement := CONCAT('SELECT error FROM error.`', error_message, '`');
  call exec_single(error_statement);
end;
//

delimiter ;
--
-- Invoke queries on each element of given collection.
--
-- This procedure will iterate a given collection. The collection is one of several
-- supported types as described below. For each element in the collection, the routine
-- invokes the given set (one or more) of queries.
--
-- Queries may relate to the particular element at hand, by using placeholders, in similar approach
-- to that used by regular expressions or the awk program.
-- 
-- foreach() supports the following collection types:
-- - Query: the collection is the rowset. An element is a single row.
-- - Numbers range: e.g. '1970:2038'
-- - Two dimentional numbers range: e.g. '-20:20,1970:2038'
-- - Constants set: e.g. '{red, green, blue}'
-- - 'schema': iterate all schemata
-- - 'schema like ...': iterate schemata whose name is like the given text
-- - 'schema ~ ...': iterate schemata whose name matches the given text
-- - 'table like ...': iterate tables whose name is like the given text
-- - 'table ~ ...': iterate tables whose name matches the given text
-- - 'table in schema_name': iterate tables in a given schema
-- 
-- Placeholders vary according to collection type:
-- - Query: ${1} - ${9}
-- - Numbers range: ${1}
-- - Two dimentional numbers range: ${1}, ${2}
-- - Constants set: ${1}
-- - 'schema': ${1} == ${schema}
-- - 'schema like ...': ${1} == ${schema}
-- - 'schema ~ ...': ${1} == ${schema}
-- - 'table like ...': ${1} == ${table}, ${2} == ${schema}, ${3} == ${engine}, ${4} == ${create_options}
-- - 'table ~ ...': ${1} == ${table}, ${2} == ${schema}, ${3} == ${engine}, ${4} == ${create_options}
-- - 'table in schema_name': ${1} == ${table}, ${2} == ${schema}, ${3} == ${engine}, ${4} == ${create_options}
-- All types support the ${NR} placeholder (row number, similar to awk)
-- 

DELIMITER $$

DROP PROCEDURE IF EXISTS _foreach $$
CREATE PROCEDURE _foreach(
   collection TEXT CHARSET utf8, 
   execute_queries TEXT CHARSET utf8,
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   in   expect_single tinyint unsigned,
   out  consumed_to_id int unsigned,
   in   variables_array_id int unsigned,
   in depth int unsigned,
   in should_execute_statement tinyint unsigned,
   out iteration_count bigint unsigned
)  
MODIFIES SQL DATA
SQL SECURITY INVOKER
COMMENT 'Invoke queries per element of given collection'

main_body: begin
  -- The following is now the constant 9.
  declare sql_query_num_columns TINYINT UNSIGNED DEFAULT 9;
  -- In any type of iteration, iteration_number indicates the 1-based number of iteration. It is similar to NR in awk.
  declare iteration_number INT UNSIGNED DEFAULT 0;
  
  set @__group_concat_max_len := @@group_concat_max_len;
  set @@group_concat_max_len := 32 * 1024 * 1024;
  
  -- Preprocessing: certain types of 'collection' are rewritten, to be handled later.
  if collection = 'schema' then
    set collection := 'schema ~ /.*/';
  end if;
  if collection RLIKE '^schema[ ]+like[ ]+[^ ]+[ ]*$' then
    begin
	  -- Rewrite as "~" regexp match
	  declare like_expression TEXT CHARSET utf8 DEFAULT unquote(trim_wspace(split_token(collection, ' like ', 2)));
	  set collection := CONCAT('schema ~ /', like_to_rlike(like_expression), '/');
    end;
  end if;
  if collection RLIKE '^schema[ ]*~[ ]*[^ ]+[ ]*$' then
    begin
	  --
	  -- Handle search for schema (filtered by regexp). rewrite as query, to be handled later.
	  --
	  declare re TEXT CHARSET utf8 DEFAULT unquote(trim_wspace(split_token(collection, '~', 2)));
	  set collection := CONCAT(
	    'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME RLIKE ',
	    '''', re, '''');
      set execute_queries := REPLACE(execute_queries, '${schema}', '${1}');
	end;
  end if;
  if collection RLIKE '^table[ ]+in[ ]+[^ ]+[ ]*$' then
    begin
	  declare db TEXT CHARSET utf8 DEFAULT unquote(trim_wspace(split_token(collection, ' in ', 2)));
	  set collection := CONCAT(
	    'SELECT TABLE_NAME, TABLE_SCHEMA, ENGINE, CREATE_OPTIONS FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA=',
	    '''', db, ''' AND TABLE_TYPE=''BASE TABLE''');
      set execute_queries := REPLACE(execute_queries, '${table}', '${1}');
      set execute_queries := REPLACE(execute_queries, '${schema}', '${2}');
      set execute_queries := REPLACE(execute_queries, '${engine}', '${3}');
      set execute_queries := REPLACE(execute_queries, '${create_options}', '${4}');
	end;
  end if;
  if collection RLIKE '^table[ ]+like[ ]+[^ ]+[ ]*$' then
    begin
	  -- Rewrite as "~" regexp match
	  declare like_expression TEXT CHARSET utf8 DEFAULT unquote(trim_wspace(split_token(collection, ' like ', 2)));
	  set collection := CONCAT('table ~ /', like_to_rlike(like_expression), '/');
    end;
  end if;

  --
  -- Analyze the type of input. What kind of iteration is this?
  --
  if collection RLIKE '^table[ ]*~[ ]*[^ ]+[ ]*$' then
    begin
	  --
	  -- Handle search for table (filtered by regexp). 
      -- This does not get rewritten as query, since it will make for poor performance
      -- on INFORMATION_SCHEMA. Instead, we iterate each schema utilizing I_S optimizations.
	  --
      declare current_db TEXT CHARSET utf8 DEFAULT NULL;
      declare re TEXT CHARSET utf8 DEFAULT unquote(trim_wspace(split_token(collection, '~', 2)));
      declare count_tables SMALLINT UNSIGNED DEFAULT 0;
      declare table_name TEXT CHARSET utf8 DEFAULT NULL;
      declare table_engine TEXT CHARSET utf8 DEFAULT NULL;
      declare table_create_options TEXT CHARSET utf8 DEFAULT NULL;
      declare tables_details TEXT CHARSET utf8 DEFAULT NULL;
      declare table_details TEXT CHARSET utf8 DEFAULT NULL;
      declare done INT DEFAULT 0;
      declare table_counter INT UNSIGNED DEFAULT 1;
      declare db_cursor cursor for SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA;
      declare continue handler for NOT FOUND set done = 1;
	  
	  open db_cursor;
      db_loop: loop
        fetch db_cursor into current_db; 
        if done then
          leave db_loop;
        end if;

        set @_foreach_tables_query:= CONCAT(
          'SELECT GROUP_CONCAT(TABLE_NAME, ''\\0\\b'', ENGINE, ''\\0\\b'', CREATE_OPTIONS SEPARATOR ''\\n\\b'') FROM INFORMATION_SCHEMA.TABLES ',
          'WHERE TABLE_SCHEMA = ''',current_db,''' AND TABLE_NAME RLIKE ''',re,''' AND TABLE_TYPE=''BASE TABLE'' ',
          'INTO @_common_schema_foreach_tables_details');
        call exec(@_foreach_tables_query);
        set tables_details := @_common_schema_foreach_tables_details;

        set count_tables := get_num_tokens(tables_details, '\n\b');
        set iteration_number := 1;
        while iteration_number <= count_tables do
          set table_details := split_token(tables_details, '\n\b', iteration_number);
          
          set table_name := split_token(table_details, '\0\b', 1);
          set table_engine := split_token(table_details, '\0\b', 2);
          set table_create_options := split_token(table_details, '\0\b', 3);
          
          set @_foreach_exec_query := execute_queries;
          set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${table}', '${1}');
          set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${1}', table_name);
          set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${schema}', '${2}');
          set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${2}', current_db);
          set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${engine}', '${3}');
          set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${3}', table_engine);
          set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${create_options}', '${4}');
          set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${4}', table_create_options);
          set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${NR}', table_counter);
          set
            @_query_script_input_col1 := table_name, 
            @_query_script_input_col2 := current_db,
            @_query_script_input_col3 := table_engine,
            @_query_script_input_col4 := table_create_options;

          call _run_foreach_step(@_foreach_exec_query, id_from, id_to, expect_single, consumed_to_id, variables_array_id, depth, should_execute_statement);
          if @_common_schema_script_break_type IS NOT NULL then
            if @_common_schema_script_break_type = 'break' then
              set @_common_schema_script_break_type := NULL;
            end if;
            leave main_body;
          end if;
          set iteration_number := iteration_number + 1;
          set table_counter := table_counter + 1;
        end while;
      end loop;
      close db_cursor;
	end;
  elseif _is_select_query(collection) then
    -- 
	-- input is query: need to execute the query and detect number of columns
	-- 
    DROP TEMPORARY TABLE IF EXISTS _tmp_foreach;
    
    set @_foreach_iterate_query := collection;
    call _wrap_select_list_columns(@_foreach_iterate_query, sql_query_num_columns, @common_schema_error);
    set @_foreach_iterate_query := CONCAT('CREATE TEMPORARY TABLE _tmp_foreach ', @_foreach_iterate_query);

    PREPARE st FROM @_foreach_iterate_query;
    EXECUTE st;
    DEALLOCATE PREPARE st;
    
    -- execute sql_query and iterate
    begin	
      declare foreach_col1, foreach_col2, foreach_col3, foreach_col4, foreach_col5, foreach_col6, foreach_col7, foreach_col8, foreach_col9 VARCHAR(4096) CHARSET utf8;
      declare done INT DEFAULT 0;
      declare query_cursor cursor for SELECT * FROM _tmp_foreach;
      declare continue handler for NOT FOUND set done = 1;
      
      set iteration_number := 1;
      open query_cursor;
      read_loop: loop
        fetch query_cursor into foreach_col1, foreach_col2, foreach_col3, foreach_col4, foreach_col5, foreach_col6, foreach_col7, foreach_col8, foreach_col9;
        if done then
          leave read_loop;
        end if;
        set
          @_query_script_input_col1 := foreach_col1, 
          @_query_script_input_col2 := foreach_col2, 
          @_query_script_input_col3 := foreach_col3, 
          @_query_script_input_col4 := foreach_col4, 
          @_query_script_input_col5 := foreach_col5, 
          @_query_script_input_col6 := foreach_col6, 
          @_query_script_input_col7 := foreach_col7, 
          @_query_script_input_col8 := foreach_col8, 
          @_query_script_input_col9 := foreach_col9;

        -- Replace placeholders
        -- NULL values are allowed, and are translated to the literal 'NULL', or else the REPLACE method would return NULL.
        set @_foreach_exec_query := execute_queries;
        set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${1}', IFNULL(foreach_col1, 'NULL'));
        set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${2}', IFNULL(foreach_col2, 'NULL'));
        set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${3}', IFNULL(foreach_col3, 'NULL'));
        set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${4}', IFNULL(foreach_col4, 'NULL'));
        set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${5}', IFNULL(foreach_col5, 'NULL'));
        set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${6}', IFNULL(foreach_col6, 'NULL'));
        set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${7}', IFNULL(foreach_col7, 'NULL'));
        set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${8}', IFNULL(foreach_col8, 'NULL'));
        set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${9}', IFNULL(foreach_col9, 'NULL'));
        set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${NR}', iteration_number);

        call _run_foreach_step(@_foreach_exec_query, id_from, id_to, expect_single, consumed_to_id, variables_array_id, depth, should_execute_statement);
        if @_common_schema_script_break_type IS NOT NULL then
          if @_common_schema_script_break_type = 'break' then
            set @_common_schema_script_break_type := NULL;
          end if;
          leave main_body;
        end if;
        
        set iteration_number := iteration_number + 1; 
      end loop;
      close query_cursor;
    end; 
    
    DROP TEMPORARY TABLE IF EXISTS _tmp_foreach;
  elseif collection RLIKE '^-?[0-9]+:-?[0-9]+,-?[0-9]+:-?[0-9]+$' then
    begin
	  --
      -- input is two dimentional integers range, both inclusive (e.g. '-10:55,1:17')
      --
      declare first_start_index int signed default NULL;
      declare first_end_index int signed default NULL;
      declare second_start_index int signed default NULL;
      declare second_end_index int signed default NULL;
      declare first_loop_index int signed default NULL;
      declare second_loop_index int signed default NULL;
      
      set @_foreach_first_range := split_token(collection, ',', 1);
      set @_foreach_second_range := split_token(collection, ',', 2);

      set first_start_index := CAST(split_token(@_foreach_first_range, ':', 1) AS SIGNED INTEGER);
      set first_end_index := CAST(split_token(@_foreach_first_range, ':', 2) AS SIGNED INTEGER);
      set second_start_index := CAST(split_token(@_foreach_second_range, ':', 1) AS SIGNED INTEGER);
      set second_end_index := CAST(split_token(@_foreach_second_range, ':', 2) AS SIGNED INTEGER);

      set iteration_number := 1;
      set first_loop_index := first_start_index;
      while first_loop_index <= first_end_index do
        set second_loop_index := second_start_index;
        while second_loop_index <= second_end_index do
          set @_foreach_exec_query := execute_queries;
          set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${1}', first_loop_index);
          set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${2}', second_loop_index);
          set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${NR}', iteration_number);
          set
            @_query_script_input_col1 := first_loop_index, 
            @_query_script_input_col2 := second_loop_index;
        
          call _run_foreach_step(@_foreach_exec_query, id_from, id_to, expect_single, consumed_to_id, variables_array_id, depth, should_execute_statement);
          if @_common_schema_script_break_type IS NOT NULL then
            if @_common_schema_script_break_type = 'break' then
              set @_common_schema_script_break_type := NULL;
            end if;
            leave main_body;
          end if;

          set iteration_number := iteration_number + 1;
          set second_loop_index := second_loop_index + 1;
        end WHILE;
        set first_loop_index := first_loop_index + 1;
      end while;
    end;
  elseif collection RLIKE '^-?[0-9]+:-?[0-9]+$' then
    begin
	  --
      -- input is integers range, both inclusive (e.g. '-10:55')
      -- 
      declare _foreach_start_index INT SIGNED DEFAULT CAST(split_token(collection, ':', 1) AS SIGNED INTEGER);
      declare _foreach_end_index INT SIGNED DEFAULT CAST(split_token(collection, ':', 2) AS SIGNED INTEGER);
      declare _foreach_loop_index INT SIGNED DEFAULT NULL;
      
      set iteration_number := 1;
      set _foreach_loop_index := _foreach_start_index;
      while _foreach_loop_index <= _foreach_end_index do
        set @_foreach_exec_query := execute_queries;
        set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${1}', _foreach_loop_index);
        set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${NR}', iteration_number);
        set
          @_query_script_input_col1 := _foreach_loop_index;
      
        call _run_foreach_step(@_foreach_exec_query, id_from, id_to, expect_single, consumed_to_id, variables_array_id, depth, should_execute_statement);
        if @_common_schema_script_break_type IS NOT NULL then
          if @_common_schema_script_break_type = 'break' then
            set @_common_schema_script_break_type := NULL;
          end if;
          leave main_body;
        end if;

        set iteration_number := iteration_number + 1;
        set _foreach_loop_index := _foreach_loop_index + 1;
      end while;
    end;
  elseif collection RLIKE '^{.*}$' then
    begin
	  --
      -- input is constant tokens (e.g. 'read green blue'), space or comma delimited
      --
      declare _foreach_iterate_tokens TEXT CHARSET utf8 DEFAULT '';
      declare _foreach_num_tokens INT UNSIGNED DEFAULT 0;
      declare _foreach_token TEXT CHARSET utf8;
      declare _foreach_token_delimiter TEXT CHARSET utf8;
      declare _foreach_row_number INT UNSIGNED DEFAULT 1;
      
      set _foreach_iterate_tokens := _retokenized_text(unwrap(collection), ' ,', '"''`', TRUE, 'skip');
      set _foreach_num_tokens := @common_schema_retokenized_count;
      set _foreach_token_delimiter := @common_schema_retokenized_delimiter;
      
      set iteration_number := 1;
      constant_tokens_loop: while iteration_number <= _foreach_num_tokens do
        set _foreach_token := split_token(_foreach_iterate_tokens, _foreach_token_delimiter, iteration_number);
        set _foreach_token := unquote(_foreach_token);
        set iteration_number := iteration_number + 1;

        set @_foreach_exec_query := execute_queries;
        set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${1}', _foreach_token);
        set @_foreach_exec_query := REPLACE(@_foreach_exec_query, '${NR}', _foreach_row_number);
        set
          @_query_script_input_col1 := _foreach_token;
      
        call _run_foreach_step(@_foreach_exec_query, id_from, id_to, expect_single, consumed_to_id, variables_array_id, depth, should_execute_statement);
        if @_common_schema_script_break_type IS NOT NULL then
          if @_common_schema_script_break_type = 'break' then
            set @_common_schema_script_break_type := NULL;
          end if;
          leave main_body;
        end if;

        set _foreach_row_number := _foreach_row_number + 1;
      end while;
    end;
  else
    call throw(CONCAT('foreach(): unrecognized collection format: \"', collection, '\"'));
  end if;    
  set iteration_count = GREATEST(iteration_number - 1, 0);
  set @@group_concat_max_len := @__group_concat_max_len;
end $$

DELIMITER ;
delimiter //

set names utf8
//

drop procedure if exists _get_json_token;
//

create procedure _get_json_token(
    in      p_text      text charset utf8
,   inout   p_from      int unsigned
,   inout   p_level     int
,   out     p_token     text charset utf8
,   in      allow_script_tokens int
,   inout   p_state     enum(
                            'alpha'
                        ,   'alphanum'
                        ,   'colon'
                        ,   'comma'                        
                        ,   'decimal'
                        ,   'error'
                        ,   'integer'
                        ,   'number'
                        ,   'object_begin'
                        ,   'object_end'
                        ,   'array_begin'
                        ,   'array_end'
                        ,   'start'
                        ,   'string'
                        ,   'whitespace'
                        )               
)
comment 'Reads a token according to lexical rules for JSON'
language SQL
deterministic
no sql
sql security invoker
begin    
    declare v_length int unsigned default character_length(p_text);
    declare v_char, v_lookahead, v_quote_char    varchar(1) charset utf8;
    declare v_from int unsigned;

    if p_from is null then
        set p_from = 1;
    end if;
    if p_level is null then
        set p_level = 0;
    end if;
    if p_state = 'object_end' then
        set p_level = p_level - 1;
    end if;
    if p_state = 'array_end' and allow_script_tokens then
        set p_level = p_level - 1;
    end if;
    set v_from = p_from;
    
    set p_token = ''
    ,   p_state = 'start';
    my_loop: while v_from <= v_length do
        set v_char = substr(p_text, v_from, 1)
        ,   v_lookahead = substr(p_text, v_from+1, 1)
        ;
        state_case: begin case p_state
            when 'error' then 
                set p_from = v_length;
                leave state_case;            
            when 'start' then
                case
                    when v_char between '0' and '9' then 
                        set p_state = 'integer';
                    when v_char between 'A' and 'Z' 
                    or   v_char between 'a' and 'z' 
                    or   v_char = '_' then
                        set p_state = 'alpha';                        
                    when v_char = ' ' then 
                        set p_state = 'whitespace'
                        ,   v_from = v_length - character_length(ltrim(substring(p_text, v_from)))
                        ;
                        leave state_case;
                    when v_char in ('\t', '\n', '\r') then 
                        set p_state = 'whitespace';
                    when v_char = '"' then
                        set p_state = 'string', v_quote_char = v_char;
                    when v_char = '.' then
                        if substr(p_text, v_from + 1, 1) between '0' and '9' then
                            set p_state = 'decimal', v_from = v_from + 1;
                        else
                            set p_state = 'error';
                            leave my_loop;
                        end if;
                    when v_char = ',' then
                        set p_state = 'comma', v_from = v_from + 1;
                        leave my_loop;
                    when v_char = ':' then 
                        set p_state = 'colon', v_from = v_from + 1;
                        leave my_loop;
                    when v_char = '{' then 
                        set p_state = 'object_begin', v_from = v_from + 1, p_level = p_level + 1;
                        leave my_loop;
                    when v_char = '}' then
                        set p_state = 'object_end', v_from = v_from + 1;
                        leave my_loop;
                    when v_char = '[' then 
                        set p_state = 'array_begin', v_from = v_from + 1, p_level = p_level + 1;
                        leave my_loop;
                    when v_char = ']' then 
                        set p_state = 'array_end', v_from = v_from + 1;
                        leave my_loop;
                    else 
                        set p_state = 'error';
                end case;
            when 'alpha' then 
                case
                    when v_char between 'A' and 'Z' 
                    or   v_char between 'a' and 'z' 
                    or   v_char = '_' then
                        leave state_case;
                    when v_char between '0' and '9' then 
                        set p_state = 'alphanum';
                    else
                        leave my_loop;
                end case;
            when 'alphanum' then 
                case
                    when v_char between 'A' and 'Z' 
                    or   v_char between 'a' and 'z' 
                    or   v_char = '_'
                    or   v_char between '0' and '9' then 
                        leave state_case;
                    else
                        leave my_loop;
                end case;
            when 'integer' then
                case 
                    when v_char between '0' and '9' then 
                        leave state_case;
                    when v_char = '.' then 
                        set p_state = 'decimal';
                    else
                        leave my_loop;                        
                end case;
            when 'decimal' then
                case 
                    when v_char between '0' and '9' then 
                        leave state_case;
                    else
                        leave my_loop;
                end case;
            when 'whitespace' then
                if v_char not in ('\t', '\n', '\r') then
                    leave my_loop;                        
                end if;
            when 'string' then
                set v_from = locate(v_quote_char, p_text, v_from);
                if v_from then
                    if substr(p_text, v_from + 1, 1) = v_quote_char then
                        set v_from = v_from + 1;
                    elseif substr(p_text, v_from - 1, 1) != '\\' then
                        set v_from = v_from + 1;
                        leave my_loop;
                    end if;
                else
                    set p_state = 'error';
                    leave my_loop;
                end if;
            else
                leave my_loop;            
        end case; end state_case;
        set v_from = v_from + 1;
    end while my_loop;
    set p_token = substr(p_text, p_from, v_from - p_from) collate utf8_general_ci;
    set p_from = v_from;
    if p_state in ('decimal', 'integer') then
      set p_state := 'number';
    end if;
    if p_state = 'alphanum' then
      set p_state := 'alpha';
    end if;
end;
//

delimiter ;
delimiter //

set names utf8
//

drop procedure if exists _get_sql_token;
//

create procedure _get_sql_token(
    in      p_text      text charset utf8
,   inout   p_from      int unsigned
,   inout   p_level     int
,   out     p_token     text charset utf8
,   in      language_mode enum ('sql', 'script', 'routine')
-- ,   inout   p_state     varchar(64)charset utf8
,   inout   p_state     enum(
                            'alpha'
                        ,   'alphanum'
                        ,   'and'
                        ,   'assign'
                        ,   'bitwise and'
                        ,   'bitwise or'
                        ,   'bitwise not'
                        ,   'bitwise xor'
                        ,   'colon'
                        ,   'comma'                        
                        ,   'conditional comment'
                        ,   'decimal'
                        ,   'delimiter'
                        ,   'divide'
                        ,   'dot'
                        ,   'equals'
                        ,   'error'
                        ,   'greater than'
                        ,   'greater than or equals'
                        ,   'integer'
                        ,   'left braces'
                        ,   'left parenthesis'
                        ,   'left shift'
                        ,   'less than'
                        ,   'less than or equals'
                        ,   'minus'
                        ,   'modulo'
                        ,   'multi line comment'
                        ,   'multiply'
                        ,   'negate'
                        ,   'not equals'
                        ,   'null safe equals'
                        ,   'or'
                        ,   'plus'
                        ,   'quoted identifier'
                        ,   'right braces'
                        ,   'right parenthesis'
                        ,   'right shift'
                        ,   'single line comment'
                        ,   'start'
                        ,   'statement delimiter'
                        ,   'string'
                        ,   'system variable'
                        ,   'user-defined variable'
                        ,   'query_script variable'
                        ,	'expanded query_script variable'
                        ,   'whitespace'
                        ,   'not'
                        )               
)
comment 'Reads a token according to lexical rules for SQL'
language SQL
deterministic
no sql
sql security invoker
begin    
    declare v_length int unsigned default character_length(p_text);
    declare v_no_ansi_quotes        bool default find_in_set('ANSI_QUOTES', @@sql_mode) = FALSE;
    declare v_char, v_lookahead, v_quote_char    char(1) charset utf8;
    declare v_from int unsigned;
    declare allow_script_tokens tinyint unsigned;
    
    set allow_script_tokens := (language_mode = 'script');

    if p_from is null then
        set p_from = 1;
    end if;
    if p_level is null then
        set p_level = 0;
    end if;
    if p_state = 'right parenthesis' then
        set p_level = p_level - 1;
    end if;
    if p_state = 'right braces' and allow_script_tokens then
        set p_level = p_level - 1;
    end if;
    set v_from = p_from;
    
    set p_token = ''
    ,   p_state = 'start';
    my_loop: while v_from <= v_length do
        set v_char = substr(p_text, v_from, 1)
        ,   v_lookahead = substr(p_text, v_from+1, 1)
        ;
        state_case: begin case p_state
            when 'error' then 
                set p_from = v_length;
                leave state_case;            
            when 'start' then
                case
                    when v_char between '0' and '9' then 
                        set p_state = 'integer';
                    when v_char between 'A' and 'Z' 
                    or   v_char between 'a' and 'z' 
                    or   v_char = '_' then
                        set p_state = 'alpha';                        
                    when v_char = ' ' then 
                        set p_state = 'whitespace'
                        ,   v_from = v_length - character_length(ltrim(substring(p_text, v_from)))
                        ;
                        leave state_case;
                    when v_char in ('\t', '\n', '\r') then 
                        set p_state = 'whitespace';
                    when v_char = '''' or v_no_ansi_quotes and v_char = '"' then
                        set p_state = 'string', v_quote_char = v_char;
                    when v_char = '`' or v_no_ansi_quotes = FALSE and v_char = '"' then
                        set p_state = 'quoted identifier', v_quote_char = v_char;
                    when v_char = '@' then
                        if v_lookahead = '@' then
                            set p_state = 'system variable', v_from = v_from + 1;
                        else
                            set p_state = 'user-defined variable';
                        end if;
                    when v_char = '$' and allow_script_tokens then
                        set p_state = 'query_script variable';
                    when v_char = '.' then
                        if substr(p_text, v_from + 1, 1) between '0' and '9' then
                            set p_state = 'decimal', v_from = v_from + 1;
                        else
                            set p_state = 'dot', v_from = v_from + 1;
                            leave my_loop;
                        end if;
                    when v_char = ';' then
                        set p_state = 'statement delimiter', v_from = v_from + 1;
                        leave my_loop;
                    when v_char = ',' then
                        set p_state = 'comma', v_from = v_from + 1;
                        leave my_loop;
                    when v_char = '=' then
                        set p_state = 'equals', v_from = v_from + 1;
                        leave my_loop;
                    when v_char = '*' then
                        set p_state = 'multiply', v_from = v_from + 1;
                        leave my_loop;
                    when v_char = '%' then
                        set p_state = 'modulo', v_from = v_from + 1;
                        leave my_loop;
                    when v_char = '/' then
                        if v_lookahead = '*' then
                            set v_from = locate('*/', p_text, p_from + 2);
                            if v_from then
                                set p_state = if (substr(p_text, p_from + 2, 1) = '!', 'conditional comment', 'multi line comment')
                                ,   v_from = v_from + 2
                                ;
                                leave my_loop;
                            else
                                set p_state = 'error';
                            end if;
                        else
                            set p_state = 'divide', v_from = v_from + 1;
                            leave my_loop;
                        end if;
                    when v_char = '-' then
                        case 
                            when v_lookahead = '-' and substr(p_text, v_from + 2, 1) = ' ' then
                                set p_state = 'single line comment'
                                ,   v_from = locate('\n', p_text, p_from)
                                ;
                                if not v_from then
                                    set v_from = v_length;
                                end if;
                                set v_from = v_from + 1;
                                leave my_loop;
                            else
                                set p_state = 'minus', v_from = v_from + 1;
                                leave my_loop;
                        end case;
                    when v_char = '#' then
                        set p_state = 'single line comment'
                        ,   v_from = locate('\n', p_text, p_from)
                        ;
                        if not v_from then
                            set v_from = v_length;
                        end if;
                        set v_from = v_from + 1;
                        leave my_loop;
                    when v_char = '+' then
                        set p_state = 'plus', v_from = v_from + 1;
                        leave my_loop;
                    when v_char = '<' then 
                        set p_state = 'less than';
                    when v_char = '>' then 
                        set p_state = 'greater than';
                    when v_char = ':' then 
                        if v_lookahead = '=' then
                            set p_state = 'assign', v_from = v_from + 2;
                            leave my_loop;
                        elseif v_lookahead = '$' and allow_script_tokens then
                            set p_state = 'expanded query_script variable';
                        else
                            set p_state = 'colon', v_from = v_from + 1;
                            leave my_loop;
                        end if;
                    when v_char = '{' and allow_script_tokens then 
                        set p_state = 'left braces', v_from = v_from + 1, p_level = p_level + 1;
                        leave my_loop;
                    when v_char = '}' and allow_script_tokens then 
                        set p_state = 'right braces', v_from = v_from + 1;
                        leave my_loop;
                    when v_char = '(' then 
                        set p_state = 'left parenthesis', v_from = v_from + 1, p_level = p_level + 1;
                        leave my_loop;
                    when v_char = ')' then 
                        set p_state = 'right parenthesis', v_from = v_from + 1;
                        leave my_loop;
                    when v_char = '^' then 
                        set p_state = 'bitwise xor', v_from = v_from + 1;
                        leave my_loop;
                    when v_char = '~' then 
                        set p_state = 'bitwise not', v_from = v_from + 1;
                        leave my_loop;
                    when v_char = '!' then
                        if v_lookahead = '=' then
                            set p_state = 'not equals', v_from = v_from + 2;
                        else
                            set p_state = 'not', v_from = v_from + 1;
                        end if;
                        leave my_loop;
                    when v_char = '|' then
                        if v_lookahead = '|' then
                            set p_state = 'or', v_from = v_from + 2;
                        else
                            set p_state = 'bitwise or', v_from = v_from + 1;
                        end if;
                        leave my_loop;
                    when v_char = '&' then
                        if v_lookahead = '&' then
                            set p_state = 'and', v_from = v_from + 2;
                        else
                            set p_state = 'bitwise and', v_from = v_from + 1;
                        end if;
                        leave my_loop;
                    else 
                        set p_state = 'error';
                end case;
            when 'less than' then
                case v_char 
                    when '=' then 
                        set p_state = 'less than or equals';
                        leave state_case;
                    when '>' then 
                        set p_state = 'not equals';
                    when '<' then 
                        set p_state = 'left shift';
                    else
                        do null;
                end case;
                leave my_loop;
            when 'less than or equals' then
                if v_char = '>' then 
                    set p_state = 'null safe equals'
                    ,   v_from = v_from + 1
                    ;
                end if;
                leave my_loop;
            when 'greater than' then
                case v_char 
                    when '=' then 
                        set p_state = 'greater than or equals';
                    when '>' then 
                        set p_state = 'right shift';
                    else
                        set p_state = 'error';
                end case;
                leave my_loop;
            when 'multi line comment' then
                if v_char = '*' and v_lookahead = '/' then
                    set v_from = v_from + 2;
                    leave my_loop;
                end if;
            when 'alpha' then 
                case
                    when v_char between 'A' and 'Z' 
                    or   v_char between 'a' and 'z' 
                    or   v_char = '_' then
                        leave state_case;
                    when v_char between '0' and '9' 
                    or   v_char = '$' then 
                        set p_state = 'alphanum';
                    else
                        leave my_loop;
                end case;
            when 'alphanum' then 
                case
                    when v_char between 'A' and 'Z' 
                    or   v_char between 'a' and 'z' 
                    or   v_char = '_'
                    or   v_char between '0' and '9' then 
                        leave state_case;
                    else
                        leave my_loop;
                end case;
            when 'integer' then
                case 
                    when v_char between '0' and '9' then 
                        leave state_case;
                    when v_char = '.' then 
                        set p_state = 'decimal';
                    else
                        leave my_loop;                        
                end case;
            when 'decimal' then
                case 
                    when v_char between '0' and '9' then 
                        leave state_case;
                    else
                        leave my_loop;
                end case;
            when 'whitespace' then
                if v_char not in ('\t', '\n', '\r') then
                    leave my_loop;                        
                end if;
            when 'string' then
                set v_from = locate(v_quote_char, p_text, v_from);
                if v_from then
                    if substr(p_text, v_from + 1, 1) = v_quote_char then
                        set v_from = v_from + 1;
                    elseif substr(p_text, v_from - 1, 1) != '\\' then
                        set v_from = v_from + 1;
                        leave my_loop;
                    end if;
                else
                    set p_state = 'error';
                    leave my_loop;
                end if;
            when 'quoted identifier' then
                if v_char != v_quote_char then 
                    leave state_case;
                else
                    set v_from = v_from + 1;
                    leave my_loop;                
                end if;
            when 'user-defined variable' then
                if v_char in (';', ',', ' ', '\t', '\n', '\r', '!', '~', '^', '%', '>', '<', ':', '=', '+', '-', '&', '*', '|', '(', ')') then
                    leave my_loop;
                elseif allow_script_tokens and v_char in ('{', '}') then
                    leave my_loop;
                end if;
            when 'query_script variable' then
                if v_char in (';', ',', ' ', '\t', '\n', '\r', '!', '~', '^', '%', '>', '<', ':', '=', '+', '-', '&', '*', '|', '(', ')') then
                    leave my_loop;
                elseif allow_script_tokens and v_char in ('{', '}', '.') then
                    leave my_loop;
                end if;
            when 'expanded query_script variable' then
                if v_char in (';', ',', ' ', '\t', '\n', '\r', '!', '~', '^', '%', '>', '<', ':', '=', '+', '-', '&', '*', '|', '(', ')') then
                    leave my_loop;
                elseif allow_script_tokens and v_char in ('{', '}', '.') then
                    leave my_loop;
                end if;
            when 'system variable' then
                if v_char in (';', ',', ' ', '\t', '\n', '\r', '!', '~', '^', '%', '>', '<', ':', '=', '+', '-', '&', '*', '|', '(', ')') then
                    leave my_loop;
                elseif allow_script_tokens and v_char in ('{', '}') then
                    leave my_loop;
                end if;
            else
                leave my_loop;            
        end case; end state_case;
        set v_from = v_from + 1;
    end while my_loop;
    set p_token = substr(p_text, p_from, v_from - p_from) collate utf8_general_ci;
    set p_from = v_from;
end;
//

delimiter ;
-- 
-- Assume the given text is a list of queries: 
-- This function calls upon _retokenized_text to parse the queries based on a semicolor
-- delimiter and quoting characters as dictated by sql_mode server variable.
-- The function recognizes semicolons which may appear within quoted text, and ignores them.
--

DELIMITER $$

DROP FUNCTION IF EXISTS _retokenized_queries $$
CREATE FUNCTION _retokenized_queries(queries TEXT CHARSET utf8) RETURNS TEXT CHARSET utf8 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Retokenizes input queries with special token'

begin
  declare quoting_characters VARCHAR(5) CHARSET ascii DEFAULT '`''';

  if not find_in_set('ANSI_QUOTES', @@sql_mode) then
    set quoting_characters := CONCAT(quoting_characters, '"');
  end if;

  return _retokenized_text(queries, ';', quoting_characters, TRUE, 'skip');
end $$

DELIMITER ;
-- 
-- Accepts input text and delimiter characters, and retokenizes text such that:
-- - original delimiters replaced with new delimiter
-- - new delimiter is known to be non-existent in original text
-- - quoted text is not tokenized (quoting characters are given)
--
-- The function:
-- - returns a retokenized text
-- - sets the @common_schema_retokenized_delimiter to the new delimiter
-- - sets the @common_schema_retokenized_count to number of tokens
-- variable to note the new delimiter.
-- Tokenizing result text by this delimiter is safe, and no further tests for quotes are required.
--
-- Paramaters:
-- - input_text: original text to be retokenized
-- - delimiters: one or more characters tokenizing the original text
-- - quoting characters: characters to be considered as quoters: this function will ignore
--   delimiters found within quoted text
-- - trim_tokens: A boolean. If TRUE, this function will trim white spaces from tokens
-- - empty_tokens_behavior: 
--   - if 'allow', empty tokens are returned. 
--   - if 'skip', empty tokens are silently discarded. 
--   - if 'error', empty tokens result with the function returning NULL 
--

DELIMITER $$

DROP FUNCTION IF EXISTS _retokenized_text $$
CREATE FUNCTION _retokenized_text(
  input_text TEXT CHARSET utf8, 
  delimiters VARCHAR(16) CHARSET utf8, 
  quoting_characters VARCHAR(16) CHARSET utf8,
  trim_tokens BOOL,
  empty_tokens_behavior enum('allow', 'skip', 'error')
) RETURNS TEXT CHARSET utf8 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Retokenizes input_text with special token'

begin
  declare current_pos INT UNSIGNED DEFAULT 1;
  declare token_start_pos INT UNSIGNED DEFAULT 1;
  declare terminating_quote_found BOOL DEFAULT FALSE;
  declare terminating_quote_pos INT UNSIGNED DEFAULT 0;
  declare terminating_quote_escape_char CHAR(1) CHARSET utf8;
  declare current_char VARCHAR(1) CHARSET utf8;
  declare quoting_char VARCHAR(1) CHARSET utf8;
  declare current_token TEXT CHARSET utf8 DEFAULT '';
  declare result_text TEXT CHARSET utf8 DEFAULT '';
  declare delimiter_template VARCHAR(64) CHARSET ascii DEFAULT '\0[\n}\b+-\t|%&{])/\r~:;&"%`@>?=<_common_schema_unlikely_token_';
  declare internal_delimiter_length TINYINT UNSIGNED DEFAULT 0;
  declare internal_delimiter VARCHAR(64) CHARSET utf8 DEFAULT '';
  
  -- Resetting result delimiter; In case of error we want this to be an indicator
  set @common_schema_retokenized_delimiter := NULL;
  set @common_schema_retokenized_count := NULL;

  -- Detect a prefix of delimiter_template which can serve as a delimiter in the retokenized text,
  -- i.e. find a shortest delimiter which does not appear in the input text at all (hence can serve as
  -- a strictly tokenizing text, regardless of quotes)
  _evaluate_internal_delimiter_loop: while internal_delimiter_length < CHAR_LENGTH(delimiter_template) do
  	set internal_delimiter_length := internal_delimiter_length + 1;
  	set internal_delimiter := LEFT(delimiter_template, internal_delimiter_length);
  	if LOCATE(internal_delimiter, input_text) = 0 then
  	  leave _evaluate_internal_delimiter_loop;
  	end if;
  end while;

  while current_pos <= CHAR_LENGTH(input_text) + 1 do
    if current_pos = CHAR_LENGTH(input_text) + 1 then
      -- make sure a delimiter "exists" at the end of input_text, so as to gracefully parse
      -- the last token in list.
      set current_char := LEFT(delimiters, 1);
    else
      set current_char := SUBSTRING(input_text, current_pos, 1);
    end if;
    if LOCATE(current_char, quoting_characters) > 0 then
      -- going into string state: search for terminating quote.
      set quoting_char := current_char;
      set terminating_quote_found := false;
      while not terminating_quote_found do
        set terminating_quote_pos := LOCATE(quoting_char, input_text, current_pos + 1);
        if terminating_quote_pos = 0 then
          -- This is an error: non-terminated string!
          return NULL;
        end if;
        if terminating_quote_pos = current_pos + 1 then
          -- an empty text
          set terminating_quote_found := true;
        else
          -- We've gone some distance to find a possible terminating character. Is it really teminating,
          -- or is it escaped?
          set terminating_quote_escape_char := SUBSTRING(input_text, terminating_quote_pos - 1, 1);
          if (terminating_quote_escape_char = quoting_char) or (terminating_quote_escape_char = '\\') then
            -- This isn't really a quote end: the quote is escaped. 
            -- We do nothing; just a trivial assignment.
            set terminating_quote_found := false;        
          else
            set terminating_quote_found := true;            
          end if;
        end if;
        set current_pos := terminating_quote_pos;
      end while;
    elseif LOCATE(current_char, delimiters) > 0 then
      -- Found a delimiter (outside of quotes).
      set current_token := SUBSTRING(input_text, token_start_pos, current_pos - token_start_pos);
      if trim_tokens then
        set current_token := trim_wspace(current_token);
      end if;
      -- What of this token?
      if ((CHAR_LENGTH(current_token) = 0) and (empty_tokens_behavior = 'error')) then
        -- select `ERROR: _retokenized_text(): found empty token` FROM DUAL INTO @common_schema_error;
        return NULL;
      end if;
      if ((CHAR_LENGTH(current_token) > 0) or (empty_tokens_behavior = 'allow')) then
        -- Replace with internal token:
        if CHAR_LENGTH(result_text) > 0 then
          set result_text := CONCAT(result_text, internal_delimiter);
        end if;
        -- Finally, we note down the token:
        set result_text := CONCAT(result_text, current_token);
        set @common_schema_retokenized_count := 1 + IFNULL(@common_schema_retokenized_count, 0);
      end if;
      set token_start_pos := current_pos + 1;
    end if;
    set current_pos := current_pos + 1;
  end while;
  -- Unfortunately we cannot return two values from a function. One goes as
  -- user defined variable.
  -- @common_schema_retokenized_delimiter must be checked by calling code so
  -- as to determine how to further split text.
  set @common_schema_retokenized_delimiter := internal_delimiter;
  return result_text;
end $$

DELIMITER ;
--
-- Called by _foreach, this routines executes a single step in iteration.
-- Execution is based on input, and the routine either dynamically executes given queries, or 
-- calls upon scripting to interpret statement.
-- 

DELIMITER $$

DROP PROCEDURE IF EXISTS _run_foreach_step $$
CREATE PROCEDURE _run_foreach_step(
   execute_query TEXT CHARSET utf8,
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   in   expect_single tinyint unsigned,
   out  consumed_to_id int unsigned,
   in   variables_array_id int unsigned,
   in depth int unsigned,
   in should_execute_statement tinyint unsigned
)  
MODIFIES SQL DATA
SQL SECURITY INVOKER
COMMENT 'Invoke queries/statement per foreach step'

main_body: begin
  if execute_query IS NOT NULL then
    call run(execute_query);
  elseif id_from IS NOT NULL then
    call _assign_input_local_variables(variables_array_id);
    call _consume_statement(id_from, id_to, expect_single, consumed_to_id, depth, should_execute_statement);
  else
    -- Panic. Should not get here.
    call throw('_run_foreach_step(): neither queries nor script position provided');
  end if;
end $$

DELIMITER ;
delimiter //

drop procedure if exists _wrap_select_list_columns
//

create procedure _wrap_select_list_columns(
    inout p_text        text    -- select statement text
,   in p_column_count   int     -- number of select-list column expressions to rewrite
,   out p_error         text    -- error message text output (to be inspected by the caller)
)
my_proc: begin
    declare v_from, v_old_from int unsigned;
    declare v_token text charset utf8;
    declare v_level int unsigned;
    declare v_state varchar(32);
    declare v_whitespace varchar(1) default '';
    declare v_done bool default FALSE;
    declare v_statement text;
    declare v_expression text default '';
    declare v_column_number int unsigned default 0;
    declare v_prev_tokens text default '';
    declare v_token_separator char(1) default '~';
    declare v_token_separator_esc char(1) default '_';
    declare v_handle text;
    declare v_substr_length int unsigned default 0;
    set @_wrap_select_num_original_columns := 0;
    
    my_main: begin
    -- part one: find the SELECT keyword.
    my_loop: repeat 
        set v_old_from = v_from;
        call _get_sql_token(p_text, v_from, v_level, v_token, 'sql', v_state);
        case 
            when v_state in ('whitespace', 'single line comment', 'multi line comment', 'conditional comment') then
                iterate my_loop;
            when v_state = 'alpha' and v_token = 'select' then
                set v_statement = substr(p_text, 1, v_from);
                leave my_loop;
            else 
                set p_error = 'No Select found';
                leave my_proc;
        end case;
    until 
        v_old_from = v_from
    end repeat;
    
    -- part two: rewrite columns
    columns_loop: repeat 
        set v_old_from = v_from;
        call _get_sql_token(p_text, v_from, v_level, v_token, 'sql', v_state);
        if v_state = 'error' then
            set p_error = 'Tokenizer returned error state';
            leave my_main;
        elseif (v_column_number = 0) and ((v_state, v_token) = ('alpha', 'distinct')) then
            set v_statement = concat(v_statement, 'distinct ');
        elseif (v_column_number < p_column_count) or (p_column_count = 0)  then
            if  v_level = 0 and (
                (v_state, v_token) in (
                    ('alpha', 'from')
                ,   ('comma', ',')
                ) 
                or v_old_from = v_from
            ) then
                -- if we ran into the from clause and there is whitespace (or comments) between the last column expression and the from keyword,
                -- then v_prev_tokens will end with a v_token_separator. We remove that here to not mess up finding the handle
                if v_token = 'from' 
                and substr(v_prev_tokens, character_length(v_prev_tokens) + 1 - character_length(v_token_separator)) = v_token_separator then
                    set v_prev_tokens = substr(v_prev_tokens, 1, character_length(v_prev_tokens) - character_length(v_token_separator));
                end if;
                -- check if we have multiple separated tokens
                if character_length(v_prev_tokens) - character_length(replace(v_prev_tokens, v_token_separator, '')) > 1 then
                    -- store the 2nd last token in v_handle
                    set v_handle = substring_index(substring_index(v_prev_tokens, v_token_separator, -2), v_token_separator, 1)
                    -- get the max length of the column expression
                    ,   v_substr_length = character_length(v_expression)
                    -- substract length that makes up the alias (and AS keyword if applicable)
                    ,   v_substr_length = v_substr_length - case 
                            when UPPER(v_handle) = 'AS' then    -- handle indicates an explicit alias.
                                2 + character_length(substring_index(v_expression, v_handle, -1))
                            when coalesce(v_handle, '') not in (  -- if the handle is not a keyword then the last token must be an alias. chop it off 
                                '', 'AND', 'BINARY', 'COLLATE', 'DIV', 'ESCAPE', 'IS', 'LIKE', 'MOD', 'NOT', 'OR', 'REGEXP', 'RLIKE', 'XOR'
                            ,   '+', '-', '/', '*', '%'
                            ,   '||', '&&', '!' 
                            ,   '<', '<=', '=>', '>', '<=>', '=', '!=', ':='
                            ,   '|', '&', '~', '^', '<<', '>>'
                            ,   '.'
                            ) and not (   -- what also counts as a keyword is a character set specifier. consider moving this into the tokenizer.
                                    v_handle = '_bin' 
                                or  v_handle LIKE '_%'
                                and exists (
                                    select  null 
                                    from    information_schema.character_sets 
                                    where   character_set_name = substring(v_handle, 2)
                                )
                            ) then
                                1+character_length(substring_index(v_prev_tokens, v_token_separator, -1))
                            else 0
                        end
                    -- chop off the alias.
                    ,   v_expression = substring(v_expression, 1, v_substr_length)
                    ;
                end if;
                
                set v_statement = concat(
                        v_statement
                    ,   if (v_column_number, ', ', '')
                    ,   TRIM(v_expression)
                    ,   ' AS col', v_column_number + 1  
                    )
                ,   v_column_number = v_column_number + 1
                ,   v_expression = ''
                ,   v_prev_tokens = ''
                ;
            else
                set v_expression = concat(v_expression, v_token);
                set v_prev_tokens = concat(
                    v_prev_tokens
                ,   if( v_level != 0
                    or  v_state not in (
                            'whitespace'
                        ,   'multi line comment'
                        ,   'single line comment'
                        )
                    ,   concat(
                            if(v_level, '', v_token_separator)
                        ,   replace(v_token, v_token_separator, v_token_separator_esc)
                        )
                    ,   ''
                    )
                );
            end if;            
        end if;
    until 
        v_old_from = v_from or v_token = 'from'
    end repeat;

    -- part three: pad null columns
    set @_wrap_select_num_original_columns := v_column_number;
    while v_column_number < p_column_count do
        set v_column_number = v_column_number + 1
        ,   v_statement = concat(v_statement, ', NULL as col', v_column_number)
        ;
    end while;

    end my_main;
    
    set p_text= concat(
                    v_statement
                ,   if(v_token = 'from', ' from', '')
                ,   substr(p_text, v_from)
                );
end;
//

delimiter ;
--
-- Search and read common_schema documentation.
--
-- help() accepts a search term, and presents a single documentation page
-- which best fits the term. The term may appear within the documentation's title
-- or description. It could be the name or part of name of one of 
-- common_schema's components (routines, views, ...), or it could be any
-- keyword appearing within the documentation.
-- The output is MySQL-friendly, in that it breaks the documentation into rows of
-- text, thereby presenting the result in a nicely formatted table.
--

DELIMITER $$

DROP PROCEDURE IF EXISTS help $$
CREATE PROCEDURE help(expression TINYTEXT CHARSET utf8) 
READS SQL DATA
SQL SECURITY INVOKER
COMMENT 'Inline help'

begin
  set expression := REPLACE(expression, '()', '');
  set expression := REPLACE(expression, ';', '');
  set expression := trim_wspace(expression);
  set expression := REPLACE(expression, ' ', '%');
  SELECT 
    split_token(help_message, '\n', n) AS help
  FROM (
    SELECT help_message FROM (
      SELECT 1 AS order_column, help_message FROM help_content WHERE topic LIKE CONCAT('%', expression, '%')
      UNION ALL
      SELECT 2, help_message FROM help_content WHERE LEFT(help_message, 256) LIKE CONCAT('%', expression, '%')
      UNION ALL
      SELECT 3, help_message FROM help_content WHERE help_message LIKE CONCAT('%', expression, '%')
      UNION ALL
      SELECT 4, CONCAT('No help topics found for "', expression, '".')
    ) select_all 
    ORDER BY order_column ASC 
    LIMIT 1
  ) select_single,
  numbers
  WHERE 
    numbers.n BETWEEN 1 AND get_num_tokens(help_message, '\n')
  ORDER BY n ASC;
end $$

DELIMITER ;
-- 
-- Return an unqualified form of grantee, user or host.
-- 
-- The function requalifies given grantee if in grantee format,
-- or returns unqualified text if in apparent user/host format.
--
-- The function returns NULL when the input is not a valid grantee term.
--
-- Example:
--
-- SELECT _requalify_grantee_term('user.name@some.host')
-- Returns (text): 'user.name'@'some.host'
-- 
DELIMITER $$

DROP FUNCTION IF EXISTS _requalify_grantee_term $$
CREATE FUNCTION _requalify_grantee_term(grantee_term TINYTEXT CHARSET utf8) 
  RETURNS TINYTEXT CHARSET utf8
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Requalify grantee input'

BEGIN
  declare tokens_delimiter VARCHAR(64) CHARSET ascii DEFAULT NULL;
  declare num_tokens INT UNSIGNED DEFAULT 0;

  set grantee_term := _retokenized_text(grantee_term, '@', '''', TRUE, 'error');
  set tokens_delimiter := @common_schema_retokenized_delimiter;
  set num_tokens := @common_schema_retokenized_count;
  
  if num_tokens = 1 then
    return unquote(grantee_term);
  end if;
  if num_tokens = 2 then
    return mysql_grantee(unquote(SUBSTRING_INDEX(grantee_term, tokens_delimiter, 1)), unquote(SUBSTRING_INDEX(grantee_term, tokens_delimiter, -1)));
  end if;
  return null;
END $$

DELIMITER ;

--
-- Create a new account with same privileges as those of given grantee.
-- Initial password for new account is also duplicated from existing account.
--

DELIMITER $$

DROP PROCEDURE IF EXISTS duplicate_grantee $$
CREATE PROCEDURE duplicate_grantee(
    IN existing_grantee TINYTEXT CHARSET utf8,
    IN new_grantee TINYTEXT CHARSET utf8
  ) 
MODIFIES SQL DATA
SQL SECURITY INVOKER
COMMENT 'Duplicate grantee''s privileges into new account'

begin
  declare sql_grants_statement TEXT charset utf8 default null;
    
  SELECT 
    MIN(REPLACE(sql_grants, _requalify_grantee_term(existing_grantee), _requalify_grantee_term(new_grantee)))
  FROM 
    sql_show_grants 
  WHERE 
    grantee = _requalify_grantee_term(existing_grantee)
  INTO
    sql_grants_statement;
  
  if sql_grants_statement is null then
    call throw(CONCAT('duplicate_grantee(): unknown grantee ', existing_grantee));
  end if;
  
  call exec(sql_grants_statement);
end $$

DELIMITER ;
--
-- Kills connections based on grantee term.
-- The grantee term can be a full grantee declaration; a grantee user; a grantee host; a user; a hostname; a user@host combination.
-- SUPER and replication connections can be terminated as well.
-- At any case, thes procedure does not kill the current connection.
--

DELIMITER $$

DROP PROCEDURE IF EXISTS killall $$
CREATE PROCEDURE killall(IN grantee_term TINYTEXT CHARSET utf8) 
READS SQL DATA
SQL SECURITY INVOKER
COMMENT 'Kills connections based on grantee term'

begin
  set grantee_term := _requalify_grantee_term(grantee_term);
  
  begin
    declare kill_process_id bigint unsigned default null;
    declare done tinyint default 0;
    declare killall_cursor cursor for 
      select 
        id 
      from 
        _processlist_grantees_exploded 
      where 
        grantee_term in (grantee, unqualified_grantee, grantee_host, grantee_user, qualified_user_host, unqualified_user_host, hostname, user)
        and id != CONNECTION_ID()
      ;
    declare continue handler for NOT FOUND set done = 1;
    declare continue handler for 1094 begin end; -- ERROR 1094 is "Unknown thread id"
  
    -- Two reason for opening a cursor and walking one by one instead of using existing constructs such as 'eval':
    -- 1. We wish to recover from error 1094 ("Unknown thread id") in case a connection has just been closed,
    -- and continue with killing of other connections.
    -- 2. We wish to be able to call this routine from with QueryScript, so no dynamic SQL allowed.
    open killall_cursor;
    read_loop: loop
      fetch killall_cursor into kill_process_id;
      if done then
        leave read_loop;
      end if;
      kill kill_process_id;
    end loop;

    close killall_cursor;
  end;
end $$

DELIMITER ;
-- 
-- Match an existing account based on user+host
--
-- Example:
--
-- SELECT match_grantee('apps', '192.128.0.1:12345');
-- Returns (text): 'apps'@'%', a closest matching account
-- 
DELIMITER $$

DROP FUNCTION IF EXISTS match_grantee $$
CREATE FUNCTION match_grantee(connection_user char(16) CHARSET utf8, connection_host char(70) CHARSET utf8) RETURNS VARCHAR(100) CHARSET utf8 
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
COMMENT 'Match an account based on user+host'

BEGIN
  DECLARE grantee_user char(16) CHARSET utf8 DEFAULT NULL;
  DECLARE grantee_host char(60) CHARSET utf8 DEFAULT NULL;

  SELECT
    MAX(user), MAX(host)
  FROM (
    SELECT
      user, host
    FROM
      mysql.user
    WHERE
      connection_user RLIKE
        CONCAT('^',
          REPLACE(
            user,
            '%', '.*'),
          '$')
      AND SUBSTRING_INDEX(connection_host, ':', 1) RLIKE
        CONCAT('^',
          REPLACE(
          REPLACE(
            host,
            '.', '\\.'),
            '%', '.*'),
          '$')
    ORDER BY
      CHAR_LENGTH(host) - CHAR_LENGTH(REPLACE(host, '%', '')) ASC,
      CHAR_LENGTH(host) - CHAR_LENGTH(REPLACE(host, '.', '')) DESC,
      host ASC,
      CHAR_LENGTH(user) - CHAR_LENGTH(REPLACE(user, '%', '')) ASC,
      user ASC
    LIMIT 1
  ) select_matching_account
  INTO 
    grantee_user, grantee_host;
    
    
  RETURN CONCAT('''', grantee_user, '''@''', grantee_host, '''');
END $$

DELIMITER ;
-- 
-- Return a qualified MySQL grantee (account) based on user and host.
-- 
-- It is a simple convenience function which wraps up the single quotes around the components
--
-- Example:
--
-- SELECT mysql_grantee('web_user', '192.128.0.%');
-- Returns (text): 'web_user'@'192.128.0.%'
-- 
DELIMITER $$

DROP FUNCTION IF EXISTS mysql_grantee $$
CREATE FUNCTION mysql_grantee(mysql_user char(16) CHARSET utf8, mysql_host char(60) CHARSET utf8) RETURNS VARCHAR(100) CHARSET utf8 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Return a qualified MySQL grantee name'

BEGIN
  RETURN CONCAT('''', mysql_user, '''@''', mysql_host, '''');
END $$

DELIMITER ;
--
-- Generate a server's security audit report
--

DELIMITER $$

DROP PROCEDURE IF EXISTS security_audit $$
CREATE PROCEDURE security_audit() 
READS SQL DATA
SQL SECURITY INVOKER
COMMENT 'Kills connections based on grantee term'

begin
  call _run_named_script('security_audit');
end $$

DELIMITER ;
-- 
-- Return "lap-time" for current query: time elapsed since last invocation of this function
-- in current query.
-- Essentially, this function allows for measurement of time elapsed between invocations.
--

DELIMITER $$

DROP FUNCTION IF EXISTS query_laptime $$
CREATE FUNCTION query_laptime() RETURNS DOUBLE 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Return current query runtime'

begin
  declare time_right_now TIMESTAMP;
  declare query_time_now TIMESTAMP;
  declare time_diff DOUBLE;
  
  set time_right_now := SYSDATE();	
  set query_time_now := NOW();	
  -- Make sure we're not examining values for a previous query_laptime() execution!
  -- NOW() is an indicator for this query.
  -- If previous query_laptime() query also started at NOW(), well, there's no harm,
  -- since same second is considered to be insignificant.
  if @_common_schema_laptime_lap_start is null then
    set @_common_schema_laptime_lap_start := query_time_now;
  else
    set @_common_schema_laptime_lap_start := GREATEST(@_common_schema_laptime_lap_start, query_time_now);
  end if;
  set time_diff := TIMESTAMPDIFF(MICROSECOND, @_common_schema_laptime_lap_start, time_right_now) / 1000000.0;
  set @_common_schema_laptime_lap_start := time_right_now;
  
  return time_diff;
end $$
-- 
-- Returns the number of seconds this query has been running for so far.
-- On servers supporting subsecond time resolution, this results with a 
-- floating point value.
-- On servers with single second resolution this results with a truncated integer.
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS query_runtime $$
CREATE FUNCTION query_runtime() RETURNS DOUBLE 
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
COMMENT 'Return current query runtime'

BEGIN
  return TIMESTAMPDIFF(MICROSECOND, NOW(), SYSDATE()) / 1000000.0;
END $$

DELIMITER ;
-- 
-- Returns an integer unique to this session 
--

DELIMITER $$

DROP FUNCTION IF EXISTS session_unique_id $$
CREATE FUNCTION session_unique_id() RETURNS INT UNSIGNED
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Returns unique ID within this session'

BEGIN
  set @_common_schema_session_unique_id := IFNULL(@_common_schema_session_unique_id, 0) + 1;
  return @_common_schema_session_unique_id;
END $$

DELIMITER ;
-- 
-- Returns the current query executed by this thread.
-- The text of current query will, of course, include the call to this_query() itself.
-- It may be useful in passing query's text to text-parsing functions which can further
-- make decisions while executing the query.
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS this_query $$
CREATE FUNCTION this_query() RETURNS LONGTEXT CHARSET utf8 
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
COMMENT 'Return current query'

BEGIN
  return (SELECT INFO FROM INFORMATION_SCHEMA.PROCESSLIST WHERE ID = CONNECTION_ID());
END $$

DELIMITER ;
-- 
-- Throttle current query by periodically sleeping throughout its execution.
-- This function sleeps an amount of time proportional to the time the query executes,
-- on a per-lap basis. That is, time is measured between two invocations of this function,
-- and that time is multiplied by throttle_ratio to conclude the extent of throttling.
-- 

DELIMITER $$

DROP function IF EXISTS throttle $$
CREATE function throttle(throttle_ratio DOUBLE) returns DOUBLE
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT ''

begin
  set @_common_schema_throttle_counter := IFNULL(@_common_schema_throttle_counter, 0) + 1;
  -- Every 1000 rows - check for throttling.
  if @_common_schema_throttle_counter % 1000 = 0 then
    set @_common_schema_throttle_counter := 0;
    set @_common_schema_throttle_sysdate := SYSDATE();
    -- Make sure we're not examining values for a previous throttle()d query!
    -- NOW() is an indicator for this query.
    -- If previous throttle()d query also started at NOW(), well, there's no harm,
    -- since same second is considered to be insignificant.
    set @_common_schema_throttle_chunk_start := IFNULL(@_common_schema_throttle_chunk_start, NOW());
    set @_common_schema_throttle_chunk_start := GREATEST(@_common_schema_throttle_chunk_start, NOW());
    set @_common_schema_throttle_timediff := TIMESTAMPDIFF(SECOND, @_common_schema_throttle_chunk_start, @_common_schema_throttle_sysdate);
    set @_common_schema_throttle_sleep_time := @_common_schema_throttle_timediff * throttle_ratio;
    -- We do not necessarily throttle. Only if there has been at least a one second lapse.
    if @_common_schema_throttle_sleep_time > 0 then
      DO SLEEP(@_common_schema_throttle_sleep_time);
      set @_common_schema_throttle_chunk_start := SYSDATE();
      return @_common_schema_throttle_sleep_time;
    end if;
  end if;
  -- No throtling this time...
  return 0;
end $$

DELIMITER ;
-- 
-- A convenience function to determine whether a certain table exists.
-- This function reads from INFORMATION_SCHEMA and utilizes I_S optimizations.
-- The function returns true if a table or view by given name exist in given schema. There is
-- no check for temporary tables.
--

DELIMITER $$

DROP FUNCTION IF EXISTS table_exists $$
CREATE FUNCTION table_exists(
  lookup_table_schema varchar(64) charset utf8, 
  lookup_table_name varchar(64) charset utf8) 
RETURNS TINYINT UNSIGNED
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
COMMENT 'Check if specified table exists'

BEGIN
  return (select count(*) from INFORMATION_SCHEMA.TABLES 
    where TABLE_SCHEMA = lookup_table_schema AND TABLE_NAME = lookup_table_name);
END $$

DELIMITER ;
--
--
--

delimiter //

drop procedure if exists _consume_expression //

create procedure _consume_expression(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   in   require_parenthesis tinyint unsigned,
   out  consumed_to_id int unsigned,
   out  expression text charset utf8,
   out  expression_statement text charset utf8,
   in   should_execute_statement tinyint unsigned
)
comment 'Reads expression'
language SQL
deterministic
reads sql data
sql security invoker
main_body: begin
    declare first_state text;
    declare expression_level int unsigned;
    declare id_end_expression int unsigned; 
    declare expanded_variables TEXT CHARSET utf8;
    declare expanded_variables_found tinyint unsigned;
    
    set expression_statement := NULL ;
    
    call _skip_spaces(id_from, id_to);
    SELECT level, state FROM _sql_tokens WHERE id = id_from INTO expression_level, first_state;

    if (first_state = 'left parenthesis') then
      SELECT MIN(id) FROM _sql_tokens WHERE id > id_from AND state = 'right parenthesis' AND level = expression_level INTO id_end_expression;
  	  if id_end_expression IS NULL then
	    call _throw_script_error(id_from, 'Unmatched "(" parenthesis');
	  end if;
	  set id_from := id_from + 1;
      call _skip_spaces(id_from, id_to);
      
      call _expand_statement_variables(id_from, id_end_expression-1, expression, expanded_variables_found, should_execute_statement);
      -- SELECT GROUP_CONCAT(token ORDER BY id SEPARATOR '') FROM _sql_tokens WHERE id BETWEEN id_from AND id_end_expression-1 INTO expression;
      
      -- Note down the statement (if any) of the expression:
      SELECT token FROM _sql_tokens WHERE id = id_from AND state = 'alpha' INTO expression_statement;
      if ((expression is NULL) or (trim_wspace(expression) = '')) and (should_execute_statement or not expanded_variables_found) then
        call _throw_script_error(id_from, 'Found empty expression');
      end if;
      -- ~~~ select expression, expression_statement;
      set consumed_to_id := id_end_expression;
    else
      if require_parenthesis then
        call _throw_script_error(id_from, 'Expected "(" on expression');
      end if;
    end if;
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _consume_foreach_expression //

create procedure _consume_foreach_expression(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   out  consumed_to_id int unsigned,
   in   depth int unsigned,
   out  collection text charset utf8,
   out  variables_array_id int unsigned,
   out  variables_delaration_id int unsigned,
   in should_execute_statement tinyint unsigned
)
comment 'Reads foreach() expression'
language SQL
deterministic
reads sql data
sql security invoker
main_body: begin
    declare first_state text;
    declare expression_level int unsigned;
    declare id_end_expression int unsigned default NULL; 
    declare id_end_variables_definition int unsigned default NULL; 
    
    call _skip_spaces(id_from, id_to);
    SELECT level, state FROM _sql_tokens WHERE id = id_from INTO expression_level, first_state;

    if (first_state != 'left parenthesis') then
      call _throw_script_error(id_from, 'Expected "(" on foreach expression');
    end if;
    
    SELECT MIN(id) FROM _sql_tokens WHERE id > id_from AND state = 'right parenthesis' AND level = expression_level INTO id_end_expression;
  	if id_end_expression IS NULL then
	  call _throw_script_error(id_from, 'Unmatched "(" parenthesis');
	end if;
	
	-- Detect the positions where variables are declared
    SELECT MIN(id) FROM _sql_tokens WHERE id > id_from AND state = 'colon' AND level = expression_level INTO id_end_variables_definition;
  	if id_end_variables_definition IS NULL then
	  call _throw_script_error(id_from, 'foreach: expected ":" as in (variables : collection)');
	end if;
	
    set id_from := id_from + 1;
	
	-- Expect variables declaration:
    call _expect_dynamic_states_list(id_from, id_end_variables_definition-1, 'query_script variable', variables_array_id);
	set variables_delaration_id := id_from;
	call _declare_local_variables(id_from, id_to, id_end_variables_definition, depth, variables_array_id);
		
    -- Get the collection clause:
	set id_from := id_end_variables_definition + 1;
    call _skip_spaces(id_from, id_to);

    call _expand_statement_variables(id_from, id_end_expression-1, collection, @_common_schema_dummy, should_execute_statement);
    -- SELECT GROUP_CONCAT(token ORDER BY id SEPARATOR '') FROM _sql_tokens WHERE id BETWEEN id_from AND id_end_expression-1 INTO collection;

    set consumed_to_id := id_end_expression;
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _consume_script_statement //

create procedure _consume_script_statement(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   in   statement_id_from      int unsigned,
   in   statement_id_to      int unsigned,
   in   depth int unsigned,
   in   script_statement text charset utf8,
   in should_execute_statement tinyint unsigned
)
comment 'Reads script statement'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  declare tokens_array_id int unsigned;
  declare tokens_array_element text charset utf8;
  declare matched_token text charset utf8;
  declare statement_arguments text charset utf8;
  declare expanded_variables_found tinyint unsigned;
  
  call _expand_statement_variables(id_from+1, statement_id_to, statement_arguments, expanded_variables_found, should_execute_statement);
  
  set tokens_array_id := NULL;
  
  case script_statement
	when 'start' then begin
	    call _expect_token(statement_id_from, statement_id_to, 'transaction', false, @_common_schema_dummy, @_common_schema_dummy);
        if should_execute_statement then
          start transaction;
        end if;
	  end;
	when 'begin' then begin
		call _expect_nothing(statement_id_from, statement_id_to);
        if should_execute_statement then
          start transaction;
        end if;
	  end;
	when 'commit' then begin
		call _expect_nothing(statement_id_from, statement_id_to);
        if should_execute_statement then
          commit;
        end if;
	  end;
	when 'rollback' then begin
		call _expect_nothing(statement_id_from, statement_id_to);
        if should_execute_statement then
          rollback;
        end if;
	  end;
	when 'echo' then begin
        if should_execute_statement then
          select trim_wspace(statement_arguments) as echo;
        end if;
	  end;
	when 'eval' then begin
        if should_execute_statement then
          call eval(statement_arguments);
        end if;
	  end;
	when 'pass' then begin
	    call _expect_nothing(statement_id_from, statement_id_to);
	  end;
	when 'sleep' then begin
	    call _expect_state(statement_id_from, statement_id_to, 'integer|decimal|user-defined variable|query_script variable', false, @_common_schema_dummy, matched_token);
	    -- Now that states list is validated, we just take the statement argument (there's only 1) for benefit of variable expansion:
        if should_execute_statement then
          call exec(CONCAT('SET @_common_schema_intermediate_var := ', statement_arguments));
          DO SLEEP(CAST(trim_wspace(@_common_schema_intermediate_var) AS DECIMAL(64, 2)));
        end if;
	  end;
	when 'throttle' then begin
	    call _expect_state(statement_id_from, statement_id_to, 'integer|decimal|user-defined variable|query_script variable', false, @_common_schema_dummy, matched_token);
	    -- Now that states list is validated, we just take the statement argument (there's only 1) for benefit of variable expansion:
        if should_execute_statement then
          call exec(CONCAT('SET @_common_schema_intermediate_var := ', statement_arguments));
          call _throttle_script(CAST(trim_wspace(@_common_schema_intermediate_var) AS DECIMAL(64, 2)));
        end if;
	  end;
    when 'throw' then begin
	    call _expect_state(statement_id_from, statement_id_to, 'string|user-defined variable|query_script variable', false, @_common_schema_dummy, matched_token);
        if should_execute_statement then
          call exec(CONCAT('SET @_common_schema_intermediate_var := ', statement_arguments));
          call throw(@_common_schema_intermediate_var);
        end if;
	  end;
    when 'var' then begin
	    call _peek_states_list(statement_id_from, statement_id_to, 'query_script variable,assign', true, true, false, @_common_schema_dummy, @_common_schema_peek_to_id);
	    if @_common_schema_peek_to_id > 0 then
	      -- a delare-and-assign statement, e.g. var $x := 3;
	      call _declare_and_assign_local_variable(id_from, id_to, statement_id_from, @_common_schema_peek_to_id, statement_id_to, depth, should_execute_statement);
	    else
          call _expect_dynamic_states_list(statement_id_from, statement_id_to, 'query_script variable', tokens_array_id);
          call _declare_local_variables(id_from, id_to, statement_id_to, depth, tokens_array_id);
	    end if;
	  end;
    when 'input' then begin
	    if @_common_schema_script_loop_nesting_level > 0 then
          call _throw_script_error(id_from, CONCAT('Invalid loop nesting level for INPUT: ', @_common_schema_script_loop_nesting_level));
	    end if;
	    call _expect_dynamic_states_list(statement_id_from, statement_id_to, 'query_script variable', tokens_array_id);
		call _declare_local_variables(id_from, id_to, statement_id_to, depth, tokens_array_id);
        if should_execute_statement then
          call _assign_input_local_variables(tokens_array_id);
        end if;
	  end;
	when 'report' then begin
        if should_execute_statement then
          call _script_report(statement_arguments);
        end if;
	  end;
    else begin 
	    -- Getting here is internal error
	    call _throw_script_error(id_from, CONCAT('Unknown script statement: "', script_statement, '"'));
	  end;
  end case;
  if tokens_array_id is not null then
    call _drop_array(tokens_array_id);
  end if;
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _consume_split_statement //

create procedure _consume_split_statement(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   out  consumed_to_id int unsigned,
   in   depth int unsigned,
   out  split_table_schema tinytext charset utf8,
   out  split_table_name tinytext charset utf8,
   out  split_injected_action_statement text charset utf8,
   out  split_injected_text tinytext charset utf8,
   out	split_options varchar(2048) charset utf8,
   in should_execute_statement tinyint unsigned
)
comment 'Reads split() expression'
language SQL
deterministic
reads sql data
sql security invoker
main_body: begin
    declare first_state text;
    declare expression_level int unsigned;
    declare id_end_action_statement int unsigned default NULL; 
    declare id_end_split_table_declaration int unsigned default NULL; 
    declare query_type_supported tinyint unsigned;
    declare tables_found varchar(32) charset ascii;
    declare colon_exists tinyint unsigned default false;
    declare found_explicit_table tinyint unsigned;
    declare found_any_params tinyint unsigned;
    declare found_possible_statement tinyint unsigned;
    
    call _skip_spaces(id_from, id_to);
    SELECT level, state FROM _sql_tokens WHERE id = id_from INTO expression_level, first_state;

    -- Validate syntax:
    if (first_state != 'left parenthesis') then
      call _throw_script_error(id_from, 'Expected "(" on split expression');
    end if;
    
    SELECT MIN(id) FROM _sql_tokens WHERE id > id_from AND state = 'right parenthesis' AND level = expression_level INTO id_end_action_statement;
  	if id_end_action_statement IS NULL then
	  call _throw_script_error(id_from, 'Unmatched "(" parenthesis');
	end if;
	
	-- Detect the separator:
    SELECT MIN(id) FROM _sql_tokens WHERE id > id_from AND state = 'colon' AND level = expression_level INTO id_end_split_table_declaration;
    set colon_exists := (id_end_split_table_declaration IS NOT NULL);
  	if id_end_split_table_declaration IS NULL then
  	  set id_end_split_table_declaration := id_end_action_statement;
	end if;
	
    set id_from := id_from + 1;
	
    set split_injected_text := '[:_query_script_split_injected_placeholder:]';
	
    set found_possible_statement := true;
    if colon_exists then
      call _consume_split_statement_params(id_from, id_end_split_table_declaration-1, should_execute_statement, split_table_schema, split_table_name, split_options, found_explicit_table, found_any_params);
      if not found_any_params then
        call _throw_script_error(id_from, 'split: must indicate table or options before colon; otherwise drop colon');
      end if;

      -- Get the action statement clause:
      set id_from := id_end_split_table_declaration + 1;
      call _skip_spaces(id_from, id_to);
    else
      -- colon does not exist
      call _consume_split_statement_params(id_from, id_end_split_table_declaration-1, should_execute_statement, split_table_schema, split_table_name, split_options, found_explicit_table, found_any_params);
      if found_any_params then
        -- no statement
        set found_possible_statement := false;
      end if;
    end if;
    
    if not (found_possible_statement or found_explicit_table) then
      call _throw_script_error(id_from, 'split: no statement nor table provided. Provide at least either one');
    end if;
    
    if found_possible_statement then
      if not found_explicit_table then
        call _skip_spaces(id_from, id_end_action_statement - 1);
        call _get_split_query_single_table(id_from, id_end_action_statement - 1, query_type_supported, tables_found, split_table_schema, split_table_name);
        call _expand_single_variable(id_from, id_end_action_statement - 1, split_table_schema, should_execute_statement);
        call _expand_single_variable(id_from, id_end_action_statement - 1, split_table_name, should_execute_statement);
        if should_execute_statement and ((split_table_schema is null) or (split_table_name is null)) then
          -- Can't get single table name. Either multi table or using hints or subquery...
          call _throw_script_error(id_from, 'split() cannot deduce split table name. Please specify explicitly');
        end if;
      end if;
      call _inject_split_where_token(id_from, id_end_action_statement - 1, split_injected_text, should_execute_statement, split_injected_action_statement);
    else
      set split_injected_action_statement := CONCAT('SELECT COUNT(NULL) FROM ', mysql_qualify(split_table_schema), '.', mysql_qualify(split_table_name), ' WHERE ', split_injected_text, ' INTO @_common_schema_dummy');
    end if;
    
    set consumed_to_id := id_end_action_statement;
end;
//

delimiter ;
--
-- Read split() parameters
--

delimiter //

drop procedure if exists _consume_split_statement_params //

create procedure _consume_split_statement_params(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   in   should_execute_statement tinyint unsigned,
   out  split_table_schema tinytext charset utf8,
   out  split_table_name tinytext charset utf8,
   out  split_options varchar(2048) charset utf8,
   out  found_explicit_table tinyint unsigned,
   out  found_any_params tinyint unsigned
)
comment 'Reads split() parameters'
language SQL
deterministic
reads sql data
sql security invoker
main_body: begin
    declare expanded_statement mediumtext charset utf8;
    declare options_value mediumtext charset utf8;
    
    call _skip_spaces(id_from, id_to);

    set split_table_schema := null;
    set split_table_name := null;
    set split_options := null;
    set found_explicit_table := false;

    call _expand_statement_variables(id_from, id_to, expanded_statement, @_common_schema_dummy, should_execute_statement);
    -- select GROUP_CONCAT(token order by id separator '') from _sql_tokens where id between id_from AND id_to into split_options;
    if _is_options_format(expanded_statement) then
      set split_options := expanded_statement;
      set options_value := get_option(split_options, 'table');
      if options_value is not null then
        if get_num_tokens(options_value, '.') = 2 then
          set split_table_schema := unquote(split_token(options_value, '.', 1));
          set split_table_name := unquote(split_token(options_value, '.', 2));
          set found_explicit_table := true;
        else
          call _throw_script_error(id_from, '''table'' option in split(): expected format schema_name.table_name');
        end if;
      end if;
    else
      begin
        -- watch out for table_schema.table_name
        declare peek_match_to int unsigned default NULL; 
        declare table_array_id varchar(16);
        
        call _create_array(table_array_id);
        call _peek_states_list(id_from, id_to, 'alpha|alphanum|quoted identifier|expanded query_script variable,dot,alpha|alphanum|quoted identifier|expanded query_script variable', false, false, true, table_array_id, peek_match_to);
        if peek_match_to > 0 then
          -- we have table_schema.table_name, and no statement
          call _get_array_element(table_array_id, '1', split_table_schema);		
          call _get_array_element(table_array_id, '3', split_table_name);
          call _expand_single_variable(id_from, id_to, split_table_schema, should_execute_statement);
          call _expand_single_variable(id_from, id_to, split_table_name, should_execute_statement);
          set split_table_schema := unquote(split_table_schema);
          set split_table_name := unquote(split_table_name);

          set found_explicit_table := true;
        end if;
        call _drop_array(table_array_id);
      end;
    end if;
    set found_any_params := (split_options is not null) or (found_explicit_table);
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _consume_sql_statement //

create procedure _consume_sql_statement(
   in   id_from      int unsigned,
   in   statement_id_to      int unsigned,
   in   should_execute_statement tinyint unsigned
)
comment 'Consumes & executes SQL statement'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  declare mysql_statement TEXT CHARSET utf8;
  
  -- Construct the original statement, send it for execution.
  call _expand_statement_variables(id_from, statement_id_to, mysql_statement, @_common_schema_dummy, should_execute_statement);
  if should_execute_statement then
    call exec_single(mysql_statement);
    set @query_script_rowcount := @common_schema_rowcount;
    set @query_script_found_rows := @common_schema_found_rows;
  end if;
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _consume_statement //

create procedure _consume_statement(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   in   expect_single tinyint unsigned,
   out  consumed_to_id int unsigned,
   in depth int unsigned,
   in should_execute_statement tinyint unsigned
)
comment 'Reads (possibly nested) statement'
language SQL
deterministic
modifies sql data
sql security invoker
main_body: begin
    declare first_token text;
    declare first_state text;
    declare statement_level int unsigned;
    declare id_end_statement int unsigned; 
    
    declare statement_delimiter_found tinyint unsigned;
    
    declare expression text charset utf8;
    declare expression_statement text charset utf8;
    declare expression_result tinyint unsigned;
    
    declare peek_match tinyint unsigned;
    declare matched_token text charset utf8;
    
    declare loop_iteration_count bigint unsigned;
    
    declare while_statement_id_from int unsigned;
    declare while_statement_id_to int unsigned;
    declare while_otherwise_statement_id_from int unsigned;
    declare while_otherwise_statement_id_to int unsigned;
    
    declare foreach_statement_id_from int unsigned;
    declare foreach_statement_id_to int unsigned;
    declare foreach_otherwise_statement_id_from int unsigned;
    declare foreach_otherwise_statement_id_to int unsigned;
    
    declare split_statement_id_from int unsigned;
    declare split_statement_id_to int unsigned;
    declare split_options varchar(2048) charset utf8;

    declare if_statement_id_from int unsigned;
    declare if_statement_id_to int unsigned;
    declare else_statement_id_from int unsigned;
    declare else_statement_id_to int unsigned;

    declare try_statement_error_found tinyint unsigned;
    declare try_statement_id_from int unsigned;
    declare try_statement_id_to int unsigned;
    declare catch_statement_id_from int unsigned;
    declare catch_statement_id_to int unsigned;

    declare foreach_variables_statement text charset utf8;
    declare foreach_collection text charset utf8;
    declare foreach_variables_array_id int unsigned;
    declare foreach_variables_delaration_id int unsigned;
    
    declare split_table_schema tinytext charset utf8;
    declare split_table_name tinytext charset utf8;
    declare split_injected_action_statement text charset utf8;
    declare split_injected_text text charset utf8;
    
    declare reset_query text charset utf8;

    statement_loop: while id_from <= id_to do
      if @_common_schema_script_break_type IS NOT NULL then
         set consumed_to_id := id_to;
         leave statement_loop;
      end if;

      SELECT level, token, state FROM _sql_tokens WHERE id = id_from INTO statement_level, first_token, first_state;
      -- ~~~ select depth, id_from, id_to, statement_level, first_token;
      case
        when first_state in ('whitespace', 'single line comment', 'multi line comment') then begin
	        -- Ignore whitespace
	        set id_from := id_from + 1;
	        iterate statement_loop;
	      end;
        when first_state = 'left braces' then begin
	        -- Start new block
            SELECT MIN(id) FROM _sql_tokens WHERE id > id_from AND state = 'right braces' AND level = statement_level INTO id_end_statement;
  	        if id_end_statement IS NULL then
	          call _throw_script_error(id_from, 'Unmatched "{" brace');
	        end if;
	        call _consume_statement(id_from+1, id_end_statement-1, FALSE, @_common_schema_dummy, depth+1, should_execute_statement);
	        set consumed_to_id := id_end_statement;
          end;
        when first_state = 'alpha' AND (SELECT COUNT(*) = 1 FROM _script_statements WHERE _script_statements.statement = first_token) then begin
	        -- This is a SQL statement
	        call _validate_statement_end(id_from, id_to, id_end_statement, statement_delimiter_found);
	        call _resolve_and_consume_sql_or_script_statement(id_from, id_to, id_from + 1, id_end_statement - IF(statement_delimiter_found, 1, 0), depth, first_token, should_execute_statement);
  	        set consumed_to_id := id_end_statement;
          end;
        when first_state = 'alpha' AND first_token = 'while' then begin
	        call _consume_expression(id_from + 1, id_to, TRUE, consumed_to_id, expression, expression_statement, should_execute_statement);
	        set id_from := consumed_to_id + 1;
	        -- consume single statement (possible compound by {})
            set @_common_schema_script_loop_nesting_level := @_common_schema_script_loop_nesting_level + 1;
	        call _consume_statement(id_from, id_to, TRUE, consumed_to_id, depth+1, FALSE);
            set @_common_schema_script_loop_nesting_level := @_common_schema_script_loop_nesting_level - 1;
	        set while_statement_id_from := id_from;
	        set while_statement_id_to := consumed_to_id;
	        -- Is there an 'otherwise' clause?
	        set while_otherwise_statement_id_from := NULL;
	        call _consume_if_exists(consumed_to_id + 1, id_to, consumed_to_id, 'otherwise', NULL, peek_match, @_common_schema_dummy);
	        if peek_match then
	          set id_from := consumed_to_id + 1;
              call _consume_statement(id_from, id_to, TRUE, consumed_to_id, depth+1, FALSE);
	          set while_otherwise_statement_id_from := id_from;
              set while_otherwise_statement_id_to := consumed_to_id;
	        end if;
            if should_execute_statement then
              -- Simulate "while" loop:
              set loop_iteration_count := 0;
              interpret_while_loop: while TRUE do
                -- Check for 'break'/'return';
                if @_common_schema_script_break_type IS NOT NULL then
                  if @_common_schema_script_break_type = 'break' then
                    set @_common_schema_script_break_type := NULL;
                  end if;
                  leave interpret_while_loop;
                end if;
                -- Evaluate 'while' expression:
                call _evaluate_expression(expression, expression_statement, expression_result);
                if NOT expression_result then
                  leave interpret_while_loop;
                end if;
                -- Expression holds true. We (re)visit 'while' block
                set loop_iteration_count := loop_iteration_count + 1;
                call _consume_statement(while_statement_id_from, while_statement_id_to, TRUE, @_common_schema_dummy, depth+1, TRUE);
              end while;
              if loop_iteration_count = 0 then
                -- no iterations made.
                -- If there's an "otherwise" statement -- invoke it!
                if while_otherwise_statement_id_from IS NOT NULL then
                  call _consume_statement(while_otherwise_statement_id_from, while_otherwise_statement_id_to, TRUE, @_common_schema_dummy, depth+1, TRUE);
                end if;
              end if;
            end if;
	      end;
        when first_state = 'alpha' AND first_token = 'loop' then begin
	        -- consume single statement (possible compound by {})
	        set id_from := id_from + 1;
            set @_common_schema_script_loop_nesting_level := @_common_schema_script_loop_nesting_level + 1;
	        call _consume_statement(id_from, id_to, TRUE, consumed_to_id, depth+1, FALSE);
            set @_common_schema_script_loop_nesting_level := @_common_schema_script_loop_nesting_level - 1;
	        set while_statement_id_from := id_from;
	        set while_statement_id_to := consumed_to_id;
	        call _consume_if_exists(consumed_to_id + 1, id_to, consumed_to_id, 'while', NULL, peek_match, @_common_schema_dummy);
	        if peek_match then
	          call _consume_expression(consumed_to_id + 1, id_to, TRUE, consumed_to_id, expression, expression_statement, should_execute_statement);
	          set id_from := consumed_to_id + 1;
            else
              call _throw_script_error(id_from, CONCAT('Expcted "while" on loop-while expression'));
	        end if;
	        call _expect_statement_delimiter(consumed_to_id + 1, id_to, consumed_to_id);
            set id_from := consumed_to_id + 1;

            if should_execute_statement then
              interpret_while_loop: while TRUE do
                -- Check for 'break'/'return';
                if @_common_schema_script_break_type IS NOT NULL then
                  if @_common_schema_script_break_type = 'break' then
                    set @_common_schema_script_break_type := NULL;
                  end if;
                  leave interpret_while_loop;
                end if;
                -- Execute statement:
                call _consume_statement(while_statement_id_from, while_statement_id_to, TRUE, @_common_schema_dummy, depth+1, TRUE);
                -- Evaluate 'while' expression:
                call _evaluate_expression(expression, expression_statement, expression_result);
                if NOT expression_result then
                  leave interpret_while_loop;
                end if;
              end while;
            end if;
	      end;
        when first_state = 'alpha' AND first_token = 'foreach' then begin
	        call _consume_foreach_expression(id_from + 1, id_to, consumed_to_id, depth, foreach_collection, foreach_variables_array_id, foreach_variables_delaration_id, should_execute_statement);

	        set id_from := consumed_to_id + 1;
	        -- consume single statement (possible compound by {})
            set @_common_schema_script_loop_nesting_level := @_common_schema_script_loop_nesting_level + 1;
	        call _consume_statement(id_from, id_to, TRUE, consumed_to_id, depth+1, FALSE);
            set @_common_schema_script_loop_nesting_level := @_common_schema_script_loop_nesting_level - 1;
	        set foreach_statement_id_from := id_from;
	        set foreach_statement_id_to := consumed_to_id;
	        update _qs_variables set scope_end_id = foreach_statement_id_to where declaration_id = foreach_variables_delaration_id;
	        -- Is there an 'otherwise' clause?
	        set foreach_otherwise_statement_id_from := NULL;
	        call _consume_if_exists(consumed_to_id + 1, id_to, consumed_to_id, 'otherwise', NULL, peek_match, @_common_schema_dummy);
	        if peek_match then
	          set id_from := consumed_to_id + 1;
              call _consume_statement(id_from, id_to, TRUE, consumed_to_id, depth+1, FALSE);
	          set foreach_otherwise_statement_id_from := id_from;
              set foreach_otherwise_statement_id_to := consumed_to_id;
	        end if;
            if should_execute_statement then
              call _foreach(foreach_collection, NULL, foreach_statement_id_from, foreach_statement_id_to, TRUE, @_common_schema_dummy, foreach_variables_array_id, depth+1, TRUE, loop_iteration_count);
              if loop_iteration_count = 0 then
                -- no iterations made.
                -- If there's an "otherwise" statement -- invoke it!
                if foreach_otherwise_statement_id_from IS NOT NULL then
                  call _consume_statement(foreach_otherwise_statement_id_from, foreach_otherwise_statement_id_to, TRUE, @_common_schema_dummy, depth+1, TRUE);
                end if;
              end if;
            end if;
	      end;
        when first_state = 'alpha' AND first_token = 'split' then begin
	        call _consume_split_statement(id_from + 1, id_to, consumed_to_id, depth, split_table_schema, split_table_name, split_injected_action_statement, split_injected_text, split_options, should_execute_statement);

	        set id_from := consumed_to_id + 1;
	        -- consume single statement (possible compound by {})
            set @_common_schema_script_loop_nesting_level := @_common_schema_script_loop_nesting_level + 1;
	        call _consume_statement(id_from, id_to, TRUE, consumed_to_id, depth+1, FALSE);
            set @_common_schema_script_loop_nesting_level := @_common_schema_script_loop_nesting_level - 1;
	        set split_statement_id_from := id_from;
	        set split_statement_id_to := consumed_to_id;
            if should_execute_statement then
             begin end;
               -- call _split(split_table_schema, split_table_name);
               call _split(split_table_schema, split_table_name, split_options, split_injected_action_statement, split_injected_text, split_statement_id_from, split_statement_id_to, TRUE, @_common_schema_dummy, depth+1, TRUE);
            end if;
	      end;
        when first_state = 'alpha' AND first_token = 'if' then begin
	        call _consume_expression(id_from + 1, id_to, TRUE, consumed_to_id, expression, expression_statement, should_execute_statement);
	        set id_from := consumed_to_id + 1;
	        -- consume single statement (possible compound by {})
	        call _consume_statement(id_from, id_to, TRUE, consumed_to_id, depth+1, FALSE);
	        set if_statement_id_from := id_from;
	        set if_statement_id_to := consumed_to_id;
	        -- Is there an 'else' clause?
	        set else_statement_id_from := NULL;
	        call _consume_if_exists(consumed_to_id + 1, id_to, consumed_to_id, 'else', NULL, peek_match, @_common_schema_dummy);
	        if peek_match then
	          set id_from := consumed_to_id + 1;
              call _consume_statement(id_from, id_to, TRUE, consumed_to_id, depth+1, FALSE);
	          set else_statement_id_from := id_from;
              set else_statement_id_to := consumed_to_id;
	        end if;
            if should_execute_statement then
              -- Simulate "if" condition:
              call _evaluate_expression(expression, expression_statement, expression_result);
              if expression_result then
                -- "if" condition holds!
                call _consume_statement(if_statement_id_from, if_statement_id_to, TRUE, @_common_schema_dummy, depth+1, TRUE);
              else
                -- If there's an "else" statement -- invoke it!
                if else_statement_id_from IS NOT NULL then
                  call _consume_statement(else_statement_id_from, else_statement_id_to, TRUE, @_common_schema_dummy, depth+1, TRUE);
                end if;
              end if;
            end if;
	      end;
        when first_state = 'alpha' AND first_token = 'try' then begin
	        -- consume single statement (possible compound by {})
            set id_from := id_from + 1;
            call _consume_statement(id_from, id_to, TRUE, consumed_to_id, depth+1, FALSE);
            set try_statement_id_from := id_from;
            set try_statement_id_to := consumed_to_id;
            -- There must be an 'catch' clause
            call _consume_if_exists(consumed_to_id + 1, id_to, consumed_to_id, 'catch', NULL, peek_match, @_common_schema_dummy);
	        if peek_match then
              set id_from := consumed_to_id + 1;
              call _consume_statement(id_from, id_to, TRUE, consumed_to_id, depth+1, FALSE);
              set catch_statement_id_from := id_from;
              set catch_statement_id_to := consumed_to_id;
            else
              call _throw_script_error(id_from, CONCAT('Expected "catch" on try-catch block'));
            end if;
            
            if should_execute_statement then
              call _consume_try_statement(try_statement_id_from, try_statement_id_to, TRUE, @_common_schema_dummy, depth+1, TRUE, try_statement_error_found);
              if try_statement_error_found then
                call _consume_statement(catch_statement_id_from, catch_statement_id_to, TRUE, @_common_schema_dummy, depth+1, TRUE);
              end if;
            end if;
	      end;
        when first_state = 'alpha' AND first_token in ('break', 'return') then begin
	        call _expect_statement_delimiter(id_from + 1, id_to, consumed_to_id);
	        if should_execute_statement then
	          set @_common_schema_script_break_type := first_token;
	        end if;
	      end;
        when first_state = 'statement delimiter' then begin
            call _throw_script_error(id_from, CONCAT('Empty statement not allowed. Use {} instead'));
	      end;
        when first_state = 'start' then begin
            if expect_single then
              call _throw_script_error(id_from, CONCAT('Unexpected end of script. Expected statement'));
            end if;
	        set consumed_to_id := id_from;
	      end;
	    else begin 
		    call _throw_script_error(id_from, CONCAT('Unsupported token: "', first_token, '"'));
		  end;
      end case;
      if expect_single then
         leave statement_loop;
      end if;
      set id_from := consumed_to_id + 1;
    end while;
    set id_from := consumed_to_id + 1;

    -- End of scope
    -- Reset local variables: remove mapping to user-defined-variables; reset value snapshots if any.
    SELECT GROUP_CONCAT('SET ', mapped_user_defined_variable_name, ' := NULL ' SEPARATOR ';') FROM _qs_variables WHERE declaration_depth = depth INTO reset_query;
    call exec(reset_query);
    UPDATE _qs_variables SET value_snapshot = NULL WHERE declaration_depth = depth;
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _consume_try_statement //

create procedure _consume_try_statement(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   in   expect_single tinyint unsigned,
   out  consumed_to_id int unsigned,
   in depth int unsigned,
   in should_execute_statement tinyint unsigned,
   out try_statement_error_found int unsigned
)
comment 'Invokes statement in try{} block'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  -- declare continue handler for 1052 set try_statement_error_found = 1051;
  -- declare continue handler for 1146 set try_statement_error_found = 1146;
  declare continue handler for SQLEXCEPTION set try_statement_error_found = true;
  
  set try_statement_error_found := false;
  call _consume_statement(id_from, id_to, expect_single, consumed_to_id, depth, should_execute_statement);
  -- select try_statement_error_found;
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _evaluate_expression //

create procedure _evaluate_expression(
   in  expression text charset utf8,
   in  expression_statement text charset utf8,
   out expression_result tinyint unsigned
)
comment 'Evaluates expression, returns boolean value'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  declare read_row_count tinyint unsigned default FALSE; 
  
  case
    when expression_statement IN ('insert', 'replace', 'update', 'delete') then begin
	    set read_row_count := TRUE;
	  end;    
    else begin
	    set expression := CONCAT('SELECT ((', expression, ') IS TRUE) INTO @_common_schema_script_expression_result'); 
	  end;
  end case;
  call exec_single(expression);
  set @query_script_rowcount := @common_schema_rowcount;
  if read_row_count then
    set expression_result := ((@query_script_rowcount > 0) IS TRUE);
  else
    set expression_result := @_common_schema_script_expression_result;
  end if;
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _get_sql_tokens//

create procedure _get_sql_tokens(
    in p_text text
)
comment 'Reads tokens according to lexical rules for SQL'
language SQL
deterministic
modifies sql data
sql security invoker
begin
    declare v_from, v_old_from int unsigned;
    declare v_token text;
    declare v_level int;
    declare v_state varchar(32);
    declare _sql_tokens_id int unsigned default 0;
    
    drop temporary table if exists _sql_tokens;
    create temporary table _sql_tokens(
        id int unsigned primary key
    ,   start int unsigned  not null
    ,   level int not null
    ,   token text          
    ,   state text           not null
    ) engine=MyISAM;
    
    repeat 
        set v_old_from = v_from;
        call _get_sql_token(p_text, v_from, v_level, v_token, 'script', v_state);
        set _sql_tokens_id := _sql_tokens_id + 1;
        insert into _sql_tokens(id,start,level,token,state) 
        values (_sql_tokens_id, v_from, v_level, v_token, v_state);
    until 
        v_old_from = v_from
    end repeat;
    
    if @common_schema_debug then
      select * 
      from _sql_tokens
      order by id;
    end if;
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _interpret//

create procedure _interpret(
  in query_script text,
  in should_execute_statement tinyint unsigned
)
comment '...'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  declare id_from int unsigned;
  declare id_to int unsigned;
  declare end_level int;
  declare negative_level_id int unsigned;
  declare expanded_variables_ids text charset ascii;
  declare num_expanded_variables_ids int unsigned;
  declare expanded_variable_index int unsigned;
  declare current_expanded_variable_id int unsigned;
  
  set @@max_sp_recursion_depth := 127;
  set @__script_group_concat_max_len := @@group_concat_max_len;
  set @@group_concat_max_len := GREATEST(@@group_concat_max_len, 32 * 1024 * 1024);
  
  call _get_sql_tokens(query_script);
  SELECT MIN(id), MAX(id) FROM _sql_tokens INTO id_from, id_to;
  SELECT MIN(id) FROM _sql_tokens WHERE level < 0 INTO negative_level_id;
  if negative_level_id IS NOT NULL then
    call throw(CONCAT('Negative nesting level detected at id ', negative_level_id));
  end if;
  SELECT level FROM _sql_tokens WHERE id = id_to INTO end_level;
  if end_level != 0 then
    call throw('Invalid nesting level detected at end of script');
  end if;

  drop temporary table if exists _qs_variables;
  create temporary table _qs_variables(
      variable_name VARCHAR(65) CHARSET ascii NOT NULL,
      mapped_user_defined_variable_name  VARCHAR(65) CHARSET ascii NOT NULL,
      declaration_depth INT UNSIGNED NOT NULL,
      declaration_id INT UNSIGNED NOT NULL,
      scope_end_id INT UNSIGNED NOT NULL,
      value_snapshot TEXT DEFAULT NULL,
      PRIMARY KEY(variable_name),
      KEY(declaration_depth),
      KEY(declaration_id),
      KEY(scope_end_id)
  ) engine=MyISAM;
--  create temporary table _qs_variables(
--      _qs_variables_id int unsigned auto_increment,
--      variable_name VARCHAR(65) CHARSET ascii NOT NULL,
--      mapped_user_defined_variable_name  VARCHAR(65) CHARSET ascii NOT NULL,
--      declaration_depth INT UNSIGNED NOT NULL,
--      declaration_id INT UNSIGNED NOT NULL,
--      scope_end_id INT UNSIGNED NOT NULL,
--      value_snapshot TEXT DEFAULT NULL,
--      PRIMARY KEY(_qs_variables_id),
--      KEY(variable_name),
--      KEY(declaration_depth),
--      KEY(declaration_id)
--  ) engine=MyISAM;
  
  -- Identify ${my_var} expanded variables. These are initially not identified as a state.
  -- We hack the _sql_tokens table to make these in their own state, combining multiple rows into one,
  -- leaving previously occupied rows as empty strings.
  select group_concat(id order by id) from _sql_tokens where state='expanded query_script variable' and token=':$' into expanded_variables_ids;
  if expanded_variables_ids then
    set num_expanded_variables_ids := get_num_tokens(expanded_variables_ids, ',');
    set expanded_variable_index := 1;
    while expanded_variable_index <= num_expanded_variables_ids do
      set current_expanded_variable_id := split_token(expanded_variables_ids, ',', expanded_variable_index);
      select 
          GROUP_CONCAT(token ORDER BY id SEPARATOR '') AS expanded_variable_tokens, 
          (
            GROUP_CONCAT(state ORDER BY id) = 'left braces,alpha,right braces' OR
            GROUP_CONCAT(state ORDER BY id) = 'left braces,alphanum,right braces' 
          ) AS expanded_variable_match
        from _sql_tokens where id between current_expanded_variable_id+1 and current_expanded_variable_id+3
        into @_expanded_variable_tokens, @_expanded_variable_match;

      if @_expanded_variable_match then
        -- set @_expanded_variable_tokens := replace_all(@_expanded_variable_tokens, '${}', '');
        -- set @_expanded_variable_tokens := CONCAT(':$',@_expanded_variable_tokens);
        update _sql_tokens set token = CONCAT(':$', @_expanded_variable_tokens) where id = current_expanded_variable_id;
        update _sql_tokens set token = '', state = 'whitespace', level = level - 1 where id between current_expanded_variable_id+1 and current_expanded_variable_id+3;
      end if;
      
      set expanded_variable_index := expanded_variable_index + 1;
    end while;    
  end if;
  
  set @_common_schema_script_break_type := NULL;
  set @_common_schema_script_loop_nesting_level := 0;
  set @_common_schema_script_throttle_chunk_start := NULL;
  set @_common_schema_script_start_timestamp := NOW();
  set @_common_schema_script_report_used := false;
  set @_common_schema_script_report_delimiter := '';

  -- We happen to know tokens in _sql_tokens begin at "1". So "0" is a safe 
  -- place not to step on anyone's toes.
  call _declare_local_variable(0, 0, id_to, 0, '$rowcount', '@query_script_rowcount', FALSE);
  call _declare_local_variable(0, 0, id_to, 0, '$found_rows', '@query_script_found_rows', FALSE);
  
  -- First, do syntax validation: go through the code, but execute nothing:
  call _consume_statement(id_from, id_to, FALSE, id_to, 0, FALSE);
  -- Now, if need be, execute it:
  if should_execute_statement then
    -- delete from _qs_variables;
    call _consume_statement(id_from, id_to, FALSE, id_to, 0, TRUE);
  end if;
  
  if @_common_schema_script_report_used then
    call _script_report_finalize();
  end if;
  
  set @@group_concat_max_len := @__script_group_concat_max_len;  
end;
//

delimiter ;
--
-- A statement has been identified as a SQL or Script statement.
-- Resolve which, and consume (possibly execute) it.
--

delimiter //

drop procedure if exists _resolve_and_consume_sql_or_script_statement //

create procedure _resolve_and_consume_sql_or_script_statement(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   in   statement_id_from      int unsigned,
   in   statement_id_to      int unsigned,
   in   depth int unsigned,
   in   statement_token text charset utf8,
   in   should_execute_statement tinyint unsigned
)
comment 'Reads script statement'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  declare resolve_statement_type text charset utf8;
  declare token_has_matched tinyint unsigned default FALSE;
  
  select statement_type from _script_statements where statement = statement_token into resolve_statement_type;
  
  case resolve_statement_type
    when 'sql' then begin
	    call _consume_sql_statement(id_from, statement_id_to, should_execute_statement);
	  end;
    when 'script' then begin
	    call _consume_script_statement(id_from, id_to, statement_id_from, statement_id_to, depth, statement_token, should_execute_statement);
	  end;
    when 'script,sql' then begin
        if statement_token = 'start' then
          -- can be script ("start transaction") or sql ("start slave" or anything else)
          set @_common_schema_dummy := 0;
          call _consume_if_exists(statement_id_from, statement_id_to, @_common_schema_dummy, 'transaction', NULL, token_has_matched, @_common_schema_dummy);
          if token_has_matched then
            call _consume_script_statement(id_from, id_to, statement_id_from, statement_id_to, depth, statement_token, should_execute_statement);
          else
            call _consume_sql_statement(id_from, statement_id_to, should_execute_statement);
          end if;
        end if;
	  end;
  end case;
end;
//

delimiter ;
--
-- Run script from _named_scripts table
--

delimiter //

drop procedure if exists _run_named_script //

create procedure _run_named_script(
  named_script_name varchar(64) CHARACTER SET ascii
)
comment 'Run script from _named_scripts table'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  declare query_script text charset utf8;
  
  select script_text from _named_scripts where script_name = named_script_name into query_script;
  if query_script is null then
    call throw(CONCAT('Unknown script: ', named_script_name));
  end if;
  call run(query_script);
end;

//

delimiter ;
-- 
-- Stores text message to be verbosed at end of script.
--

DELIMITER $$

DROP procedure IF EXISTS _script_report $$
CREATE procedure _script_report(report_params TEXT CHARSET utf8)
DETERMINISTIC
MODIFIES SQL DATA
SQL SECURITY INVOKER
COMMENT ''

begin
  declare report_query text charset utf8;
  
  declare is_header tinyint unsigned default 0;
  declare is_paragraph tinyint unsigned default 0;
  declare is_bullet tinyint unsigned default 0;
  declare is_code tinyint unsigned default 0;
  declare is_horizontal_ruler tinyint unsigned default 0;
  
  if not @_common_schema_script_report_used then
    drop temporary table if exists _script_report_data;
    create temporary table _script_report_data (
      id int unsigned AUTO_INCREMENT,
      info text charset utf8,
      PRIMARY KEY (id)
    ) engine=MyISAM;
    set @_common_schema_script_report_used := true;
  end if;
  
  set report_params := trim_wspace(report_params);
  set @_common_schema_script_report_prefix_len := 0;
  if (@_common_schema_script_report_prefix_len := starts_with(report_params, 'h1 ')) then
    set is_header := 1;
  elseif (@_common_schema_script_report_prefix_len := starts_with(report_params, 'p ')) then
    set is_paragraph := 1;
  elseif (@_common_schema_script_report_prefix_len := starts_with(report_params, 'li ')) then
    set is_bullet := 1;
  elseif (@_common_schema_script_report_prefix_len := starts_with(report_params, 'code ')) then
    set is_code := 1;
  elseif (@_common_schema_script_report_prefix_len := starts_with(report_params, 'hr ')) then
    set is_horizontal_ruler := 1;
  end if;
  set report_params := substring(report_params, @_common_schema_script_report_prefix_len + 1);
  
  set report_query := CONCAT('set @_query_script_report_line := CONCAT_WS(@_common_schema_script_report_delimiter, ', report_params, ')');
  call exec_single(report_query);
  
  set @_query_script_report_line := trim_wspace(@_query_script_report_line);
--  insert into 
--    _script_report_data (info) values (@_query_script_report_line);
  if is_header then
    set @_query_script_report_line := CONCAT('\n', @_query_script_report_line,
      '\n', REPEAT('=', CHAR_LENGTH(@_query_script_report_line)));
  end if;
  if is_bullet then
    set @_query_script_report_line := CONCAT('- ', @_query_script_report_line);
  end if;
  if is_code then
    set @_query_script_report_line := CONCAT('> ', @_query_script_report_line);
  end if;
  if is_paragraph then
    set @_query_script_report_line := CONCAT('\n', @_query_script_report_line);
  end if;
  if is_horizontal_ruler then
    set @_query_script_report_line := CONCAT('---\n', @_query_script_report_line);
  end if;
  
  insert into 
    _script_report_data (info) 
  SELECT 
    split_token(@_query_script_report_line, '\n', n)
  FROM
    numbers
  WHERE 
    numbers.n BETWEEN 1 AND get_num_tokens(@_query_script_report_line, '\n')
  ORDER BY 
    n ASC;

  set @_query_script_report_line := NULL;
end $$

DELIMITER ;
-- 
-- Verbose all reported messages
--
DELIMITER $$

DROP procedure IF EXISTS _script_report_finalize $$
CREATE procedure _script_report_finalize()
DETERMINISTIC
MODIFIES SQL DATA
SQL SECURITY INVOKER
COMMENT ''

begin
  call _script_report(
    CONCAT('hr ', QUOTE('Report generated on '), QUOTE(NOW()))
  );

  select info as `report` from _script_report_data order by id;
end $$

DELIMITER ;
-- 
-- Do not invoke twice within the same script 
--
DELIMITER $$

DROP procedure IF EXISTS _throttle_script $$
CREATE procedure _throttle_script(throttle_ratio DOUBLE)
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

begin
  set @_common_schema_script_throttle_sysdate := SYSDATE();
  -- _interpret() resets @_common_schema_script_throttle_chunk_start to NULL per script.
  set @_common_schema_script_throttle_chunk_start := IFNULL(@_common_schema_script_throttle_chunk_start, @_common_schema_script_start_timestamp);
  set @_common_schema_script_throttle_timediff := TIMESTAMPDIFF(SECOND, @_common_schema_script_throttle_chunk_start, @_common_schema_script_throttle_sysdate);
  set @_common_schema_script_throttle_sleep_time := @_common_schema_script_throttle_timediff * throttle_ratio;
  -- We do not necessarily throttle. Only if there has been at least a one second lapse.
  if @_common_schema_script_throttle_sleep_time > 0 then
    DO SLEEP(@_common_schema_script_throttle_sleep_time);
    set @_common_schema_script_throttle_chunk_start := SYSDATE();
  end if;
end $$

DELIMITER ;
--
--
--

delimiter //

drop procedure if exists _throw_script_error //

create procedure _throw_script_error(
   in id_from      int unsigned,
   in message varchar(1024) charset utf8
)
comment 'Raises error and quites from script'
language SQL
deterministic
reads sql data
sql security invoker

main_body: begin
    declare full_message varchar(2048);
    declare error_pos int unsigned;

    SELECT LEFT(GROUP_CONCAT(token ORDER BY id SEPARATOR ''), 80), SUBSTRING_INDEX(GROUP_CONCAT(start ORDER BY id), ',', 1) FROM _sql_tokens WHERE id >= id_from INTO full_message, error_pos;
    
    set full_message := CONCAT('QueryScript error: [', message, '] at ', error_pos, ': "', full_message, '"');
    call throw(full_message);
end;
//

delimiter ;
--
-- Run a given QueryScript code
--

delimiter //

drop procedure if exists run //

create procedure run(
  in query_script text
)
comment 'Run given QueryScript text'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  if (LEFT(query_script, 1) in ('/', '\\')) and (LEFT(query_script, 2) != '/*') then
    begin
	  declare query_script_file_name text;  
      -- Assume filename
      set query_script_file_name := query_script;
      set query_script := LOAD_FILE(query_script_file_name);
      if query_script is null then
        call throw(CONCAT('Cannot load script file: ', query_script_file_name));
      end if;
    end;
  end if;
  call _interpret(query_script, TRUE);
end;

//

delimiter ;
--
-- Load and run QueryScript code from file
--

delimiter //

drop procedure if exists run_file //

create procedure run_file(
  in query_script_file_name text
)
comment 'Run given QueryScript file'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  call run(LOAD_FILE(query_script_file_name));
end;

//

delimiter ;
-- 
-- Returns the number of seconds elapsed since QueryScript execution began.
-- Calling this function only makes since from within a script.
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS script_runtime $$
CREATE FUNCTION script_runtime() RETURNS DOUBLE 
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
COMMENT 'Return current script runtime seconds'

BEGIN
  return TIMESTAMPDIFF(MICROSECOND, @_common_schema_script_start_timestamp, SYSDATE()) / 1000000.0;
END $$

DELIMITER ;
--
--
--

delimiter //

drop procedure if exists _consume_if_exists //

create procedure _consume_if_exists(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   inout  consumed_to_id int unsigned,
   in   expected_token text charset utf8,
   in   expected_states text charset utf8,
   out  token_has_matched tinyint unsigned,
   out  matched_token text charset utf8
) 
comment 'Consumes token or state if indeed exists'
language SQL
deterministic
reads sql data
sql security invoker

main_body: begin
  call _skip_spaces(id_from, id_to);
  set token_has_matched := FALSE;
  SELECT token, ((token = expected_token) OR FIND_IN_SET(state, REPLACE(expected_states, '|', ','))) IS TRUE FROM _sql_tokens WHERE id = id_from INTO matched_token, token_has_matched;
  if token_has_matched then
    set consumed_to_id = id_from;
  end if;
end;
//

delimiter ;
--
-- Given a state (or optional states), expect a dynamic length comma 
-- delimited list where each element is given state(s).
--

delimiter //

drop procedure if exists _expect_dynamic_states_list //

create procedure _expect_dynamic_states_list(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   in   expected_states text charset utf8,
   out  tokens_array_id VARCHAR(16) charset ascii
) 
comment 'Expects a state or raises error'
language SQL
deterministic
reads sql data
sql security invoker

main_body: begin
  call _match_states(id_from, id_to, expected_states, false, false, 0, 'comma', true, true, @_common_schema_dummy, tokens_array_id, @_common_schema_dummy, @_common_schema_dummy);
end;
//

delimiter ;
--
-- Expects an exact list of states.
-- spaces are only allowed before and after list of states, but not between states.
--

delimiter //

drop procedure if exists _expect_exact_states_list //

create procedure _expect_exact_states_list(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   in   expected_states_list text charset utf8,
   out  tokens_array_id VARCHAR(16) charset ascii
) 
comment 'Expects states or raises error'
language SQL
deterministic
reads sql data
sql security invoker

main_body: begin
  call _match_states(id_from, id_to, expected_states_list, false, false, 1, null, true, true, @_common_schema_dummy, tokens_array_id, @_common_schema_dummy, @_common_schema_dummy);
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _expect_nothing //

create procedure _expect_nothing(
   in   id_from      int unsigned,
   in   id_to      int unsigned
) 
comment 'Expect nothing or whitespace only'
language SQL
deterministic
reads sql data
sql security invoker

main_body: begin
  declare consumed_to_id int unsigned;
  declare token_has_matched tinyint unsigned;

  call _skip_spaces(id_from, id_to);
  if id_from > id_to then
    -- Nothing more here, all is well
    leave main_body;
  end if;
  -- Still stuff here: we only allow the statement delimiter:
  call _consume_if_exists(id_from, id_to, consumed_to_id, NULL, 'statement delimiter|start', token_has_matched, @_common_schema_dummy);
  if not token_has_matched then
    call _throw_script_error(id_from, 'Nothing more expected');
  end if;
end;
//

delimiter ;
--
-- Expect a given state, possible padded with whitespace, or raise an error.
--

delimiter //

drop procedure if exists _expect_state //

create procedure _expect_state(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   in   expected_states text charset utf8,
   in   allow_trailing_states tinyint unsigned,
   out  consumed_to_id int unsigned,
   out  matched_token text charset utf8
) 
comment 'Expects a state or raises error'
language SQL
deterministic
reads sql data
sql security invoker

main_body: begin
  declare state_has_matched tinyint unsigned default FALSE;

  call _consume_if_exists(id_from, id_to, consumed_to_id, NULL, expected_states, state_has_matched, matched_token);
  if not state_has_matched then
    call _throw_script_error(id_from, CONCAT('Expected ', REPLACE(expected_states, '|', '/')));
  end if;
  if not allow_trailing_states then
    set id_from := consumed_to_id + 1;
    call _expect_nothing(id_from, id_to);
  end if;
end;
//

delimiter ;
--
-- A private case for _Expect_state, which is all too common
--

delimiter //

drop procedure if exists _expect_statement_delimiter //

create procedure _expect_statement_delimiter(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   out  consumed_to_id int unsigned
) 
comment 'Expects ";" or raises error'
language SQL
deterministic
reads sql data
sql security invoker

main_body: begin
  call _expect_state(id_from, id_to, 'statement delimiter', true, consumed_to_id, @_common_schema_dummy);
end;
//

delimiter ;
--
-- Expect a given token, possible padded with whitespace, or raise an error.
--

delimiter //

drop procedure if exists _expect_token //

create procedure _expect_token(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   in   expected_tokens text charset utf8,
   in   allow_trailing tinyint unsigned,
   out  consumed_to_id int unsigned,
   out  matched_token text charset utf8
) 
comment 'Expects a token or raises error'
language SQL
deterministic
reads sql data
sql security invoker

main_body: begin
  declare token_has_matched tinyint unsigned default FALSE;

  call _consume_if_exists(id_from, id_to, consumed_to_id, expected_tokens, NULL, token_has_matched, matched_token);
  if not token_has_matched then
    call _throw_script_error(id_from, CONCAT('Expected "', REPLACE(expected_tokens, '|', '/'), '"'));
  end if;
  if not allow_trailing then
    set id_from := consumed_to_id + 1;
    call _expect_nothing(id_from, id_to);
  end if;
end;
//

delimiter ;
--
-- Given a state (or optional states), expect a dynamic length comma 
-- delimited list where each element is given state(s).
--

delimiter //

drop procedure if exists _match_states //

create procedure _match_states(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   in   expected_states_list text charset utf8,
   in	allow_spaces_between_states tinyint unsigned,
   in	allow_trailing_states tinyint unsigned,
   in   repeat_count int unsigned,
   in   repeat_delimiter_state text charset utf8,
   in	return_tokens_array_id tinyint unsigned,
   in   throw_on_mismatch tinyint unsigned,
   out  states_have_matched tinyint unsigned,
   out  tokens_array_id VARCHAR(16) charset ascii,
   out  single_matched_token text charset utf8,
   out	consumed_to_id int unsigned
) 
comment 'Expects a state or raises error'
language SQL
deterministic
reads sql data
sql security invoker

main_body: begin
  declare state_has_matched tinyint unsigned default FALSE;
  declare num_states int unsigned default 0;
  declare states_index int unsigned;
  declare repeat_index int unsigned;
  declare expected_states text charset utf8;
  
  if return_tokens_array_id then
    call _create_array(tokens_array_id);
  end if;

  set num_states := get_num_tokens(expected_states_list, ',');
  if num_states = 0 then
    call _throw_script_error(id_from, 'Internal error: num_states = 0 in _match_states');
  end if;
  
  -- repeat_count = 0 means undefined length, dynamic.
  set states_have_matched := true;
  set repeat_index := 1;
  repeat_loop: while (repeat_index <= repeat_count) or (repeat_count = 0) do
    call _skip_spaces(id_from, id_to);
    set states_index := 1;

    while states_index <= num_states do
      -- Read a single state, one of current expected states.
      if allow_spaces_between_states then
        call _skip_spaces(id_from, id_to);
      else
        -- empty spaces are result of common_schema/QueryScript internal hacks
        -- when tokenizing :${t} variables.
        call _skip_empty_spaces(id_from, id_to);
      end if;
      set expected_states := split_token(expected_states_list, ',', states_index);

      select token, FIND_IN_SET(state, REPLACE(expected_states, '|', ',')) is true from _sql_tokens where id = id_from into single_matched_token, state_has_matched;
      if state_has_matched then
        set consumed_to_id := id_from;
        if return_tokens_array_id then
          call _push_array_element(tokens_array_id, single_matched_token);
        end if;
      else
        set states_have_matched := false;
        leave repeat_loop;
      end if;
      set id_from := id_from + 1;
      
      set states_index := states_index + 1;
    end while;
    -- End reading single-occurence of expected states.
    -- We now expect delimiters, if appliccable (NULL delimiter means no delimiter expected)
    if repeat_delimiter_state != 'whitespace' then
      -- If expected delimiter is whitespace, well, we want to consume it,
      -- not skip it... 
      call _skip_spaces(id_from, id_to);
    end if;
    if repeat_delimiter_state is not null then
      select token, (state = repeat_delimiter_state) from _sql_tokens where id = id_from into @_common_schema_dummy, state_has_matched;
      if not state_has_matched then
        -- Could not find dilimiter.
        -- This is fine for last repeat-step, or when there is
        -- a dynamic repeat_count (== 0); and it just means we're
        -- through with repeats. Otherwise this means no match.
        if (repeat_index < repeat_count) then
          set states_have_matched := false;
        end if;
        leave repeat_loop;
      end if;
      set id_from := id_from + 1;
    end if;
    -- Phew, got here: this means a delimiter is matched.
    set repeat_index := repeat_index + 1; 
  end while;

  if states_have_matched then
    -- wrap up the match
    if allow_trailing_states then
      -- don't care about the rest
      leave main_body;
    end if;
 
    -- Do not allow trailing states: expect nothing more but spaces or statement delimiter
    call _skip_spaces(id_from, id_to);
    call _skip_end_of_statement(id_from, id_to);
    if id_from <= id_to then
      set states_have_matched := false;
    end if;
  end if;
  
  if not states_have_matched then
    -- This entire routine fails: there is no match
    if throw_on_mismatch then
      call _throw_script_error(id_from, CONCAT('Expected ', REPLACE(expected_states, '|', '/')));
    else
      leave main_body;
    end if;
  end if;

end;
//

delimiter ;
--
-- Check if given states list apply.
-- Returned value: tokens_matched_to, the id of last matched token, or 0 on mismatch
--

delimiter //

drop procedure if exists _peek_states_list //

create procedure _peek_states_list(
   in   id_from					int unsigned,
   in   id_to					int unsigned,
   in   expected_states_list	text charset utf8,
   in	allow_spaces			tinyint unsigned,
   in	allow_trailing_states	tinyint unsigned,
   in	return_tokens_array_id	tinyint unsigned,
   out  tokens_array_id			varchar(16) charset ascii,
   out	tokens_matched_to		int unsigned
) 
comment 'Check if given states list apply'
language SQL
deterministic
reads sql data
sql security invoker

main_body: begin
  declare states_have_matched tinyint unsigned default false;

  call _match_states(id_from, id_to, expected_states_list, allow_spaces, allow_trailing_states, 1, null, return_tokens_array_id, false, states_have_matched, tokens_array_id, @_common_schema_dummy, tokens_matched_to);
  if not states_have_matched then
    set tokens_matched_to := 0;
  end if;
end;
//

delimiter ;
--
-- Skips empty spaces (the '' tokens)
-- Required be case of hack converting the :${t} expanded variable format
-- from multiple tokens into a singe token, emptying the rest of the tokens.
--

delimiter //

drop procedure if exists _skip_empty_spaces //

create procedure _skip_empty_spaces(
   inout   id_from      int unsigned,
   in   id_to      int unsigned
)
comment 'Skips empty whitespace tokens'
language SQL
deterministic
reads sql data
sql security invoker
main_body: begin
    select min(id) from _sql_tokens 
      where id >= id_from and id <= id_to 
      and (state, CHAR_LENGTH(token)) != ('whitespace', 0) 
    into id_from;
    if id_from is null then
      set id_from := id_to + 1;
    end if;
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _skip_end_of_statement //

create procedure _skip_end_of_statement(
   inout   id_from      int unsigned,
   in   id_to      int unsigned
)
comment 'Skips enf of statement state'
language SQL
deterministic
reads sql data
sql security invoker
main_body: begin
	call _skip_states(id_from, id_to, 'statement delimiter,start', null);
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _skip_spaces //

create procedure _skip_spaces(
   inout   id_from      int unsigned,
   in   id_to      int unsigned
)
comment 'Skips whitespace tokens'
language SQL
deterministic
reads sql data
sql security invoker
main_body: begin
    call _skip_tokens_and_spaces(id_from, id_to, null);
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _skip_states //

create procedure _skip_states(
   inout   id_from      int unsigned,
   in   id_to      int unsigned,
   in	states_list text charset utf8,
   in	tokens_list text charset utf8
)
comment 'Skips given states'
language SQL
deterministic
reads sql data
sql security invoker
main_body: begin
	set states_list := IFNULL(states_list, '');
	set tokens_list := LOWER(IFNULL(tokens_list, ''));
    select min(id) from _sql_tokens 
      where id >= id_from and id <= id_to 
      and FIND_IN_SET(state, states_list) = 0 
      and FIND_IN_SET(LOWER(token), tokens_list) = 0 
    into id_from;
    if id_from is null then
      set id_from := id_to + 1;
    end if;
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _skip_tokens_and_spaces //

create procedure _skip_tokens_and_spaces(
   inout   id_from      int unsigned,
   in   id_to      int unsigned,
   in	tokens_list text charset utf8
)
comment 'Skips whitespace and given tokens'
language SQL
deterministic
reads sql data
sql security invoker
main_body: begin
    call _skip_states(id_from, id_to, 'whitespace,single line comment,multi line comment,start', tokens_list);
end;
//

delimiter ;
--
-- Expects and validates that statement ends with delimiter or end of block, returning 
-- position of end of statement
--

delimiter //

drop procedure if exists _validate_statement_end //

create procedure _validate_statement_end(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   out  id_end_statement int unsigned,
   out	statement_delimiter_found tinyint unsigned
) 
comment 'Validates delimiter or end of block'
language SQL
deterministic
reads sql data
sql security invoker

main_body: begin
  declare state_end_statement text charset utf8 default NULL;
  
  set id_end_statement := NULL;
  -- id_to limits scope of this statement until end of block or end of script.
  -- it is possible that a new block starts within these bounds, or multiple statements appear, or any combination of the above.
  SELECT id, state FROM _sql_tokens WHERE id > id_from AND id <= id_to AND state IN ('statement delimiter', 'left braces') ORDER BY id ASC LIMIT 1 INTO id_end_statement, state_end_statement;
  if state_end_statement = 'left braces' then
    call _throw_script_error(id_from, 'Missing '';'' statement delimiter');
  end if; 
  if id_end_statement IS NULL then
    -- Last query in script or block is allowed not to be terminated by ';'
    set id_end_statement := id_to;
  end if;
  set statement_delimiter_found := (state_end_statement = 'statement delimiter');
end;
//

delimiter ;
--
-- Assign input values into local variables
--

delimiter //

drop procedure if exists _assign_input_local_variables //

create procedure _assign_input_local_variables(
   variables_array_id int unsigned
)
comment 'Declares local variables'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  declare num_variables int unsigned;
  declare variable_index int unsigned default 0;
  declare local_variable varchar(65) charset ascii;
  declare user_defined_variable_name varchar(65) charset ascii;
  declare reset_query text charset ascii;
  
  call _get_array_size(variables_array_id, num_variables);
  set variable_index := 1;
  while variable_index <= num_variables do
    call _get_array_element(variables_array_id, variable_index, local_variable);
    SELECT mapped_user_defined_variable_name FROM _qs_variables WHERE variable_name = local_variable INTO user_defined_variable_name;
    
    set reset_query := CONCAT('SET ', user_defined_variable_name, ' := @_query_script_input_col', variable_index);
    call exec_single(reset_query);
    
    set variable_index := variable_index + 1;
  end while;
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _declare_and_assign_local_variable //

create procedure _declare_and_assign_local_variable(
   in   id_from      int unsigned,
   in   id_to        int unsigned,
   in   statement_id_from      int unsigned,
   in   assign_id    int unsigned,
   in   statement_id_to      int unsigned,
   in   depth int unsigned,
   in should_execute_statement tinyint unsigned
)
comment 'Declares local variables'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  declare local_variable varchar(65) charset ascii;
  declare user_defined_variable_name varchar(65) charset ascii;
  declare set_expression text charset utf8;
  declare set_statement text charset utf8;
  declare declaration_is_new tinyint unsigned default 0;
    
  call _expect_state(statement_id_from, id_to, 'query_script variable', true, @_common_schema_dummy, local_variable);

  SELECT (COUNT(*) = 0) FROM _qs_variables WHERE declaration_id = id_from INTO declaration_is_new;
  if declaration_is_new then
    set user_defined_variable_name := CONCAT('@__qs_local_var_', session_unique_id());
    call _declare_local_variable(id_from, statement_id_to, id_to, depth, local_variable, user_defined_variable_name, TRUE);
  end if;
  
  if should_execute_statement then
    call _expand_statement_variables(assign_id+1, statement_id_to, set_expression, @_common_schema_dummy, should_execute_statement);
  
    -- select GROUP_CONCAT(token order by id separator '') from _sql_tokens where id between assign_id+1 AND statement_id_to-1 into set_expression;
    select CONCAT('SET ', mapped_user_defined_variable_name, ' := ', set_expression) from _qs_variables where variable_name = local_variable and declaration_depth = depth into set_statement;
    call exec(set_statement);
    -- SELECT GROUP_CONCAT('SET ', mapped_user_defined_variable_name, ' := NULL ' SEPARATOR ';') FROM _qs_variables WHERE declaration_depth = depth INTO reset_query;
    
  end if;
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _declare_local_variable //

create procedure _declare_local_variable(
   in   id_variable_declaration      int unsigned,
   in   id_from    int unsigned,
   in   id_to      int unsigned,
   in   depth int unsigned,
   in	local_variable varchar(65) charset ascii,
   in	user_defined_variable_name varchar(65) charset ascii,
   in	throw_when_exists tinyint unsigned
)
comment 'Declare a local variable'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  -- select *, 'existing',id_variable_declaration from _qs_variables WHERE variable_name = local_variable;
  delete from _qs_variables WHERE variable_name = local_variable and ((scope_end_id < id_variable_declaration) or (declaration_id >= id_variable_declaration));

  -- declare overlapping_variable_exists tinyint unsigned;	
  -- select (count(*) > 0) from _qs_variables where variable_name = local_variable and id_variable_declaration between declaration_id and scope_end_id into overlapping_variable_exists;
  -- if overlapping_variable_exists and throw_when_exists then
  --   call _throw_script_error(id_from, CONCAT('Duplicate local variable: ', local_variable));
  -- end if;
   
  INSERT IGNORE INTO _qs_variables (variable_name, mapped_user_defined_variable_name, declaration_depth, declaration_id, scope_end_id) VALUES (local_variable, user_defined_variable_name, depth, id_variable_declaration, id_to);
  if ROW_COUNT() = 0 and throw_when_exists then
    call _throw_script_error(id_variable_declaration, CONCAT('Duplicate local variable: ', local_variable));
  end if;
  -- since the user defined variables are unique to this session, and have unlikely names they are expected to be NULL.
  -- Thus, we do not bother resetting them.

  -- Since this is first declaration point, we modify the _sql_tokens table by replacing variables with mapped user defined variables:
  -- UPDATE _sql_tokens SET token = user_defined_variable_name, state = 'user-defined variable' WHERE id > id_from AND id <= id_to AND token = local_variable AND state = 'query_script variable';
  -- Bwahaha!
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _declare_local_variables //

create procedure _declare_local_variables(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   in   statement_id_to      int unsigned,
   in   depth int unsigned,
   variables_array_id int unsigned
)
comment 'Declares local variables'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  declare num_variables int unsigned;
  declare variable_index int unsigned default 0;
  declare local_variable varchar(65) charset ascii;
  declare user_defined_variable_name varchar(65) charset ascii;
  declare declaration_is_new tinyint unsigned default 0;
  
  SELECT (COUNT(*) = 0) FROM _qs_variables WHERE declaration_id = id_from INTO declaration_is_new;
  if not declaration_is_new then
    -- Apparently there is a loop, since this id has already been visited and the variables in this id have already been declared.
    -- There is no need to do anything. The previous end-of-the-loop caused the mapped user defined variables to be reset to NULL. 
    leave main_body;
  end if;
  
  -- Start declaration
  call _get_array_size(variables_array_id, num_variables);
  set variable_index := 1;
  while variable_index <= num_variables do
    call _get_array_element(variables_array_id, variable_index, local_variable);
    set user_defined_variable_name := CONCAT('@__qs_local_var_', session_unique_id());
    
    call _declare_local_variable(id_from, statement_id_to, id_to, depth, local_variable, user_defined_variable_name, TRUE);
    
    set variable_index := variable_index + 1;
  end while;
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _expand_single_variable //

create procedure _expand_single_variable(
   in   id_from            int unsigned,
   in   id_to              int unsigned,
   inout   variable_token     text charset utf8,
   in   should_execute_statement tinyint unsigned
)
comment 'Returns an expanded value'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  declare expanded_variable_name TEXT CHARSET utf8;
  
  set expanded_variable_name := _extract_expanded_query_script_variable_name(variable_token);
  if expanded_variable_name is null then
    -- Token is not expanded variable... return as it
    leave main_body;
  end if;
  
  -- Token is expanded variable. Try to match it against current from->to scope.
  if not should_execute_statement then
    leave main_body;
  end if;
  
  call _take_local_variables_snapshot(expanded_variable_name);
 
  SELECT 
    MIN(_qs_variables.value_snapshot)
  FROM 
    _sql_tokens 
    LEFT JOIN _qs_variables ON (
      /* Try to match an expanded  query script variable */
      (state = 'expanded query_script variable' AND _extract_expanded_query_script_variable_name(token) = _qs_variables.variable_name AND _qs_variables.variable_name  = expanded_variable_name) /* expanded */ 
      and (id_from between _qs_variables.declaration_id and _qs_variables.scope_end_id)
    )
  where 
    (id between id_from and id_to) 
  INTO 
    variable_token;
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _expand_statement_variables //

create procedure _expand_statement_variables(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   out  expanded_statement text charset utf8,
   out  expanded_variables_found tinyint unsigned,
   in should_execute_statement tinyint unsigned
)
comment 'Returns an expanded script statement'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  declare expanded_variables TEXT CHARSET utf8;
  
  SELECT GROUP_CONCAT(DISTINCT _extract_expanded_query_script_variable_name(token)) from _sql_tokens where (id between id_from and id_to) and (state = 'expanded query_script variable') INTO expanded_variables;
  set expanded_variables_found := (expanded_variables IS NOT NULL); 
  if expanded_variables_found and should_execute_statement then
    call _take_local_variables_snapshot(expanded_variables);
  end if;
  SELECT 
    GROUP_CONCAT(
      case
        when _qs_variables.mapped_user_defined_variable_name IS NOT NULL then
          case
            when state = 'expanded query_script variable' then _qs_variables.value_snapshot /* expanded */ 
            else _qs_variables.mapped_user_defined_variable_name /* non-expanded */
          end
        else token /* not a query script variable at all */
      end 
      ORDER BY id SEPARATOR ''
    ) 
  FROM 
    _sql_tokens 
    LEFT JOIN _qs_variables ON (
      /* Try to match a query script variable, or an expanded  query script variable */
      (
        (state = 'expanded query_script variable' AND _extract_expanded_query_script_variable_name(token) = _qs_variables.variable_name) /* expanded */ 
        or (state = 'query_script variable' AND token = _qs_variables.variable_name) /* non-expanded */
      )
      and (id_from between _qs_variables.declaration_id and _qs_variables.scope_end_id)
    )
  where 
    (id between id_from and id_to) 
  INTO 
    expanded_statement;
  set expanded_statement := trim_wspace(expanded_statement);
end;
//

delimiter ;
--
--
--

DELIMITER $$

DROP FUNCTION IF EXISTS _extract_expanded_query_script_variable_name $$
CREATE FUNCTION _extract_expanded_query_script_variable_name(
	expanded_query_script_variable TEXT CHARSET ascii) RETURNS TEXT CHARSET ascii 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Get name of qs variable from expanded format'

begin
  -- :${my_var} turns into $my_var
  if expanded_query_script_variable LIKE ':${%}' then
    return CONCAT('$', SUBSTRING(expanded_query_script_variable, 4, CHAR_LENGTH(expanded_query_script_variable) - 4));
  end if;
  -- :$my_var turns into $my_var
  if expanded_query_script_variable LIKE ':$%' then
    return SUBSTRING(expanded_query_script_variable, 2);
  end if;
  return NULL;
end $$

DELIMITER ;
--
-- Assign input values into local variables
--

delimiter //

drop procedure if exists _take_local_variables_snapshot //

create procedure _take_local_variables_snapshot(
   expanded_variables text charset utf8
)
comment 'Declares local variables'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  declare num_variables int unsigned;
  declare variable_index int unsigned default 0;
  declare local_variable varchar(65) charset ascii;
  declare user_defined_variable_name varchar(65) charset ascii;
  declare snapshot_query text charset ascii;
  
  set num_variables := get_num_tokens(expanded_variables, ',');
  set variable_index := 1;
  while variable_index <= num_variables do
    set local_variable := split_token(expanded_variables, ',', variable_index);
    SELECT mapped_user_defined_variable_name FROM _qs_variables WHERE variable_name = local_variable INTO user_defined_variable_name;
    
    set snapshot_query := CONCAT('UPDATE _qs_variables SET value_snapshot = ', user_defined_variable_name, ' WHERE variable_name = ', QUOTE(local_variable));
    call exec_single(snapshot_query);
    
    set variable_index := variable_index + 1;
  end while;
end;

--	create procedure _take_local_variables_snapshot(
--	   variables_array_id int unsigned
--	)
--	comment 'Declares local variables'
--	language SQL
--	deterministic
--	modifies sql data
--	sql security invoker
--	
--	main_body: begin
--	  declare num_variables int unsigned;
--	  declare variable_index int unsigned default 0;
--	  declare local_variable varchar(65) charset ascii;
--	  declare user_defined_variable_name varchar(65) charset ascii;
--	  declare snapshot_query text charset ascii;
--	  
--	  call _get_array_size(variables_array_id, num_variables);
--	  set variable_index := 1;
--	  while variable_index <= num_variables do
--	    call _get_array_element(variables_array_id, variable_index, local_variable);
--	    SELECT mapped_user_defined_variable_name FROM _qs_variables WHERE variable_name = local_variable INTO user_defined_variable_name;
--	    
--	    set snapshot_query := CONCAT('UPDATE _qs_variables SET value_snapshot = ', user_defined_variable_name, ' WHERE variable_name = ', QUOTE(local_variable));
--	    call exec_single(snapshot_query);
--	    
--	    set variable_index := variable_index + 1;
--	  end while;
--	end;

//

delimiter ;
--
--

delimiter //

drop procedure if exists _create_array //

create procedure _create_array(
   out  array_id VARCHAR(16) charset ascii
) 
comment 'Creates an array, returning its ID'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  select _create_mxarray() into array_id;
end;
//

delimiter ;
--
--

delimiter //

drop procedure if exists _drop_array //

create procedure _drop_array(
   in  array_id int unsigned
) 
comment 'Drops an array'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  select _drop_mxarray(array_id) into @_common_schema_dummy;
end;
//

delimiter ;
--
--

delimiter //

drop procedure if exists _get_array_element //

create procedure _get_array_element(
   in  array_id VARCHAR(16) charset ascii,
   in array_key varchar(127) charset utf8,
   out element text charset utf8
) 
comment 'Creates an array, returning its ID'
language SQL
deterministic
reads sql data
sql security invoker

main_body: begin
  select _get_mxarray_element(array_id, array_key) into element;
end;
//

delimiter ;
--
--

delimiter //

drop procedure if exists _get_array_size //

create procedure _get_array_size(
   in  array_id VARCHAR(16) charset ascii,
   out array_size int unsigned
) 
comment 'Creates an array, returning its ID'
language SQL
deterministic
reads sql data
sql security invoker

main_body: begin
  select _get_mxarray_size(array_id) into array_size;
end;
//

delimiter ;
--
--

delimiter //

drop procedure if exists _push_array_element //

create procedure _push_array_element(
   in  array_id VARCHAR(16) charset ascii,
   in  element text charset utf8
) 
comment 'Pushes new element, key becomes incrementing number'
language SQL
deterministic
modifies sql data
sql security invoker

main_body: begin
  do _push_mxarray_element(array_id, element);
end;
//

delimiter ;
--
--

delimiter //

drop function if exists _create_mxarray //

create function _create_mxarray()
returns int unsigned

comment 'Creates an array, returning its ID'
language SQL
deterministic
no sql
sql security invoker

main_body: begin
  if @_common_schema_mx_array IS NULL then
    set @_common_schema_mx_array := '<ma></ma>';
  end if;
  
  set @_common_schema_create_mxarray_id := session_unique_id();
  set @_common_schema_mx_array := REPLACE(@_common_schema_mx_array, '</ma>', CONCAT('<a id="', @_common_schema_create_mxarray_id, '"><maxkey aid="', @_common_schema_create_mxarray_id, '">0</maxkey></a></ma>'));
  return @_common_schema_create_mxarray_id;
end;
//

delimiter ;
--
--

delimiter //

drop function if exists _drop_mxarray //

create function _drop_mxarray(
   array_id int unsigned
) returns int unsigned
comment 'Drops an array'
language SQL
deterministic
no sql
sql security invoker

main_body: begin
  declare xpath varchar(64) charset utf8;
  if array_id is null then
    return null;
  end if;
  set xpath := CONCAT('/ma/a[@id="', array_id, '"]');
  set @_common_schema_mx_array := UpdateXML(@_common_schema_mx_array, xpath, '');
  return array_id;
end;
//

delimiter ;
--
--

delimiter //

drop function if exists _get_mxarray_element //

create function _get_mxarray_element(
   array_id int unsigned,
   array_key varchar(127) charset utf8
) returns text charset utf8
comment 'Get an element by array id and key'
language SQL
deterministic
no sql
sql security invoker

main_body: begin
  declare xpath varchar(64) charset utf8;
  if _mxarray_key_exists(array_id, array_key) then
    set xpath := CONCAT('/ma/a[@id="', array_id, '"]/e[@key="', encode_xml(array_key), '"][1]');
    return decode_xml(ExtractValue(@_common_schema_mx_array, xpath));
  end if;
  return null;
end;
//

delimiter ;
--
--

delimiter //

drop function if exists _get_mxarray_max_key //

create function _get_mxarray_max_key(
   array_id int unsigned
) returns int unsigned
comment '(internal) get array''s current max key'
language SQL
deterministic
no sql
sql security invoker

main_body: begin
  return CAST(ExtractValue(@_common_schema_mx_array, CONCAT('/ma/a[@id="', array_id, '"]/maxkey')) AS UNSIGNED);
end;
//

delimiter ;
--
--

delimiter //

drop function if exists _get_mxarray_size //

create function _get_mxarray_size(
   array_id int unsigned
) returns int unsigned

comment 'Return number of elements in indicated array'
language SQL
deterministic
no sql
sql security invoker

main_body: begin
  return CAST(IFNULL(ExtractValue(@_common_schema_mx_array, CONCAT('count(/ma/a[@id="', array_id, '"]/e)')), 0) AS UNSIGNED);
end;
//

delimiter ;
--
--

delimiter //

drop function if exists _mxarray_key_exists //

create function _mxarray_key_exists(
   array_id int unsigned,
   array_key varchar(127) charset utf8
) returns tinyint unsigned
comment 'Check whether key exists within array'
language SQL
deterministic
no sql
sql security invoker

main_body: begin
  declare xpath varchar(64) charset utf8;
  set xpath := CONCAT('count(/ma/a[@id="', array_id, '"]/e[@key="', encode_xml(array_key), '"][1])');
  return (IFNULL(ExtractValue(@_common_schema_mx_array, xpath), 0) > 0);
end;
//

delimiter ;
--
--

delimiter //

drop function if exists _push_mxarray_element //

create function _push_mxarray_element(
   array_id int unsigned,
   element text charset utf8
) returns int unsigned

comment 'Pushes new element into array'
language SQL
deterministic
no sql
sql security invoker

main_body: begin
  declare array_max_key int unsigned;
  
  if array_id is null then
    return null;
  end if;
  
  set array_max_key := _get_mxarray_max_key(array_id);
  set @_common_schema_mx_array := REPLACE(@_common_schema_mx_array, CONCAT('<maxkey aid="', array_id, '">'), CONCAT('<e key="', (array_max_key+1), '">', encode_xml(element), '</e><maxkey aid="', array_id, '">'));
  do _update_mxarray_max_key(array_id, (array_max_key+1));
  return (array_max_key+1);
end;
//

delimiter ;
--
--

delimiter //

drop function if exists _update_mxarray_max_key //

create function _update_mxarray_max_key(
   array_id int unsigned,
   array_max_key int unsigned
) returns int unsigned

comment '(internal) updated max-key indicator'
language SQL
deterministic
no sql
sql security invoker

main_body: begin
  set @_common_schema_mx_array := UpdateXML(@_common_schema_mx_array, CONCAT('/ma/a[@id="', array_id, '"]/maxkey'), CONCAT('<maxkey aid="', array_id, '">', array_max_key, '</maxkey>'));
  return array_id;
end;
//

delimiter ;
-- 
-- 
-- 

DELIMITER $$

DROP PROCEDURE IF EXISTS _split $$
CREATE PROCEDURE _split(
  split_table_schema varchar(128), 
  split_table_name varchar(128),
  split_options varchar(2048) charset utf8,
  split_injected_action_statement TEXT CHARSET utf8, 
  split_injected_text TEXT CHARSET utf8,
  in   id_from      int unsigned,
  in   id_to      int unsigned,
  in   expect_single tinyint unsigned,
  out  consumed_to_id int unsigned,
  in depth int unsigned,
  in should_execute_statement tinyint unsigned
  ) 
MODIFIES SQL DATA
SQL SECURITY INVOKER
COMMENT 'split values by columns...'

main_body: begin
  declare is_overflow tinyint unsigned;
  declare is_empty_range tinyint unsigned;
  declare deadlock_detected tinyint unsigned;
  declare split_range_size int unsigned;
  declare comparison_clause text charset utf8;
  declare action_statement text charset utf8;
  declare continue handler for 1205 SET deadlock_detected = TRUE;

  set @_split_is_first_step_flag := true;
  
  call _split_generate_dependency_tables(split_table_schema, split_table_name);
  call _split_deduce_columns(split_table_schema, split_table_name);
  call _split_init_variables();
  call _split_assign_min_max_variables(id_from, split_table_schema, split_table_name, split_options, is_empty_range);
  
  if is_empty_range then
    leave main_body;
  end if;
  
  call _split_assign_initial_range_start_variables();
  
  set @_query_script_split_step_index := 0;
  set @_query_script_split_total_rowcount := 0;
  set @query_script_split_start_time := SYSDATE();
  
  call _declare_local_variable(id_from, id_from, id_to, depth, '$split_columns', '@query_script_split_columns', FALSE);
  call _declare_local_variable(id_from, id_from, id_to, depth, '$split_min', '@query_script_split_min', FALSE);
  call _declare_local_variable(id_from, id_from, id_to, depth, '$split_max', '@query_script_split_max', FALSE);
  call _declare_local_variable(id_from, id_from, id_to, depth, '$split_clause', '@query_script_split_comparison_clause', FALSE);
  call _declare_local_variable(id_from, id_from, id_to, depth, '$split_step', '@query_script_split_step_index', FALSE);
  call _declare_local_variable(id_from, id_from, id_to, depth, '$split_range_start', '@query_script_split_range_start_snapshot', FALSE);
  call _declare_local_variable(id_from, id_from, id_to, depth, '$split_range_end', '@query_script_split_range_end_snapshot', FALSE);
  call _declare_local_variable(id_from, id_from, id_to, depth, '$split_rowcount', '@query_script_split_rowcount', FALSE);
  call _declare_local_variable(id_from, id_from, id_to, depth, '$split_total_rowcount', '@query_script_split_total_rowcount', FALSE);
  call _declare_local_variable(id_from, id_from, id_to, depth, '$split_total_elapsed_time', '@query_script_split_total_elapsed_time', FALSE);
  call _declare_local_variable(id_from, id_from, id_to, depth, '$split_table_schema', '@query_script_split_table_schema', FALSE);
  call _declare_local_variable(id_from, id_from, id_to, depth, '$split_table_name', '@query_script_split_table_name', FALSE);
  
  set split_range_size := least(10000, greatest(100, floor(ifnull(get_option(split_options, 'size'), 1000))));
  _split_step_loop: loop
    call _split_is_range_start_overflow(is_overflow);
    if is_overflow and not @_split_is_first_step_flag then
      leave _split_step_loop;
    end if;
    call _split_assign_range_end_variables(split_table_schema, split_table_name, split_range_size);
    -- We now have a range start+end
    -- start split step operation
    call _split_get_step_comparison_clause(comparison_clause);

    set action_statement := REPLACE(split_injected_action_statement, split_injected_text, comparison_clause);

    repeat
      set deadlock_detected := false;
      call exec_single(action_statement);
      if deadlock_detected then
        select 'deadlock detected...' as msg;
      end if;

      set @_query_script_split_step_index := @_query_script_split_step_index + 1;
      set @query_script_split_step_index := @_query_script_split_step_index;
      set @query_script_split_rowcount := @common_schema_rowcount;
      set @_query_script_split_total_rowcount := @_query_script_split_total_rowcount + GREATEST(@query_script_split_rowcount, 0);
      set @query_script_split_total_rowcount := @_query_script_split_total_rowcount;
      set @query_script_split_total_elapsed_time := TIMESTAMPDIFF(MICROSECOND, @query_script_split_start_time, SYSDATE())/1000000.0;
      set @query_script_split_table_schema := split_table_schema;
      set @query_script_split_table_name := split_table_name;
      set @query_script_split_min := @_query_script_split_min;
      set @query_script_split_max := @_query_script_split_max;
      set @query_script_split_columns := @_query_script_split_columns;
      call _split_set_step_clause_and_ranges_local_variables(comparison_clause);
    
      call _consume_statement(id_from, id_to, expect_single, consumed_to_id, depth, should_execute_statement);

      if @_common_schema_script_break_type IS NOT NULL then
        if @_common_schema_script_break_type = 'break' then
          set @_common_schema_script_break_type := NULL;
        end if;
        leave _split_step_loop;
      end if;
    until deadlock_detected = false
    end repeat;

    call _split_assign_next_range_start_variables();
    set @_split_is_first_step_flag := false;
  end loop;
end $$

DELIMITER ;
-- 
-- 
-- 

DELIMITER $$

DROP PROCEDURE IF EXISTS _split_assign_initial_range_start_variables $$
CREATE PROCEDURE _split_assign_initial_range_start_variables() 
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

begin
  declare queries text default NULL;

  select 
    GROUP_CONCAT(
      'set ', range_start_variable_name, ' := ', min_variable_name, ';'
      separator ''
    )
    from _split_column_names_table
    into queries;
    
  call exec(queries);
  
  set @_split_column_variable_range_end_1 := NULL;
end $$

DELIMITER ;
-- 
-- 
-- 

DELIMITER $$

DROP PROCEDURE IF EXISTS _split_assign_min_max_variables $$
CREATE PROCEDURE _split_assign_min_max_variables(
  id_from      int unsigned,
  split_table_schema varchar(128), 
  split_table_name varchar(128),
  split_options varchar(2048) charset utf8,
  out is_empty_range tinyint unsigned
  ) 
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

begin
  declare query text default NULL;
  declare manual_min_max_params_used tinyint unsigned default false;
  declare column_names text default _split_get_columns_names();
  declare columns_order_ascending_clause text default _split_get_columns_order_ascending_clause();
  declare min_variables_names text default _split_get_min_variables_names();
  declare columns_order_descending_clause text default _split_get_columns_order_descending_clause();
  declare max_variables_names text default _split_get_max_variables_names();
  declare columns_count tinyint unsigned default _split_get_columns_count();
  
  set is_empty_range := false;

  set query := CONCAT(
    'select ', column_names, ' from ',
    mysql_qualify(split_table_schema), '.', mysql_qualify(split_table_name), 
    ' order by ', columns_order_ascending_clause,
    ' limit 1 ',
    ' into ', min_variables_names
  );
  call exec_single(query);

  set query := CONCAT(
    'select ', column_names, ' from ',
    mysql_qualify(split_table_schema), '.', mysql_qualify(split_table_name), 
    ' order by ', columns_order_descending_clause,
    ' limit 1 ',
    ' into ', max_variables_names
  );
  call exec_single(query);
  
  if get_option(split_options, 'start') is not null then
    if columns_count = 1 then
      set query := CONCAT(
        'set ', min_variables_names, ' := GREATEST(', min_variables_names, ', ', QUOTE(get_option(split_options, 'start')), ')'
      );
      call exec_single(query);
      set manual_min_max_params_used := true;
    else
      call _throw_script_error(id_from, 'Found ''start'' option, but this split uses multiple columns');
    end if;
  end if;
  if get_option(split_options, 'stop') is not null then
    if columns_count = 1 then
      set query := CONCAT(
        'set ', max_variables_names, ' := LEAST(', max_variables_names, ', ', QUOTE(get_option(split_options, 'stop')), ')'
      );
      call exec_single(query);
      set manual_min_max_params_used := true;
    else
      call _throw_script_error(id_from, 'Found ''stop'' option, but this split uses multiple columns');
    end if;
  end if;
  if manual_min_max_params_used then
    -- Due to manual intervention, we need to verify boundaries.
    -- We know for certain there is one column in splitting key (due to above checks)
    select 
      CONCAT(
        'SELECT (',
          min_variable_name, ' > ', max_variable_name,
        ') INTO @_split_is_empty_range_result'
        )
      from _split_column_names_table
      into query;

    call exec_single(query);
    if @_split_is_empty_range_result then
      set is_empty_range := true;
    end if;
    
  end if;

  -- Check if range is empty
  select 
    CONCAT(
      'SELECT (',
      GROUP_CONCAT(
        min_variable_name, ' IS NULL'
        separator ' AND '
      ),
      ') INTO @_split_is_empty_range_result'
      )
    from _split_column_names_table
    into query;

  call exec_single(query);
  if @_split_is_empty_range_result then
    set is_empty_range := true;
  end if;

  
  set @_query_script_split_min := TRIM(TRAILING ',' FROM CONCAT_WS(',',
  	IF(columns_count >= 1, QUOTE((SELECT @_split_column_variable_min_1)), ''),
  	IF(columns_count >= 2, QUOTE((SELECT @_split_column_variable_min_2)), ''),
  	IF(columns_count >= 3, QUOTE((SELECT @_split_column_variable_min_3)), ''),
  	IF(columns_count >= 4, QUOTE((SELECT @_split_column_variable_min_4)), ''),
  	IF(columns_count >= 5, QUOTE((SELECT @_split_column_variable_min_5)), ''),
  	IF(columns_count >= 6, QUOTE((SELECT @_split_column_variable_min_6)), ''),
  	IF(columns_count >= 7, QUOTE((SELECT @_split_column_variable_min_7)), ''),
  	IF(columns_count >= 8, QUOTE((SELECT @_split_column_variable_min_8)), ''),
  	IF(columns_count >= 9, QUOTE((SELECT @_split_column_variable_min_9)), '')
  ));
  set @_query_script_split_max := TRIM(TRAILING ',' FROM CONCAT_WS(',',
  	IF(columns_count >= 1, QUOTE((SELECT @_split_column_variable_max_1)), ''),
  	IF(columns_count >= 2, QUOTE((SELECT @_split_column_variable_max_2)), ''),
  	IF(columns_count >= 3, QUOTE((SELECT @_split_column_variable_max_3)), ''),
  	IF(columns_count >= 4, QUOTE((SELECT @_split_column_variable_max_4)), ''),
  	IF(columns_count >= 5, QUOTE((SELECT @_split_column_variable_max_5)), ''),
  	IF(columns_count >= 6, QUOTE((SELECT @_split_column_variable_max_6)), ''),
  	IF(columns_count >= 7, QUOTE((SELECT @_split_column_variable_max_7)), ''),
  	IF(columns_count >= 8, QUOTE((SELECT @_split_column_variable_max_8)), ''),
  	IF(columns_count >= 9, QUOTE((SELECT @_split_column_variable_max_9)), '')
  ));
  
end $$

DELIMITER ;
-- 
-- 
-- 

DELIMITER $$

DROP PROCEDURE IF EXISTS _split_assign_next_range_start_variables $$
CREATE PROCEDURE _split_assign_next_range_start_variables() 
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

begin
  declare queries text default NULL;

  select 
    GROUP_CONCAT(
      'set ', range_start_variable_name, ' := ', range_end_variable_name, ';'
      separator ''
    )
    from _split_column_names_table
    into queries;
    
  call exec(queries);
end $$

DELIMITER ;
-- 
-- 
-- 

DELIMITER $$

DROP PROCEDURE IF EXISTS _split_assign_range_end_variables $$
CREATE PROCEDURE _split_assign_range_end_variables(
  split_table_schema varchar(128),
  split_table_name varchar(128),
  split_range_size int unsigned
  ) 
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

begin
  declare query text default NULL;
  declare column_names text default _split_get_columns_names();
  
  declare columns_order_ascending_clause text default _split_get_columns_order_ascending_clause();
  declare range_end_variables_names text default _split_get_range_end_variables_names();
  
  declare columns_order_descending_clause text default _split_get_columns_order_descending_clause();
  declare max_variables_names text default _split_get_max_variables_names();
  
  declare columns_count tinyint unsigned default _split_get_columns_count();
  
  declare as_of_range_start_comparison_clause text default _split_get_columns_comparison_clause('>', 'range_start', _split_is_first_step(), columns_count);
  declare limit_by_max_comparison_clause text default _split_get_columns_comparison_clause('<', 'max', true, columns_count);

  set query := CONCAT(
    'select ', column_names, ' from (',
      'select ', column_names, ' from ',
      mysql_qualify(split_table_schema), '.', mysql_qualify(split_table_name), 
      ' where ', as_of_range_start_comparison_clause,
      ' and ', limit_by_max_comparison_clause,
      ' order by ', columns_order_ascending_clause,
      ' limit ', split_range_size,
    ') sel_split_range ',
    ' order by ', columns_order_descending_clause,
    ' limit 1 ',
    ' into ', range_end_variables_names
  );
  call exec_single(query);
end $$

DELIMITER ;
-- 
-- 
-- 

DELIMITER $$

DROP PROCEDURE IF EXISTS _split_deduce_columns $$
CREATE PROCEDURE _split_deduce_columns(split_table_schema varchar(128), split_table_name varchar(128)) 
MODIFIES SQL DATA
SQL SECURITY INVOKER
COMMENT 'split values by columns...'

begin
  declare split_column_names varchar(2048) default NULL;
  declare split_num_column tinyint unsigned;
  
  SELECT 
      column_names, count_column_in_index
    FROM 
      _split_candidate_keys_recommended 
    WHERE 
      table_schema = split_table_schema AND table_name = split_table_name 
    INTO split_column_names, split_num_column;
  if split_column_names is null then
    call throw(CONCAT('split: no key or definition found for: ', split_table_schema, '.', split_table_name));
  end if;
  
  drop temporary table if exists _split_column_names_table;
  create temporary table _split_column_names_table (
    column_order TINYINT UNSIGNED,
    split_table_name varchar(128) charset utf8,
    column_name VARCHAR(128) charset utf8,
    min_variable_name VARCHAR(128) charset utf8,
    max_variable_name VARCHAR(128) charset utf8,
    range_start_variable_name VARCHAR(128) charset utf8,
    range_end_variable_name VARCHAR(128) charset utf8
  );
  insert into _split_column_names_table
    select
      n,
      split_table_name,
      split_token(split_column_names, ',', n),
      CONCAT('@_split_column_variable_min_', n),
      CONCAT('@_split_column_variable_max_', n),
      CONCAT('@_split_column_variable_range_start_', n),
      CONCAT('@_split_column_variable_range_end_', n)
    from
      numbers
    where 
      n between 1 and split_num_column;
  select
    group_concat(mysql_qualify(column_name) order by column_order)
  from
    _split_column_names_table
  into
    @_query_script_split_columns;
end $$

DELIMITER ;
-- 
-- 
-- 

DELIMITER $$

DROP PROCEDURE IF EXISTS _split_generate_dependency_tables $$
CREATE PROCEDURE _split_generate_dependency_tables(split_table_schema varchar(128), split_table_name varchar(128)) 
MODIFIES SQL DATA
SQL SECURITY INVOKER
COMMENT 'split values by columns...'

begin
  declare split_column_names varchar(2048) default NULL;
  declare split_num_column tinyint unsigned;
  
  drop temporary table if exists _split_unique_keys;
  create temporary table _split_unique_keys
   SELECT
      TABLE_SCHEMA,
      TABLE_NAME,
      INDEX_NAME,
      COUNT(*) AS COUNT_COLUMN_IN_INDEX,
      IF(SUM(NULLABLE = 'YES') > 0, 1, 0) AS has_nullable,
      IF(INDEX_NAME = 'PRIMARY', 1, 0) AS is_primary,
      GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX ASC) AS COLUMN_NAMES,
      SUBSTRING_INDEX(GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX ASC), ',', 1) AS FIRST_COLUMN_NAME
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE
      TABLE_SCHEMA = split_table_schema
      AND TABLE_NAME = split_table_name
      AND NON_UNIQUE=0
    GROUP BY TABLE_SCHEMA, TABLE_NAME, INDEX_NAME
  ;
  
  drop temporary table if exists _split_i_s_columns;
  create temporary table _split_i_s_columns
   SELECT
      TABLE_SCHEMA,
      TABLE_NAME,
      COLUMN_NAME,
      DATA_TYPE,
      CHARACTER_SET_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      TABLE_SCHEMA = split_table_schema
      AND TABLE_NAME = split_table_name
  ;
  
  drop temporary table if exists _split_candidate_keys;
  create temporary table _split_candidate_keys
    SELECT
      _split_i_s_columns.TABLE_SCHEMA AS table_schema,
      _split_i_s_columns.TABLE_NAME AS table_name,
      _split_unique_keys.INDEX_NAME AS index_name,
      _split_unique_keys.has_nullable AS has_nullable,
      _split_unique_keys.is_primary AS is_primary,
      _split_unique_keys.COLUMN_NAMES AS column_names,
      _split_unique_keys.COUNT_COLUMN_IN_INDEX AS count_column_in_index,
      _split_i_s_columns.DATA_TYPE AS data_type,
      _split_i_s_columns.CHARACTER_SET_NAME AS character_set_name,
      (CASE IFNULL(CHARACTER_SET_NAME, '')
          WHEN '' THEN 0
          ELSE 1
      END << 20
      )
      + (CASE LOWER(DATA_TYPE)
        WHEN 'tinyint' THEN 0
        WHEN 'smallint' THEN 1
        WHEN 'int' THEN 2
        WHEN 'timestamp' THEN 3
        WHEN 'bigint' THEN 4
        WHEN 'datetime' THEN 5
        ELSE 9
      END << 16
      ) + (COUNT_COLUMN_IN_INDEX << 0
      ) AS candidate_key_rank_in_table  
    FROM 
      _split_i_s_columns
      INNER JOIN _split_unique_keys ON (
        _split_i_s_columns.TABLE_SCHEMA = _split_unique_keys.TABLE_SCHEMA AND
        _split_i_s_columns.TABLE_NAME = _split_unique_keys.TABLE_NAME AND
        _split_i_s_columns.COLUMN_NAME = _split_unique_keys.FIRST_COLUMN_NAME
      )
    ORDER BY   
      _split_i_s_columns.TABLE_SCHEMA, _split_i_s_columns.TABLE_NAME, candidate_key_rank_in_table
  ;
  
  drop temporary table if exists _split_candidate_keys_recommended;
  create temporary table _split_candidate_keys_recommended
    SELECT
      table_schema,
      table_name,	
      SUBSTRING_INDEX(GROUP_CONCAT(index_name ORDER BY candidate_key_rank_in_table ASC), ',', 1) AS recommended_index_name,
      CAST(SUBSTRING_INDEX(GROUP_CONCAT(has_nullable ORDER BY candidate_key_rank_in_table ASC), ',', 1) AS UNSIGNED INTEGER) AS has_nullable,
      CAST(SUBSTRING_INDEX(GROUP_CONCAT(is_primary ORDER BY candidate_key_rank_in_table ASC), ',', 1) AS UNSIGNED INTEGER) AS is_primary,
      CAST(SUBSTRING_INDEX(GROUP_CONCAT(count_column_in_index ORDER BY candidate_key_rank_in_table ASC), ',', 1) AS UNSIGNED INTEGER) AS count_column_in_index,
      SUBSTRING_INDEX(GROUP_CONCAT(column_names ORDER BY candidate_key_rank_in_table ASC SEPARATOR '\n'), '\n', 1) AS column_names
    FROM 
      _split_candidate_keys
    GROUP BY
      table_schema, table_name
    ORDER BY   
      table_schema, table_name
    ;
  
end $$

DELIMITER ;
-- 
-- 
DELIMITER $$

DROP function IF EXISTS _split_get_columns_comparison_clause $$
CREATE function _split_get_columns_comparison_clause(
    comparison_operator VARCHAR(3), 
    split_variable_type enum('range_start', 'range_end', 'max'), 
    comparison_includes_equals TINYINT UNSIGNED,
    num_split_columns TINYINT UNSIGNED) 
  returns TEXT CHARSET utf8
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

BEGIN	
  declare return_value TEXT CHARSET utf8;
  
  select
    group_concat('(', partial_comparison, ')' order by n separator ' OR ') as comparison
  from (
    select 
      n,
      group_concat('(', column_name, ' ', if(is_last, comparison_operator, '='), ' ', variable_name, ')' order by column_order separator ' AND ') as partial_comparison
    from (
      select 
        n, CONCAT(mysql_qualify(split_table_name), '.', mysql_qualify(column_name)) AS column_name,
        case split_variable_type
          when 'range_start' then range_start_variable_name
          when 'range_end' then range_end_variable_name
          when 'max' then max_variable_name
        end as variable_name,
        _split_column_names_table.column_order, _split_column_names_table.column_order = n as is_last 
      from 
        numbers, _split_column_names_table 
      where 
        n between _split_column_names_table.column_order and num_split_columns 
      order by n, _split_column_names_table.column_order
    ) s1
    group by n
  ) s2
  into return_value
  ;
  
  if comparison_includes_equals then
    select
      CONCAT(
        return_value, ' OR (',
        GROUP_CONCAT(
          '(', CONCAT(mysql_qualify(split_table_name), '.', mysql_qualify(column_name)), ' = ', 
          case split_variable_type
            when 'range_start' then range_start_variable_name
            when 'range_end' then range_end_variable_name
            when 'max' then max_variable_name
          end,
          ')' order by column_order separator ' AND '),
        ')'
      )
    from
      _split_column_names_table
    into return_value
    ;
  end if;
  set return_value := CONCAT('(', return_value, ')');

  return return_value;
END $$

DELIMITER ;
-- 
-- 
DELIMITER $$

DROP function IF EXISTS _split_get_columns_count $$
CREATE function _split_get_columns_count() 
  returns TINYINT UNSIGNED
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

BEGIN	
  declare return_value TINYINT UNSIGNED;
  
  select 
      count(*)
    from
      _split_column_names_table
    into return_value
    ;
  return return_value;
END $$

DELIMITER ;
-- 
-- 
DELIMITER $$

DROP function IF EXISTS _split_get_columns_names $$
CREATE function _split_get_columns_names() 
  returns TEXT CHARSET utf8
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

BEGIN	
  declare return_value TEXT CHARSET utf8;
  
  select 
      group_concat(column_name order by column_order separator ', ')
    from
      _split_column_names_table
    into return_value
    ;
  return return_value;
END $$

DELIMITER ;
-- 
-- 
DELIMITER $$

DROP function IF EXISTS _split_get_columns_order_ascending_clause $$
CREATE function _split_get_columns_order_ascending_clause() 
  returns TEXT CHARSET utf8
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

BEGIN	
  declare return_value TEXT CHARSET utf8;
  
  select 
      group_concat(column_name, ' ASC' order by column_order separator ', ')
    from
      _split_column_names_table
    into return_value
    ;
  return return_value;
END $$

DELIMITER ;
-- 
-- 
DELIMITER $$

DROP function IF EXISTS _split_get_columns_order_descending_clause $$
CREATE function _split_get_columns_order_descending_clause() 
  returns TEXT CHARSET utf8
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

BEGIN	
  declare return_value TEXT CHARSET utf8;
  
  select 
      group_concat(column_name, ' DESC' order by column_order separator ', ')
    from
      _split_column_names_table
    into return_value
    ;
  return return_value;
END $$

DELIMITER ;
-- 
-- 
DELIMITER $$

DROP function IF EXISTS _split_get_max_variables_names $$
CREATE function _split_get_max_variables_names() 
  returns TEXT CHARSET utf8
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

BEGIN	
  declare return_value TEXT CHARSET utf8;
  
  select 
      group_concat(max_variable_name order by column_order separator ', ')
    from
      _split_column_names_table
    into return_value
    ;
  return return_value;
END $$

DELIMITER ;
-- 
-- 
DELIMITER $$

DROP function IF EXISTS _split_get_min_variables_names $$
CREATE function _split_get_min_variables_names() 
  returns TEXT CHARSET utf8
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

BEGIN	
  declare return_value TEXT CHARSET utf8;
  
  select 
      group_concat(min_variable_name order by column_order separator ', ')
    from
      _split_column_names_table
    into return_value
    ;
  return return_value;
END $$

DELIMITER ;
-- 
-- 
DELIMITER $$

DROP function IF EXISTS _split_get_range_end_variables_names $$
CREATE function _split_get_range_end_variables_names() 
  returns TEXT CHARSET utf8
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

BEGIN	
  declare return_value TEXT CHARSET utf8;
  
  select 
      group_concat(range_end_variable_name order by column_order separator ', ')
    from
      _split_column_names_table
    into return_value
    ;
  return return_value;
END $$

DELIMITER ;
-- 
-- 
DELIMITER $$

DROP function IF EXISTS _split_get_range_start_variables_names $$
CREATE function _split_get_range_start_variables_names() 
  returns TEXT CHARSET utf8
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

BEGIN	
  declare return_value TEXT CHARSET utf8;
  
  select 
      group_concat(range_start_variable_name order by column_order separator ', ')
    from
      _split_column_names_table
    into return_value
    ;
  return return_value;
END $$

DELIMITER ;
-- 
-- 
DELIMITER $$

DROP PROCEDURE IF EXISTS _split_get_step_comparison_clause $$
CREATE PROCEDURE _split_get_step_comparison_clause(
    out comparison_clause text charset utf8
  ) 
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

BEGIN	
  declare columns_count tinyint unsigned default _split_get_columns_count();
  declare range_start_comparison_clause text default _split_get_columns_comparison_clause('>', 'range_start', @_split_is_first_step_flag, columns_count);
  declare range_end_comparison_clause text default _split_get_columns_comparison_clause('<', 'range_end', true, columns_count);

  set comparison_clause := CONCAT(
  	'(', range_start_comparison_clause, ' AND ', range_end_comparison_clause, ')'
  );
END $$

DELIMITER ;
-- 
-- 
-- 

DELIMITER $$

DROP PROCEDURE IF EXISTS _split_init_variables $$
CREATE PROCEDURE _split_init_variables() 
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

begin
  declare queries text default NULL;

  select 
    GROUP_CONCAT(
      'set ', min_variable_name, ' := NULL; ',
      'set ', max_variable_name, ' := NULL; ',
      'set ', range_start_variable_name, ' := NULL; ',
      'set ', range_end_variable_name, ' := NULL; '
      separator ''
    )
    from _split_column_names_table
    into queries;
    
  call exec(queries);
end $$

DELIMITER ;
-- 
-- 
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS _split_is_first_step $$
CREATE FUNCTION _split_is_first_step() RETURNS TINYINT UNSIGNED
NO SQL
SQL SECURITY INVOKER
COMMENT ''

begin
  return @_split_is_first_step_flag;
end $$

DELIMITER ;
-- 
-- 
-- 

DELIMITER $$

DROP PROCEDURE IF EXISTS _split_is_range_start_overflow $$
CREATE PROCEDURE _split_is_range_start_overflow(out is_overflow tinyint unsigned) 
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

begin
  declare query text default NULL;

  declare range_start_variables_names text default _split_get_range_start_variables_names();
  declare max_variables_names text default _split_get_max_variables_names();

  set query := CONCAT(
    'select (', range_start_variables_names, ') >= (', max_variables_names, ') into @_split_is_overflow'
  );
  call exec_single(query);
  set is_overflow := @_split_is_overflow;
end $$

DELIMITER ;
-- 
-- 
DELIMITER $$

DROP PROCEDURE IF EXISTS _split_set_step_clause_and_ranges_local_variables $$
CREATE PROCEDURE _split_set_step_clause_and_ranges_local_variables(
    in comparison_clause text charset utf8
  ) 
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

BEGIN
  declare columns_count tinyint unsigned default _split_get_columns_count();

  set @query_script_split_comparison_clause := comparison_clause;
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_start_1', QUOTE((SELECT @_split_column_variable_range_start_1)));
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_start_2', QUOTE((SELECT @_split_column_variable_range_start_2)));
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_start_3', QUOTE((SELECT @_split_column_variable_range_start_3)));
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_start_4', QUOTE((SELECT @_split_column_variable_range_start_4)));
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_start_5', QUOTE((SELECT @_split_column_variable_range_start_5)));
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_start_6', QUOTE((SELECT @_split_column_variable_range_start_6)));
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_start_7', QUOTE((SELECT @_split_column_variable_range_start_7)));
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_start_8', QUOTE((SELECT @_split_column_variable_range_start_8)));
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_start_9', QUOTE((SELECT @_split_column_variable_range_start_9)));
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_end_1', QUOTE((SELECT @_split_column_variable_range_end_1)));
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_end_2', QUOTE((SELECT @_split_column_variable_range_end_2)));
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_end_3', QUOTE((SELECT @_split_column_variable_range_end_3)));
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_end_4', QUOTE((SELECT @_split_column_variable_range_end_4)));
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_end_5', QUOTE((SELECT @_split_column_variable_range_end_5)));
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_end_6', QUOTE((SELECT @_split_column_variable_range_end_6)));
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_end_7', QUOTE((SELECT @_split_column_variable_range_end_7)));
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_end_8', QUOTE((SELECT @_split_column_variable_range_end_8)));
  set @query_script_split_comparison_clause := REPLACE(@query_script_split_comparison_clause, '@_split_column_variable_range_end_9', QUOTE((SELECT @_split_column_variable_range_end_9)));
  
  set @query_script_split_range_start_snapshot := TRIM(TRAILING ',' FROM CONCAT_WS(',',
  	IF(columns_count >= 1, QUOTE((SELECT @_split_column_variable_range_start_1)), ''),
  	IF(columns_count >= 2, QUOTE((SELECT @_split_column_variable_range_start_2)), ''),
  	IF(columns_count >= 3, QUOTE((SELECT @_split_column_variable_range_start_3)), ''),
  	IF(columns_count >= 4, QUOTE((SELECT @_split_column_variable_range_start_4)), ''),
  	IF(columns_count >= 5, QUOTE((SELECT @_split_column_variable_range_start_5)), ''),
  	IF(columns_count >= 6, QUOTE((SELECT @_split_column_variable_range_start_6)), ''),
  	IF(columns_count >= 7, QUOTE((SELECT @_split_column_variable_range_start_7)), ''),
  	IF(columns_count >= 8, QUOTE((SELECT @_split_column_variable_range_start_8)), ''),
  	IF(columns_count >= 9, QUOTE((SELECT @_split_column_variable_range_start_9)), '')
  ));
  set @query_script_split_range_end_snapshot := TRIM(TRAILING ',' FROM CONCAT_WS(',',
  	IF(columns_count >= 1, QUOTE((SELECT @_split_column_variable_range_end_1)), ''),
  	IF(columns_count >= 2, QUOTE((SELECT @_split_column_variable_range_end_2)), ''),
  	IF(columns_count >= 3, QUOTE((SELECT @_split_column_variable_range_end_3)), ''),
  	IF(columns_count >= 4, QUOTE((SELECT @_split_column_variable_range_end_4)), ''),
  	IF(columns_count >= 5, QUOTE((SELECT @_split_column_variable_range_end_5)), ''),
  	IF(columns_count >= 6, QUOTE((SELECT @_split_column_variable_range_end_6)), ''),
  	IF(columns_count >= 7, QUOTE((SELECT @_split_column_variable_range_end_7)), ''),
  	IF(columns_count >= 8, QUOTE((SELECT @_split_column_variable_range_end_8)), ''),
  	IF(columns_count >= 9, QUOTE((SELECT @_split_column_variable_range_end_9)), '')
  ));
END $$

DELIMITER ;
--
--
--

delimiter //

drop procedure if exists _get_split_query_single_table //

create procedure _get_split_query_single_table (
   in  id_from      int unsigned,
   in  id_to      int unsigned,
   out query_type_supported tinyint unsigned,
   out tables_found enum ('none', 'single', 'multi'),
   out table_schema varchar(80) charset utf8, 
   out table_name varchar(80) charset utf8
)
comment ''
language SQL
deterministic
reads sql data
sql security invoker
main_body: begin
	declare split_query_type varchar(32) charset ascii;
    declare table_definitions_found tinyint unsigned;
    declare table_definitions_id_from int unsigned;
    declare table_definitions_id_to int unsigned;
    
    set table_schema := null;
    set table_name := null;

    -- Analyze query type
    call _get_split_query_type(id_from, id_to, split_query_type, @_common_schema_dummy, @_common_schema_dummy);
    if split_query_type = 'unsupported' then
      set query_type_supported := false;
      leave main_body;
    end if;
    set query_type_supported := true;

    -- Try to isolate table definitions clause
    call _get_split_query_table_definitions_clause(id_from, id_to, split_query_type, 
      table_definitions_found, table_definitions_id_from, table_definitions_id_to);
    if not table_definitions_found then
      set tables_found := 'none';
      leave main_body;
    end if;
    
    -- Finally, get table_schema & table_name, if possible:
    call _get_split_single_table_from_table_definitions(
      table_definitions_id_from,
      table_definitions_id_to,
      tables_found,
      table_schema,
      table_name
      );
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _get_split_query_table_definitions_clause //

create procedure _get_split_query_table_definitions_clause(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   in   split_query_type enum (
     'unsupported', 'delete', 'update', 'select', 'insert_select', 'replace_select'),
   out	table_definitions_found tinyint unsigned,
   out	table_definitions_id_from int unsigned,
   out	table_definitions_id_to   int unsigned
)
comment 'Get type of query supported by split() statement'
language SQL
deterministic
reads sql data
sql security invoker
main_body: begin
    declare statement_level int unsigned;

    declare starting_id int unsigned;
    declare terminating_id int unsigned;
    declare following_select_id int unsigned;
    
    set table_definitions_found := false;
    set table_definitions_id_from := null;
    set table_definitions_id_to := null;
    
    if split_query_type = 'unsupported' then
      leave main_body;
    end if;
    
    select level from _sql_tokens where id = id_from into statement_level;

    if split_query_type = 'update' then
      select MIN(id) from _sql_tokens where (id between id_from and id_to) and level = statement_level and state = 'alpha' and LOWER(token) = 'set' into terminating_id;
      if terminating_id is not null then
        set table_definitions_found := true;
        set table_definitions_id_from := id_from + 1;
        set table_definitions_id_to := terminating_id - 1;
      end if;
      leave main_body;    
    end if;

    if split_query_type = 'delete' then
      -- find FROM
      select MIN(id) from _sql_tokens where (id between id_from and id_to) and level = statement_level and state = 'alpha' and LOWER(token) = 'from' into starting_id;
      if starting_id is not null then
        set table_definitions_found := true;
        set table_definitions_id_from := starting_id + 1;
        -- But if there's USING, then override:
        select MIN(id) from _sql_tokens where (id between table_definitions_id_from and id_to) and level = statement_level and state = 'alpha' and LOWER(token) = 'using' into starting_id;
        if starting_id is not null then
          set table_definitions_id_from := starting_id + 1;
        end if;
        -- now find the terminating token: WHERE, ORDER or LIMIT (or end of line)
        select MIN(id) from _sql_tokens where (id between table_definitions_id_from and id_to) and level = statement_level and state = 'alpha' and LOWER(token) in ('where', 'order', 'limit') into terminating_id;
        if terminating_id is not null then
          set table_definitions_id_to := terminating_id - 1;
        else
          set table_definitions_id_to := id_to;
        end if;
      end if;
      leave main_body;    
    end if;

    if split_query_type in ('insert_select', 'replace_select') then
      -- We know for sure the 'INSERT' or 'REPLACE' are followed by a 'SELECT'. 
      -- It just so happens that there's nothing special about it: we can parse the query 
      -- as if it were a SELECT query: we just look for the FROM clause.
      set split_query_type := 'select';
    end if;

    if split_query_type = 'select' then
      -- find FROM
      select MIN(id) from _sql_tokens where (id between id_from and id_to) and level = statement_level and state = 'alpha' and LOWER(token) = 'from' into starting_id;
      if starting_id is not null then
        set table_definitions_found := true;
        set table_definitions_id_from := starting_id + 1;
        -- now find the terminating token: WHERE, ORDER or LIMIT (or end of line)
        select MIN(id) from _sql_tokens where (id between table_definitions_id_from and id_to) and level = statement_level and state = 'alpha' and LOWER(token) in ('where', 'group', 'having', 'order', 'limit', 'procedure', 'into', 'for', 'lock') into terminating_id;
        if terminating_id is not null then
          set table_definitions_id_to := terminating_id - 1;
        else
          set table_definitions_id_to := id_to;
        end if;
      end if;
      leave main_body;    
    end if;
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _get_split_query_type //

create procedure _get_split_query_type(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   out  split_query_type enum (
     'unsupported', 'delete', 'update', 'select', 'insert_select', 'replace_select'),
   out  split_query_id_from int unsigned,
   out  split_query_following_select_id int unsigned
)
comment 'Get type of query supported by split() statement'
language SQL
deterministic
reads sql data
sql security invoker
main_body: begin
    declare statement_level int unsigned;
    declare statement_type tinytext charset utf8 default null;
    
    set split_query_type := 'unsupported';
    set split_query_following_select_id := null;
    
    call _skip_spaces(id_from, id_to);
    SELECT id, level, LOWER(token) FROM _sql_tokens WHERE id = id_from AND state = 'alpha' INTO split_query_id_from, statement_level, statement_type;
    
	if statement_type in ('insert', 'replace') then
      SELECT MIN(id) FROM _sql_tokens WHERE id > id_from AND id <= id_to AND level = statement_level AND state = 'alpha' AND LOWER(token) = 'select' INTO split_query_following_select_id;
    end if;
    
    if statement_type = 'delete' then
      set split_query_type := 'delete';
    elseif statement_type = 'update' then
      set split_query_type := 'update';
    elseif statement_type = 'select' then
      set split_query_type := 'select';
    elseif statement_type = 'insert' and split_query_following_select_id is not null then
      set split_query_type := 'insert_select';
    elseif statement_type = 'replace' and split_query_following_select_id is not null then
      set split_query_type := 'replace_select';
    end if;
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _get_split_single_table_from_table_definitions //

create procedure _get_split_single_table_from_table_definitions (
   in  id_from      int unsigned,
   in  id_to      int unsigned,
   out tables_found enum ('none', 'single', 'multi'),
   out table_schema varchar(80) charset utf8, 
   out table_name varchar(80) charset utf8
)
comment 'Get table_schema, table_name from table definitions clause'
language SQL
deterministic
reads sql data
sql security invoker
main_body: begin
    declare statement_level int unsigned;
	declare multi_table_indicator_id int unsigned;
    declare tokens_array_id int unsigned;
    declare peek_match_to int unsigned;
     
    set table_schema := null;
    set table_name := null;
    set tables_found := 'none';
    
    select level from _sql_tokens where id = id_from into statement_level;
    -- Check for multiple tables indicator: a JOIN, a STRAIGHT_JOIN, a comma,
    -- parenthesis (may indicate subquery, a USE INDEX, ON, USING)
    -- Oh, yes -- index hints not allwed here.
    select MIN(id) from _sql_tokens where 
      (id between id_from and id_to) 
      and (
        ((state = 'comma') and (level = statement_level))
        or 
        ((state = 'alpha') and (LOWER(token) in ('join', 'straight_join')) and (level = statement_level))
        or 
        ((state = 'left parenthesis') and (level = statement_level + 1))
      )
      into multi_table_indicator_id;
      
    if multi_table_indicator_id is not null then
       set tables_found := 'multi';
       leave main_body;
    end if;
    -- Got here: there is one single table.
    -- It should be in the following format: [schema_name.]tbl_name [[AS] alias]
    -- (valid SQL)
    -- We expect it to be in 'schema_name.tbl_name [[AS] alias]' format
    -- An alias means we cannot automagically add our special split clause
    -- since table name will not match -- bummer. At this point we do not
    -- allow aliases, so we actually expect table_schema.table_name

    call _skip_tokens_and_spaces(id_from, id_to, 'ignore,low_priority');
    call _peek_states_list(id_from, id_to, 'alpha|alphanum|quoted identifier|expanded query_script variable,dot,alpha|alphanum|quoted identifier|expanded query_script variable', false, false, true, tokens_array_id, peek_match_to);
    if peek_match_to > 0 then
      call _get_array_element(tokens_array_id, '1', table_schema);		
      call _get_array_element(tokens_array_id, '3', table_name);
      set table_schema := unquote(table_schema);
      set table_name := unquote(table_name);
      set tables_found := 'single';
    end if;
    call _drop_array(tokens_array_id);
end;
//

delimiter ;
--
--
--

delimiter //

drop procedure if exists _inject_split_where_token //

create procedure _inject_split_where_token(
   in   id_from      int unsigned,
   in   id_to      int unsigned,
   in   split_injected_text tinytext charset utf8,
   in   should_execute_statement tinyint unsigned,
   out  split_injected_action_statement text charset utf8
)
comment 'Injects a magical token into the WHERE statement'
language SQL
deterministic
reads sql data
sql security invoker
main_body: begin
    declare statement_level int unsigned;
    declare id_where_clause int unsigned default NULL; 
    declare id_where_clause_end int unsigned default NULL; 
    declare id_end_split_table_declaration int unsigned default NULL;
    declare query_part_prefix text charset utf8 default '';
    declare query_part_where_clause text charset utf8 default '';
    declare query_part_suffix text charset utf8 default '';
 	declare split_query_type varchar(32) charset ascii;
 	declare split_query_id_from int unsigned;
    declare split_query_following_select_id int unsigned;
   
    call _skip_spaces(id_from, id_to);
    SELECT level FROM _sql_tokens WHERE id = id_from INTO statement_level;
    
    -- Analyze query type
    call _get_split_query_type(id_from, id_to, split_query_type, split_query_id_from, split_query_following_select_id);
    
    if split_query_type = 'unsupported' then
      call _throw_script_error(id_from, 'split(): unsupported query type');
    end if;

    SELECT 
      MIN(id) FROM _sql_tokens 
      WHERE 
        level = statement_level AND state = 'alpha' and LOWER(token) = 'where' 
        AND id between id_from and id_to
      INTO id_where_clause;
    if id_where_clause is NULL then
      -- No "WHERE" clause.
      -- Attempt to find a clause which appears after the WHERE clause

      -- "INTO" is such a pain: is appears both in "INSERT INTO ... SELECT" (irrelevant to our injection)
      -- as well as in "SELECT ... INTO ..." (relevant to our injection)
      -- There's a lot of fuss to make sure to stop at the right "INTO".
      SELECT 
        MIN(id) FROM _sql_tokens 
        WHERE 
          level = statement_level 
          AND state = 'alpha' and LOWER(token) IN ('group', 'having', 'order', 'limit', 'into') 
          AND id between GREATEST(id_from, split_query_id_from, IFNULL(split_query_following_select_id, split_query_id_from)) and id_to
        INTO id_where_clause_end;
      if id_where_clause_end is NULL then
        -- No "WHERE", no following clause... Just invent a new "WHERE" clause...
        call _expand_statement_variables(id_from, id_to, query_part_prefix, @common_schema_dummy, should_execute_statement);
      else
        -- No "WHERE", but we found a following clause. Invent a new "WHERE"
        -- clause before that clause...
        call _expand_statement_variables(id_from, id_where_clause_end - 1, query_part_prefix, @common_schema_dummy, should_execute_statement);
        call _expand_statement_variables(id_where_clause_end, id_to, query_part_suffix, @common_schema_dummy, should_execute_statement);
      end if;
      -- Must invent/inject a "WHERE" clause
      set split_injected_action_statement := CONCAT(
          query_part_prefix, ' WHERE ', split_injected_text, ' ', query_part_suffix
        );
    else
      -- "WHERE" clause found.
      call _expand_statement_variables(id_from, id_where_clause, query_part_prefix, @common_schema_dummy, should_execute_statement);
      -- Search for end of "WHERE" clause
      SELECT 
        MIN(id) FROM _sql_tokens 
        WHERE 
          level = statement_level 
          AND state = 'alpha' and LOWER(token) IN ('group', 'having', 'order', 'limit', 'into') 
          AND id between id_from and id_to
          AND id > id_where_clause
        INTO id_where_clause_end;
      if id_where_clause_end is NULL then
        -- Nothing after the "WHERE" clause. So the "WHERE" clause 
        -- terminates at id_to
        call _expand_statement_variables(id_where_clause + 1, id_to, query_part_where_clause, @common_schema_dummy, should_execute_statement);
      else
        call _expand_statement_variables(id_where_clause + 1, id_where_clause_end - 1, query_part_where_clause, @common_schema_dummy, should_execute_statement);
        call _expand_statement_variables(id_where_clause_end, id_to, query_part_suffix, @common_schema_dummy, should_execute_statement);
      end if;
      -- inject text in exsiting WHERE clause
      set split_injected_action_statement := CONCAT(
          query_part_prefix, ' (', query_part_where_clause, ') AND ', split_injected_text, ' ', query_part_suffix
        );
    end if;
end;
//

delimiter ;
-- 
-- Extract value from options dictionary based on key
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS _is_options_format $$
CREATE FUNCTION _is_options_format(options TEXT CHARSET utf8) 
  returns tinyint unsigned
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Return value of option in JS options format'

begin
  if options is null then
    return false;
  end if;
  return (trim_wspace(options) RLIKE '^{.*}$') is true;
end $$

DELIMITER ;
-- 
-- Decode escaped XML text
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS decode_xml $$
CREATE FUNCTION decode_xml(txt TEXT CHARSET utf8) RETURNS TEXT CHARSET utf8 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Decode escaped XML'

begin
  set txt := REPLACE(txt, '&apos;', '''');
  set txt := REPLACE(txt, '&quot;', '"');
  set txt := REPLACE(txt, '&gt;', '>');
  set txt := REPLACE(txt, '&lt;', '<');
  set txt := REPLACE(txt, '&amp;', '&');
  
  return txt;
end $$

DELIMITER ;
-- 
-- Encode a given text for XML.
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS encode_xml $$
CREATE FUNCTION encode_xml(txt TEXT CHARSET utf8) RETURNS TEXT CHARSET utf8 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Encode (escape) given text for XML'

begin
  set txt := REPLACE(txt, '&', '&amp;');
  set txt := REPLACE(txt, '<', '&lt;');
  set txt := REPLACE(txt, '>', '&gt;');
  set txt := REPLACE(txt, '"', '&quot;');
  set txt := REPLACE(txt, '''', '&apos;');
  
  return txt;
end $$

DELIMITER ;
--
--
--

delimiter //

drop function if exists extract_json_value//

create function extract_json_value(
    json_text text charset utf8,
    xpath text charset utf8
) returns text charset utf8
comment 'Extracts JSON value via XPath'
language SQL
deterministic
modifies sql data
sql security invoker
begin
  return ExtractValue(json_to_xml(json_text), xpath);	
end;
//

delimiter ;
-- 
-- Return number of tokens in delimited text
-- txt: input string
-- delimiter: char or text by which to split txt
--
-- example:
--
-- SELECT get_num_tokens('the quick brown fox', ' ') AS num_token;
-- Returns: 4
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS get_num_tokens $$
CREATE FUNCTION get_num_tokens(txt TEXT CHARSET utf8, delimiter_text VARCHAR(255) CHARSET utf8) RETURNS INT UNSIGNED 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Return number of tokens in delimited text'

begin
  if CHAR_LENGTH(txt) = 0 then
    return 0;
  end if;
  if CHAR_LENGTH(delimiter_text) = 0 then
    return CHAR_LENGTH(txt);
  else
    return (CHAR_LENGTH(txt) - CHAR_LENGTH(REPLACE(txt, delimiter_text, '')))/CHAR_LENGTH(delimiter_text) + 1;
  end if;
end $$

DELIMITER ;
-- 
-- Extract value from options dictionary based on key
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS get_option $$
CREATE FUNCTION get_option(options TEXT CHARSET utf8, key_name VARCHAR(255) CHARSET utf8) 
  RETURNS TEXT CHARSET utf8 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Return value of option in JS options format'

begin
  declare options_delimiter VARCHAR(64) CHARSET ascii DEFAULT NULL;
  declare num_options INT UNSIGNED DEFAULT 0;
  declare options_counter INT UNSIGNED DEFAULT 0;
  declare current_option TEXT CHARSET utf8 DEFAULT ''; 
  declare current_option_delimiter VARCHAR(64) CHARSET ascii DEFAULT NULL;
  declare current_key TEXT CHARSET utf8 DEFAULT ''; 
  declare current_value TEXT CHARSET utf8 DEFAULT ''; 
  
  if not _is_options_format(options) then
    return null;
  end if;
  
  set key_name := unquote(key_name);

  -- parse options into key:value pairs
  set options := _retokenized_text(unwrap(trim_wspace(options)), ',', '"''`', TRUE, 'error');
  set options_delimiter := @common_schema_retokenized_delimiter;
  set num_options := @common_schema_retokenized_count;
  set options_counter := 1;
  while options_counter <= num_options do
    -- per option, parse key:value pair into key, value
    set current_option := split_token(options, options_delimiter, options_counter);
    set current_option = _retokenized_text(current_option, ':', '"''`', TRUE, 'error');

    set current_option_delimiter := @common_schema_retokenized_delimiter;
    if (@common_schema_retokenized_count != 2) then
      return NULL;
    end if;
    set current_key := split_token(current_option, current_option_delimiter, 1);
    set current_key := unquote(current_key);
    if current_key = key_name then
      set current_value := split_token(current_option, current_option_delimiter, 2);
      if current_value = 'NULL' then
        return NULL;
      end if;
      set current_value := unquote(current_value);
      return current_value;
    end if;
    set options_counter := options_counter + 1;
  end while;    
  return NULL;
end $$

DELIMITER ;
--
--
--

delimiter //

drop function if exists json_to_xml//

create function json_to_xml(
    json_text text charset utf8
) returns text charset utf8
comment 'Transforms JSON to XML'
language SQL
deterministic
modifies sql data
sql security invoker
begin
    declare v_from, v_old_from int unsigned;
    declare v_token text;
    declare v_level int;
    declare v_state, expect_state varchar(255);
    declare _json_tokens_id int unsigned default 0;
    declare is_lvalue, is_rvalue tinyint unsigned;
    declare scope_stack text charset ascii;
    declare xml text charset utf8;
    declare xml_nodes, xml_node text charset utf8;
    
    set json_text := trim_wspace(json_text);
    
    set expect_state := 'object_begin';
    set is_lvalue := true;
    set is_rvalue := false;
    set scope_stack := '';
    set xml_nodes := '';
    set xml_node := '';
    set xml := '';
    get_token_loop: repeat 
        set v_old_from = v_from;
        call _get_json_token(json_text, v_from, v_level, v_token, 1, v_state);
        set _json_tokens_id := _json_tokens_id + 1;
        if v_state = 'whitespace' then
          iterate get_token_loop;
        end if;
        if v_level < 0 then
          return null;
          -- call throw('Negative nesting level found in _get_json_tokens');
        end if;
        if v_state = 'start' and scope_stack = '' then
          leave get_token_loop;
        end if;
        if FIND_IN_SET(v_state, expect_state) = 0 then
          return null;
          -- call throw(CONCAT('Expected ', expect_state, '. Got ', v_state));
        end if;
        if v_state = 'array_end' and left(scope_stack, 1) = 'o' then
          return null;
          -- call throw(CONCAT('Missing "}". Found ', v_state));
        end if;
        if v_state = 'object_end' and left(scope_stack, 1) = 'a' then
          return null;
          -- call throw(CONCAT('Missing "]". Found ', v_state));
        end if;
        if v_state = 'alpha' and lower(v_token) not in ('true', 'false', 'null') then
          return null;
          -- call throw(CONCAT('Unsupported literal: ', v_token));
        end if;
        set is_rvalue := false;
        case 
          when v_state = 'object_begin' then set expect_state := 'string', scope_stack := concat('o', scope_stack), is_lvalue := true;
          when v_state = 'array_begin' then set expect_state := 'string,object_begin', scope_stack := concat('a', scope_stack), is_lvalue := false;
          when v_state = 'string' and is_lvalue then set expect_state := 'colon', xml_node := v_token;
          when v_state = 'colon' then set expect_state := 'string,number,alpha,object_begin,array_begin', is_lvalue := false;
          when FIND_IN_SET(v_state, 'string,number,alpha') and not is_lvalue then set expect_state := 'comma,object_end,array_end', is_rvalue := true;
          when v_state = 'object_end' then set expect_state := 'comma,object_end,array_end', scope_stack := substring(scope_stack, 2);
          when v_state = 'array_end' then set expect_state := 'comma,object_end,array_end', scope_stack := substring(scope_stack, 2);
          when v_state = 'comma' and left(scope_stack, 1) = 'o' then set expect_state := 'string', is_lvalue := true;
          when v_state = 'comma' and left(scope_stack, 1) = 'a' then set expect_state := 'string,object_begin', is_lvalue := false;
        end case;
        set xml_node := unquote(xml_node);
        if v_state = 'object_begin' then 
          if substring_index(xml_nodes, ',', 1) != '' then
            set xml := concat(xml, '<', substring_index(xml_nodes, ',', 1), '>');
          end if;
          set xml_nodes := concat(',', xml_nodes);
        end if;
        if v_state = 'string' and is_lvalue then
          if left(xml_nodes, 1) = ',' then
            set xml_nodes := concat(xml_node, xml_nodes);
          else
            set xml_nodes := concat(xml_node, substring(xml_nodes, locate(',', xml_nodes)));
          end if;
        end if;
        if is_rvalue then
          set xml := concat(xml, '<', xml_node, '>', encode_xml(unquote(v_token)), '</', xml_node, '>');
        end if;
        if v_state = 'object_end' then 
          set xml_nodes := substring(xml_nodes, locate(',', xml_nodes) + 1);
          if substring_index(xml_nodes, ',', 1) != '' then
            set xml := concat(xml, '</', substring_index(xml_nodes, ',', 1), '>');
          end if;
        end if;
    until 
        v_old_from = v_from
    end repeat;
    return xml;
end;
//

delimiter ;
-- 
-- Convert a LIKE expression to an RLIKE (REGEXP) expression
-- expression: a LIKE expression
--
-- example:
--
-- SELECT like_to_rlike('c_oun%')
-- Returns: '^c.oun.*$'
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS like_to_rlike $$
CREATE FUNCTION like_to_rlike(expression TEXT CHARSET utf8) RETURNS TEXT CHARSET utf8 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Convert a LIKE expression to an RLIKE expression'

begin
  set expression := REPLACE(expression, '.', '[.]');
  set expression := REPLACE(expression, '*', '[*]');
  set expression := REPLACE(expression, '_', '.');
  set expression := REPLACE(expression, '%', '.*');
  set expression := CONCAT('^', expression, '$');
  return expression;
end $$

DELIMITER ;
-- 
-- Return a qualified MySQL name (e.g. database name, table name, column name, ...) from given text.
-- 
-- Can be used for dynamic query generation by INFORMATION_SCHEMA, where names are unqualified.
--
-- Example:
--
-- SELECT mysql_qualify('film_actor') AS qualified;
-- Returns: '`film_actor`'
-- 
DELIMITER $$

DROP FUNCTION IF EXISTS mysql_qualify $$
CREATE FUNCTION mysql_qualify(name TINYTEXT CHARSET utf8) RETURNS TINYTEXT CHARSET utf8 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Return a qualified MySQL name from given text'

begin
  if name RLIKE '^`[^`]*`$' then
    return name;
  end if;
  return CONCAT('`', REPLACE(name, '`', '``'), '`');
end $$

DELIMITER ;
-- Outputs a prettified text message, one row per line in text
--

DELIMITER $$

DROP PROCEDURE IF EXISTS prettify_message $$
CREATE PROCEDURE prettify_message(title TINYTEXT CHARSET utf8, msg MEDIUMTEXT CHARSET utf8) 
NO SQL
SQL SECURITY INVOKER
COMMENT 'Outputs a prettified text message, one row per line in text'

main_body: begin
  declare query text charset utf8;
  
  if msg is null or msg = '' then
    leave main_body;
  end if;
  
  set @_prettify_message_text := msg;
  set @_prettify_message_num_rows := get_num_tokens(msg, '\n');
  set query := CONCAT('
    SELECT 
        split_token(@_prettify_message_text, \'\\n\', n) AS ', mysql_qualify(title), '
      FROM 
        numbers
      WHERE 
        numbers.n BETWEEN 1 AND @_prettify_message_num_rows
      ORDER BY n ASC;
    ');
  call exec_single(query);
  set @_prettify_message_text := NULL;
  set @_prettify_message_num_rows := NULL;
end $$

DELIMITER ;
-- 
-- Replaces characters in a given text with a given replace-text.
-- txt: input text
-- from_characters: a text consisting of characters to replace.
-- to_str: a string to plant in place of each occurance of a character from from_characters.
--   Can be of any length.
--
-- example:
--
-- SELECT replace_all('red, green, blue;', '; ,', '-') 
-- Returns: 'red--green--blue-'
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS replace_all $$
CREATE FUNCTION replace_all(txt TEXT CHARSET utf8, from_characters VARCHAR(1024) CHARSET utf8, to_str TEXT CHARSET utf8) RETURNS TEXT CHARSET utf8 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Replace any char in from_characters with to_str '

begin
  declare counter SMALLINT UNSIGNED DEFAULT 1;

  while counter <= CHAR_LENGTH(from_characters) do
    set txt := REPLACE(txt, SUBSTRING(from_characters, counter, 1), to_str);
    set counter := counter + 1;
  end while;
  return txt;
end $$

DELIMITER ;
-- 
-- Return substring by index in delimited text
-- txt: input string
-- delimiter: char or text by which to split txt
-- token_index: 1-based index of token in split string
--
-- example:
--
-- SELECT split_token('the quick brown fox', ' ', 3) AS token;
-- Returns: 'brown'
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS split_token $$
CREATE FUNCTION split_token(txt TEXT CHARSET utf8, delimiter_text VARCHAR(255) CHARSET utf8, token_index INT UNSIGNED) RETURNS TEXT CHARSET utf8 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Return substring by index in delimited text'

begin
  if CHAR_LENGTH(delimiter_text) = '' then
    return SUBSTRING(txt, token_index, 1);
  else
    return SUBSTRING_INDEX(SUBSTRING_INDEX(txt, delimiter_text, token_index), delimiter_text, -1);
  end if;
end $$

DELIMITER ;
-- 
-- Checks whether given text starts with given prefix.
-- Returns length of prefix if indeed text starts with it
-- Returns 0 when text does not start with prefix
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS starts_with $$
CREATE FUNCTION starts_with(txt TEXT CHARSET utf8, prefix TEXT CHARSET utf8)
RETURNS INT UNSIGNED
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Return substring by index in delimited text'

begin
  if left(txt, CHAR_LENGTH(prefix)) = prefix then
    return CHAR_LENGTH(prefix);
  end if;
  return 0;
end $$

DELIMITER ;
-- 
-- Strips URLs from given text, replacing them with an empty string.
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS strip_urls $$
CREATE FUNCTION strip_urls(txt TEXT CHARSET utf8) RETURNS TEXT CHARSET utf8 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Strips URLs from given text'

begin
  declare end_pos INT UNSIGNED DEFAULT 0;
  declare done TINYINT UNSIGNED DEFAULT 0;
  
  while ((@_strip_urls_url_pos := LOCATE('http://', txt)) > 0) do
    set end_pos := @_strip_urls_url_pos;
    while (SUBSTRING(txt, end_pos, 1) not in (' ', '\n', '\r', '<', '')) do
      set end_pos := end_pos + 1;
    end while;
    set txt := CONCAT(LEFT(txt, @_strip_urls_url_pos - 1), SUBSTRING(txt, end_pos));
  end while;
  while ((@_strip_urls_url_pos := LOCATE('https://', txt)) > 0) do
    set end_pos := @_strip_urls_url_pos;
    while (SUBSTRING(txt, end_pos, 1) not in (' ', '\n', '\r', '<', '')) do
      set end_pos := end_pos + 1;
    end while;
    set txt := CONCAT(LEFT(txt, @_strip_urls_url_pos - 1), SUBSTRING(txt, end_pos));
  end while;
  return txt;
end $$

DELIMITER ;
-- 
-- Outputs ordered result set of tokens of given text
-- 
-- txt: input string
-- delimiter_text: char or text by which to split txt
--
-- example:
--
-- CALL tokenize('the quick brown fox', ' ');
-- +---+-------+
-- | n | token |
-- +---+-------+
-- | 1 | the   |
-- | 2 | quick |
-- | 3 | brown |
-- | 4 | fox   |
-- +---+-------+
--

DELIMITER $$

DROP PROCEDURE IF EXISTS tokenize $$
CREATE PROCEDURE tokenize(txt TEXT CHARSET utf8, delimiter_text VARCHAR(255) CHARSET utf8) 
READS SQL DATA
SQL SECURITY INVOKER
COMMENT ''

begin
  declare num_tokens INT UNSIGNED DEFAULT get_num_tokens(txt, delimiter_text);  
  SELECT n, split_token(txt, delimiter_text, n) AS token FROM numbers WHERE n BETWEEN 1 AND num_tokens;
end $$

DELIMITER ;
-- 
-- Trim white space characters on both sides of text.
-- As opposed to the standard TRIM() function, which only trims
-- strict space characters (' '), trim_wspace() also trims new line, 
-- tab and backspace characters
--
-- example:
--
-- SELECT trim_wspace('\n a b c \n  ')
-- Returns: 'a b c'
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS trim_wspace $$
CREATE FUNCTION trim_wspace(txt TEXT CHARSET utf8) RETURNS TEXT CHARSET utf8 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Trim whitespace characters on both sides'

begin
  declare len INT UNSIGNED DEFAULT 0;
  declare done TINYINT UNSIGNED DEFAULT 0;
  if txt IS NULL then
    return txt;
  end if;
  while not done do
    set len := CHAR_LENGTH(txt);
    set txt = trim(' ' FROM txt);
    set txt = trim('\r' FROM txt);
    set txt = trim('\n' FROM txt);
    set txt = trim('\t' FROM txt);
    set txt = trim('\b' FROM txt);
    if CHAR_LENGTH(txt) = len then
      set done := 1;
    end if;
  end while;
  return txt;
end $$

DELIMITER ;
-- 
-- Unquotes a given text.
-- Removes leading and trailing quoting characters (one of: "'/)
-- Unquoting works only if both leading and trailing character are identical.
-- There is no nesting or sub-unquoting.
--
-- example:
--
-- SELECT unquote('\"saying\"') 
-- Returns: 'saying'
--

DELIMITER $$

DROP FUNCTION IF EXISTS unquote $$
CREATE FUNCTION unquote(txt TEXT CHARSET utf8) RETURNS TEXT CHARSET utf8 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Unquotes a given text'

begin
  declare quoting_char VARCHAR(1) CHARSET utf8;
  declare terminating_quote_escape_char VARCHAR(1) CHARSET utf8;
  declare current_pos INT UNSIGNED;
  declare end_quote_pos INT UNSIGNED;

  if CHAR_LENGTH(txt) < 2 then
    return txt;
  end if;
  
  set quoting_char := LEFT(txt, 1);
  if not quoting_char in ('''', '"', '`', '/') then
    return txt;
  end if;
  if txt in ('''''', '""', '``', '//') then
    return '';
  end if;
  
  set current_pos := 1;
  terminating_quote_loop: while current_pos > 0 do
    set current_pos := LOCATE(quoting_char, txt, current_pos + 1);
    if current_pos = 0 then
      -- No terminating quote
      return txt;
    end if;
    if SUBSTRING(txt, current_pos, 2) = REPEAT(quoting_char, 2) then
      set current_pos := current_pos + 1;
      iterate terminating_quote_loop;
    end if;
    set terminating_quote_escape_char := SUBSTRING(txt, current_pos - 1, 1);
    if (terminating_quote_escape_char = quoting_char) or (terminating_quote_escape_char = '\\') then
      -- This isn't really a quote end: the quote is escaped. 
      -- We do nothing; just a trivial assignment.
      iterate terminating_quote_loop;
    end if;
    -- Found terminating quote.
    leave terminating_quote_loop;
  end while;
  if current_pos = CHAR_LENGTH(txt) then
      return SUBSTRING(txt, 2, CHAR_LENGTH(txt) - 2);
    end if;
  return txt;
end $$

DELIMITER ;
-- 
-- Unwraps a given text from braces
-- Removes leading and trailing braces (round, square, curly)
-- Unwraps works only if both leading and trailing character are matching.
-- There is no nesting or sub-unwrapping.
--
-- example:
--
-- SELECT unwrap('{set}') 
-- Returns: 'set'
--

DELIMITER $$

DROP FUNCTION IF EXISTS unwrap $$
CREATE FUNCTION unwrap(txt TEXT CHARSET utf8) RETURNS TEXT CHARSET utf8 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Unwraps a given text from braces'

begin
  if CHAR_LENGTH(txt) < 2 then
    return txt;
  end if;
  if LEFT(txt, 1) = '{' AND RIGHT(txt, 1) = '}' then
    return SUBSTRING(txt, 2, CHAR_LENGTH(txt) - 2);
  end if;
  if LEFT(txt, 1) = '[' AND RIGHT(txt, 1) = ']' then
    return SUBSTRING(txt, 2, CHAR_LENGTH(txt) - 2);
  end if;
  if LEFT(txt, 1) = '(' AND RIGHT(txt, 1) = ')' then
    return SUBSTRING(txt, 2, CHAR_LENGTH(txt) - 2);
  end if;
  return txt;
end $$

DELIMITER ;
-- 
-- Checks whether the given string is a valid datetime.
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS _as_datetime $$
CREATE FUNCTION _as_datetime(txt TINYTEXT) RETURNS DATETIME
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Convert given text to DATETIME or NULL.'

BEGIN
  declare continue handler for SQLEXCEPTION return NULL; 
  RETURN (txt + interval 0 second);
END $$

DELIMITER ;
-- 
-- Returns DATE of easter day in given DATETIME's year
-- 
-- Example:
--
-- SELECT easter_day('2011-01-01');
-- Returns: '2011-04-24' (as DATE)
--

DELIMITER $$

DROP FUNCTION IF EXISTS easter_day $$
CREATE FUNCTION easter_day(dt DATETIME) RETURNS DATE
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Returns date of easter day for given year'

BEGIN
    DECLARE p_year    SMALLINT DEFAULT YEAR(dt);
    DECLARE a    SMALLINT DEFAULT p_year % 19;
    DECLARE b    SMALLINT DEFAULT p_year DIV 100;
    DECLARE c    SMALLINT DEFAULT p_year % 100;
    DECLARE d    SMALLINT DEFAULT b DIV 4;
    DECLARE e    SMALLINT DEFAULT b % 4;
    DECLARE f    SMALLINT DEFAULT (b + 8) DIV 25;
    DECLARE g    SMALLINT DEFAULT (b - f + 1) DIV 3;
    DECLARE h    SMALLINT DEFAULT (19*a + b - d - g + 15) % 30;
    DECLARE i    SMALLINT DEFAULT c DIV 4;
    DECLARE k    SMALLINT DEFAULT c % 4;
    DECLARE L    SMALLINT DEFAULT (32 + 2*e + 2*i - h - k) % 7;
    DECLARE m    SMALLINT DEFAULT (a + 11*h + 22*L) DIV 451;
    DECLARE v100 SMALLINT DEFAULT h + L - 7*m + 114;
        
    RETURN STR_TO_DATE(
                CONCAT(
                    p_year
                ,   '-'
                ,    v100 DIV 31
                ,   '-'
                ,   (v100 % 31) + 1
                )
            ,   '%Y-%c-%e'
            );
END $$

DELIMITER ;
-- 
-- Checks whether the given string is a valid datetime.
-- 

DELIMITER $$

DROP FUNCTION IF EXISTS is_datetime $$
CREATE FUNCTION is_datetime(txt TINYTEXT) RETURNS TINYINT UNSIGNED
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Checks whether given txt is a valid DATETIME.'

BEGIN
  RETURN (_as_datetime(txt) is not null);
END $$

DELIMITER ;
-- 
-- Returns DATETIME of beginning of round hour of given DATETIME.
-- 
-- Example:
--
-- SELECT start_of_hour('2011-03-24 11:17:08');
-- Returns: '2011-03-24 11:00:00' (as DATETIME)
--

DELIMITER $$

DROP FUNCTION IF EXISTS start_of_hour $$
CREATE FUNCTION start_of_hour(dt DATETIME) RETURNS DATETIME
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Returns DATETIME of beginning of round hour of given DATETIME.'

BEGIN
  RETURN DATE(dt) + INTERVAL HOUR(dt) HOUR;
END $$

DELIMITER ;
-- 
-- Returns first day of month of given datetime, as DATE object
-- 
-- Example:
--
-- SELECT start_of_month('2011-03-24 11:13:42');
-- Returns: '2011-03-01' (as DATE)
--

DELIMITER $$

DROP FUNCTION IF EXISTS start_of_month $$
CREATE FUNCTION start_of_month(dt DATETIME) RETURNS DATE 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Returns first day of month of given datetime, as DATE object'

BEGIN
  RETURN DATE(dt) - INTERVAL (DAYOFMONTH(dt) - 1) DAY;
END $$

DELIMITER ;
-- 
-- Returns first day of quarter of given datetime, as DATE object
-- 
-- Example:
--
-- SELECT start_of_quarter('2010-08-24 11:13:42');
-- Returns: '2010-07-01' (as DATE)
--

DELIMITER $$

DROP FUNCTION IF EXISTS start_of_quarter $$
CREATE FUNCTION start_of_quarter(dt DATETIME) RETURNS DATE 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Returns first day of quarter of given datetime, as DATE object'

BEGIN
  RETURN DATE(dt) - INTERVAL (MONTH(dt) -1) MONTH - INTERVAL (DAYOFMONTH(dt) - 1) DAY + INTERVAL (QUARTER(dt) - 1) QUARTER;
END $$

DELIMITER ;
-- 
-- Returns first day of week of given datetime (i.e. start of Monday), as DATE object
-- 
-- Example:
--
-- SELECT start_of_week('2011-03-24 11:13:42');
-- Returns: '2011-03-21' (which is Monday, as DATE)
--

DELIMITER $$

DROP FUNCTION IF EXISTS start_of_week $$
CREATE FUNCTION start_of_week(dt DATETIME) RETURNS DATE 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Returns Monday-based first day of week of given datetime'

BEGIN
  RETURN DATE(dt) - INTERVAL WEEKDAY(dt) DAY;
END $$

DELIMITER ;
-- 
-- Returns first day of week, Sunday based, of given datetime, as DATE object
-- 
-- Example:
--
-- SELECT start_of_week_sunday('2011-03-24 11:13:42');
-- Returns: '2011-03-20' (which is Sunday, as DATE)
--

DELIMITER $$

DROP FUNCTION IF EXISTS start_of_week_sunday $$
CREATE FUNCTION start_of_week_sunday(dt DATETIME) RETURNS DATE 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Returns Sunday-based first day of week of given datetime'

BEGIN
  RETURN DATE(dt) - INTERVAL (WEEKDAY(dt) + 1) DAY;
END $$

DELIMITER ;


-- 
-- Returns first day of year of given datetime, as DATE object
-- 
-- Example:
--
-- SELECT start_of_year('2011-03-24 11:13:42');
-- Returns: '2011-01-01' (as DATE)
--

DELIMITER $$

DROP FUNCTION IF EXISTS start_of_year $$
CREATE FUNCTION start_of_year(dt DATETIME) RETURNS DATE 
DETERMINISTIC
NO SQL
SQL SECURITY INVOKER
COMMENT 'Returns first day of month of given datetime, as DATE object'

BEGIN
  RETURN DATE(dt) - INTERVAL (MONTH(dt) -1) MONTH - INTERVAL (DAYOFMONTH(dt) - 1) DAY;
END $$

DELIMITER ;
-- 
-- Unique keys: listing of all unique keys aith aggregated column names and additional data
-- 
CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW _unique_keys AS
  SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    INDEX_NAME,
    COUNT(*) AS COUNT_COLUMN_IN_INDEX,
    IF(SUM(NULLABLE = 'YES') > 0, 1, 0) AS has_nullable,
    IF(INDEX_NAME = 'PRIMARY', 1, 0) AS is_primary,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX ASC) AS COLUMN_NAMES,
    SUBSTRING_INDEX(GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX ASC), ',', 1) AS FIRST_COLUMN_NAME
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE NON_UNIQUE=0
  GROUP BY TABLE_SCHEMA, TABLE_NAME, INDEX_NAME
;

-- 
-- Candidate keys: listing of prioritized candidate keys: keys which are UNIQUE, by order of best-use. 
-- 

CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW candidate_keys AS
SELECT
  COLUMNS.TABLE_SCHEMA AS table_schema,
  COLUMNS.TABLE_NAME AS table_name,
  _unique_keys.INDEX_NAME AS index_name,
  _unique_keys.has_nullable AS has_nullable,
  _unique_keys.is_primary AS is_primary,
  _unique_keys.COLUMN_NAMES AS column_names,
  _unique_keys.COUNT_COLUMN_IN_INDEX AS count_column_in_index,
  COLUMNS.DATA_TYPE AS data_type,
  COLUMNS.CHARACTER_SET_NAME AS character_set_name,
  (CASE IFNULL(CHARACTER_SET_NAME, '')
      WHEN '' THEN 0
      ELSE 1
  END << 20
  )
  + (CASE LOWER(DATA_TYPE)
    WHEN 'tinyint' THEN 0
    WHEN 'smallint' THEN 1
    WHEN 'int' THEN 2
    WHEN 'timestamp' THEN 3
    WHEN 'bigint' THEN 4
    WHEN 'datetime' THEN 5
    ELSE 9
  END << 16
  ) + (COUNT_COLUMN_IN_INDEX << 0
  ) AS candidate_key_rank_in_table  
FROM 
  INFORMATION_SCHEMA.COLUMNS 
  INNER JOIN _unique_keys ON (
    COLUMNS.TABLE_SCHEMA = _unique_keys.TABLE_SCHEMA AND
    COLUMNS.TABLE_NAME = _unique_keys.TABLE_NAME AND
    COLUMNS.COLUMN_NAME = _unique_keys.FIRST_COLUMN_NAME
  )
ORDER BY   
  COLUMNS.TABLE_SCHEMA, COLUMNS.TABLE_NAME, candidate_key_rank_in_table
;


-- 
-- Candidate keys: listing of prioritized candidate keys: keys which are UNIQUE, by order of best-use. 
-- 

CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW candidate_keys_recommended AS
SELECT
  table_schema,
  table_name,
  SUBSTRING_INDEX(GROUP_CONCAT(index_name ORDER BY candidate_key_rank_in_table ASC), ',', 1) AS recommended_index_name,
  CAST(SUBSTRING_INDEX(GROUP_CONCAT(has_nullable ORDER BY candidate_key_rank_in_table ASC), ',', 1) AS UNSIGNED INTEGER) AS has_nullable,
  CAST(SUBSTRING_INDEX(GROUP_CONCAT(is_primary ORDER BY candidate_key_rank_in_table ASC), ',', 1) AS UNSIGNED INTEGER) AS is_primary,
  CAST(SUBSTRING_INDEX(GROUP_CONCAT(count_column_in_index ORDER BY candidate_key_rank_in_table ASC), ',', 1) AS UNSIGNED INTEGER) AS count_column_in_index,
  SUBSTRING_INDEX(GROUP_CONCAT(column_names ORDER BY candidate_key_rank_in_table ASC SEPARATOR '\n'), '\n', 1) AS column_names
FROM 
  candidate_keys
GROUP BY
  table_schema, table_name
ORDER BY   
  table_schema, table_name
;
-- 
-- InnoDB tables where no PRIMARY KEY is defined
-- 
CREATE OR REPLACE
ALGORITHM = UNDEFINED
SQL SECURITY INVOKER
VIEW no_pk_innodb_tables AS
  SELECT 
    TABLES.TABLE_SCHEMA,
    TABLES.TABLE_NAME,
    TABLES.ENGINE,
    GROUP_CONCAT(
      IF(CONSTRAINT_TYPE='UNIQUE', CONSTRAINT_NAME, NULL)
      ) AS candidate_keys
  FROM 
    INFORMATION_SCHEMA.TABLES 
    LEFT JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS USING(TABLE_SCHEMA, TABLE_NAME)
  WHERE 
    TABLES.ENGINE='InnoDB'
  GROUP BY
    TABLES.TABLE_SCHEMA,
    TABLES.TABLE_NAME,
    TABLES.ENGINE
  HAVING
    IFNULL(
      SUM(CONSTRAINT_TYPE='PRIMARY KEY'),
      0
    ) = 0
;

-- 
-- Redundant indexes: indexes which are made redundant (or duplicate) by other (dominant) keys. 
-- 

CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW _flattened_keys AS
  SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    INDEX_NAME,
    MAX(NON_UNIQUE) AS non_unique,
    MAX(IF(SUB_PART IS NULL, 0, 1)) AS subpart_exists,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS index_columns
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE
    INDEX_TYPE='BTREE'
    AND TABLE_SCHEMA NOT IN ('mysql', 'INFORMATION_SCHEMA', 'PERFORMANCE_SCHEMA')
  GROUP BY
    TABLE_SCHEMA, TABLE_NAME, INDEX_NAME
;

-- 
-- Redundant indexes: indexes which are made redundant (or duplicate) by other (dominant) keys. 
-- 
CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW redundant_keys AS
  SELECT
    redundant_keys.table_schema,
    redundant_keys.table_name,
    redundant_keys.index_name AS redundant_index_name,
    redundant_keys.index_columns AS redundant_index_columns,
    redundant_keys.non_unique AS redundant_index_non_unique,
    dominant_keys.index_name AS dominant_index_name,
    dominant_keys.index_columns AS dominant_index_columns,
    dominant_keys.non_unique AS dominant_index_non_unique,
    IF(redundant_keys.subpart_exists OR dominant_keys.subpart_exists, 1 ,0) AS subpart_exists,
    CONCAT(
      'ALTER TABLE `', redundant_keys.table_schema, '`.`', redundant_keys.table_name, '` DROP INDEX `', redundant_keys.index_name, '`'
      ) AS sql_drop_index
  FROM
    _flattened_keys AS redundant_keys
    INNER JOIN _flattened_keys AS dominant_keys
    USING (TABLE_SCHEMA, TABLE_NAME)
  WHERE
    redundant_keys.index_name != dominant_keys.index_name
    AND (
      ( 
        /* Identical columns */
        (redundant_keys.index_columns = dominant_keys.index_columns)
        AND (
          (redundant_keys.non_unique > dominant_keys.non_unique)
          OR (redundant_keys.non_unique = dominant_keys.non_unique 
          	AND IF(redundant_keys.index_name='PRIMARY', '', redundant_keys.index_name) > IF(dominant_keys.index_name='PRIMARY', '', dominant_keys.index_name)
          )
        )
      )
      OR
      ( 
        /* Non-unique prefix columns */
        LOCATE(CONCAT(redundant_keys.index_columns, ','), dominant_keys.index_columns) = 1
        AND redundant_keys.non_unique = 1
      )
      OR
      ( 
        /* Unique prefix columns */
        LOCATE(CONCAT(dominant_keys.index_columns, ','), redundant_keys.index_columns) = 1
        AND dominant_keys.non_unique = 0
      )
    )
;
-- 
-- Generate ALTER TABLE statements per table, with engine and create options
-- 
CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW sql_alter_table AS
  SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    ENGINE,
    CONCAT(
      'ALTER TABLE `', TABLE_SCHEMA, '`.`', TABLE_NAME, 
      '` ENGINE=', ENGINE, ' ',
      IF(CREATE_OPTIONS='partitioned', '', CREATE_OPTIONS)
    ) AS alter_statement
  FROM 
    INFORMATION_SCHEMA.TABLES
  WHERE
    TABLE_SCHEMA NOT IN ('mysql', 'INFORMATION_SCHEMA', 'performance_schema')
    AND ENGINE IS NOT NULL
;

-- 
-- Generate 'ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY ... / DROP FOREIGN KEY' statement pairs
-- 
CREATE OR REPLACE
ALGORITHM = UNDEFINED
SQL SECURITY INVOKER
VIEW sql_foreign_keys AS
  SELECT 
    KEY_COLUMN_USAGE.TABLE_SCHEMA,
    KEY_COLUMN_USAGE.TABLE_NAME,
    KEY_COLUMN_USAGE.CONSTRAINT_NAME,
    CONCAT(
      'ALTER TABLE `', KEY_COLUMN_USAGE.TABLE_SCHEMA, '`.`', KEY_COLUMN_USAGE.TABLE_NAME, 
      '` DROP FOREIGN KEY `', KEY_COLUMN_USAGE.CONSTRAINT_NAME, '`'
    ) AS drop_statement,
    CONCAT(
      'ALTER TABLE `', KEY_COLUMN_USAGE.TABLE_SCHEMA, '`.`', KEY_COLUMN_USAGE.TABLE_NAME, 
      '` ADD CONSTRAINT `', KEY_COLUMN_USAGE.CONSTRAINT_NAME, 
      '` FOREIGN KEY (', GROUP_CONCAT('`', KEY_COLUMN_USAGE.COLUMN_NAME, '`' ORDER BY KEY_COLUMN_USAGE.ORDINAL_POSITION), ')', 
      ' REFERENCES `', KEY_COLUMN_USAGE.REFERENCED_TABLE_SCHEMA, '`.`', KEY_COLUMN_USAGE.REFERENCED_TABLE_NAME, 
      '` (', GROUP_CONCAT('`', KEY_COLUMN_USAGE.REFERENCED_COLUMN_NAME, '`' ORDER BY KEY_COLUMN_USAGE.ORDINAL_POSITION), ')',
      ' ON DELETE ', MIN(REFERENTIAL_CONSTRAINTS.DELETE_RULE), 
      ' ON UPDATE ', MIN(REFERENTIAL_CONSTRAINTS.UPDATE_RULE)
    ) AS create_statement
  FROM 
    INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
    INNER JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS USING(CONSTRAINT_SCHEMA, CONSTRAINT_NAME)
  WHERE 
    KEY_COLUMN_USAGE.REFERENCED_TABLE_SCHEMA IS NOT NULL
  GROUP BY
    KEY_COLUMN_USAGE.TABLE_SCHEMA, KEY_COLUMN_USAGE.TABLE_NAME, KEY_COLUMN_USAGE.CONSTRAINT_NAME, KEY_COLUMN_USAGE.REFERENCED_TABLE_SCHEMA, KEY_COLUMN_USAGE.REFERENCED_TABLE_NAME
;

-- 
-- 
-- 

CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW _sql_range_partitions_summary AS
  select 
    table_schema, 
    table_name, 
    COUNT(*) as count_partitions,
    substring_index(group_concat(PARTITION_NAME order by PARTITION_ORDINAL_POSITION), ',', 1) as first_partition_name,
    substring_index(group_concat(IF((PARTITION_ORDINAL_POSITION = 1 and PARTITION_DESCRIPTION = 0), NULL, PARTITION_NAME) order by PARTITION_ORDINAL_POSITION), ',', 1) as first_partition_name_skipping_zero,    
    substring_index(group_concat(PARTITION_NAME order by PARTITION_ORDINAL_POSITION), ',', -1) as last_partition_name,
    SUM(PARTITION_DESCRIPTION = 'MAXVALUE') as has_maxvalue,
    MAX(IF(PARTITION_DESCRIPTION = 'MAXVALUE', PARTITION_NAME, NULL)) as maxvalue_partition_name,
    MAX(IF(PARTITION_DESCRIPTION != 'MAXVALUE', 
      IFNULL(_as_datetime(unquote(PARTITION_DESCRIPTION)), CAST(PARTITION_DESCRIPTION AS SIGNED)), 
      NULL)
      ) as max_partition_description
  from 
    information_schema.partitions
  where 
    PARTITION_METHOD IN ('RANGE', 'RANGE COLUMNS')
  group by
    table_schema, table_name
;

-- 
-- Diff all values.
-- Ignore first partition if it's "LESS THAN 0" as this is a common use case and is not part of a constant interval.
-- 

CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW _sql_range_partitions_base AS
  select 
    p0.TABLE_SCHEMA, 
    p0.table_name, 
    unquote(p0.PARTITION_DESCRIPTION) as unquoted_description,
    p0.PARTITION_DESCRIPTION >= TO_DAYS('1000-01-01') as valid_from_days,
    p1.PARTITION_DESCRIPTION - p0.PARTITION_DESCRIPTION as diff,
    TIMESTAMPDIFF(DAY, _as_datetime(unquote(p0.PARTITION_DESCRIPTION)), _as_datetime(unquote(p1.PARTITION_DESCRIPTION))) AS diff_day,
    TIMESTAMPDIFF(WEEK, _as_datetime(unquote(p0.PARTITION_DESCRIPTION)), _as_datetime(unquote(p1.PARTITION_DESCRIPTION))) AS diff_week,
    TIMESTAMPDIFF(MONTH, _as_datetime(unquote(p0.PARTITION_DESCRIPTION)), _as_datetime(unquote(p1.PARTITION_DESCRIPTION))) AS diff_month,
    TIMESTAMPDIFF(YEAR, _as_datetime(unquote(p0.PARTITION_DESCRIPTION)), _as_datetime(unquote(p1.PARTITION_DESCRIPTION))) AS diff_year,
    TIMESTAMPDIFF(DAY, _as_datetime(FROM_UNIXTIME(p0.PARTITION_DESCRIPTION)), _as_datetime(FROM_UNIXTIME(p1.PARTITION_DESCRIPTION))) AS diff_day_from_unixtime,
    TIMESTAMPDIFF(WEEK, _as_datetime(FROM_UNIXTIME(p0.PARTITION_DESCRIPTION)), _as_datetime(FROM_UNIXTIME(p1.PARTITION_DESCRIPTION))) AS diff_week_from_unixtime,
    TIMESTAMPDIFF(MONTH, _as_datetime(FROM_UNIXTIME(p0.PARTITION_DESCRIPTION)), _as_datetime(FROM_UNIXTIME(p1.PARTITION_DESCRIPTION))) AS diff_month_from_unixtime,
    TIMESTAMPDIFF(YEAR, _as_datetime(FROM_UNIXTIME(p0.PARTITION_DESCRIPTION)), _as_datetime(FROM_UNIXTIME(p1.PARTITION_DESCRIPTION))) AS diff_year_from_unixtime,
    TIMESTAMPDIFF(DAY, _as_datetime(FROM_DAYS(p0.PARTITION_DESCRIPTION)), _as_datetime(FROM_DAYS(p1.PARTITION_DESCRIPTION))) AS diff_day_from_days,
    TIMESTAMPDIFF(WEEK, _as_datetime(FROM_DAYS(p0.PARTITION_DESCRIPTION)), _as_datetime(FROM_DAYS(p1.PARTITION_DESCRIPTION))) AS diff_week_from_days,
    TIMESTAMPDIFF(MONTH, _as_datetime(FROM_DAYS(p0.PARTITION_DESCRIPTION)), _as_datetime(FROM_DAYS(p1.PARTITION_DESCRIPTION))) AS diff_month_from_days,
    TIMESTAMPDIFF(YEAR, _as_datetime(FROM_DAYS(p0.PARTITION_DESCRIPTION)), _as_datetime(FROM_DAYS(p1.PARTITION_DESCRIPTION))) AS diff_year_from_days
  from 
    information_schema.partitions p0 
    join information_schema.partitions p1 on (p0.table_schema=p1.table_schema and p0.table_name=p1.table_name and p0.PARTITION_ORDINAL_POSITION = p1.PARTITION_ORDINAL_POSITION-1)
  where 
    p0.PARTITION_METHOD IN ('RANGE', 'RANGE COLUMNS')
    and p1.PARTITION_DESCRIPTION != 'MAXVALUE'
    and not (p0.PARTITION_ORDINAL_POSITION = 1 and p0.PARTITION_DESCRIPTION = 0)
;

-- 
-- 
-- 

CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW _sql_range_partitions_diff AS
  select
    table_schema,
    table_name,
    if(count(distinct(diff)) = 1, min(diff), 0) as diff, 
    if(count(distinct(diff_day)) = 1, min(diff_day), 0) as diff_day, 
    if(count(distinct(diff_week)) = 1, min(diff_week), 0) as diff_week, 
    if(count(distinct(diff_month)) = 1, min(diff_month), 0) as diff_month, 
    if(count(distinct(diff_year)) = 1, min(diff_year), 0) as diff_year, 
    if(count(distinct(diff_day_from_unixtime)) = 1, min(diff_day_from_unixtime), 0) as diff_day_from_unixtime, 
    if(count(distinct(diff_week_from_unixtime)) = 1, min(diff_week_from_unixtime), 0) as diff_week_from_unixtime, 
    if(count(distinct(diff_month_from_unixtime)) = 1, min(diff_month_from_unixtime), 0) as diff_month_from_unixtime, 
    if(count(distinct(diff_year_from_unixtime)) = 1, min(diff_year_from_unixtime), 0) as diff_year_from_unixtime, 
    if((count(distinct(diff_day_from_days)) = 1) and min(valid_from_days), min(diff_day_from_days), 0) as diff_day_from_days, 
    if((count(distinct(diff_week_from_days)) = 1) and min(valid_from_days), min(diff_week_from_days), 0) as diff_week_from_days, 
    if((count(distinct(diff_month_from_days)) = 1) and min(valid_from_days), min(diff_month_from_days), 0) as diff_month_from_days, 
    if((count(distinct(diff_year_from_days)) = 1) and min(valid_from_days), min(diff_year_from_days), 0) as diff_year_from_days
  from
    _sql_range_partitions_base
  group by
    table_schema, table_name
;


-- 
-- 
-- 

CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW _sql_range_partitions_analysis AS
  select
    _sql_range_partitions_summary.*,
    substring_index(case
      when diff_year_from_unixtime != 0 then unix_timestamp(from_unixtime(max_partition_description) + interval diff_year_from_unixtime year)
      when diff_month_from_unixtime != 0 then unix_timestamp(from_unixtime(max_partition_description) + interval diff_month_from_unixtime month)
      when diff_week_from_unixtime != 0 then unix_timestamp(from_unixtime(max_partition_description) + interval diff_week_from_unixtime week)
      when diff_day_from_unixtime != 0 then unix_timestamp(from_unixtime(max_partition_description) + interval diff_day_from_unixtime day)
      when diff_year_from_days != 0 then to_days(from_days(max_partition_description) + interval diff_year_from_days year)
      when diff_month_from_days != 0 then to_days(from_days(max_partition_description) + interval diff_month_from_days month)
      when diff_week_from_days != 0 then to_days(from_days(max_partition_description) + interval diff_week_from_days week)
      when diff_day_from_days != 0 then to_days(from_days(max_partition_description) + interval diff_day_from_days day)
      when diff_year != 0 then max_partition_description + interval diff_year year
      when diff_month != 0 then max_partition_description + interval diff_month month
      when diff_week != 0 then max_partition_description + interval diff_week week
      when diff_day != 0 then max_partition_description + interval diff_day day
      when diff != 0 then max_partition_description + diff
      else NULL
    end, '.', 1) as next_partition_description,
    substring_index(case
      when diff_year_from_unixtime != 0 then (from_unixtime(max_partition_description) + interval diff_year_from_unixtime year)
      when diff_month_from_unixtime != 0 then (from_unixtime(max_partition_description) + interval diff_month_from_unixtime month)
      when diff_week_from_unixtime != 0 then (from_unixtime(max_partition_description) + interval diff_week_from_unixtime week)
      when diff_day_from_unixtime != 0 then (from_unixtime(max_partition_description) + interval diff_day_from_unixtime day)
      when diff_year_from_days != 0 then (from_days(max_partition_description) + interval diff_year_from_days year)
      when diff_month_from_days != 0 then (from_days(max_partition_description) + interval diff_month_from_days month)
      when diff_week_from_days != 0 then (from_days(max_partition_description) + interval diff_week_from_days week)
      when diff_day_from_days != 0 then (from_days(max_partition_description) + interval diff_day_from_days day)
      when diff_year != 0 then max_partition_description + interval diff_year year
      when diff_month != 0 then max_partition_description + interval diff_month month
      when diff_week != 0 then max_partition_description + interval diff_week week
      when diff_day != 0 then max_partition_description + interval diff_day day
      when diff != 0 then max_partition_description + diff
      else NULL
    end, '.', 1) as next_partition_human_description
  from
    _sql_range_partitions_diff
    join _sql_range_partitions_summary using (table_schema, table_name)
;


-- 
-- 
-- 

CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW _sql_range_partitions_beautified AS
  select
    *,
    CONCAT('p_', IFNULL(DATE_FORMAT(_as_datetime(next_partition_human_description), '%Y%m%d%H%i%s'), next_partition_human_description)) as next_partition_name,
    (_as_datetime(next_partition_human_description) is not null) as next_partition_human_description_is_datetime,
    IFNULL(CONCAT(' /* ', _as_datetime(next_partition_human_description), ' */ '), '') as next_partition_human_description_comment
  from
    _sql_range_partitions_analysis
;

-- 
-- Generate SQL statements for managing range partitions
-- Generates DROP/ADD/REORGANIZE statements which drops oldest
-- partition, as well as creating/adding next partition, reorganizing if required.
-- 

CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW sql_range_partitions AS
  select
    table_schema,
    table_name,
    count_partitions,
    CONCAT('alter table ', mysql_qualify(table_schema), '.', mysql_qualify(table_name), ' drop partition ', mysql_qualify(first_partition_name_skipping_zero)) as sql_drop_first_partition,
    IF (has_maxvalue,
      CONCAT(
        'alter table ', mysql_qualify(table_schema), '.', mysql_qualify(table_name), 
        ' reorganize partition ', mysql_qualify(last_partition_name), 
        ' into (partition ', mysql_qualify(next_partition_name), ' values less than (', IF(is_datetime(next_partition_description), quote(next_partition_description), next_partition_description), 
        ')', next_partition_human_description_comment, ', partition p_maxvalue values less than MAXVALUE', ')'),
      CONCAT('alter table ', mysql_qualify(table_schema), '.', mysql_qualify(table_name), 
        ' add partition (partition ', mysql_qualify(next_partition_name), ' values less than (', IF(is_datetime(next_partition_description), quote(next_partition_description), next_partition_description), ')', next_partition_human_description_comment, ')')
      ) as sql_add_next_partition
  from
    _sql_range_partitions_beautified
;
-- 
-- Tables' charsets and collations
-- 
CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW table_charset AS
  SELECT 
    TABLE_SCHEMA, 
    TABLE_NAME, 
    CHARACTER_SET_NAME, 
    TABLE_COLLATION
  FROM 
    INFORMATION_SCHEMA.TABLES
    INNER JOIN INFORMATION_SCHEMA.COLLATION_CHARACTER_SET_APPLICABILITY 
      ON (TABLES.TABLE_COLLATION = COLLATION_CHARACTER_SET_APPLICABILITY.COLLATION_NAME)
  WHERE 
    TABLE_SCHEMA NOT IN ('mysql', 'INFORMATION_SCHEMA', 'performance_schema')
;
-- 
-- Textual columns charsets & collations
-- 
CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW text_columns AS
  SELECT 
    TABLE_SCHEMA, 
    TABLE_NAME, 
    COLUMN_NAME, 
    COLUMN_TYPE,
    CHARACTER_SET_NAME, 
    COLLATION_NAME
  FROM 
    INFORMATION_SCHEMA.COLUMNS
  WHERE 
    TABLE_SCHEMA NOT IN ('mysql', 'INFORMATION_SCHEMA', 'performance_schema')
    AND CHARACTER_SET_NAME IS NOT NULL
    AND DATA_TYPE != 'enum'
    AND DATA_TYPE != 'set'
;
-- 
-- AUTO_INCREMENT columns and their capacity
-- 
CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW auto_increment_columns AS
  SELECT 
    TABLE_SCHEMA, 
    TABLE_NAME, 
    COLUMN_NAME, 
    DATA_TYPE,
    COLUMN_TYPE,
    (LOCATE('unsigned', COLUMN_TYPE) = 0) AS is_signed,
    (LOCATE('unsigned', COLUMN_TYPE) > 0) AS is_unsigned,
    (
      CASE DATA_TYPE
        WHEN 'tinyint' THEN 255
        WHEN 'smallint' THEN 65535
        WHEN 'mediumint' THEN 16777215
        WHEN 'int' THEN 4294967295
        WHEN 'bigint' THEN 18446744073709551615
      END >> IF(LOCATE('unsigned', COLUMN_TYPE) > 0, 0, 1)
    ) AS max_value,
    AUTO_INCREMENT,
    AUTO_INCREMENT / (
      CASE DATA_TYPE
        WHEN 'tinyint' THEN 255
        WHEN 'smallint' THEN 65535
        WHEN 'mediumint' THEN 16777215
        WHEN 'int' THEN 4294967295
        WHEN 'bigint' THEN 18446744073709551615
      END >> IF(LOCATE('unsigned', COLUMN_TYPE) > 0, 0, 1)
    ) AS auto_increment_ratio
  FROM 
    INFORMATION_SCHEMA.COLUMNS
    INNER JOIN INFORMATION_SCHEMA.TABLES USING (TABLE_SCHEMA, TABLE_NAME)
  WHERE 
    TABLE_SCHEMA NOT IN ('mysql', 'INFORMATION_SCHEMA', 'performance_schema')
    AND TABLE_TYPE='BASE TABLE'
    AND EXTRA='auto_increment'
;
-- 
-- Dataset size per engine
-- 
CREATE OR REPLACE
ALGORITHM = UNDEFINED
SQL SECURITY INVOKER
VIEW data_size_per_engine AS
  SELECT 
    ENGINE, 
    COUNT(*) AS count_tables,
    SUM(DATA_LENGTH) AS data_size,
    SUM(INDEX_LENGTH) AS index_size,
    SUM(DATA_LENGTH+INDEX_LENGTH) AS total_size,
    SUBSTRING_INDEX(GROUP_CONCAT(CONCAT('`', TABLE_SCHEMA, '`.`', TABLE_NAME, '`') ORDER BY DATA_LENGTH+INDEX_LENGTH DESC), ',', 1) AS largest_table,
    MAX(DATA_LENGTH+INDEX_LENGTH) AS largest_table_size
  FROM 
    INFORMATION_SCHEMA.TABLES
  WHERE 
    TABLE_SCHEMA NOT IN ('INFORMATION_SCHEMA', 'performance_schema')
    AND ENGINE IS NOT NULL
  GROUP BY 
    ENGINE
;
-- 
-- Dataset size per schema
-- 
CREATE OR REPLACE
ALGORITHM = UNDEFINED
SQL SECURITY INVOKER
VIEW data_size_per_schema AS
  SELECT 
    TABLE_SCHEMA, 
    SUM(TABLE_TYPE = 'BASE TABLE') AS count_tables,
    SUM(TABLE_TYPE = 'VIEW') AS count_views,
    COUNT(DISTINCT ENGINE) AS distinct_engines,
    SUM(DATA_LENGTH) AS data_size,
    SUM(INDEX_LENGTH) AS index_size,
    SUM(DATA_LENGTH+INDEX_LENGTH) AS total_size,
    SUBSTRING_INDEX(GROUP_CONCAT(IF(TABLE_TYPE = 'BASE TABLE', TABLE_NAME, NULL) ORDER BY DATA_LENGTH+INDEX_LENGTH DESC), ',', 1) AS largest_table,
    MAX(DATA_LENGTH+INDEX_LENGTH) AS largest_table_size
  FROM 
    INFORMATION_SCHEMA.TABLES
  WHERE 
    TABLE_SCHEMA NOT IN ('INFORMATION_SCHEMA', 'performance_schema')
  GROUP BY 
    TABLE_SCHEMA
;

-- 
-- Complement INFORMATION_SCHEMA.ROUTINES with missing param_list    
-- 

CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW routines AS
  SELECT 
    ROUTINES.*, proc.param_list
  FROM
    INFORMATION_SCHEMA.ROUTINES
    JOIN mysql.proc ON (db = ROUTINE_SCHEMA and name = ROUTINE_NAME and type = ROUTINE_TYPE)
;
-- 
-- General metadata/status of common_schema
-- 
CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW status AS
  select 
    max(if(attribute_name = 'project_name', attribute_value, null)) as project_name,
    max(if(attribute_name = 'version', attribute_value, null)) as version,
    max(if(attribute_name = 'revision', attribute_value, null)) as revision,
    max(if(attribute_name = 'install_time', attribute_value, null)) as install_time,
    max(if(attribute_name = 'install_success', attribute_value, null)) as install_success,    
    max(if(attribute_name = 'base_components_installed', attribute_value, null)) as base_components_installed,    
    max(if(attribute_name = 'innodb_plugin_components_installed', attribute_value, null)) as innodb_plugin_components_installed,    
    max(if(attribute_name = 'percona_server_components_installed', attribute_value, null)) as percona_server_components_installed,    
    max(if(attribute_name = 'install_mysql_version', attribute_value, null)) as install_mysql_version,
    max(if(attribute_name = 'install_sql_mode', attribute_value, null)) as install_sql_mode
  from
    metadata
;
-- 
-- (Internal use): sample of GLOBAL_STATUS with time delay
-- 
CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW _global_status_sleep AS
  (
    SELECT 
      VARIABLE_NAME,
      VARIABLE_VALUE 
    FROM 
      INFORMATION_SCHEMA.GLOBAL_STATUS
  )
  UNION ALL
  (
    SELECT 
      '' AS VARIABLE_NAME, 
      SLEEP(10) 
    FROM DUAL
  )
;


-- 
-- Status variables difference over time, with interpolation and extrapolation per time unit  
-- 
CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW global_status_diff AS
  SELECT 
    LOWER(gs0.VARIABLE_NAME) AS variable_name,
    gs0.VARIABLE_VALUE AS variable_value_0,
    gs1.VARIABLE_VALUE AS variable_value_1,
    (gs1.VARIABLE_VALUE - gs0.VARIABLE_VALUE) AS variable_value_diff,
    (gs1.VARIABLE_VALUE - gs0.VARIABLE_VALUE) / 10 AS variable_value_psec,
    (gs1.VARIABLE_VALUE - gs0.VARIABLE_VALUE) * 60 / 10 AS variable_value_pminute
  FROM
    _global_status_sleep AS gs0
    JOIN INFORMATION_SCHEMA.GLOBAL_STATUS gs1 USING (VARIABLE_NAME)
;

-- 
-- Status variables difference over time, with spaces where zero diff encountered  
-- 
CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW global_status_diff_clean AS
  SELECT 
    variable_name,
    variable_value_0,
    variable_value_1,
    IF(variable_value_diff = 0, '', variable_value_diff) AS variable_value_diff,
    IF(variable_value_diff = 0, '', variable_value_psec) AS variable_value_psec,
    IF(variable_value_diff = 0, '', variable_value_pminute) AS variable_value_pminute
  FROM
    global_status_diff
;

-- 
-- Status variables difference over time, only nonzero findings listed
-- 
CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW global_status_diff_nonzero AS
  SELECT 
    *
  FROM
    global_status_diff
  WHERE
    variable_value_diff != 0
;
-- 
-- Active processes sorted by current query runtime, desc (longest first). Exclude current connection.
-- 
CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW processlist_grantees AS
  SELECT 
    PROCESSLIST.ID,
    PROCESSLIST.USER,
    PROCESSLIST.HOST,
    PROCESSLIST.DB,
    PROCESSLIST.COMMAND,
    PROCESSLIST.TIME,
    PROCESSLIST.STATE,
    PROCESSLIST.INFO,
    USER_PRIVILEGES.GRANTEE,
    mysql.user.user AS grantee_user,
    mysql.user.host AS grantee_host,
    SUM(USER_PRIVILEGES.PRIVILEGE_TYPE = 'SUPER') AS is_super,
    (PROCESSLIST.USER = 'system user' OR PROCESSLIST.COMMAND = 'Binlog Dump') AS is_repl,
    id = CONNECTION_ID() AS is_current,
    CONCAT('KILL QUERY ', PROCESSLIST.ID) AS sql_kill_query,
    CONCAT('KILL ', PROCESSLIST.ID) AS sql_kill_connection
  FROM 
    INFORMATION_SCHEMA.PROCESSLIST 
    LEFT JOIN INFORMATION_SCHEMA.USER_PRIVILEGES ON (match_grantee(USER, HOST) = USER_PRIVILEGES.GRANTEE)
    LEFT JOIN mysql.user ON (CONCAT('''', mysql.user.user, '''@''', mysql.user.host, '''') = USER_PRIVILEGES.GRANTEE)
  GROUP BY
    PROCESSLIST.ID, PROCESSLIST.USER, PROCESSLIST.HOST, PROCESSLIST.DB, PROCESSLIST.COMMAND, PROCESSLIST.TIME, PROCESSLIST.STATE, PROCESSLIST.INFO, USER_PRIVILEGES.GRANTEE, mysql.user.user, mysql.user.host
;


-- 
-- Explode various grantee, user & host combinations
-- 
CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW _processlist_grantees_exploded AS
  SELECT 
    id,
    sql_kill_query,
    sql_kill_connection,
    grantee,
    concat(grantee_user, '@', grantee_host) as unqualified_grantee,
    grantee_host,
    grantee_user,
    concat('''', user, '''@''', SUBSTRING_INDEX(host, ':', 1), '''') as qualified_user_host,
    concat(user, '@', SUBSTRING_INDEX(host, ':', 1)) as unqualified_user_host,
    SUBSTRING_INDEX(host, ':', 1) as hostname,
    user
  FROM
    processlist_grantees
;
-- 
-- State of processes per user/host: connected, executing, average execution time
-- 
CREATE OR REPLACE
ALGORITHM = UNDEFINED
SQL SECURITY INVOKER
VIEW processlist_per_userhost AS
  SELECT 
    USER AS user,
    MIN(SUBSTRING_INDEX(HOST, ':', 1)) AS host,
    COUNT(*) AS count_processes,
    SUM(COMMAND != 'Sleep') AS active_processes,
    CAST(split_token(GROUP_CONCAT(IF(COMMAND != 'Sleep', TIME, NULL) ORDER BY TIME), ',', COUNT(IF(COMMAND != 'Sleep', TIME, NULL))/2) AS DECIMAL(10,2)) AS median_active_time,
    CAST(split_token(GROUP_CONCAT(IF(COMMAND != 'Sleep', TIME, NULL) ORDER BY TIME), ',', COUNT(IF(COMMAND != 'Sleep', TIME, NULL))*95/100) AS DECIMAL(10,2)) AS median_95pct_active_time,
    MAX(IF(COMMAND != 'Sleep', TIME, NULL)) AS max_active_time,
    AVG(IF(COMMAND != 'Sleep', TIME, NULL)) AS average_active_time
  FROM 
    INFORMATION_SCHEMA.PROCESSLIST 
  WHERE 
    id != CONNECTION_ID()
  GROUP BY
    USER, SUBSTRING_INDEX(HOST, ':', 1)
;
-- 
-- Replication processes only (both Master & Slave)
-- 
CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW processlist_repl AS
  SELECT 
    PROCESSLIST.*,
    USER = 'system user' AS is_system,
    (USER = 'system user' AND state_type = 'replication_io_thread') IS TRUE AS is_io_thread,
    (USER = 'system user' AND state_type = 'replication_sql_thread') IS TRUE AS is_sql_thread,
    COMMAND = 'Binlog Dump' AS is_slave
  FROM 
    INFORMATION_SCHEMA.PROCESSLIST 
    LEFT JOIN _known_thread_states ON (_known_thread_states.state LIKE CONCAT(PROCESSLIST.STATE, '%'))
  WHERE 
    USER = 'system user'
    OR COMMAND = 'Binlog Dump'
;
-- 
-- Summary of processlist states and their runtimes
-- 
CREATE OR REPLACE
ALGORITHM = UNDEFINED
SQL SECURITY INVOKER
VIEW processlist_states AS
  SELECT 
    STATE as state,
    COUNT(*) AS count_processes,
    CAST(split_token(GROUP_CONCAT(TIME ORDER BY TIME), ',', COUNT(*)/2) AS DECIMAL(10,2)) AS median_state_time,
    CAST(split_token(GROUP_CONCAT(TIME ORDER BY TIME), ',', COUNT(*)*95/100) AS DECIMAL(10,2)) AS median_95pct_state_time,
    MAX(TIME) AS max_state_time,
    SUM(TIME) AS sum_state_time
  FROM 
    INFORMATION_SCHEMA.PROCESSLIST 
  WHERE 
    id != CONNECTION_ID()
  GROUP BY
    STATE
  ORDER BY
    COUNT(*) DESC
;

-- 
-- Summary of processlist: number of connected, sleeping, running connections and slow query count
-- 

CREATE OR REPLACE
ALGORITHM = UNDEFINED
SQL SECURITY INVOKER
VIEW processlist_summary AS
  SELECT 
    COUNT(*) AS count_processes,
    SUM(COMMAND != 'Sleep') AS active_processes,
    SUM(COMMAND = 'Sleep') AS sleeping_processes,
    SUM((COMMAND != 'Sleep') AND (USER != 'system user') AND (COMMAND != 'Binlog Dump')) AS active_queries, 
    IFNULL(SUM(IF(
        (COMMAND != 'Sleep') AND (USER != 'system user') AND (COMMAND != 'Binlog Dump'),
        TIME >= 1,
        NULL
      )), 0) AS num_queries_over_1_sec,
    IFNULL(SUM(IF(
        (COMMAND != 'Sleep') AND (USER != 'system user') AND (COMMAND != 'Binlog Dump'),
        TIME >= 10,
        NULL
      )), 0) AS num_queries_over_10_sec,
    IFNULL(SUM(IF(
        (COMMAND != 'Sleep') AND (USER != 'system user') AND (COMMAND != 'Binlog Dump'),
        TIME >= 60,
        NULL
      )), 0) AS num_queries_over_60_sec,
    IFNULL(AVG(IF(
        (COMMAND != 'Sleep') AND (USER != 'system user') AND (COMMAND != 'Binlog Dump'),
        TIME,
        NULL
      )), 0) AS average_active_time,
    IFNULL(CAST(
      split_token(
        GROUP_CONCAT(
          IF(
            (COMMAND != 'Sleep') AND (USER != 'system user') AND (COMMAND != 'Binlog Dump'),
            TIME,
            NULL
          ) ORDER BY TIME
        ), 
        ',', COUNT(*)*95/100
      ) AS DECIMAL(10,2)
    ), 0) AS median_95pct_active_time
  FROM 
    INFORMATION_SCHEMA.PROCESSLIST 
  WHERE 
    id != CONNECTION_ID()
;
-- 
-- Active processes sorted by current query runtime, desc (longest first). Exclude current connection.
-- 
CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW processlist_top AS
  SELECT 
    *,
    CONCAT('KILL QUERY ', PROCESSLIST.ID) AS sql_kill_query,
    CONCAT('KILL ', PROCESSLIST.ID) AS sql_kill_connection    
  FROM 
    INFORMATION_SCHEMA.PROCESSLIST 
  WHERE 
    COMMAND != 'Sleep'
    AND id != CONNECTION_ID()
  ORDER BY
    TIME DESC
;
-- 
-- Summary view on INFORMATION_SCHEMA.PROFILING
-- 
CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW _query_profiling_summary AS
  SELECT 
    QUERY_ID,
    COUNT(*) AS count_state_calls,
    COUNT(DISTINCT STATE) AS count_distinct_states,
    SUM(DURATION) AS sum_duration,
    SUM(CPU_USER) AS sum_cpu_user,
    SUM(CPU_SYSTEM) AS sum_cpu_system,
    SUM(SWAPS) AS sum_swpas
  FROM 
    INFORMATION_SCHEMA.PROFILING
  GROUP BY
    QUERY_ID
  ORDER BY
    QUERY_ID
;


-- 
-- Summary view on INFORMATION_SCHEMA.PROFILING
-- 
CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW _query_profiling_minmax AS
  SELECT 
    MIN(QUERY_ID) AS min_query_id,
    MAX(QUERY_ID) AS max_query_id
  FROM 
    INFORMATION_SCHEMA.PROFILING
;

-- 
-- Per query profiling info, aggregated by STATE, such that info is displayed per state and
-- relative to general query info
-- 
CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW query_profiling AS
  SELECT 
    QUERY_ID,
    STATE,
    COUNT(*) AS state_calls,
    SUM(DURATION) AS state_sum_duration,
    SUM(DURATION)/COUNT(*) AS state_duration_per_call,
    ROUND(100.0 * SUM(DURATION) / MAX(_query_profiling_summary.sum_duration), 2) AS state_duration_pct,
    GROUP_CONCAT(SEQ ORDER BY SEQ) AS state_seqs
  FROM 
    INFORMATION_SCHEMA.PROFILING
    JOIN _query_profiling_summary USING(QUERY_ID)
  GROUP BY
    QUERY_ID, STATE
;

-- 
-- Profiling info for last query, aggregated by STATE
-- 
CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW last_query_profiling AS
  SELECT 
    query_profiling.*
  FROM 
    query_profiling
    JOIN _query_profiling_minmax ON (query_profiling.QUERY_ID = _query_profiling_minmax.max_query_id)
;
-- 
-- Get slave hosts: hosts connected to this server and replicating from it 
-- (i.e. their process is doing 'Binlog Dump')
-- 

CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW slave_hosts AS
  SELECT 
    SUBSTRING_INDEX(HOST, ':', 1) AS host
  FROM 
    processlist_repl
  WHERE 
    is_slave IS TRUE
;
-- 
-- Provide with slave status info
-- 
CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW slave_status AS
  SELECT 
    SUM(IF(is_io_thread, TIME, NULL)) AS Slave_Connected_time,
    SUM(is_io_thread) IS TRUE AS Slave_IO_Running,
    SUM(is_sql_thread OR (is_system AND NOT is_io_thread)) IS TRUE AS Slave_SQL_Running,
    (SUM(is_system) = 2) IS TRUE AS Slave_Running,
    SUM(IF(is_sql_thread OR (is_system AND NOT is_io_thread), TIME, NULL)) AS Seconds_Behind_Master
  FROM 
    processlist_repl
;
DROP TABLE IF EXISTS `routine_privileges`;

-- 
-- INFORMATION_SCHEMA-like privileges on routines    
-- 
CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW routine_privileges AS
  SELECT
    CONCAT('\'', User, '\'@\'', Host, '\'') AS GRANTEE,
    NULL AS ROUTINE_CATALOG,
    Db AS ROUTINE_SCHEMA,
    Routine_name AS ROUTINE_NAME,
    Routine_type AS ROUTINE_TYPE,
    REPLACE(UPPER(SUBSTRING_INDEX(SUBSTRING_INDEX(Proc_priv, ',', n+1), ',', -1)), '\0', ' ') AS PRIVILEGE_TYPE,
    IF(find_in_set('Grant', Proc_priv) > 0, 'YES', 'NO') AS IS_GRANTABLE
  FROM
    mysql.procs_priv
    CROSS JOIN numbers
  WHERE
    numbers.n BETWEEN 0 AND CHAR_LENGTH(Proc_priv) - CHAR_LENGTH(REPLACE(Proc_priv, ',', ''))
    AND UPPER(SUBSTRING_INDEX(SUBSTRING_INDEX(Proc_priv, ',', n+1), ',', -1)) != 'GRANT'
;
-- 
-- 
-- 

CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW _sql_accounts_base AS
  SELECT 
    user,
    host,
    mysql_grantee(user, host) AS grantee,
    password,
    password = '' or password rlike '^[?]{41}$' as is_empty_password,
    password rlike '^[*][0-9a-fA-F]{40}$' or password rlike '^[0-9a-fA-F]{40}[*]$' as is_new_password,
    password rlike '^[0-9a-fA-F]{16}$' or password rlike '^[~]{25}[0-9a-fA-F]{16}$' as is_old_password,
    password rlike '^[0-9a-fA-F]{40}[*]$' or password rlike '^[~]{25}[0-9a-fA-F]{16}$' or password rlike '^[?]{41}$' as is_blocked,
    REVERSE(password) AS reversed_password,
    REPLACE(password, '~', '') AS untiled_password,
    CONCAT(REPEAT('~', IF(CHAR_LENGTH(password) = 16, 25, 0)), password) AS tiled_password
  FROM
    mysql.user
;


-- 
-- 
-- 

CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW _sql_accounts_password AS
  SELECT
    *,
    CASE
      WHEN is_blocked THEN password
      WHEN is_empty_password THEN REPEAT('?', 41)
      WHEN is_new_password THEN reversed_password
      WHEN is_old_password THEN tiled_password
    END as password_for_sql_block_account,
    CASE
      WHEN not is_blocked THEN password
      WHEN is_empty_password THEN ''
      WHEN is_new_password THEN reversed_password
      WHEN is_old_password THEN untiled_password
    END as password_for_sql_release_account    
  FROM
    _sql_accounts_base
;

-- 
-- Generate SQL statements to block/release accounts. Provide info on accounts.
-- 

CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW sql_accounts AS
  SELECT
    user,
    host,
    grantee,
    password,
    is_empty_password,
    is_new_password or is_empty_password as is_new_password,
    is_old_password,
    is_blocked,
    CONCAT('SET PASSWORD FOR ', grantee, ' = ''', password_for_sql_block_account, '''') as sql_block_account,
    CONCAT('SET PASSWORD FOR ', grantee, ' = ''', password_for_sql_release_account, '''') as sql_release_account    
  FROM
    _sql_accounts_password
;

DROP TABLE IF EXISTS `routine_privileges`;
CREATE TABLE IF NOT EXISTS `routine_privileges` (
  `GRANTEE` varchar(81),
  `ROUTINE_CATALOG` binary(0),
  `ROUTINE_SCHEMA` char(64),
  `ROUTINE_NAME` char(64),
  `ROUTINE_TYPE` enum('FUNCTION','PROCEDURE'),
  `PRIVILEGE_TYPE` varchar(27),
  `IS_GRANTABLE` varchar(3)
) ENGINE=MyISAM;

-- 
-- (Internal use): privileges set on columns   
-- 
CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW _columns_privileges AS
  SELECT
    GRANTEE,
    TABLE_SCHEMA,
    TABLE_NAME,
    MAX(IS_GRANTABLE) AS IS_GRANTABLE, 
    CONCAT(
      PRIVILEGE_TYPE,
      ' (', GROUP_CONCAT(COLUMN_NAME ORDER BY COLUMN_NAME SEPARATOR ', '), ')'
      ) AS column_privileges    
  FROM
    INFORMATION_SCHEMA.COLUMN_PRIVILEGES
  GROUP BY
    GRANTEE, TABLE_SCHEMA, TABLE_NAME, PRIVILEGE_TYPE
;

-- 
-- (Internal use): GRANTs, account details, privileges details   
-- 
CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW _sql_grants_components AS
  (
    SELECT 
      GRANTEE,
      '*.*' AS priv_level,
      'user' AS priv_level_name,
      '' AS object_type,
      NULL AS object_schema,
      NULL AS object_name,
      'USAGE' AS current_privileges,
      MAX(IS_GRANTABLE) AS IS_GRANTABLE, 
      1 AS result_order
    FROM
      INFORMATION_SCHEMA.USER_PRIVILEGES
    GROUP BY
      GRANTEE
  )
  UNION ALL
  (
    SELECT 
      GRANTEE,
      '*.*' AS priv_level,
      'user' AS priv_level_name,
      '' AS object_type,
      NULL AS object_schema,
      NULL AS object_name,
      GROUP_CONCAT(PRIVILEGE_TYPE ORDER BY PRIVILEGE_TYPE SEPARATOR ', ') AS current_privileges,
      MAX(IS_GRANTABLE) AS IS_GRANTABLE, 
      2 AS result_order
    FROM
      INFORMATION_SCHEMA.USER_PRIVILEGES
    GROUP BY
      GRANTEE
    HAVING
      GROUP_CONCAT(PRIVILEGE_TYPE ORDER BY PRIVILEGE_TYPE) != 'USAGE'
  )
  UNION ALL
  (
    SELECT
      GRANTEE,
      CONCAT('`', TABLE_SCHEMA, '`.*') AS priv_level,
      'schema' AS priv_level_name,
      '' AS object_type,
      NULL AS object_schema,
      TABLE_SCHEMA AS object_name,
      GROUP_CONCAT(PRIVILEGE_TYPE ORDER BY PRIVILEGE_TYPE SEPARATOR ', ') AS current_privileges,
      MAX(IS_GRANTABLE) AS IS_GRANTABLE, 
      3 AS result_order
    FROM 
      INFORMATION_SCHEMA.SCHEMA_PRIVILEGES
    GROUP BY
      GRANTEE, TABLE_SCHEMA
  )
  UNION ALL
  (
    SELECT
      GRANTEE,
      CONCAT('`', TABLE_SCHEMA, '`.`', TABLE_NAME, '`') AS priv_level,
      'table' AS priv_level_name,
      'table' AS object_type,
      TABLE_SCHEMA AS object_schema,
      TABLE_NAME AS object_name,
      GROUP_CONCAT(PRIVILEGE_TYPE ORDER BY PRIVILEGE_TYPE SEPARATOR ', ') AS current_privileges,
      MAX(IS_GRANTABLE) AS IS_GRANTABLE, 
      4 AS result_order
    FROM 
      INFORMATION_SCHEMA.TABLE_PRIVILEGES
    GROUP BY
      GRANTEE, TABLE_SCHEMA, TABLE_NAME
  )
  UNION ALL
  (
    SELECT
      GRANTEE,
      CONCAT('`', TABLE_SCHEMA, '`.`', TABLE_NAME, '`') AS priv_level,
      'column' AS priv_level_name,
      '' AS object_type,
      TABLE_SCHEMA AS object_schema,
      TABLE_NAME AS object_name,
      GROUP_CONCAT(column_privileges ORDER BY column_privileges SEPARATOR ', ') AS current_privileges,
      MAX(IS_GRANTABLE) AS IS_GRANTABLE, 
      5 AS result_order
    FROM 
      _columns_privileges
    GROUP BY
      GRANTEE, TABLE_SCHEMA, TABLE_NAME
  )
  UNION ALL
  (
    SELECT
      GRANTEE,
      CONCAT('`', ROUTINE_SCHEMA, '`.`', ROUTINE_NAME, '`') AS priv_level,
      'routine' AS priv_level_name,
      MAX(ROUTINE_TYPE) AS object_type,
      ROUTINE_SCHEMA AS object_schema,
      ROUTINE_NAME AS object_name,
      GROUP_CONCAT(PRIVILEGE_TYPE ORDER BY PRIVILEGE_TYPE SEPARATOR ', ') AS current_privileges,
      MAX(IS_GRANTABLE) AS IS_GRANTABLE, 
      6 AS result_order
    FROM 
      routine_privileges
    GROUP BY
      GRANTEE, ROUTINE_SCHEMA, ROUTINE_NAME
  )
;

-- 
-- Current grantee privileges and additional info breakdown, generated GRANT and REVOKE sql statements  
-- 
CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW sql_grants AS
  SELECT 
    GRANTEE, 
    user.user,
    user.host,
    priv_level,
    priv_level_name,
    object_schema,
    object_name,
    current_privileges,
    IS_GRANTABLE,
    CONCAT(
      'GRANT ', current_privileges, 
      ' ON ', IF(priv_level_name = 'routine', CONCAT(object_type, ' '), ''), priv_level, 
      ' TO ', GRANTEE,
      IF(priv_level = '*.*' AND current_privileges = 'USAGE', 
        CONCAT(' IDENTIFIED BY PASSWORD ''', user.password, ''''), ''),
      IF(IS_GRANTABLE = 'YES', 
        ' WITH GRANT OPTION', '')
      ) AS sql_grant,
    CASE
      WHEN current_privileges = 'USAGE' AND priv_level = '*.*' THEN ''
      ELSE
        CONCAT(
          'REVOKE ', current_privileges, 
          IF(IS_GRANTABLE = 'YES', 
            ', GRANT OPTION', ''),
          ' ON ', priv_level, 
          ' FROM ', GRANTEE
          )      
    END AS sql_revoke,
    CONCAT(
      'DROP USER ', GRANTEE
      ) AS sql_drop_user
  FROM 
    _sql_grants_components
    JOIN mysql.user ON (GRANTEE = CONCAT('''', user.user, '''@''', user.host, ''''))
  ORDER BY 
    GRANTEE, result_order
;


-- 
-- SHOW GRANTS like output, for all accounts  
-- 
CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW sql_show_grants AS
  SELECT
    GRANTEE,
    user,
    host,
    GROUP_CONCAT(
      CONCAT(sql_grant, ';')
      SEPARATOR '\n'
      ) AS sql_grants
  FROM
    sql_grants
  GROUP BY
    GRANTEE, user, host
;

-- 
-- _bare_grantee_grants: just the grants per grantee, exluding the grantee name and password from statements  
-- 
CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW _bare_grantee_grants AS
  SELECT
    GRANTEE,
    user,
    host,
    GROUP_CONCAT(
      CONCAT(
        SUBSTRING_INDEX(
          REPLACE(sql_grant, GRANTEE, ''), 
          'IDENTIFIED BY PASSWORD', 
          1), 
        ';')
      ORDER BY sql_grant
      SEPARATOR '\n'
      ) AS sql_grants
  FROM
    sql_grants
  GROUP BY
    GRANTEE, user, host
;


-- 
-- _bare_grantee_grants: just the grants per grantee, exluding USAGE (which is shared by all), and exluding the grantee name from statement  
-- 
CREATE OR REPLACE
ALGORITHM = TEMPTABLE
SQL SECURITY INVOKER
VIEW similar_grants AS
  SELECT
    MIN(GRANTEE) AS sample_grantee,
    COUNT(GRANTEE) AS count_grantees,
    GROUP_CONCAT(GRANTEE ORDER BY GRANTEE) AS similar_grantees
  FROM
    _bare_grantee_grants
  GROUP BY
    sql_grants
  ORDER BY
    COUNT(*) DESC
;


--
--
--
set @script := "
try {
  set @common_schema_percona_server_expected := @common_schema_percona_server_expected + 1; 
-- 
-- Number of row cardinality per keys per columns in InnoDB tables
-- 
CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW innodb_index_rows AS
  SELECT
    STATISTICS.TABLE_SCHEMA,
    STATISTICS.TABLE_NAME,
    STATISTICS.INDEX_NAME,
    STATISTICS.SEQ_IN_INDEX,
    STATISTICS.COLUMN_NAME,
    SEQ_IN_INDEX = INNODB_INDEX_STATS.fields - IF(NON_UNIQUE, 1, 0) AS is_last_column_in_index,
    CAST(TRIM(split_token(rows_per_key, ',', SEQ_IN_INDEX)) AS UNSIGNED) AS incremental_row_per_key
  FROM
    INFORMATION_SCHEMA.INNODB_INDEX_STATS
    JOIN INFORMATION_SCHEMA.STATISTICS USING (TABLE_SCHEMA, TABLE_NAME, INDEX_NAME)
;

  set @common_schema_percona_server_installed := @common_schema_percona_server_installed + 1;
}
catch {
}
";

call run(@script);

--
--
--
set @script := "
try {
  set @common_schema_percona_server_expected := @common_schema_percona_server_expected + 1; 
-- 
-- Enhanced view of INNODB_INDEX_STATS: Estimated InnoDB depth & split factor of key's B+ Tree  
-- 
CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW innodb_index_stats AS
  SELECT
    *,
    IFNULL(
      ROUND((index_total_pages - 1)/(index_total_pages - index_leaf_pages), 1),
      0
    ) AS split_factor,
    IFNULL(
      ROUND(1 + log(index_leaf_pages)/log((index_total_pages - 1)/(index_total_pages - index_leaf_pages)), 1),
      0
    ) AS index_depth
  FROM
    INFORMATION_SCHEMA.INNODB_INDEX_STATS
;

  set @common_schema_percona_server_installed := @common_schema_percona_server_installed + 1;
}
catch {
}
";

call run(@script);

--
--
--
set @script := "
try {
  set @common_schema_innodb_plugin_expected := @common_schema_innodb_plugin_expected + 1; 
-- 
-- Locked transactions, the locks they are waiting on and the transactions holding those locks.
-- 
CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW innodb_locked_transactions AS
  SELECT 
    locked_transaction.trx_id AS locked_trx_id,
    locked_transaction.trx_started AS locked_trx_started,
    locked_transaction.trx_wait_started AS locked_trx_wait_started,
    locked_transaction.trx_mysql_thread_id AS locked_trx_mysql_thread_id,
    locked_transaction.trx_query AS locked_trx_query,
    INNODB_LOCK_WAITS.requested_lock_id,
    INNODB_LOCK_WAITS.blocking_lock_id,
    locking_transaction.trx_id AS locking_trx_id,
    locking_transaction.trx_started AS locking_trx_started,
    locking_transaction.trx_wait_started AS locking_trx_wait_started,
    locking_transaction.trx_mysql_thread_id AS locking_trx_mysql_thread_id,
    locking_transaction.trx_query AS locking_trx_query,
    TIMESTAMPDIFF(SECOND, locked_transaction.trx_wait_started, NOW()) as trx_wait_seconds,
    CONCAT('KILL QUERY ', locking_transaction.trx_mysql_thread_id) AS sql_kill_blocking_query,
    CONCAT('KILL ', locking_transaction.trx_mysql_thread_id) AS sql_kill_blocking_connection    
  FROM 
    INFORMATION_SCHEMA.INNODB_TRX AS locked_transaction
    JOIN INFORMATION_SCHEMA.INNODB_LOCK_WAITS ON (locked_transaction.trx_id = INNODB_LOCK_WAITS.requesting_trx_id)
    JOIN INFORMATION_SCHEMA.INNODB_TRX AS locking_transaction ON (locking_transaction.trx_id = INNODB_LOCK_WAITS.blocking_trx_id)
  WHERE
    locking_transaction.trx_mysql_thread_id != CONNECTION_ID()
;

  set @common_schema_innodb_plugin_installed := @common_schema_innodb_plugin_installed + 1;
}
catch {
}
";

call run(@script);

--
--
--
set @script := "
try {
  set @common_schema_innodb_plugin_expected := @common_schema_innodb_plugin_expected + 1; 
-- 
-- Simplification of INNODB_LOCKS table
-- 
CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW innodb_simple_locks AS
  SELECT 
    lock_id,
    lock_trx_id,
    lock_type,
    lock_table,
    lock_index,
    lock_data
  FROM 
    INFORMATION_SCHEMA.INNODB_LOCKS
;

  set @common_schema_innodb_plugin_installed := @common_schema_innodb_plugin_installed + 1;
}
catch {
}
";

call run(@script);

--
--
--
set @script := "
try {
  set @common_schema_innodb_plugin_expected := @common_schema_innodb_plugin_expected + 1; 
-- 
-- Active InnoDB transactions
-- 
CREATE OR REPLACE
ALGORITHM = MERGE
SQL SECURITY INVOKER
VIEW innodb_transactions AS
  SELECT 
    INFORMATION_SCHEMA.INNODB_TRX.*, 
    PROCESSLIST.INFO,
    TIMESTAMPDIFF(SECOND, trx_started, SYSDATE()) as trx_runtime_seconds,
    TIMESTAMPDIFF(SECOND, trx_wait_started, SYSDATE()) as trx_wait_seconds,
    IF(PROCESSLIST.COMMAND = 'Sleep', PROCESSLIST.TIME, 0) AS trx_idle_seconds,
    CONCAT('KILL QUERY ', trx_mysql_thread_id) AS sql_kill_query,
    CONCAT('KILL ', trx_mysql_thread_id) AS sql_kill_connection    
  FROM 
    INFORMATION_SCHEMA.INNODB_TRX
    LEFT JOIN INFORMATION_SCHEMA.PROCESSLIST ON (trx_mysql_thread_id = PROCESSLIST.ID)
  WHERE 
    trx_mysql_thread_id != CONNECTION_ID()
;

  set @common_schema_innodb_plugin_installed := @common_schema_innodb_plugin_installed + 1;
}
catch {
}
";

call run(@script);

--
--
--
set @script := "
try {
  set @common_schema_innodb_plugin_expected := @common_schema_innodb_plugin_expected + 1; 
-- 
-- One liner summary info on InnoDB transactions (count, running, locked, locks)
-- 
CREATE OR REPLACE
ALGORITHM = UNDEFINED
SQL SECURITY INVOKER
VIEW innodb_transactions_summary AS
  SELECT 
    COUNT(*) AS count_transactions,
    IFNULL(SUM(trx_state = 'RUNNING'), 0) AS running_transactions,
    IFNULL(SUM(trx_requested_lock_id IS NOT NULL), 0) AS locked_transactions,
    COUNT(DISTINCT trx_requested_lock_id) AS distinct_locks
  FROM 
    INFORMATION_SCHEMA.INNODB_TRX
  WHERE 
    trx_mysql_thread_id != CONNECTION_ID()
;

  set @common_schema_innodb_plugin_installed := @common_schema_innodb_plugin_installed + 1;
}
catch {
}
";

call run(@script);


			INSERT INTO common_schema._named_scripts (script_name, script_text) VALUES ('security_audit','
report h1 ''Checking for non-local root accounts'';
set @loop_counter := 0;
foreach ($user, $host: select user, host from mysql.user where user=''root'' and host not in (''127.0.0.1'', ''localhost''))
{
  if ((@loop_counter := @loop_counter+1) = 1) {
    report ''Recommendation: limit following root accounts to local machines'';
  }
  report code ''rename '', mysql_grantee($user, $host), '' to '', quote($user), ''@'', quote(''localhost''); 
}
otherwise
  report ''OK'';

  
report h1 ''Checking for anonymous users'';
set @loop_counter := 0;
foreach ($user, $host: select user, host from mysql.user where user='''')
{
  if ((@loop_counter := @loop_counter+1) = 1) {
    report ''Recommendation: Drop these users and do not use them'';
  }
  report code ''drop user '', mysql_grantee($user, $host); 
}
otherwise
  report ''OK'';

  
report h1 ''Looking for accounts accessible from any host'';
set @loop_counter := 0;
foreach ($user, $host: select user, host from mysql.user where host in (''%'', ''''))
{
  if ((@loop_counter := @loop_counter+1) = 1) {
    report ''Recommendation: limit following accounts to specific hosts/subnet'';
  }
  report code ''rename user '', mysql_grantee($user, $host), '' to '', mysql_grantee($user, ''<specific host>''); 
}
otherwise
  report ''OK'';


report h1 ''Checking for accounts with empty passwords'';
set @loop_counter := 0;  
foreach ($user, $host: select user, host from mysql.user where password='''')
{
  if ((@loop_counter := @loop_counter+1) = 1) {
    report ''Recommendation: set a decent password to these accounts.'';
  }
  report code ''set password for '', mysql_grantee($user, $host), '' = PASSWORD(...)'';
}
otherwise
  report ''OK'';

report h1 ''Looking for accounts with identical (non empty) passwords'';
set @loop_counter := 0;  
drop temporary table if exists _security_audit_identical_passwords;
create temporary table _security_audit_identical_passwords (
  user  varchar(128),
  host  varchar(128),
  password varchar(128),
  KEY (password)
) engine=MyISAM;

insert into _security_audit_identical_passwords
  SELECT 
    user, host, password 
  FROM (
    SELECT 
      user1.user, user1.host, 
      user2.user AS u2, user2.host AS h2, 
      user1.password as password 
    FROM 
      mysql.user AS user1 
      INNER JOIN mysql.user AS user2 ON (user1.password = user2.password) 
    WHERE 
      user1.user != user2.user 
      AND user1.password != ''''
  ) users 
  GROUP BY 
    user, host 
  ORDER BY 
    password
;
foreach ($password: select password from _security_audit_identical_passwords group by password)
{
  if ((@loop_counter := @loop_counter+1) = 1) {
    report ''Different users should not share same password.'';
    report ''Recommendation: Change passwords for accounts listed below.'';
  }
  report p ''The following accounts share the same password:'';
  foreach ($user, $host: select user, host from _security_audit_identical_passwords where password = $password)
  	report mysql_grantee($user, $host);
}
otherwise
  report ''OK'';


report h1 ''Looking for (non-root) accounts with admin privileges'';
set @loop_counter := 0;  
foreach ($grantee: SELECT GRANTEE, GROUP_CONCAT(PRIVILEGE_TYPE) AS privileges 
  FROM information_schema.USER_PRIVILEGES 
  WHERE PRIVILEGE_TYPE IN (''SUPER'', ''SHUTDOWN'', ''RELOAD'', ''PROCESS'', ''CREATE USER'', ''REPLICATION CLIENT'') 
  and grantee not like ''''''root''''@%''
  GROUP BY GRANTEE)
{
  if ((@loop_counter := @loop_counter+1) = 1) {
    report ''Normal users should not have admin privileges, such as'';
    report ''SUPER, SHUTDOWN, RELOAD, PROCESS, CREATE USER, REPLICATION CLIENT.'';
    report ''Recommendation: limit privileges to following accounts.'';
  }
  report code ''GRANT <non-admin-privileges> ON *.* TO '', $grantee; 
}
otherwise
  report ''OK'';


report h1 ''Looking for (non-root) accounts with global DDL privileges'';
set @loop_counter := 0;  
foreach ($grantee: SELECT GRANTEE, GROUP_CONCAT(PRIVILEGE_TYPE) AS privileges 
  FROM information_schema.USER_PRIVILEGES 
  WHERE PRIVILEGE_TYPE IN (''CREATE'', ''DROP'', ''EVENT'', ''ALTER'', ''INDEX'', ''TRIGGER'', ''CREATE VIEW'', ''ALTER ROUTINE'', ''CREATE ROUTINE'') 
  and grantee not like ''''''root''''@%''
  GROUP BY GRANTEE)
{
  if ((@loop_counter := @loop_counter+1) = 1) {
    report ''Normal users should not have global DDL privileges, such as'';
    report ''CREATE, DROP, EVENT, ALTER, INDEX, TRIGGER, CREATE VIEW, ...'';
    report ''Recommendation: limit privileges to following accounts.'';
  }
  report code ''GRANT <non-ddl-privileges> ON *.* TO '', $grantee; 
}
otherwise
  report ''OK'';

  
report h1 ''Looking for (non-root) accounts with global DML privileges'';
set @loop_counter := 0;  
foreach ($grantee: SELECT GRANTEE, GROUP_CONCAT(PRIVILEGE_TYPE) AS privileges 
  FROM information_schema.USER_PRIVILEGES 
  WHERE PRIVILEGE_TYPE IN (''DELETE'', ''INSERT'', ''UPDATE'', ''CREATE TEMPORARY TABLES'') 
  and grantee not like ''''''root''''@%''
  GROUP BY GRANTEE)
{
  if ((@loop_counter := @loop_counter+1) = 1) {
    report ''Normal users should not have global DML privileges.'';
    report ''Such privileges allow these users operation on the mysql system tables.'';
    report ''Recommendation: limit privileges to following accounts, so as'';
    report ''to act on specific schemas.'';
  }
  report code ''GRANT <dml-privileges> ON *.''''<specific_schema>'''' TO '', $grantee; 
}
otherwise
  report ''OK'';


report h1 ''Testing sql_mode'';
if (FIND_IN_SET(''NO_AUTO_CREATE_USER'', @@global.sql_mode) = 0) {
  report ''Server''''s sql_mode does not include NO_AUTO_CREATE_USER.'';
  report ''This means users can be created with empty passwords.'';
  report ''Recommendation: add NO_AUTO_CREATE_USER to sql_mode,'';
  report ''both in config file as well as dynamically.'';
  report code ''SET @@global.sql_mode := CONCAT(@@global.sql_mode, '''',NO_AUTO_CREATE_USER'''')''; 
}
else
  report ''OK'';

  
report h1 ''Testing old_passwords'';
if (select @@global.old_passwords) {
  report ''This server is running with @@old_passwords = 1.'';
  report ''This means password encryption is very weak.'';
  report ''Recommendation: remove ''''all_passwords'''' config, and reset passwords'';
  report ''for all accounts.''; 
}
else
  report ''OK'';

  
report h1 ''Checking for `test` database'';
foreach ($schema: schema like test) {
  report ''`test` database has been found.'';
  report ''`test` is a special database where any user can create, drop and manipulate'';
  report ''table data. Recommendation: drop it'';
  report code ''DROP DATABASE `test`''; 
}
otherwise
  report ''OK'';

report '''';

');
		
			INSERT INTO common_schema._named_scripts (script_name, script_text) VALUES ('self_test','report h1 ''Self testing...'';
var $x := 17;
if ($x)
  pass;
else
  pass;
report ''OK'';');
		
-- 
			INSERT INTO common_schema.help_content VALUES ('documentation','This is the official documentation for common_schema.
Documentation is available in the following formats:

* Online HTML pages: these are located within the public repository, and are
  MIMEd as text/html. At current, repository is in Google Code, and
  documentation is found in this address:
  http://common-schema.googlecode.com/svn/trunk/common_schema/doc/html/
  introduction.html.
* Bundled HTML pages, downloadable in archived format: the common_schema
  releases include a documentation bundle, such that is version compatible
  with code. Bundled documentation for latest version can be downloaded in
  this address:
  http://code.google.com/p/common-schema/. Other versions can be downloaded in
  the following address: http://code.google.com/p/common-schema/downloads/
  list.
* Inline help, accessible from within common_schema using the mysql command
  line client or any other MySQL connector.
  To search the help pages, invoke:


         call common_schema.help(''search term'');



The common_schema documentation covers all public interfaces, i.e. routines,
views, tables. Anything that is not in the docs is considered to be private
and subject to change without notice.
');
		
			INSERT INTO common_schema.help_content VALUES ('download','The common_schema project is currently hosted by Google Code. Downloads are
available at the Google Code common_schema_project_page
The common_schema distribution is a plain text SQL source file.
The common_schema distribution file supports MySQL 5.1, 5.5, Percona Server,
with and without InnoDB Plugin. It should support MySQL 5.6, which is not yet
GA at the time of this release of common_schema.
common_schema includes its own documentation (see help()). However, it is also
possible to download the documentation as a bundled HTML archive.

Get it

I''m ready! Take_me_to_downloads_page

Notes

There is no MySQL 5.0 compatible distribution.
');
		
			INSERT INTO common_schema.help_content VALUES ('install','common_schema distribution file is a SQL source file. To install it, you
should execute it on your MySQL server.
There are many ways to import a SQL file into MySQL, listed below. Make sure
to execute them as a privileged user, e.g. ''root''@''localhost'', as installation
involves creation of schema, tables, views & routines.
Consult the download_page for obtaining the common_schema distribution file.

* Within MySQL, issue (replace "common_schema_distribution_file" with actual
  file name):


         mysql> SOURCE ''/path/to/common_schema_distribution_file.sql'';


* From shell, execute:


         bash$ mysql < /path/to/common_schema_distribution_file.sql


* Use your favorite MySQL GUI editor, copy+paste file content, execute.

To verify installation, check that the common_schema database exists. e.g.:


       root@mysql> SHOW DATABASES;
       +--------------------+
       | Database           |
       +--------------------+
       | information_schema |
       | common_schema      |
       | mysql              |
       | sakila             |
       | world              |
       +--------------------+



Requirements

The common_schema distribution file supports MySQL 5.1, 5.5, Percona Server,
with and without InnoDB Plugin. It should support MySQL 5.6, which is not yet
GA at the time of this release of common_schema.
Percona Server features are supported for versions >= 5.5.8. Please note that
common_schema will install regardless of the version. It will automatically
recognize available feature set and install accordingly. Likewise, it will
install regardless of the availability of InnoDB Plugin and associated
INFORMATION_SCHEMA tables.
If you should upgrade your MySQL server, or enable features which were turned
off during install of common_schema, the new feature set are not automatically
available by common_schema, and a re-install of common_schema is required.

Troubleshooting

Since installation is merely an import act, you should only expect trouble if
schema generation is unable to execute on your server.

* Are you executing on a 5.0 MySQL server? This version is not supported.
* Were errors reported during installation process?
* What was common_schema''s last message during install?
* What is the output of SELECT * FROM common_schema.status?

');
		
			INSERT INTO common_schema.help_content VALUES ('introduction','common_schema is a framework for MySQL server administration.
common_schema provides with query scripting, analysis & informational views,
and a function library, allowing for easier administration and diagnostics for
MySQL. It introduces SQL based tools which simplify otherwise complex shell
and client scripts, allowing the DBA to be independent of operating system,
installed packages and dependencies.
It is a self contained schema, compatible with all MySQL >= 5.1 servers.
Installed by importing the schema into the server, there is no need to
configure nor compile. No special plugins are required, and no changes to your
configuration.
common_schema has a small footprint (well under 1MB).

What can common_schema do?

Here''s a quick peek at some of common_schema''s capabilities:

Query scripting & execution

Run QueryScript code:


       foreach($table, $schema, $engine: table in sakila)
         if ($engine = ''InnoDB'')
           ALTER TABLE :$schema.:$table ENGINE=InnoDB
       ROW_FORMAT=Compressed KEY_BLOCK_SIZE=8;


Throttle queries:


       SELECT Id, Name, throttle(1)
         FROM world.City
         ORDER BY Population DESC;
       ...



Schema analysis

Detect duplicate keys:


       SELECT redundant_index_name, sql_drop_index FROM redundant_keys;
       +----------------------+------------------------------------------
       ----------------+
       | redundant_index_name | sql_drop_index
       |
       +----------------------+------------------------------------------
       ----------------+
       | rental_date_2        | ALTER TABLE `sakila`.`rental` DROP INDEX
       `rental_date_2` |
       +----------------------+------------------------------------------
       ----------------+



Monitoring

Show status change on your server over time:


       mysql> SELECT * FROM common_schema.global_status_diff_nonzero;
       +-----------------------+------------------+------------------+---
       ------------------+---------------------+------------------------+
       | variable_name         | variable_value_0 | variable_value_1 |
       variable_value_diff | variable_value_psec | variable_value_pminute
       |
       +-----------------------+------------------+------------------+---
       ------------------+---------------------+------------------------+
       | handler_read_rnd_next | 3871             | 4458             |
       587 |                58.7 |                   3522 |
       | handler_write         | 10868            | 11746            |
       878 |                87.8 |                   5268 |
       | open_files            | 39               | 37               |
       -2 |                -0.2 |                    -12 |
       | select_full_join      | 3                | 4                |
       1 |                 0.1 |                      6 |
       | select_scan           | 30               | 32               |
       2 |                 0.2 |                     12 |
       +-----------------------+------------------+------------------+---
       ------------------+---------------------+------------------------+



Process watch

Find the GRANTEE for active processes:


       mysql> SELECT * FROM common_schema.processlist_grantees;
       +--------+------------+---------------------+---------------------
       ---+--------------+--------------+----------+---------+-----------
       --------+---------------------+
       | ID     | USER       | HOST                | GRANTEE
       | grantee_user | grantee_host | is_super | is_repl |
       sql_kill_query    | sql_kill_connection |
       +--------+------------+---------------------+---------------------
       ---+--------------+--------------+----------+---------+-----------
       --------+---------------------+
       | 650472 | replica    | jboss00.myweb:34266 | ''replica''@''%.myweb''
       | replica      | %.myweb      |        0 |       1 | KILL QUERY
       650472 | KILL 650472         |
       | 692346 | openarkkit | jboss02.myweb:43740 |
       ''openarkkit''@''%.myweb'' | openarkkit   | %.myweb      |        0 |
       0 | KILL QUERY 692346 | KILL 692346         |
       | 842853 | root       | localhost           | ''root''@''localhost''
       | root         | localhost    |        1 |       0 | KILL QUERY
       842853 | KILL 842853         |
       | 843443 | jboss      | jboss03.myweb:40007 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       843443 | KILL 843443         |
       | 843444 | jboss      | jboss03.myweb:40012 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       843444 | KILL 843444         |
       | 843510 | jboss      | jboss00.myweb:49850 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       843510 | KILL 843510         |
       +--------+------------+---------------------+---------------------
       ---+--------------+--------------+----------+---------+-----------
       --------+---------------------+


See top running processes:


       mysql> SELECT * FROM common_schema.processlist_top;
       +----------+-------------+--------------+-----------+-------------
       +---------+-------------------------------------------------------
       -----------+------------------------------------------------------
       -----------------------------------------------------------------
       +------------+
       | ID       | USER        | HOST         | DB        | COMMAND
       | TIME    | STATE
       | INFO
       | TIME_MS    |
       +----------+-------------+--------------+-----------+-------------
       +---------+-------------------------------------------------------
       -----------+------------------------------------------------------
       -----------------------------------------------------------------
       +------------+
       |  3598334 | system user |              | NULL      | Connect
       | 4281883 | Waiting for master to send event
       | NULL
       | 4281883102 |
       |  3598469 | replica     | sql01:51157  | NULL      | Binlog Dump
       | 4281878 | Has sent all binlog to slave; waiting for binlog to be
       updated   | NULL
       | 4281877707 |
       | 31066726 | replica     | sql02:48924  | NULL      | Binlog Dump
       | 1041758 | Has sent all binlog to slave; waiting for binlog to be
       updated   | NULL
       | 1041758134 |
       |  3598335 | system user |              | NULL      | Connect
       |  195747 | Has read all relay log; waiting for the slave I/
       O thread to upda | NULL
       |          0 |
       | 39946702 | store       | app03:46795  | datastore | Query
       |       0 | Writing to net
       | SELECT * FROM store_location
       |         27 |
       | 39946693 | store       | app05:51090  | datastore | Query
       |       0 | Writing to net
       | SELECT store.store_id, store_location.zip_code FROM store JOIN
       store_location USING (store_id) WHERE store_class = 5  |
       54 |
       | 39946692 | store       | sql01:47849  | datastore | Query
       |       0 | Writing to net
       | SELECT store.store_id, store_location.zip_code FROM store JOIN
       store_location USING (store_id) WHERE store_class = 34 |
       350 |
       +----------+-------------+--------------+-----------+-------------
       +---------+-------------------------------------------------------
       -----------+------------------------------------------------------
       -----------------------------------------------------------------
       +------------+


common_schema provides plenty of more functionality. The documentation is
extensive!

RISKS

Please refer to the risks page.

LICENSE

common_schema is released under the BSD_license.


       Copyright (c) 2011 - 2012, Shlomi Noach
       All rights reserved.

       Redistribution and use in source and binary forms, with or without
       modification, are permitted provided that the following conditions
       are met:
       * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
       * Redistributions in binary form must reproduce the above
       copyright notice, this list of conditions and the following
       disclaimer in the documentation and/or other materials provided
       with the distribution.
       * Neither the name of the organization nor the names of its
       contributors may be used to endorse or promote products derived
       from this software without specific prior written permission.
       THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
       CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
       INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
       MERCHANTABILITY AND FITNESS FOR
       A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
       COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
       INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
       (INCLUDING, BUT NOT
       LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
       USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
       AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
       LIABILITY, OR
       TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
       THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
       SUCH DAMAGE.



AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('risks','This is not the usual "It''s your responsibility" stuff. Please read through.
common_schema is a database schema. It includes routines, views and tables.
The risks of using this schema are those affected by issuing queries against
its views or routines.
In particular, most of the views rely on INFORMATION_SCHEMA views.
MySQL''s INFORMATION_SCHEMA views are not all equal. Some are pretty
lightweight (like PROCESSLIST); some take a bit more time to evaluate (like
GLOBAL_STATUS) but do not impose locks affecting your data.
Some views, however, require getting metadata for tables, and in fact, require
metadata for all tables at once. First and foremost: the TABLES table, but
also COLUMNS, STATISTICS etc. Performing even the simplest query on one of
these views may cause, in extreme cases, lockdown of your database for long
minutes. The author has also witnessed databases crash because of queries on
such tables. See also: Making_changes_to_many_tables_at_once, How_to_tell_when
using_INFORMATION_SCHEMA_might_crash_your_database. Consider setting
innodb_stats_on_metadata=0 as suggested in Solving_INFORMATION_SCHEMA
slowness.
It is safer to perform such heavyweight queries on a replicating slave. A
slave may actually sustain less "damage" from these queries due to its single-
threaded writing mode, making for less contention on table locks. At least
this is the author''s experience; no guarantees made.
The good news is that those views relying on heavyweight INFORMATION_SCHEMA
tables are those you don''t mind running on the slave, or on an offline
machine. These views usually analyze your table structure, data size, keys,
AUTO_INCREMENT columns, etc. They don''t have anything in particular for
monitoring a live, running server. Some of these views don''t actually require
data to work on, just a schema.
Examples of common_schema views which rely on heavyweight INFORMATION_SCHEMA
tables:

* no_pk_innodb_tables
* redundant_keys
* sql_alter_table
* sql_foreign_keys
* table_charset
* text_columns
* auto_increment_columns
* data_size_per_engine
* data_size_per_schema
* innodb_index_rows

The list above may change, or may not reflect the actual state of views &
functions.
common_schema views which are lightweight are the various process, security,
monitoring, InnoDB_plugin and Percona_Server views.
Of course, just as would be able to drop your database being a super user, you
could also use common_schema to execute destructive queries. Many routines
support the @common_schema_dryrun user variable; use it (set it to 1) if
you''re not sure about expected results.
You should also note that "common_schema" is hard coded into the distribution
files; if you have a schema after the same name, make sure to change
"common_schema" in the distribution file.
And, it''s your responsibility. By using common_schema, your agree to its
license:

LICENSE

common_schema is released under the BSD license.


       Copyright (c) 2011 - 2012, Shlomi Noach
       All rights reserved.

       Redistribution and use in source and binary forms, with or without
       modification, are permitted provided that the following conditions
       are met:
       * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
       * Redistributions in binary form must reproduce the above
       copyright notice, this list of conditions and the following
       disclaimer in the documentation and/or other materials provided
       with the distribution.
       * Neither the name of the organization nor the names of its
       contributors may be used to endorse or promote products derived
       from this software without specific prior written permission.
       THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
       CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
       INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
       MERCHANTABILITY AND FITNESS FOR
       A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
       COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
       INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
       (INCLUDING, BUT NOT
       LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
       USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
       AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
       LIABILITY, OR
       TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
       THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
       SUCH DAMAGE.



AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('auto_increment_columns','
NAME

auto_increment_columns: List AUTO_INCREMENT columns and their capacity

TYPE

View

DESCRIPTION

auto_increment_columns presents current capacity and limits for AUTO_INCREMENT
columns.
For each AUTO_INCREMENT column, it observes its column type and its signed/
unsigned status, and calculates the maximum possible value expressed by this
column. It cross references this with table''s current AUTO_INCREMENT value, to
present with current usage or capacity.
This view answers the questions: "Am I running out of AUTO_INCREMENT values?",
"Should I modify to BIGINT?"

STRUCTURE



       mysql> DESC common_schema.auto_increment_columns;
       +----------------------+------------------------+------+-----+----
       -----+-------+
       | Field                | Type                   | Null | Key |
       Default | Extra |
       +----------------------+------------------------+------+-----+----
       -----+-------+
       | TABLE_SCHEMA         | varchar(64)            | NO   |     |
       |       |
       | TABLE_NAME           | varchar(64)            | NO   |     |
       |       |
       | COLUMN_NAME          | varchar(64)            | NO   |     |
       |       |
       | DATA_TYPE            | varchar(64)            | NO   |     |
       |       |
       | COLUMN_TYPE          | longtext               | NO   |     |
       NULL    |       |
       | is_signed            | int(1)                 | NO   |     | 0
       |       |
       | is_unsigned          | int(1)                 | NO   |     | 0
       |       |
       | max_value            | bigint(21) unsigned    | YES  |     |
       NULL    |       |
       | AUTO_INCREMENT       | bigint(21) unsigned    | YES  |     |
       NULL    |       |
       | auto_increment_ratio | decimal(24,4) unsigned | YES  |     |
       NULL    |       |
       +----------------------+------------------------+------+-----+----
       -----+-------+



SYNOPSIS

Columns of this view:

* TABLE_SCHEMA: schema of table with AUTO_INCREMENT columns
* TABLE_NAME: name of table with AUTO_INCREMENT columns
* COLUMN_NAME: AUTO_INCREMENT column name
* DATA_TYPE: type of column: this is always an integer type: TINYINT,
  SMALLINT, MEDIUMINT, INT, BIGINT.
* COLUMN_TYPE: full description of column type
* is_signed: 1 if type is SIGNED, 0 if UNSIGNED
* is_unsigned: 1 if type is UNSIGNED, 0 if SIGNED. This is just the opposite
  of is_signed and is provided for convenience
* max_value: maximum value which can be expressed by this column
* AUTO_INCREMENT: current AUTO_INCREMENT value for table
* auto_increment_ratio: ratio between max_value and table''s AUTO_INCREMENT.
  Ranges [0..1]. Expresses capacity

Upper case columns are directly derived from underlying INFORMATION_SCHEMA
tables, whereas lower case columns are computed.

EXAMPLES

Show AUTO_INCREMENT capacity for ''sakila'' database:


       mysql> SELECT * FROM common_schema.auto_increment_columns WHERE
       TABLE_SCHEMA=''sakila'';
       +--------------+------------+--------------+-----------+----------
       -------------+-----------+-------------+------------+-------------
       ---+----------------------+
       | TABLE_SCHEMA | TABLE_NAME | COLUMN_NAME  | DATA_TYPE |
       COLUMN_TYPE           | is_signed | is_unsigned | max_value  |
       AUTO_INCREMENT | auto_increment_ratio |
       +--------------+------------+--------------+-----------+----------
       -------------+-----------+-------------+------------+-------------
       ---+----------------------+
       | sakila       | actor      | actor_id     | smallint  | smallint
       (5) unsigned  |         0 |           1 |      65535 |
       201 |               0.0031 |
       | sakila       | address    | address_id   | smallint  | smallint
       (5) unsigned  |         0 |           1 |      65535 |
       606 |               0.0092 |
       | sakila       | category   | category_id  | tinyint   | tinyint
       (3) unsigned   |         0 |           1 |        255 |
       17 |               0.0667 |
       | sakila       | city       | city_id      | smallint  | smallint
       (5) unsigned  |         0 |           1 |      65535 |
       601 |               0.0092 |
       | sakila       | country    | country_id   | smallint  | smallint
       (5) unsigned  |         0 |           1 |      65535 |
       110 |               0.0017 |
       | sakila       | customer   | customer_id  | smallint  | smallint
       (5) unsigned  |         0 |           1 |      65535 |
       600 |               0.0092 |
       | sakila       | film       | film_id      | smallint  | smallint
       (5) unsigned  |         0 |           1 |      65535 |
       1001 |               0.0153 |
       | sakila       | inventory  | inventory_id | mediumint | mediumint
       (8) unsigned |         0 |           1 |   16777215 |
       4582 |               0.0003 |
       | sakila       | language   | language_id  | tinyint   | tinyint
       (3) unsigned   |         0 |           1 |        255 |
       7 |               0.0275 |
       | sakila       | payment    | payment_id   | smallint  | smallint
       (5) unsigned  |         0 |           1 |      65535 |
       16050 |               0.2449 |
       | sakila       | rental     | rental_id    | int       | int(11)
       |         1 |           0 | 2147483647 |          16050 |
       0.0000 |
       | sakila       | staff      | staff_id     | tinyint   | tinyint
       (3) unsigned   |         0 |           1 |        255 |
       3 |               0.0118 |
       | sakila       | store      | store_id     | tinyint   | tinyint
       (3) unsigned   |         0 |           1 |        255 |
       3 |               0.0118 |
       +--------------+------------+--------------+-----------+----------
       -------------+-----------+-------------+------------+-------------
       ---+----------------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

data_size_per_engine, data_size_per_schema

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('candidate_keys','
NAME

candidate_keys: Listing of prioritized candidate keys: keys which are UNIQUE,
by order of best-use.

TYPE

View

DESCRIPTION

candidate_keys lists candidate keys for all tables. Each candidate key gets a
score: a lower score is given to "better" keys.
Candidate keys are, technically, simply UNIQUE KEYs. Conceptually, these are
keys whose values are able to represent tuples (rows). Such keys can be used
by different operations on a table, such as separating it to chunks, breaking
long, heavy weight operations into smaller, faster operations.
MySQL''s PRIMARY KEYs must not cover NULLable columns. This view indicates
whether a key has NULLable columns. While technically this means the key is
not an immediate candidate (trying to turn it into PRIMARY KEY will fail due
to NULLable columns), such keys are nevertheless listed, as often times
columns are created NULLable by mistake; that is: many times a NULLable column
never has NULL values. In such cases, an ALTER TABLE MODIFY COLUMN is required
so as to make the key a true candidate key.
Not all candidate keys are the same. Some are "better" than others in terms of
space and I/O. A UNIQUE KEY over a couple of INTEGER columns is smaller (hence
"better") than a UNIQUE KEY over a VARCHAR(192) field (e.g. some URL). It is
easier to walk through the table using smaller keys, since less search is
involved.
candidate_keys provides with a heuristic ranking of candidate keys within a
table. Each candidate key receives a candidate_key_rank_in_table rank (score).
The smaller the better; so "better" keys can be detected using ORDER BY.
The heuristic works as follows:

* Non-character-typed columns get better score than character-typed columns.
  Only first column in index is compared in this heuristic.
* Smaller data types get better score than larger data types (e.g. INT is
  smaller than DATETIME). Only first column in index is compared in this
  heuristic.
* Keys covering fewer columns get better score
* There is no preference for PRIMARY KEYs, although with InnoDB they are
  technically fastest in access to row data due to the clustering index
  structure of InnoDB tables. Consult the is_primary column to prefer PRIMARY
  KEYs.


STRUCTURE



       mysql> DESC common_schema.candidate_keys;
       +-----------------------------+---------------------+------+-----
       +---------+-------+
       | Field                       | Type                | Null | Key |
       Default | Extra |
       +-----------------------------+---------------------+------+-----
       +---------+-------+
       | table_schema                | varchar(64)         | NO   |     |
       |       |
       | table_name                  | varchar(64)         | NO   |     |
       |       |
       | index_name                  | varchar(64)         | NO   |     |
       |       |
       | has_nullable                | int(1)              | NO   |     |
       0       |       |
       | is_primary                  | int(1)              | NO   |     |
       0       |       |
       | column_names                | longtext            | YES  |     |
       NULL    |       |
       | count_column_in_index       | bigint(21)          | NO   |     |
       0       |       |
       | data_type                   | varchar(64)         | NO   |     |
       |       |
       | character_set_name          | varchar(32)         | YES  |     |
       NULL    |       |
       | candidate_key_rank_in_table | bigint(23) unsigned | YES  |     |
       NULL    |       |
       +-----------------------------+---------------------+------+-----
       +---------+-------+



SYNOPSIS

Columns of this view:

* table_schema: schema of candidate key
* table_name: table of candidate key
* index_name: name of candidate key
* has_nullable: 1 if any column in this index is NULLable; 0 if all columns
  are NOT NULL
* is_primary: 1 if this key is PRIMARY, 0 otherwise.
* column_names: names of columns covered by key
* count_column_in_index: number of columns covered by key
* data_type: data type of first column covered by key
* character_set_name: character set name of first column covered by key, or
  NULL if not character-typed
* candidate_key_rank_in_table: rank (score) of index within table. Lower is
  "better". It makes no sense to compare ranks between keys of different
  tables.


EXAMPLES

Show candidate key ranking for tables in sakila


       mysql> SELECT * FROM common_schema.candidate_keys WHERE
       TABLE_SCHEMA=''sakila'';
       +--------------+---------------+--------------------+-------------
       -+------------+--------------------------------------+------------
       -----------+-----------+--------------------+---------------------
       --------+
       | table_schema | table_name    | index_name         | has_nullable
       | is_primary | column_names                         |
       count_column_in_index | data_type | character_set_name |
       candidate_key_rank_in_table |
       +--------------+---------------+--------------------+-------------
       -+------------+--------------------------------------+------------
       -----------+-----------+--------------------+---------------------
       --------+
       | sakila       | actor         | PRIMARY            |            0
       |          1 | actor_id                             |
       1 | smallint  | NULL               |                       65537 |
       | sakila       | address       | PRIMARY            |            0
       |          1 | address_id                           |
       1 | smallint  | NULL               |                       65537 |
       | sakila       | category      | PRIMARY            |            0
       |          1 | category_id                          |
       1 | tinyint   | NULL               |                           1 |
       | sakila       | city          | PRIMARY            |            0
       |          1 | city_id                              |
       1 | smallint  | NULL               |                       65537 |
       | sakila       | country       | PRIMARY            |            0
       |          1 | country_id                           |
       1 | smallint  | NULL               |                       65537 |
       | sakila       | customer      | PRIMARY            |            0
       |          1 | customer_id                          |
       1 | smallint  | NULL               |                       65537 |
       | sakila       | film          | PRIMARY            |            0
       |          1 | film_id                              |
       1 | smallint  | NULL               |                       65537 |
       | sakila       | film_actor    | PRIMARY            |            0
       |          1 | actor_id,film_id                     |
       2 | smallint  | NULL               |                       65538 |
       | sakila       | film_category | PRIMARY            |            0
       |          1 | film_id,category_id                  |
       2 | smallint  | NULL               |                       65538 |
       | sakila       | film_text     | PRIMARY            |            0
       |          1 | film_id                              |
       1 | smallint  | NULL               |                       65537 |
       | sakila       | inventory     | PRIMARY            |            0
       |          1 | inventory_id                         |
       1 | mediumint | NULL               |                      589825 |
       | sakila       | language      | PRIMARY            |            0
       |          1 | language_id                          |
       1 | tinyint   | NULL               |                           1 |
       | sakila       | payment       | PRIMARY            |            0
       |          1 | payment_id                           |
       1 | smallint  | NULL               |                       65537 |
       | sakila       | rental        | PRIMARY            |            0
       |          1 | rental_id                            |
       1 | int       | NULL               |                      131073 |
       | sakila       | rental        | rental_date        |            0
       |          0 | rental_date,inventory_id,customer_id |
       3 | datetime  | NULL               |                      327683 |
       | sakila       | staff         | PRIMARY            |            0
       |          1 | staff_id                             |
       1 | tinyint   | NULL               |                           1 |
       | sakila       | store         | idx_unique_manager |            0
       |          0 | manager_staff_id                     |
       1 | tinyint   | NULL               |                           1 |
       | sakila       | store         | PRIMARY            |            0
       |          1 | store_id                             |
       1 | tinyint   | NULL               |                           1 |
       +--------------+---------------+--------------------+-------------
       -+------------+--------------------------------------+------------
       -----------+-----------+--------------------+---------------------
       --------+


In the above we can see tables film and store each have 2 possible candidate
keys.

ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

candidate_keys_recommended, no_pk_innodb_tables, redundant_keys,
sql_foreign_keys

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('candidate_keys_recommended','
NAME

candidate_keys_recommended: Recommended candidate key per table.

TYPE

View

DESCRIPTION

candidate_keys_recommended recommends a single candidate key per table, where
such keys are available.
Follow discussion on candidate_keys for more on candidate keys.
This view assist in deciding whether assigned PRIMARY KEYs for tables are
indeed the best candidate keys assigned. With InnoDB, where a PRIMARY KEY is
of greater significance than secondary keys, it is important to choose the
PRIMARY KEY wisely. Other candidate keys can be promoted to PRIMARY in place
of a weak PRIMARY KEY.
The common utilization of this view would be to note down recommended keys
which are not PRIMARY KEYs.

STRUCTURE



       mysql> DESC common_schema.candidate_keys_recommended;
       +------------------------+---------------------+------+-----+-----
       ----+-------+
       | Field                  | Type                | Null | Key |
       Default | Extra |
       +------------------------+---------------------+------+-----+-----
       ----+-------+
       | table_schema           | varchar(64)         | NO   |     |
       |       |
       | table_name             | varchar(64)         | NO   |     |
       |       |
       | recommended_index_name | longtext            | YES  |     | NULL
       |       |
       | has_nullable           | bigint(67) unsigned | YES  |     | NULL
       |       |
       | is_primary             | bigint(67) unsigned | YES  |     | NULL
       |       |
       | column_names           | longtext            | YES  |     | NULL
       |       |
       +------------------------+---------------------+------+-----+-----
       ----+-------+



SYNOPSIS

Columns of this view:

* table_schema: schema of candidate key
* table_name: table of candidate key
* recommended_index_name: name of recommended candidate key
* has_nullable: 1 if any column in recommended index is NULLable; 0 if all
  columns are NOT NULL
* is_primary: 1 if recommended key is PRIMARY, 0 otherwise.
* column_names: names of columns covered by key


EXAMPLES

Show recommended candidate keys for tables in sakila


       mysql> SELECT * FROM common_schema.candidate_keys_recommended
       WHERE TABLE_SCHEMA=''sakila'';
       +--------------+---------------+------------------------+---------
       -----+------------+--------------+
       | table_schema | table_name    | recommended_index_name |
       has_nullable | is_primary | column_names |
       +--------------+---------------+------------------------+---------
       -----+------------+--------------+
       | sakila       | actor         | PRIMARY                |
       0 |          1 | actor_id     |
       | sakila       | address       | PRIMARY                |
       0 |          1 | address_id   |
       | sakila       | category      | PRIMARY                |
       0 |          1 | category_id  |
       | sakila       | city          | PRIMARY                |
       0 |          1 | city_id      |
       | sakila       | country       | PRIMARY                |
       0 |          1 | country_id   |
       | sakila       | customer      | PRIMARY                |
       0 |          1 | customer_id  |
       | sakila       | film          | PRIMARY                |
       0 |          1 | film_id      |
       | sakila       | film_actor    | PRIMARY                |
       0 |          1 | actor_id     |
       | sakila       | film_category | PRIMARY                |
       0 |          1 | film_id      |
       | sakila       | film_text     | PRIMARY                |
       0 |          1 | film_id      |
       | sakila       | inventory     | PRIMARY                |
       0 |          1 | inventory_id |
       | sakila       | language      | PRIMARY                |
       0 |          1 | language_id  |
       | sakila       | payment       | PRIMARY                |
       0 |          1 | payment_id   |
       | sakila       | rental        | PRIMARY                |
       0 |          1 | rental_id    |
       | sakila       | staff         | PRIMARY                |
       0 |          1 | staff_id     |
       | sakila       | store         | PRIMARY                |
       0 |          1 | store_id     |
       +--------------+---------------+------------------------+---------
       -----+------------+--------------+


In the above we note that for all tables the recommended candidate key is
indeed the PRIMARY KEY.

ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

candidate_keys, no_pk_innodb_tables, redundant_keys, sql_foreign_keys

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('crc64','
NAME

crc64(): Return a 64 bit CRC of given input, as unsigned big integer.

TYPE

Function

DESCRIPTION

This function complements MySQL''s crc32() function, which results with poor
distribution on large number of values. The crc64() algorithm relies on MD5 as
underlying mechanism.
While input data is textual, any type can be passed in, due to SQL''s implicit
casting nature.
This code is based on the idea presented in the book High Performance MySQL,
2nd Edition, By Baron Schwartz et al., published by O''REILLY

SYNOPSIS



       crc64(data LONGTEXT CHARSET utf8)
         RETURNS BIGINT UNSIGNED


Input:

* data: data to run CRC on. This can be textual, numeric, temporal, or any
  other type that can be implicitly converted to TEXT.


EXAMPLES

Calculate 64 bit CRC for some text:


       mysql> SELECT common_schema.crc64(''mysql'') AS crc64;
       +---------------------+
       | crc64               |
       +---------------------+
       | 9350511318824990686 |
       +---------------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

query_checksum(), random_hash()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('data_dimension_views','
SYNOPSIS

Data dimension views: informational views on general data dimentions,
capaticies and limitations.

* auto_increment_columns: List AUTO_INCREMENT columns and their capacity
* data_size_per_engine: Present with data size measurements per storage engine
* data_size_per_schema: Present with data size measurements per schema


DESCRIPTION

Through analysis of INFORMATION_SCHEMA, these views can provide with
information on per-engine or per-schema estimated data size summary, or on
AUTO_INCREMENT capacities.

EXAMPLES

Show dimensions per schema:


       mysql> SELECT * FROM common_schema.data_size_per_schema;
       +---------------+--------------+-------------+------------------+-
       ----------+------------+------------+----------------------+------
       --------------+
       | TABLE_SCHEMA  | count_tables | count_views | distinct_engines |
       data_size | index_size | total_size | largest_table        |
       largest_table_size |
       +---------------+--------------+-------------+------------------+-
       ----------+------------+------------+----------------------+------
       --------------+
       | common_schema |            1 |          27 |                1 |
       28672 |      35840 |      64512 | numbers              |
       64512 |
       | google_charts |            1 |           1 |                1 |
       16384 |          0 |      16384 | chart_data           |
       16384 |
       | mycheckpoint  |           13 |          50 |                2 |
       3022602 |      88064 |    3110666 | status_variables     |
       2654208 |
       | mysql         |           23 |           0 |                2 |
       3259223 |    2551808 |    5811031 | time_zone_transition |
       4297362 |
       | sakila        |           16 |           7 |                2 |
       4297536 |    2761728 |    7059264 | rental               |
       2850816 |
       | test          |            6 |           0 |                2 |
       80232 |      45056 |     125288 | t                    |
       49152 |
       | world         |            3 |           0 |                2 |
       510355 |      28672 |     539027 | City                 |
       409600 |
       +---------------+--------------+-------------+------------------+-
       ----------+------------+------------+----------------------+------
       --------------+


Show AUTO_INCREMENT capacity for ''sakila'' database:


       mysql> SELECT * FROM common_schema.auto_increment_columns WHERE
       TABLE_SCHEMA=''sakila'';
       +--------------+------------+--------------+-----------+----------
       -------------+-----------+------------+----------------+----------
       ------------+
       | TABLE_SCHEMA | TABLE_NAME | COLUMN_NAME  | DATA_TYPE |
       COLUMN_TYPE           | is_signed | max_value  | AUTO_INCREMENT |
       auto_increment_ratio |
       +--------------+------------+--------------+-----------+----------
       -------------+-----------+------------+----------------+----------
       ------------+
       | sakila       | actor      | actor_id     | smallint  | smallint
       (5) unsigned  |         1 |      65535 |            201 |
       0.0031 |
       | sakila       | address    | address_id   | smallint  | smallint
       (5) unsigned  |         1 |      65535 |            606 |
       0.0092 |
       | sakila       | category   | category_id  | tinyint   | tinyint
       (3) unsigned   |         1 |        255 |             17 |
       0.0667 |
       | sakila       | city       | city_id      | smallint  | smallint
       (5) unsigned  |         1 |      65535 |            601 |
       0.0092 |
       | sakila       | country    | country_id   | smallint  | smallint
       (5) unsigned  |         1 |      65535 |            110 |
       0.0017 |
       | sakila       | customer   | customer_id  | smallint  | smallint
       (5) unsigned  |         1 |      65535 |            600 |
       0.0092 |
       | sakila       | film       | film_id      | smallint  | smallint
       (5) unsigned  |         1 |      65535 |           1001 |
       0.0153 |
       | sakila       | inventory  | inventory_id | mediumint | mediumint
       (8) unsigned |         1 |   16777215 |           4582 |
       0.0003 |
       | sakila       | language   | language_id  | tinyint   | tinyint
       (3) unsigned   |         1 |        255 |              7 |
       0.0275 |
       | sakila       | payment    | payment_id   | smallint  | smallint
       (5) unsigned  |         1 |      65535 |          16050 |
       0.2449 |
       | sakila       | rental     | rental_id    | int       | int(11)
       |         0 | 2147483647 |          16050 |               0.0000 |
       | sakila       | staff      | staff_id     | tinyint   | tinyint
       (3) unsigned   |         1 |        255 |              3 |
       0.0118 |
       | sakila       | store      | store_id     | tinyint   | tinyint
       (3) unsigned   |         1 |        255 |              3 |
       0.0118 |
       +--------------+------------+--------------+-----------+----------
       -------------+-----------+------------+----------------+----------
       ------------+


');
		
			INSERT INTO common_schema.help_content VALUES ('data_size_per_engine','
NAME

data_size_per_engine: Present with data size measurements per storage engine

TYPE

View

DESCRIPTION

data_size_per_engine provides with an approximate data size in bytes per
storage engine. It is useful in diagnosing an unfamiliar server, checking up
on the different defined engines and the volumes they hold.
This view includes dimensions of the `mysql` schema, since this schema may
also include user data such as stored routines. It does not consider
INFORMATION_SCHEMA nor PERFORMANCE_SCHEMA.

STRUCTURE



       mysql> DESC common_schema.data_size_per_engine;
       +--------------------+---------------------+------+-----+---------
       +-------+
       | Field              | Type                | Null | Key | Default
       | Extra |
       +--------------------+---------------------+------+-----+---------
       +-------+
       | ENGINE             | varchar(64)         | YES  |     | NULL
       |       |
       | count_tables       | bigint(21)          | NO   |     | 0
       |       |
       | data_size          | decimal(42,0)       | YES  |     | NULL
       |       |
       | index_size         | decimal(42,0)       | YES  |     | NULL
       |       |
       | total_size         | decimal(43,0)       | YES  |     | NULL
       |       |
       | largest_table      | longtext            | YES  |     | NULL
       |       |
       | largest_table_size | bigint(20) unsigned | YES  |     | NULL
       |       |
       +--------------------+---------------------+------+-----+---------
       +-------+



SYNOPSIS

Columns of this view:

* ENGINE: name of storage engine
* count_tables: number of tables of this engine
* data_size: approximate data size in bytes for all tables of this engine
* index_size: approximate index size in bytes for all tables of this engine
* total_size: sum of data_size and index_size: approximate total size on disk
* largest_table: fully qualified name of largest table of this engine
* largest_table_size: total size in bytes of largest_table


EXAMPLES

Show dimensions per storage engine on an InnoDB-dedicated server:


       mysql> SELECT * FROM common_schema.data_size_per_engine;
       +--------+--------------+--------------+-------------+------------
       --+---------------------------+--------------------+
       | ENGINE | count_tables | data_size    | index_size  | total_size
       | largest_table             | largest_table_size |
       +--------+--------------+--------------+-------------+------------
       --+---------------------------+--------------------+
       | CSV    |            2 |            0 |           0 |
       0 | `mysql`.`general_log`     |                  0 |
       | InnoDB |          172 | 252877864960 | 68769677312 |
       321647542272 | `webdata`.`data_archive`  |       150358507520 |
       | MyISAM |           21 |       573493 |       95232 |
       668725 | `mysql`.`help_topic`      |             442472 |
       | SPHINX |            1 |            0 |           0 |
       0 | `webdata`.`sphinx_search` |                  0 |
       +--------+--------------+--------------+-------------+------------
       --+---------------------------+--------------------+


In the above example the only MyISAM tables are those of the `mysql` schema.

ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

auto_increment_columns, data_size_per_schema

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('data_size_per_schema','
NAME

data_size_per_schema: Present with data size measurements per schema

TYPE

View

DESCRIPTION

data_size_per_schema provides with an analysis of number and size of tables,
views & engines per schema. It is useful in diagnosing an unfamiliar server,
in checking up on the different engines, quickly recognizing largest tables.
This view includes dimensions of the `mysql` schema, since this schema may
also include user data such as stored routines. It does not consider
INFORMATION_SCHEMA nor PERFORMANCE_SCHEMA.

STRUCTURE



       mysql> DESC common_schema.data_size_per_schema;
       +--------------------+---------------------+------+-----+---------
       +-------+
       | Field              | Type                | Null | Key | Default
       | Extra |
       +--------------------+---------------------+------+-----+---------
       +-------+
       | TABLE_SCHEMA       | varchar(64)         | NO   |     |
       |       |
       | count_tables       | decimal(23,0)       | YES  |     | NULL
       |       |
       | count_views        | decimal(23,0)       | YES  |     | NULL
       |       |
       | distinct_engines   | bigint(21)          | NO   |     | 0
       |       |
       | data_size          | decimal(42,0)       | YES  |     | NULL
       |       |
       | index_size         | decimal(42,0)       | YES  |     | NULL
       |       |
       | total_size         | decimal(43,0)       | YES  |     | NULL
       |       |
       | largest_table      | longtext            | YES  |     | NULL
       |       |
       | largest_table_size | bigint(20) unsigned | YES  |     | NULL
       |       |
       +--------------------+---------------------+------+-----+---------
       +-------+



SYNOPSIS

Columns of this view:

* TABLE_SCHEMA: name of schema
* count_tables: number of tables in this schema
* count_views: number of views in this schema
* distinct_engines: number of distinct storage engines of tables in this
  schema
* data_size: approximate data size of schema''s tables
* index_size: approximate index size of schema''s tables
* total_size: sum of data_size and index_size
* largest_table: name of largest table in this schema
* largest_table_size: total size in bytes of largest_table


EXAMPLES

Show dimensions per schema:


       mysql> SELECT * FROM common_schema.data_size_per_schema;
       +---------------+--------------+-------------+------------------+-
       ----------+------------+------------+----------------------+------
       --------------+
       | TABLE_SCHEMA  | count_tables | count_views | distinct_engines |
       data_size | index_size | total_size | largest_table        |
       largest_table_size |
       +---------------+--------------+-------------+------------------+-
       ----------+------------+------------+----------------------+------
       --------------+
       | common_schema |            1 |          27 |                1 |
       28672 |      35840 |      64512 | numbers              |
       64512 |
       | google_charts |            1 |           1 |                1 |
       16384 |          0 |      16384 | chart_data           |
       16384 |
       | mycheckpoint  |           13 |          50 |                2 |
       3022602 |      88064 |    3110666 | status_variables     |
       2654208 |
       | mysql         |           23 |           0 |                2 |
       3259223 |    2551808 |    5811031 | time_zone_transition |
       4297362 |
       | sakila        |           16 |           7 |                2 |
       4297536 |    2761728 |    7059264 | rental               |
       2850816 |
       | test          |            6 |           0 |                2 |
       80232 |      45056 |     125288 | t                    |
       49152 |
       | world         |            3 |           0 |                2 |
       510355 |      28672 |     539027 | City                 |
       409600 |
       +---------------+--------------+-------------+------------------+-
       ----------+------------+------------+----------------------+------
       --------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

auto_increment_columns, data_size_per_engine

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('decode_xml','
NAME

decode_xml(): Decode XML characters in text.

TYPE

Function

DESCRIPTION

Return a decoded (unescaped) text of a given XML-valid text

SYNOPSIS



       decode_xml(txt TEXT CHARSET utf8)
         RETURNS TEXT CHARSET utf8


Input:

* txt: a XML text, to be decoded


EXAMPLES

Decode a normal text (no change expetced):


       mysql> SELECT decode_xml(''The quick brown fox'') AS decoded;
       +---------------------+
       | decoded             |
       +---------------------+
       | The quick brown fox |
       +---------------------+


Encode a text with special characters:


       mysql> SELECT decode_xml(''3 &gt; &quot;2&quot; &amp; 4 &lt; 5'') as
       decoded;
       +-----------------+
       | decoded         |
       +-----------------+
       | 3 > "2" & 4 < 5 |
       +-----------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

encode_xml()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('duplicate_grantee','
NAME

duplicate_grantee(): Create new account (grantee), identical to given account

TYPE

Procedure

DESCRIPTION

Given an existing GRANTEE anda new one, duplicate existing GRANTEE, along with
all applied set of privileges and password, to new account, creating the new
account if necessary.
This is essentially a Copy+Paste of an account.
The new account is generated via GRANT commands. For clarification, there is
no direct tampering with the mysql system tables (no DML used).

SYNOPSIS



       duplicate_grantee(
           IN existing_grantee TINYTEXT CHARSET utf8,
           IN new_grantee TINYTEXT CHARSET utf8
         )
         MODIFIES SQL DATA


Input:

* existing_grantee: an existing account/GRANTEE name. An error is thrown when
  no such account is found.
* new_grantee: name for new account.
  The new account is created, if not existing.
  In case this account already exists, it is added the set of privileges
  applying to existing_grantee, and its password is updated.

Both existing_grantee and new_grantee can be provided in relaxed format:
''web_user@10.0.0.%'' is a valid input, and is implicitly translated to
"''web_user''@''10.0.0.%''", which is the fully qualified account name.

EXAMPLES

Duplicate an account, creating a new GRANTEE. Verify operation''s result:


       mysql> SELECT * FROM similar_grants WHERE sample_grantee like
       ''%apps%'';
       +----------------+----------------+------------------+
       | sample_grantee | count_grantees | similar_grantees |
       +----------------+----------------+------------------+
       | ''apps''@''%''     |              1 | ''apps''@''%''       |
       +----------------+----------------+------------------+

       mysql> call duplicate_grantee(''apps@%'', ''apps@myhost'');
       Query OK, 0 rows affected (0.16 sec)

       mysql> SELECT * FROM similar_grants WHERE sample_grantee like
       ''%apps%'';
       +----------------+----------------+----------------------------+
       | sample_grantee | count_grantees | similar_grantees           |
       +----------------+----------------+----------------------------+
       | ''apps''@''%''     |              2 | ''apps''@''%'',''apps''@''myhost'' |
       +----------------+----------------+----------------------------+

       mysql> SHOW GRANTS FOR ''apps''@''%'';
       +-----------------------------------------------------------------
       ----------------------------------------------------+
       | Grants for apps@%
       |
       +-----------------------------------------------------------------
       ----------------------------------------------------+
       | GRANT USAGE ON *.* TO ''apps''@''%'' IDENTIFIED BY PASSWORD
       ''*6BB4837EB74329105EE4568DDA7DC67ED2CA2AD9''                 |
       | GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO ''apps''@''%''
       |
       | GRANT SELECT (title, description, film_id), UPDATE (description)
       ON `sakila`.`film` TO ''apps''@''%'' WITH GRANT OPTION |
       +-----------------------------------------------------------------
       ----------------------------------------------------+
       3 rows in set (0.00 sec)

       mysql> SHOW GRANTS FOR ''apps''@''myhost'';
       +-----------------------------------------------------------------
       ---------------------------------------------------------+
       | Grants for apps@myhost
       |
       +-----------------------------------------------------------------
       ---------------------------------------------------------+
       | GRANT USAGE ON *.* TO ''apps''@''myhost'' IDENTIFIED BY PASSWORD
       ''*6BB4837EB74329105EE4568DDA7DC67ED2CA2AD9''                 |
       | GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO
       ''apps''@''myhost''
       |
       | GRANT SELECT (title, description, film_id), UPDATE (description)
       ON `sakila`.`film` TO ''apps''@''myhost'' WITH GRANT OPTION |
       +-----------------------------------------------------------------
       ---------------------------------------------------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

match_grantee(), mysql_grantee(), similar_grants, sql_accounts

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('easter_day','
NAME

easter_day(): Returns DATE of easter day in given DATETIME''s year.

TYPE

Function

DESCRIPTION

Compute date for Easter Day on given year.

SYNOPSIS



       easter_day(dt DATETIME)
         RETURNS DATE


Input:

* dt: a DATETIME object, by which computation is made. dt is only checked for
  its YEAR part. All other information (month, day, time) is irrelevant.
  Hence, the two inputs ''2012-01-01'' and ''2012-08-27 15:16:17'' yield with the
  same result.


EXAMPLES



       mysql> SELECT common_schema.easter_day(''2012-01-01'') AS
       easter_day_2012;
       +-----------------+
       | easter_day_2012 |
       +-----------------+
       | 2012-04-08      |
       +-----------------+



ENVIRONMENT

MySQL 5.1 or newer

AUTHOR

Shlomi Noach, based on contribution by Roland Bouman
');
		
			INSERT INTO common_schema.help_content VALUES ('encode_xml','
NAME

encode_xml(): Encode a given text for XML.

TYPE

Function

DESCRIPTION

Return the given text valid for XML, with special characters properly encoded.

SYNOPSIS



       encode_xml(txt TEXT CHARSET utf8)
         RETURNS TEXT CHARSET utf8


Input:

* txt: an arbitrary text, to be encoded


EXAMPLES

Encode a normal text (no change expetced):


       mysql> SELECT encode_xml(''The quick brown fox'') AS encoded;
       +---------------------+
       | encoded             |
       +---------------------+
       | The quick brown fox |
       +---------------------+


Encode a text with special characters:


       mysql> SELECT encode_xml(''3 > "2" & 4 < 5'') AS encoded;
       +-------------------------------------+
       | encoded                             |
       +-------------------------------------+
       | 3 &gt; &quot;2&quot; &amp; 4 &lt; 5 |
       +-------------------------------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

decode_xml()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('eval','
NAME

eval(): Evaluates the queries generated by a given query.

TYPE

Procedure

DESCRIPTION

Evaluates the queries generated by a given query. Given sql_query is expected
to be a SQL generating query. That is, it is expected to produce, when
invoked, a single text column consisting of SQL queries. The column may
contain one or more queries per row. If multiple queries provided, the
semicolon (;) delimiter is expected to terminate each. The last query does not
have to be terminated with a semicolon.
The eval() procedure will invoke said queries, and then invoke (evaluate) any
of the resulting queries.
Invoker of this procedure must have the CREATE TEMPORARY TABLES privilege, as
well as any privileges required for evaluating implied queries.
Many of common_schema''s views include SQL columns: columns containing read-to-
invoke statements. Consider processlist_grantees, redundant_keys,
sql_accounts, sql_alter_table, sql_foreign_keys, sql_grants,
sql_range_partitions and more. Thus, it is possible to invoke eval() directly
on such views, see examples below.
common_schema offers alternatives to eval(), on popular use cases. In
particular, see QueryScript''s foreach statement for many operations that can
be produced via INFORMATION_SCHEMA.TABLES.
QueryScript also offers the eval statement, built into the language, which
uses exact same logic as this routine (and in fact relies on it).

SYNOPSIS



       eval(sql_query TEXT CHARSET utf8)
         MODIFIES SQL DATA


Input:

* sql_query: a query which generates SQL queries to be evaluated. Must return
  with exactly one column.

This procedure relies on exec_single(), which means it respects:

* @common_schema_dryrun: when 1, queries are not executed, but rather printed.
* @common_schema_verbose: when 1, queries are verbosed.


EXAMPLES

In the following example we kill all connections executing queries for more
than 20 seconds.


       mysql> SHOW PROCESSLIST;
       +----+------+-----------+---------------+---------+------+--------
       ----+---------------------+
       | Id | User | Host      | db            | Command | Time | State
       | Info                |
       +----+------+-----------+---------------+---------+------+--------
       ----+---------------------+
       |  2 | root | localhost | common_schema | Query   |    0 | NULL
       | SHOW PROCESSLIST    |
       | 43 | apps | localhost | NULL          | Query   |   28 | User
       sleep | select sleep(10000) |
       +----+------+-----------+---------------+---------+------+--------
       ----+---------------------+
       2 rows in set (0.00 sec)

       mysql> CALL eval(''SELECT CONCAT(\\''KILL \\'',id) FROM
       INFORMATION_SCHEMA.PROCESSLIST WHERE TIME > 20'');

       mysql> SHOW PROCESSLIST;
       +----+------+-----------+---------------+---------+------+-------
       +------------------+
       | Id | User | Host      | db            | Command | Time | State |
       Info             |
       +----+------+-----------+---------------+---------+------+-------
       +------------------+
       |  2 | root | localhost | common_schema | Query   |    0 | NULL  |
       SHOW PROCESSLIST |
       +----+------+-----------+---------------+---------+------+-------
       +------------------+
       1 row in set (0.00 sec)


As per previous note on common_schema views providing with SQL columns, see an
alternative to the above (and slightly more sophisticated), utilizing
processlist_grantees:


       mysql> CALL eval("SELECT sql_kill_query FROM processlist_grantees
       WHERE COMMAND != ''Sleep'' AND TIME > 20 AND is_super = 0 AND
       is_repl = 0");


Automatically add partition to a RANGE partition table (see
sql_range_partitions):


       mysql> CALL eval("SELECT sql_add_next_partition FROM
       sql_range_partitions WHERE table_name=''quarterly_report_status''");


Block accounts for user ''gromit'' (see sql_accounts):


       mysql> CALL eval("SELECT sql_block_account FROM sql_accounts WHERE
       USER = ''gromit''");


Kill transactions idle for 30 seconds or more:


       mysql> CALL eval("SELECT sql_kill_query FROM
       common_schema.innodb_transactions WHERE trx_idle_seconds >= 30");



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

eval, exec(), exec_single(), foreach(), repeat_exec()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('exec','
NAME

exec(): Executes a given query or semicolon delimited list of queries.

TYPE

Procedure

DESCRIPTION

This procedure will invoke a list of queries (one or more), by utilizing
dynamic SQL. It calls upon exec_single() for each query.
Queries may be of any valid type, that is allowed to invoke from within a
prepared statement:

* DML (e.g. INSERT, UPDATE, ...)
* DDL (e.g. CREATE, ALTER, ...)
* Other (e.g. KILL, SHOW, ...)

Refer to the MySQL_Manual for complete listing of valid statements.
The procedure is used as the underlying execution mechanism for other
common_schema routines, such as foreach(), repeat_exec() and exec_file().
Users will often not use this routine directly. Since it relies on exec_single
(), it respects the same input configuration (see following).
Invoker of this procedure must have the privileges required for execution of
given queries.

SYNOPSIS



       exec(IN execute_queries TEXT CHARSET utf8)
         MODIFIES SQL DATA


Input:

* execute_queries: one or more queries to execute.

  o Queries must be separated by a semicolon (";").
  o Last (or single) query may optionally be terminated by a semicolon, but it
    does not have to.
  o A semicolon may appear within quoted strings in queries.
  o Empty queries are discarded silently.


Input config (see also exec_single()):

* @common_schema_dryrun: when 1, queries are not executed, but rather printed.
* @common_schema_verbose: when 1, queries are verbosed.

Output:

* Whatever output the queries may produce.
* @common_schema_rowcount: number of rows affected by execution of the last
  query.


EXAMPLES

Execute sequence of commands, both DDL and DML:


       call exec(''CREATE TABLE test.t(id INT); INSERT INTO test.t VALUES
       (2),(3),(5); SELECT SUM(id) FROM test.t INTO @result;'');
       Query OK, 0 rows affected (0.06 sec)

       mysql> SELECT @result;
       +---------+
       | @result |
       +---------+
       |      10 |
       +---------+


Execute queries from server-side file (see also exec_file()).


       mysql> call exec(LOAD_FILE(''/tmp/statements.sql''));



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

eval(), exec_file(), exec_single(), foreach(), repeat_exec()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('exec_file','
NAME

exec_file(): Executes queries from given file, residing on server

TYPE

Procedure

DESCRIPTION

This procedure will read and execute a given file. The file is expected to
contain valid SQL statements.
The procedure acts in similar manner to the SOURCE command; only the SOURCE
command is a mysql_command_line_tool command, and works by reading a file from
the client.
exec_file() reads the file from the server machine. It does not require the
mysql command line tool, and works exclusively in server side.
Invoker of this procedure must have the FILE privilege, as well as any other
privilege required for executing the commands in the input file.
File size cannot be arbitrarily large. At current, a 64K is a hard limit on
the contents of the file. Due to internal mechanism, the limit turns lower
than 64K, depending on number and length of queries.
Statements are assumed to be separated be semicolons (";"). exec_file() does
not interpret DELIMITER commands.
As a general recommendation, you should not use this routine to import dumps,
nor should you attempt to ready very large files.

SYNOPSIS



       exec_file(IN file_name TEXT CHARSET utf8)
         MODIFIES SQL DATA


Input:

* file_name: input file name. This file must exist on the server host; must be
  readable (some Linux distributions contain AppArmor or similar security
  enhancements which place strict restrictions on reading files from MySQL).
  The file is assumed to contain valid SQL statements.
  Refer to the MySQL_Manual for complete listing of valid statements.


EXAMPLES

Execute command in file:


       call exec_file(''/tmp/my_statements.sql'');



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

eval(), exec(), exec_single()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('exec_single','
NAME

exec_single(): Executes a given query.

TYPE

Procedure

DESCRIPTION

Given a query, this procedure executes it. Essentially, is uses dynamic SQL to
invoke the query.
Query may be of any valid type:

* DML (e.g. INSERT, UPDATE, ...)
* DDL (e.g. CREATE, ALTER, ...)
* Other (e.g. KILL, SHOW, ...)

Refer to the MySQL_Manual for complete listing of valid statements.
The procedure is used as the underlying execution mechanism for other
common_schema routines. It''s main advantage is that it accepts input
configuration (see following). Users will often not use this routine directly.
Invoker of this procedure must have the privileges required for execution of
given query.

SYNOPSIS



       exec_single(IN execute_query TEXT CHARSET utf8)
         MODIFIES SQL DATA


Input:

* execute_query: a single query to execute. This can be DML, DDL or any other
  valid MySQL command. The procedure will not execute nor change anything when
  this input is empty (blank space). The query may be terminated by a
  semicolon, but does not have to. A semicolon may appear within query (e.g.
  in quoted text).

Input config:

* @common_schema_dryrun: when 1, query is not executed, but rather printed.
* @common_schema_verbose: when 1, query is verbosed.

Output:

* Whatever output the query may have.
* @common_schema_rowcount: number of rows affected by execution.


EXAMPLES

Use exec_single() to create a table:


       mysql> SHOW TABLES FROM world;
       +-----------------+
       | Tables_in_world |
       +-----------------+
       | City            |
       | Country         |
       | CountryLanguage |
       +-----------------+

       mysql> CALL exec_single(''CREATE TABLE world.Region (id INT)'');

       mysql> SHOW TABLES FROM world;
       +-----------------+
       | Tables_in_world |
       +-----------------+
       | City            |
       | Country         |
       | CountryLanguage |
       | Region          |
       +-----------------+


Do an insert, get resulting number of affected rows:


       mysql> CALL exec_single(''INSERT INTO world.Region VALUES (1),(2),
       (3),(4),(5)'');
       	
       mysql> SELECT @common_schema_rowcount;
       +-------------------------+
       | @common_schema_rowcount |
       +-------------------------+
       |                       5 |
       +-------------------------+


Do a dry run: do not actually execute statement, just print out your
intentions:


       mysql> SET @common_schema_dryrun := 1;
       	
       mysql> CALL exec_single(''DELETE FROM world.Region WHERE id < 3'');
       +---------------------------------------+
       | exec_single: @common_schema_dryrun    |
       +---------------------------------------+
       | DELETE FROM world.Region WHERE id < 3 |
       +---------------------------------------+

       mysql> SELECT COUNT(*) FROM world.Region;
       +----------+
       | COUNT(*) |
       +----------+
       |        5 |
       +----------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

eval(), exec(), foreach(), repeat_exec()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('execution_routines','
SYNOPSIS

Execution routines: stored routines managing dynamic query execution,
iteration & evaluation.

* eval(): Evaluates the queries generated by a given query.
* exec(): Executes a given query or semicolon delimited list of queries.
* exec_file():Executes queries from given file, residing on server./li>
* exec_single(): Executes a given query.
* foreach() aka $(): Invoke script on each element of given collection.
* repeat_exec(): Repeatedly executes given query or queries until some
  condition holds.
* run(): run a QueryScript code provided as text.
* run_file(): run a QueryScript code from file.
* script_runtime(): number of seconds elapsed since script execution began.
* throw(): Disrupt execution with error.


DESCRIPTION

These featured routines allow for scripting & semi-scripting capabilities in
MySQL. Looping through collections, row sets, numbers, tables; repeating tasks
until a given condition hold, or dynamically evaluating queries. The execution
routines simplify a DBA''s maintenance work by providing with a simpler,
cleaner and more familiar syntax.
The run() and run_file() routines execute QueryScript code. The rest of the
routines make for lower level, semi-scripting execution.
The majority of operations in these routines use dynamic queries, based on
prepared statements. Note that MySQL does not support invoking a prepared
statement from within a prepared statement. This means you may wish to avoid
calling on these routines using prepared statements code (some frameworks
will, by default, invoke queries using prepared statements regardless of the
query type).

EXAMPLES

Use foreach() to convert sakila tables to InnoDB:


       mysql> call foreach(
       	  ''table in sakila'',
       	  ''ALTER TABLE ${schema}.${table} ENGINE=InnoDB
       ROW_FORMAT=COMPACT'');


Use repeat_exec() to delete huge amount of rows in smaller chunks, with
sleeping interval:


       mysql> call repeat_exec(2,
       	  ''DELETE FROM sakila.rental WHERE customer_id=7 ORDER BY
       rental_id LIMIT 1000'',
       	  0);


Use eval() to kill transactions being idle for over 30 seconds:


       mysql> call eval("SELECT sql_kill_query FROM
       common_schema.innodb_transactions WHERE trx_idle_seconds > 30");


');
		
			INSERT INTO common_schema.help_content VALUES ('extract_json_value','
NAME

extract_json_value(): Extract value from JSON notation via XPath

TYPE

Function

DESCRIPTION

extract_json_value() accepts text in JSON format, and an XPath expression, and
extracts data from JSON matching path.
While XPath was originally developed for XML, its usage in other fields became
quickly widespread, including searching through object oriented structures.
XPath easily applies to JSON.
This function internally relies on json_to_xml(): it first converts the JSON
data to XML, then uses ExtractValue to apply XPath.
NOTE: this function is CPU intensive. This solution should ideally be
implemented through built-in functions, not stored routines.

SYNOPSIS



       extract_json_value(
           json_text TEXT CHARSET utf8
           xpath TEXT CHARSET utf8
       ) RETURNS TEXT CHARSET utf8


Input:

* json_text: a valid JSON formatted text.
* xpath: a valid XPath notation.


EXAMPLES

Extract JSON data:


       mysql> SET @json := ''
       {
         "menu": {
           "id": "file",
           "value": "File",
           "popup": {
             "menuitem": [
               {"value": "New", "onclick": "CreateNewDoc()"},
               {"value": "Open", "onclick": "OpenDoc()"},
               {"value": "Close", "onclick": "CloseDoc()"}
             ]
           }
         }
       }
       '';

       mysql> SELECT extract_json_value(@json, ''//id'') AS result;
       +--------+
       | result |
       +--------+
       | file   |
       +--------+

       mysql> SELECT extract_json_value(@json, ''count(/menu/popup/
       menuitem)'') AS count_items;
       +-------------+
       | count_items |
       +-------------+
       | 3           |
       +-------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

json_to_xml()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('foreach','
NAME

foreach(): Invoke a script on each element of given collection. $() is a
synonym of this routine.

TYPE

Procedure

DESCRIPTION

This procedure accepts collections of varying types, including result sets,
and invokes a QueryScript code per element.
The script can be as simple as a query, a set of queries, or a complex code.
The foreach() routine differs from the foreach flow control structure in
QueryScript, though they both use similar syntax and share some use cases.
Read here on the differences between the two.
foreach() passes on information about iterated values onto the script in two
ways:

* Using place holders (e.g. ${1}, ${2} etc.)
  In this approach the script''s text is manipulated such that placeholder
  occurrences are replaced with iterated values. This is a simple text search
  & replace approach, is very flexible, and allows for a lot of META tweaks.
  See following tables and examples for more on placeholders.
* Using input variables:
  Variables are passed on to the script as input variables. These are dynamic
  variables, on which the genral rules for user defined variables apply.

foreach() acts on server side only, and does not require shell access nor the
mysql command line client, although it may be spawned from within the mysql
client.
foreach() accepts several types of collections. They are automatically
recognized by their pattern. The following collections are recognized (also
see EXAMPLES section below):

* A SELECT query: any SELECT statement makes for a collection, which is the
  result set of the query.
  The query must specify result columns. That is, a SELECT * query is not
  valid.
  Otherwise any SELECT query is valid, with any result set. However, only
  first 9 columns in the result set can be used as place holders for the
  callback queries.
  Each row in the result set is an element.
  The queries are allowed to act upon the table(s) being iterated, i.e. one
  can execute a DELETE on rows being iterated.
  The place holders ${1} - ${9} relate to columns #1 - #9.
* Numbers range: a range of integers, both inclusive, e.g. ''1970:2038''.
  Negative values are allowed. The first (left) value should be smaller or
  equal to the second (right) value, or else no iteration is performed.
  The place holder ${1} indicates the iterated value.
* Two dimensional numbers range: a double range of integers, e.g. ''-10:
  10,1970:2038''.
  Each one of the ranges answers to the same rules as for a single range.
  There will be m * n iterations on ranges of size m and n. For example, in
  the sample range above there will be 11 * 69 iterations (or elements).
  The place holders ${1}, ${2} indicate the iterated values.
* A constants set: a predefined set of constant values, e.g. ''{red, green,
  blue}''.
  Constants are separated by either spaces or commas (or both).
  Constants can be quoted so as to allow spaces or commas within constant
  value. Quotes themselves are discarded.
  Empty constants are discarded.
  The place holder ${1} indicates the current constant value.
* ''schema'': this is the collection of available schemata (e.g. as with SHOW
  DATABASES).
  The place holder ${1} indicates the current schema. ${schema} is a synonym
  for ${1}.
* ''schema like expr'': databases whose names match the given LIKE expression.
  The place holder ${1} indicates the current schema. ${schema} is a synonym
  for ${1}.
* ''schema ~ /regexp/'': databases whose names match the given regular
  expression.
  The place holder ${1} indicates the current schema. ${schema} is a synonym
  for ${1}.
* ''table in schema_names'': collection of all tables in given schema. Only
  tables are included: views are not listed.
  This syntax is INFORMATION_SCHEMA friendly, in that it only scans and opens
  .frm files for given schema.
  The place holder ${1} indicates the current table. ${table} is a synonym for
  ${1}.
  The place holder ${2} indicates the schema. ${schema} is a synonym for ${2}.

  The place holder ${3} indicates the storage engine. ${engine} is a synonym
  for ${3}.
  The place holder ${4} indicates the CREATE_OPTIONS ${create_options} is a
  synonym for ${4}.
* ''table like expr'': all tables whose names match the given LIKE expression.
  These can be tables from different databases/schemata.
  This syntax is INFORMATION_SCHEMA friendly, in that it only scans and opens
  .frm files for a single schema at a time. This reduces locks and table cache
  entries, while potentially taking longer to complete.
  The place holder ${1} indicates the current table. ${table} is a synonym for
  ${1}.
  The place holder ${2} indicates the schema for current table. ${schema} is a
  synonym for ${2}.
  The place holder ${3} indicates the storage engine. ${engine} is a synonym
  for ${3}.
  The place holder ${4} indicates the CREATE_OPTIONS ${create_options} is a
  synonym for ${4}.
* ''table ~ /regexp/'': all tables whose names match the given regular
  expression. These can be tables from different databases/schemata.
  This syntax is INFORMATION_SCHEMA friendly, in that it only scans and opens
  .frm files for a single schema at a time. This reduces locks and table cache
  entries, while potentially taking longer to complete.
  The place holder ${1} indicates the current table. ${table} is a synonym for
  ${1}.
  The place holder ${2} indicates the schema for current table. ${schema} is a
  synonym for ${2}.
  The place holder ${3} indicates the storage engine. ${engine} is a synonym
  for ${3}.
  The place holder ${4} indicates the CREATE_OPTIONS ${create_options} is a
  synonym for ${4}.

Any other type of input raises an error.
Following is a brief sample of valid collection input:

Collection type               Example of valid input
SELECT query                  ''SELECT id, name FROM
                              INFORMATION_SCHEMA.PROCESSLIST WHERE time > 20''
Numbers range                 ''1970:2038''
Two dimensional numbers range ''0:23,0:59''
Constants set                 ''{USA, "GREAT BRITAIN", FRA, IT, JP}''
''schema''                      ''schema''
''schema like expr''            ''schema like customer_%''
''schema ~ /regexp/''           ''schema ~ /^customer_[0-9]+$/
''table in schema_name''        ''table in sakila''
''table like expr''             ''table like wp_%''
''table ~ /regexp/''            ''table ~ /^state_[A-Z]{2}$/''

The following table summarizes the types of collections and the valid place
holders:

Collection type               Valid place holders
SELECT query                  ${1}, ${2}, ..., ${9}, ${NR}
Numbers range                 ${1}, ${NR}
Two dimensional numbers range ${1}, ${2}, ${NR}
Constants set                 ${1}, ${NR}
''schema''                      ${1} or ${schema}, ${NR}
''schema like expr''            ${1} or ${schema}, ${NR}
''schema ~ /regexp/''           ${1} or ${schema}, ${NR}
''table in schema_name''        ${1} or ${table), ${2} or ${schema}, ${3} or $
                              {engine}, ${4} or ${create_options}, ${NR}
''table like expr''             ${1} or ${table), ${2} or ${schema}, ${3} or $
                              {engine}, ${4} or ${create_options}, ${NR}
''table ~ /regexp/''            ${1} or ${table), ${2} or ${schema}, ${3} or $
                              {engine}, ${4} or ${create_options}, ${NR}

${NR} is accepted in all collections, and returns the iteration index, 1
based. That is, the first element in a collection has 1 for ${NR}, the seconds
has 2, etc. It is similar in concept to ${NR} in awk.
Invoker of this procedure must have the privileges required for execution of
given queries.

SYNOPSIS



       foreach(collection TEXT CHARSET utf8, execute_queries TEXT CHARSET
       utf8)


Input:

* collection: the collection on which to iterate; must be in a recognized
  format as discussed above.
* execute_queries: one or more queries to execute per loop iteration.
  Queries are separated by semicolons (;). See exec() for details.

Since the routines relies on exec(), it accepts the following input config:

* @common_schema_dryrun: when 1, queries are not executed, but rather printed.
* @common_schema_verbose: when 1, queries are verbosed.

Output:

* Whatever output the queries may produce.


EXAMPLES


* SELECT query
  Kill queries for user ''analytics''.
  We take advantage of the fact we do not use ANSI_QUOTES, and so we are able
  to use nicer quoting scheme, as with JavaScript or Python.


         mysql> call foreach(
         	"SELECT id FROM INFORMATION_SCHEMA.PROCESSLIST WHERE user =
         ''analytics''",
         	''KILL QUERY ${1}'');


  Select multiple columns; execute multiple queries based on those columns:


         mysql> call foreach(
         	"SELECT Code, Name FROM world.Country WHERE
         Continent=''Europe''",
         	"DELETE FROM world.CountryLanguage WHERE CountryCode = ''${1}'';
         	DELETE FROM world.City WHERE CountryCode = ''${1}'';
         	DELETE FROM Country WHERE Code = ''${1}'';
         	INSERT INTO logs (msg) VALUES (''deleted country: name=$
         {2}'');");


* Numbers range:
  Delete records from July-August for years 2001 - 2009:


         mysql> call foreach(
         	''2001:2009'',
         	"DELETE FROM sakila.rental WHERE rental_date >= ''${1}-07-01''
         AND rental_date < ''${1}-09-01''");


  Generate tables; use $() synonym of foreach():


         mysql> call $(''1:50'', "CREATE TABLE test.t_${1} (id INT)");
         		
         mysql> SHOW TABLES FROM test;
         +----------------+
         | Tables_in_test |
         +----------------+
         | from_file      |
         | t              |
         | t_1            |
         | t_10           |
         | t_11           |
         | t_12           |
         | t_13           |
         | t_14           |
         ...
         +----------------+ 		


* Two dimensional numbers range:
  Fill in data for all tables generated on last step:


         mysql> call foreach(''1:50,1970:2038'', "INSERT INTO test.t_${1}
         VALUES (${2})");


* Constants set:
  Generate databases:


         mysql> call foreach(''{US, GB, Japan, FRA}'', ''CREATE DATABASE
         db_${1}'');

         mysql> show databases LIKE ''db_%'';
         +-----------------+
         | Database (db_%) |
         +-----------------+
         | db_FRA          |
         | db_GB           |
         | db_Japan        |
         | db_US           |
         +-----------------+


* ''schema'':
  List full tables on all schemata:


         mysql> call foreach(''schema'', "SHOW FULL TABLES FROM $
         {schema}");
         +---------------------------------------+-------------+
         | Tables_in_information_schema          | Table_type  |
         +---------------------------------------+-------------+
         | CHARACTER_SETS                        | SYSTEM VIEW |
         | COLLATIONS                            | SYSTEM VIEW |
         | COLLATION_CHARACTER_SET_APPLICABILITY | SYSTEM VIEW |
         | COLUMNS                               | SYSTEM VIEW |
         | COLUMN_PRIVILEGES                     | SYSTEM VIEW |
         ...
         +---------------------------------------+-------------+

         ...
         		
         +-----------------+------------+
         | Tables_in_world | Table_type |
         +-----------------+------------+
         | City            | BASE TABLE |
         | Country         | BASE TABLE |
         | CountryLanguage | BASE TABLE |
         | Region          | BASE TABLE |
         +-----------------+------------+


* ''schema like expr'':
  Create a new table in all hosted WordPress schemata:


         mysql> call foreach(
         	''schema like wp%'',
         	''CREATE TABLE ${schema}.wp_likes(id int, data VARCHAR(128))'');
         		


* ''schema ~ /regexp/'':
  Likewise, be more accurate on schema name:


         mysql> call foreach(
         	''schema ~ /^wp_[\\d]+$/'',
         	''CREATE TABLE ${schema}.wp_likes(id int, data VARCHAR(128))'');
         		


* ''table in schema_name'':
  Convert all tables in world to InnoDB:


         mysql> call $(''table in world'',	''ALTER TABLE ${schema}.${table}
         ENGINE=InnoDB'');
         		


* ''table like expr'':
  Add a column to all wp_posts tables in hosted WordPress databases:


         mysql> call foreach(
         	''table like wp_posts'',
         	''ALTER TABLE ${schema}.${table} ADD COLUMN post_geo_location
         VARCHAR(128);'');
         		


* ''table ~ /regexp/'':
  Add a column to tables whose name matches the given regular expression, in
  any database:


         mysql> call foreach(
         	''table ~ /^customer_data_[\\d]+$/'',
         	''ALTER TABLE ${schema}.${table} ADD COLUMN
         customer_geo_location VARCHAR(128);'');
         		




ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

exec(), exec_single(), repeat_exec()

AUTHOR

Shlomi Noach, Roland Bouman
');
		
			INSERT INTO common_schema.help_content VALUES ('general_routines','
SYNOPSIS

General routines: general purpose tasks routines.

* crc64(): Return a 64 bit CRC of given input, as unsigned big integer.
* query_checksum(): Checksum the result set of a query.
* random_hash(): Return a 64 bit CRC of given input, as unsigned big integer.
* shorttime_to_seconds(): Return the number of seconds represented by the
  given short form.


EXAMPLES

Calculate 64 bit CRC for some text:


       mysql> SELECT common_schema.crc64(''mysql'') AS crc64;
       +---------------------+
       | crc64               |
       +---------------------+
       | 9350511318824990686 |
       +---------------------+


Use shorttime_to_seconds() to parse ''2h'', making for 2 hours:


       mysql> SELECT shorttime_to_seconds(''2h'') as seconds;
       +---------+
       | seconds |
       +---------+
       |    7200 |
       +---------+


');
		
			INSERT INTO common_schema.help_content VALUES ('get_event_dependencies','
NAME

get_event_dependencies(): Analyze and list the dependencies of a given event
(BETA)

TYPE

Procedure

DESCRIPTION

This procedure will analyze the CREATE EVENT statement of the given event, and
provide with dependency listing: the objects on which this event depends, e.g.
tables or routines.
get_event_dependencies() will parse the internal event''s stored routine code,
detect queries issued within, including calls to other routines, and will list
such dependencies.
The routine does not perform deep search, and will not analyze views or
routines on which the given event depends.
It is not, and will not be, able to parse dynamic SQL, i.e. prepared
statements made from string literals.
This procedure calls upon the more generic get_sql_dependencies() routine.
This code is in BETA stage.

SYNOPSIS



       get_event_dependencies (
           IN p_routine_schema VARCHAR(64) CHARSET utf8
       ,   IN p_routine_name VARCHAR(64) CHARSET utf8
       )
       DETERMINISTIC
       READS SQL DATA


Input:

* p_table_schema: schema where event is located.
* p_table_name: name of event.


STRUCTURE

The procedure returns a result set of dependencies for this event, in same
format as in get_sql_dependencies():

* schema_name: schema where dependency is located.
* object_name: name of dependency object.
* object_type: type of dependency object (e.g. ''table'', ''function'' etc.).
* action: type of action performed on object (e.g. ''select'', ''call'' etc.).


EXAMPLES

Analyze an event on sakila:


       mysql> CREATE EVENT
         sakila.purge_history
       ON SCHEDULE
         EVERY 1 DAY
       ON COMPLETION PRESERVE
       ENABLE
       DO
         DELETE FROM sakila.rental WHERE rental_date < DATE(NOW() -
       INTERVAL 5 YEAR);
       	
       mysql> call common_schema.get_event_dependencies(''sakila'',
       ''purge_history'');
       +-------------+-------------+-------------+--------+
       | schema_name | object_name | object_type | action |
       +-------------+-------------+-------------+--------+
       | sakila      | rental      | table       | delete |
       +-------------+-------------+-------------+--------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

get_routine_dependencies(), get_sql_dependencies(), get_view_dependencies()

AUTHOR

Roland Bouman
');
		
			INSERT INTO common_schema.help_content VALUES ('get_num_tokens','
NAME

get_num_tokens(): Return number of tokens in delimited text.

TYPE

Function

DESCRIPTION

Assumes given text txt is tokenized by given delimiter_text, and returns the
number of tokens in the split text. Delimiter is assumed to be fixed text, of
any length (not necessarily one character).

SYNOPSIS



       get_num_tokens(txt TEXT CHARSET utf8, delimiter_text VARCHAR(255)
       CHARSET utf8)
         RETURNS INT UNSIGNED


Input:

* txt: text to be parsed. When NULL, the result is NULL.
* delimiter_text: delimiter text; can be zero or more characters.
  When delimiter_text is the empty text (zero characters), function''s result
  is the number of characters in txt.
  When delimiter_text is not found in the text, function returns with 1.


EXAMPLES

Tokenize by space:


       mysql> SELECT common_schema.get_num_tokens(''the quick brown fox'',
       '' '') AS num_tokens;
       +------------+
       | num_tokens |
       +------------+
       |          4 |
       +------------+


Tokenize by non-existing delimiter:


       mysql> SELECT common_schema.get_num_tokens(''single'', '','') AS
       num_tokens;
       +------------+
       | num_tokens |
       +------------+
       |          1 |
       +------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

split_token()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('get_option','
NAME

get_option(): Extract value from options dictionary based on key

TYPE

Function

DESCRIPTION

get_option() accepts a simple dictionary and a key, and extract the value
which maps to give nkey within the dictionary.
The dictionary is similar in format to Python''s dictionary or to JavaScript''s
shallow JSON object. For example, consider the following:


       {name: "Wallace", num_children: 0, "pet": Gromit}


In the above there are three entries, each with key and value. Either key or
value can be quoted, but mostly do not have to be. Quotes are essential when
the characters "," or ";" appear within name or value.
Everything is considered to be a string, even if a number is provided. Key and
value may consist of any character, and neither are limited to alphanumeric
values. They may contain spaces, though these are best used within quotes.
The dictionary cannot have sub-dictionaries. Any such values are treated as
text.
There may be multiple entries for the same key, in which case get_option()
returns the first one defined. When a key does not exist the function returns
NULL. The value NULL, when not quoted, is interpreted as the SQL NULL value.
Upon error (e.g. incorrect dictionary definition) the function returns NULL.

SYNOPSIS



       get_option(options TEXT CHARSET utf8, key_name VARCHAR(255)
       CHARSET utf8)
         RETURNS TEXT CHARSET utf8


Input:

* options: a dictionary, in Python-style format (see examples following)
* key_name: entry to look for within the dictionary.


EXAMPLES

Get an existing value:


       mysql> SELECT get_option(''{name: "Wallace", num_children: 0,
       "pet": Gromit}'', ''pet'') AS result;
       +--------+
       | result |
       +--------+
       | Gromit |
       +--------+


Attempt to read an unmapped value:


       mysql> SELECT get_option(''{name: "Wallace", num_children: 0,
       "pet": Gromit}'', ''wife'') AS result;
       +--------+
       | result |
       +--------+
       | NULL   |
       +--------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

split_token()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('get_routine_dependencies','
NAME

get_routine_dependencies(): Analyze and list the dependencies of a given
routine (BETA)

TYPE

Procedure

DESCRIPTION

This procedure will analyze the CREATE PROCEDURE or CREATE FUNCTION statement
of the given routine, and provide with dependency listing: the objects on
which this routine depends, e.g. tables or routines.
get_routine_dependencies() will parse the internal stored routine code, detect
queries issued within, including calls to other routines, and will list such
dependencies.
The routine does not perform deep search, and will not analyze views or
routines on which the given routine depends.
It is not, and will not be, able to parse dynamic SQL, i.e. prepared
statements made from string literals.
This procedure calls upon the more generic get_sql_dependencies() routine.
This code is in BETA stage.

SYNOPSIS



       get_routine_dependencies (
           IN p_routine_schema VARCHAR(64) CHARSET utf8
       ,   IN p_routine_name VARCHAR(64) CHARSET utf8
       )
       DETERMINISTIC
       READS SQL DATA


Input:

* p_table_schema: schema where routine is located.
* p_table_name: name of routine.


STRUCTURE

The procedure returns a result set of dependencies for this routine, in same
format as in get_sql_dependencies():

* schema_name: schema where dependency is located.
* object_name: name of dependency object.
* object_type: type of dependency object (e.g. ''table'', ''function'' etc.).
* action: type of action performed on object (e.g. ''select'', ''call'' etc.).


EXAMPLES

Analyze sakila''s inventory_in_stock routine:


       mysql> call get_routine_dependencies(''sakila'',
       ''inventory_in_stock'');
       +-------------+-------------+-------------+--------+
       | schema_name | object_name | object_type | action |
       +-------------+-------------+-------------+--------+
       | sakila      | inventory   | table       | select |
       | sakila      | rental      | table       | select |
       +-------------+-------------+-------------+--------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

get_event_dependencies(), get_sql_dependencies(), get_view_dependencies()

AUTHOR

Roland Bouman
');
		
			INSERT INTO common_schema.help_content VALUES ('get_sql_dependencies','
NAME

get_sql_dependencies(): Analyze and list the dependencies of a given query
(BETA)

TYPE

Procedure

DESCRIPTION

This procedure will analyze the given query, and provide with dependency
listing: the objects on which this query depends, e.g. tables, routines, views
etc.
get_sql_dependencies() will parse the query''s text to detect such objects. It
will not validate their existence or correctness. It will not perform deep
search in order to further find dependencies of those objects.
Thus, this routines does not actually perform any SQL operations, other than
create and use internal temporary structures. It will not access
INFORMATION_SCHEMA nor any other metadata.
It is not, and will not be, able to parse dynamic SQL, i.e. prepared
statements made from string literals.
This procedure serves as the basis to other analysis routines.
This code is in BETA stage.

SYNOPSIS



       get_sql_dependencies(
           IN p_sql               TEXT charset utf8
       ,   IN p_default_schema    VARCHAR(64) charset utf8
       )
       DETERMINISTIC


Input:

* p_sql: query to analyze
* p_default_schema: schema context to assume for query


STRUCTURE

The procedure returns a result set of dependencies for this routine:

* schema_name: schema where dependency is located.
* object_name: name of dependency object.
* object_type: type of dependency object (e.g. ''table'', ''function'' etc.).
* action: type of action performed on object (e.g. ''select'', ''call'' etc.).


EXAMPLES

Analyze a CREATE VIEW query:


       mysql> call get_sql_dependencies(''CREATE VIEW sakila.simple_actor
       AS SELECT actor_id, first_name FROM sakila.actor'', ''sakila'');

       +-------------+--------------+-------------+--------+
       | schema_name | object_name  | object_type | action |
       +-------------+--------------+-------------+--------+
       | sakila      | actor        | table       | select |
       | sakila      | simple_actor | view        | create |
       +-------------+--------------+-------------+--------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

get_event_dependencies(), get_routine_dependencies(), get_view_dependencies()

AUTHOR

Roland Bouman
');
		
			INSERT INTO common_schema.help_content VALUES ('get_view_dependencies','
NAME

get_view_dependencies(): Analyze and list the dependencies of a given view
(BETA)

TYPE

Procedure

DESCRIPTION

This procedure will analyze the CREATE VIEW statement of the given view, and
provide with dependency listing: the objects on which this view depends, e.g.
tables or routines.
The routine does not perform deep search, and will not analyze views or
routines on which the given view depends.
This procedure calls upon the more generic get_sql_dependencies() routine.
This code is in BETA stage.

SYNOPSIS



       get_view_dependencies (
           IN p_table_schema VARCHAR(64) CHARSET utf8
       ,   IN p_table_name VARCHAR(64) CHARSET utf8
       )
       DETERMINISTIC
       READS SQL DATA


Input:

* p_table_schema: schema where view is located.
* p_table_name: name of view.


STRUCTURE

The procedure returns a result set of dependencies for this view, in same
format as in get_sql_dependencies():

* schema_name: schema where dependency is located.
* object_name: name of dependency object.
* object_type: type of dependency object (e.g. ''table'', ''function'' etc.).
* action: type of action performed on object (e.g. ''select'', ''create'' etc.).


EXAMPLES

Analyze sakila''s actor_info view, which joins several tables:


       mysql> call get_view_dependencies(''sakila'', ''actor_info'');
       +-------------+---------------+-------------+--------+
       | schema_name | object_name   | object_type | action |
       +-------------+---------------+-------------+--------+
       | sakila      | actor         | table       | select |
       | sakila      | category      | table       | select |
       | sakila      | film          | table       | select |
       | sakila      | film_actor    | table       | select |
       | sakila      | film_category | table       | select |
       +-------------+---------------+-------------+--------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

get_event_dependencies(), get_routine_dependencies(), get_sql_dependencies()

AUTHOR

Roland Bouman
');
		
			INSERT INTO common_schema.help_content VALUES ('global_status_diff','
NAME

global_status_diff: Status variables difference over time, with interpolation
and extrapolation per time unit

TYPE

View

DESCRIPTION

global_status_diff takes two samples of GLOBAL STATUS, 10 seconds apart
(within the view''s query) and prints out the difference between the two
samples, along with interpolated/extrapolated change per second/minute,
respectively.
Measuring changes in GLOBAL STATUS is essential to any MySQL monitoring
scheme. For example, the change in com_select presents the number of issues
SELECT queries. Knowing the rate of queries (e.g. number of SELECTs per
second) is key information to understanding server behavior and analyzing its
performance.
global_status_diff provides with possibly the simplest status sampling code,
as it allows one to query such information from within MySQL. Other tools
require external applications/scripts to execute.
The view utilizes INFORMATION_SCHEMA.GLOBAL_STATUS and calculates the change
for all variables. For some variables this does not make sense (examples are:
rpl_status, slave_running, open_tables etc.). It is up to the user of this
view to isolate desired variables.
Querying this view takes 10 seconds to complete. In between the first and
second samples the view''s query will be sleeping.

STRUCTURE



       mysql> DESC common_schema.global_status_diff;
       +------------------------+---------------+------+-----+---------+-
       ------+
       | Field                  | Type          | Null | Key | Default |
       Extra |
       +------------------------+---------------+------+-----+---------+-
       ------+
       | variable_name          | varchar(64)   | YES  |     | NULL    |
       |
       | variable_value_0       | longtext      | YES  |     | NULL    |
       |
       | variable_value_1       | varchar(1024) | YES  |     | NULL    |
       |
       | variable_value_diff    | double        | YES  |     | NULL    |
       |
       | variable_value_psec    | double        | YES  |     | NULL    |
       |
       | variable_value_pminute | double        | YES  |     | NULL    |
       |
       +------------------------+---------------+------+-----+---------+-
       ------+



SYNOPSIS

Columns of this view:

* variable_name: name of global status variable
* variable_value_0: first sample value
* variable_value_1: second sample value
* variable_value_diff: difference between the two samples
* variable_value_psec: average change in value per second of execution
* variable_value_pminute: estimated (via extrapolation) average change in
  value per minute of execution


EXAMPLES

Get status difference for varios InnoDB write metrics:


       mysql> SELECT * FROM common_schema.global_status_diff WHERE
       variable_name LIKE ''innodb_%write%'';
       +-----------------------------------+------------------+----------
       --------+---------------------+---------------------+-------------
       -----------+
       | variable_name                     | variable_value_0 |
       variable_value_1 | variable_value_diff | variable_value_psec |
       variable_value_pminute |
       +-----------------------------------+------------------+----------
       --------+---------------------+---------------------+-------------
       -----------+
       | innodb_buffer_pool_write_requests | 1000528622       |
       1000528683       |                  61 |                 6.1 |
       366 |
       | innodb_data_pending_writes        | 0                | 0
       |                   0 |                   0 |
       0 |
       | innodb_data_writes                | 100335216        | 100335247
       |                  31 |                 3.1 |
       186 |
       | innodb_dblwr_writes               | 603031           | 603032
       |                   1 |                 0.1 |
       6 |
       | innodb_log_write_requests         | 338838621        | 338838633
       |                  12 |                 1.2 |
       72 |
       | innodb_log_writes                 | 69311204         | 69311213
       |                   9 |                 0.9 |
       54 |
       | innodb_os_log_pending_writes      | 0                | 0
       |                   0 |                   0 |
       0 |
       +-----------------------------------+------------------+----------
       --------+---------------------+---------------------+-------------
       -----------+


Show complete samples analysis:


       mysql> SELECT * FROM common_schema.global_status_diff;
       +---------------------------------------+------------------+------
       ------------+---------------------+---------------------+---------
       ---------------+
       | variable_name                         | variable_value_0 |
       variable_value_1 | variable_value_diff | variable_value_psec |
       variable_value_pminute |
       +---------------------------------------+------------------+------
       ------------+---------------------+---------------------+---------
       ---------------+
       | aborted_clients                       | 2276049          |
       2276059          |                  10 |                   1 |
       60 |
       | aborted_connects                      | 72               | 72
       |                   0 |                   0 |
       0 |
       | binlog_cache_disk_use                 | 0                | 0
       |                   0 |                   0 |
       0 |
       | binlog_cache_use                      | 0                | 0
       |                   0 |                   0 |
       0 |
       | bytes_received                        | 48240316982      |
       48240364869      |               47887 |              4788.7 |
       287322 |
       | bytes_sent                            | 400087906753     |
       400090499674     |             2592921 |            259292.1 |
       15557526 |
       | com_admin_commands                    | 0                | 0
       |                   0 |                   0 |
       0 |
       | com_assign_to_keycache                | 0                | 0
       |                   0 |                   0 |
       0 |
       | com_alter_db                          | 0                | 0
       |                   0 |                   0 |
       0 |
       | com_alter_db_upgrade                  | 0                | 0
       |                   0 |                   0 |
       0 |
       | com_alter_event                       | 0                | 0
       |                   0 |                   0 |
       0 |
       | com_alter_function                    | 0                | 0
       |                   0 |                   0 |
       0 |
       | com_alter_procedure                   | 0                | 0
       |                   0 |                   0 |
       0 |
       | com_alter_server                      | 0                | 0
       |                   0 |                   0 |
       0 |
       | com_alter_table                       | 2                | 2
       |                   0 |                   0 |
       0 |
       | com_alter_tablespace                  | 0                | 0
       |                   0 |                   0 |
       0 |
       | com_analyze                           | 102952           |
       102952           |                   0 |                   0 |
       0 |
       | com_backup_table                      | 0                | 0
       |                   0 |                   0 |
       0 |
       | com_begin                             | 0                | 0
       |                   0 |                   0 |
       0 |
       | com_binlog                            | 0                | 0
       |                   0 |                   0 |
       0 |
       | com_call_procedure                    | 0                | 0
       |                   0 |                   0 |
       0 |
       | com_change_db                         | 3762413          |
       3762422          |                   9 |                 0.9 |
       54 |
       ...
       many more rows
       ...
       +------------+----------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ------+


Just look at the number of selects:


       mysql> SELECT * FROM common_schema.global_status_diff WHERE
       variable_name = ''com_select'';
       +---------------+------------------+------------------+-----------
       ----------+---------------------+------------------------+
       | variable_name | variable_value_0 | variable_value_1 |
       variable_value_diff | variable_value_psec | variable_value_pminute
       |
       +---------------+------------------+------------------+-----------
       ----------+---------------------+------------------------+
       | com_select    | 44977723         | 44977764         |
       41 |                 4.1 |                    246 |
       +---------------+------------------+------------------+-----------
       ----------+---------------------+------------------------+


global_status_diff_clean and global_status_diff_nonzero build upon this view
for further common usage.

ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

global_status_diff_clean, global_status_diff_nonzero

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('global_status_diff_clean','
NAME

global_status_diff_clean: Status variables difference over time, with spaces
where zero diff encountered

TYPE

View

DESCRIPTION

global_status_diff_clean is a visual presentation case for global_status_diff
It presents with same data from global_status_diff, except that when no
difference encountered (value unchanged for the sampling duration), the zero
value is replaced with empty text.
It is merely a visualization aid, allowing the eye to more easily catch
changed values. Automated reads should keep to global_status_diff.

STRUCTURE



       mysql> DESC common_schema.global_status_diff_clean;
       +------------------------+---------------+------+-----+---------+-
       ------+
       | Field                  | Type          | Null | Key | Default |
       Extra |
       +------------------------+---------------+------+-----+---------+-
       ------+
       | variable_name          | varchar(64)   | YES  |     | NULL    |
       |
       | variable_value_0       | longtext      | YES  |     | NULL    |
       |
       | variable_value_1       | varchar(1024) | YES  |     | NULL    |
       |
       | variable_value_diff    | varbinary(23) | YES  |     | NULL    |
       |
       | variable_value_psec    | varbinary(23) | YES  |     | NULL    |
       |
       | variable_value_pminute | varbinary(23) | YES  |     | NULL    |
       |
       +------------------------+---------------+------+-----+---------+-
       ------+



SYNOPSIS

The structure of this view is identical to that of global_status_diff, except:

* variable_value_diff: difference between the two samples, or empty text when
  difference is zero
* variable_value_psec: average change in value per second of execution, or
  empty text when difference is zero
* variable_value_pminute: estimated (via extrapolation) average change in
  value per minute of execution, or empty text when difference is zero


EXAMPLES

Get status difference for various InnoDB write metrics:


       mysql> SELECT * FROM common_schema.global_status_diff_clean WHERE
       variable_name LIKE ''innodb_%write%'';
       +-----------------------------------+------------------+----------
       --------+---------------------+---------------------+-------------
       -----------+
       | variable_name                     | variable_value_0 |
       variable_value_1 | variable_value_diff | variable_value_psec |
       variable_value_pminute |
       +-----------------------------------+------------------+----------
       --------+---------------------+---------------------+-------------
       -----------+
       | innodb_buffer_pool_write_requests | 1000933916       |
       1000934526       | 610                 | 61                  |
       3660                   |
       | innodb_data_pending_writes        | 0                | 0
       |                     |                     |
       |
       | innodb_data_writes                | 100388839        | 100389001
       | 162                 | 16.2                | 972
       |
       | innodb_dblwr_writes               | 603346           | 603346
       |                     |                     |
       |
       | innodb_log_write_requests         | 338954473        | 338954531
       | 58                  | 5.8                 | 348
       |
       | innodb_log_writes                 | 69347559         | 69347618
       | 59                  | 5.9                 | 354
       |
       | innodb_os_log_pending_writes      | 0                | 0
       |                     |                     |
       |
       +-----------------------------------+------------------+----------
       --------+---------------------+---------------------+-------------
       -----------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

global_status_diff, global_status_diff_nonzero

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('global_status_diff_nonzero','
NAME

global_status_diff_nonzero: Status variables difference over time, only
nonzero findings listed

TYPE

View

DESCRIPTION

global_status_diff_nonzero is a common implementation case for
global_status_diff
This view merely presents with all global_status_diff where differences are
found. That is, a GLOBAL STATUS variable which indicated no change in the
sampling duration, is filtered out.

STRUCTURE



       mysql> DESC common_schema.global_status_diff_nonzero;
       +------------------------+---------------+------+-----+---------+-
       ------+
       | Field                  | Type          | Null | Key | Default |
       Extra |
       +------------------------+---------------+------+-----+---------+-
       ------+
       | variable_name          | varchar(64)   | YES  |     | NULL    |
       |
       | variable_value_0       | longtext      | YES  |     | NULL    |
       |
       | variable_value_1       | varchar(1024) | YES  |     | NULL    |
       |
       | variable_value_diff    | double        | YES  |     | NULL    |
       |
       | variable_value_psec    | double        | YES  |     | NULL    |
       |
       | variable_value_pminute | double        | YES  |     | NULL    |
       |
       +------------------------+---------------+------+-----+---------+-
       ------+



SYNOPSIS

The structure of this view is identical to that of global_status_diff.

EXAMPLES

Show GLOBAL STATUS changes (analyzing a QA server):


       mysql> SELECT * FROM common_schema.global_status_diff_nonzero;
       +-----------------------------------+------------------+----------
       --------+---------------------+---------------------+-------------
       -----------+
       | variable_name                     | variable_value_0 |
       variable_value_1 | variable_value_diff | variable_value_psec |
       variable_value_pminute |
       +-----------------------------------+------------------+----------
       --------+---------------------+---------------------+-------------
       -----------+
       | aborted_clients                   | 2308192          | 2308200
       |                   8 |                 0.8 |
       48 |
       | bytes_received                    | 48781508357      |
       48781571162      |               62805 |              6280.5 |
       376830 |
       | bytes_sent                        | 404710036897     |
       404712641950     |             2605053 |            260505.3 |
       15630318 |
       | com_change_db                     | 3813988          | 3813997
       |                   9 |                 0.9 |
       54 |
       | com_delete                        | 5823865          | 5823897
       |                  32 |                 3.2 |
       192 |
       | com_insert                        | 50395791         | 50395868
       |                  77 |                 7.7 |
       462 |
       | com_insert_select                 | 11840815         | 11840832
       |                  17 |                 1.7 |
       102 |
       | com_select                        | 45527485         | 45527537
       |                  52 |                 5.2 |
       312 |
       | com_set_option                    | 100093882        | 100094023
       |                 141 |                14.1 |
       846 |
       | com_show_collations               | 3813977          | 3813986
       |                   9 |                 0.9 |
       54 |
       | com_show_variables                | 3813980          | 3813989
       |                   9 |                 0.9 |
       54 |
       | com_update                        | 5671892          | 5671897
       |                   5 |                 0.5 |
       30 |
       | connections                       | 3839731          | 3839740
       |                   9 |                 0.9 |
       54 |
       | created_tmp_disk_tables           | 859679           | 859681
       |                   2 |                 0.2 |
       12 |
       | created_tmp_tables                | 8731648          | 8731669
       |                  21 |                 2.1 |
       126 |
       | handler_commit                    | 114182717        | 114182891
       |                 174 |                17.4 |
       1044 |
       | handler_delete                    | 10772896         | 10772927
       |                  31 |                 3.1 |
       186 |
       | handler_read_first                | 5913266          | 5913293
       |                  27 |                 2.7 |
       162 |
       | handler_read_key                  | 788386238        | 788387730
       |                1492 |               149.2 |
       8952 |
       | handler_read_next                 | 255429456        | 255469852
       |               40396 |              4039.6 |
       242376 |
       | handler_read_rnd                  | 410066910        | 410068623
       |                1713 |               171.3 |
       10278 |
       | handler_read_rnd_next             | 2530187881       |
       2530208075       |               20194 |              2019.4 |
       121164 |
       | handler_update                    | 25384145         | 25384216
       |                  71 |                 7.1 |
       426 |
       | handler_write                     | 2054152644       |
       2054159103       |                6459 |               645.9 |
       38754 |
       | innodb_buffer_pool_pages_data     | 30052            | 30057
       |                   5 |                 0.5 |
       30 |
       | innodb_buffer_pool_pages_dirty    | 183              | 204
       |                  21 |                 2.1 |
       126 |
       | innodb_buffer_pool_pages_flushed  | 38805231         | 38805438
       |                 207 |                20.7 |
       1242 |
       | innodb_buffer_pool_pages_free     | 4                | 1
       |                  -3 |                -0.3 |                    -
       18 |
       | innodb_buffer_pool_pages_misc     | 1943             | 1941
       |                  -2 |                -0.2 |                    -
       12 |
       | innodb_buffer_pool_read_requests  | 2205096023       |
       2205140951       |               44928 |              4492.8 |
       269568 |
       | innodb_buffer_pool_reads          | 9070710          | 9070712
       |                   2 |                 0.2 |
       12 |
       | innodb_buffer_pool_write_requests | 1009629688       |
       1009632455       |                2767 |               276.7 |
       16602 |
       | innodb_data_fsyncs                | 5691358          | 5691388
       |                  30 |                   3 |
       180 |
       | innodb_data_read                  | 3709091840       |
       3709104128       |               12288 |              1228.8 |
       73728 |
       | innodb_data_reads                 | 9526208          | 9526211
       |                   3 |                 0.3 |
       18 |
       | innodb_data_writes                | 101457695        | 101457999
       |                 304 |                30.4 |
       1824 |
       | innodb_data_written               | 1160983040       |
       1165887488       |             4904448 |            490444.8 |
       29426688 |
       | innodb_dblwr_pages_written        | 38805231         | 38805438
       |                 207 |                20.7 |
       1242 |
       | innodb_dblwr_writes               | 610255           | 610258
       |                   3 |                 0.3 |
       18 |
       | innodb_log_write_requests         | 341450412        | 341451248
       |                 836 |                83.6 |
       5016 |
       | innodb_log_writes                 | 70075432         | 70075559
       |                 127 |                12.7 |
       762 |
       | innodb_os_log_fsyncs              | 2336505          | 2336517
       |                  12 |                 1.2 |
       72 |
       | innodb_os_log_written             | 2583788544       |
       2584199168       |              410624 |             41062.4 |
       2463744 |
       | innodb_pages_created              | 1152396          | 1152398
       |                   2 |                 0.2 |
       12 |
       | innodb_pages_read                 | 9846270          | 9846273
       |                   3 |                 0.3 |
       18 |
       | innodb_pages_written              | 38805231         | 38805438
       |                 207 |                20.7 |
       1242 |
       | innodb_rows_deleted               | 10772886         | 10772917
       |                  31 |                 3.1 |
       186 |
       | innodb_rows_inserted              | 35117242         | 35117332
       |                  90 |                   9 |
       540 |
       | innodb_rows_read                  | 1197149081       |
       1197203914       |               54833 |              5483.3 |
       328998 |
       | innodb_rows_updated               | 22474281         | 22474351
       |                  70 |                   7 |
       420 |
       | key_read_requests                 | 21689837         | 21689845
       |                   8 |                 0.8 |
       48 |
       | open_files                        | 7                | 5
       |                  -2 |                -0.2 |                    -
       12 |
       | opened_files                      | 3666398          | 3666406
       |                   8 |                 0.8 |
       48 |
       | questions                         | 232437302        | 232437654
       |                 352 |                35.2 |
       2112 |
       | select_full_join                  | 99               | 100
       |                   1 |                 0.1 |
       6 |
       | select_range                      | 753753           | 753754
       |                   1 |                 0.1 |
       6 |
       | select_scan                       | 13123762         | 13123808
       |                  46 |                 4.6 |
       276 |
       | sort_rows                         | 409565982        | 409567695
       |                1713 |               171.3 |
       10278 |
       | sort_scan                         | 801869           | 801872
       |                   3 |                 0.3 |
       18 |
       | table_locks_immediate             | 129542449        | 129542648
       |                 199 |                19.9 |
       1194 |
       | threads_cached                    | 7                | 8
       |                   1 |                 0.1 |
       6 |
       | threads_created                   | 838815           | 838817
       |                   2 |                 0.2 |
       12 |
       +-----------------------------------+------------------+----------
       --------+---------------------+---------------------+-------------
       -----------+


Show GLOBAL STATUS changes (analyzing a stale, quiet server):


       mysql> SELECT * FROM common_schema.global_status_diff_nonzero;
       +-----------------------+------------------+------------------+---
       ------------------+---------------------+------------------------+
       | variable_name         | variable_value_0 | variable_value_1 |
       variable_value_diff | variable_value_psec | variable_value_pminute
       |
       +-----------------------+------------------+------------------+---
       ------------------+---------------------+------------------------+
       | handler_read_rnd_next | 3871             | 4458             |
       587 |                58.7 |                   3522 |
       | handler_write         | 10868            | 11746            |
       878 |                87.8 |                   5268 |
       | open_files            | 39               | 37               |
       -2 |                -0.2 |                    -12 |
       | select_full_join      | 3                | 4                |
       1 |                 0.1 |                      6 |
       | select_scan           | 30               | 32               |
       2 |                 0.2 |                     12 |
       +-----------------------+------------------+------------------+---
       ------------------+---------------------+------------------------+


Note in the above that merely querying this view causes some status variables
to change.

ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

global_status_diff, global_status_diff_clean

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('help','
NAME

help(): search and read common_schema documentation.

TYPE

Procedure

DESCRIPTION

help() is a meta routine allowing access to documentation from within
common_schema itself.
The documentation, including, for example, this very page, is embedded within
common_schema''s tables, such that it can be searched and read using standard
SQL queries.
help() accepts a search term, and presents a single documentation page which
best fits the term. The term may appear within the documentation''s title or
description. It could be the name or part of name of one of common_schema''s
components (routines, views, ...), or it could be any keyword appearing within
the documentation.
The output is MySQL-friendly, in that it breaks the documentation into rows of
text, thereby presenting the result in a nicely formatted table.

SYNOPSIS



       help(expression TINYTEXT CHARSET utf8)


Input:

* expression: a search term to be looked for.
  The term could be a full or partial word. The search is case insensitive.
  Regular expression search is not supported.


EXAMPLES

Find help on a search term:


       mysql> call help(''match'');
       +-----------------------------------------------------------------
       --------------+
       | help
       |
       +-----------------------------------------------------------------
       --------------+
       |
       |
       | NAME
       |
       |
       |
       | match_grantee(): Match an existing account based on user+host.
       |
       |
       |
       | TYPE
       |
       |
       |
       | Function
       |
       |
       |
       | DESCRIPTION
       |
       |
       |
       | MySQL does not provide with identification of logged in
       accounts. It only     |
       | provides with user + host:port combination within processlist.
       Alas, these do |
       | not directly map to accounts, as MySQL lists the host:port from
       which the     |
       | connection is made, but not the (possibly wildcard) user or
       host.             |
       | This function matches a user+host combination against the known
       accounts,     |
       | using the same matching method as the MySQL server, to detect
       the account     |
       | which MySQL identifies as the one matching. It is similar in
       essence to       |
       | CURRENT_USER(), only it works for all sessions, not just for the
       current      |
       | session.
       |
       |
       |
       | SYNOPSIS
       |
       |
       |
       |
       |
       |
       |
       |        match_grantee(connection_user char(16) CHARSET utf8,
       |
       |        connection_host char(70) CHARSET utf8)
       |
       |          RETURNS VARCHAR(100) CHARSET utf8
       |
       |
       |
       |
       |
       | Input:
       |
       |
       |
       | * connection_user: user login (e.g. as specified by PROCESSLIST)
       |
       | * connection_host: login host. May optionally specify port
       number (e.g.       |
       |   webhost:12345), which is discarded by the function. This is to
       support      |
       |   immediate input from as specified by PROCESSLIST.
       |
       |
       |
       |
       |
       | EXAMPLES
       |
       |
       |
       | Find an account matching the given use+host combination:
       |
       |
       |
       |
       |
       |        mysql> SELECT match_grantee(''apps'', ''192.128.0.1:12345'')
       AS            |
       |        grantee;
       |
       |        +------------
       +                                                         |
       |        | grantee    |
       |
       |        +------------
       +                                                         |
       |        | ''apps''@''%'' |
       |
       |        +------------
       +                                                         |
       |
       |
       |
       |
       |
       |
       | ENVIRONMENT
       |
       |
       |
       | MySQL 5.1 or newer
       |
       |
       |
       | SEE ALSO
       |
       |
       |
       | processlist_grantees
       |
       |
       |
       | AUTHOR
       |
       |
       |
       | Shlomi Noach
       |
       |
       |
       +-----------------------------------------------------------------
       --------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

metadata, prettify_message()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('innodb_index_rows','
NAME

innodb_index_rows: Number of row cardinality per keys per columns in InnoDB
tables

TYPE

View

DESCRIPTION

innodb_index_rows extends the INNODB_INDEX_STATS patch in Percona Server, and
presents with information on InnoDB keys cardinality as per indexed column.
The Percona Server INNODB_INDEX_STATS table presents with cardinality values
per index, per indexed column. That is, it lets us know the average number of
rows expected to be found in an index for some key.
For single column keys, this is simple enough. However, for compound indexes
(indexes over multiple columns), this information becomes even more
interesting, as it lets us examine the reduction in cardinality (and
improvement of selectivity) per column. However, the Percona Server patch only
informs us with numbers.
innodb_index_rows extends that information and adds column information. It
lists column names and their sequence within the key, and provides with easier
to read format.
This view depends upon the INNODB_INDEX_STATS patch in Percona Server.
Note that Percona Server 5.5.8-20.0 version introduced changes to the
INNODB_INDEX_STATS schema. This view is compatible with the new schema, and is
incompatible with older releases.

STRUCTURE



       mysql> DESC common_schema.innodb_index_rows;
       +-------------------------+---------------------+------+-----+----
       -----+-------+
       | Field                   | Type                | Null | Key |
       Default | Extra |
       +-------------------------+---------------------+------+-----+----
       -----+-------+
       | TABLE_SCHEMA            | varchar(64)         | NO   |     |
       |       |
       | TABLE_NAME              | varchar(64)         | NO   |     |
       |       |
       | INDEX_NAME              | varchar(64)         | NO   |     |
       |       |
       | SEQ_IN_INDEX            | bigint(2)           | NO   |     | 0
       |       |
       | COLUMN_NAME             | varchar(64)         | NO   |     |
       |       |
       | is_last_column_in_index | int(1)              | NO   |     | 0
       |       |
       | incremental_row_per_key | bigint(67) unsigned | YES  |     |
       NULL    |       |
       +-------------------------+---------------------+------+-----+----
       -----+-------+



SYNOPSIS

Columns of this view:

* TABLE_SCHEMA: Table schema of examined index
* TABLE_NAME: Examined index'' table
* INDEX_NAME: name of index examined
* SEQ_IN_INDEX: position of column within index (1 based)
* COLUMN_NAME: name of column within index
* is_last_column_in_index: boolean, 1 if current column is last in index
  definition.
  The last column in an index is of particular interest since the number of
  rows per last column signifies the index''s maximum selectivity
* incremental_row_per_key: Cardinality (number of values per key) of index up
  to and including current column


EXAMPLES

Examine index cardinality on a specific table (discussion follows):


       mysql> SELECT * FROM common_schema.innodb_index_rows WHERE
       TABLE_SCHEMA=''sakila'' AND TABLE_NAME=''inventory'';
       +--------------+------------+----------------------+--------------
       +--------------+-------------------------+------------------------
       -+
       | TABLE_SCHEMA | TABLE_NAME | INDEX_NAME           | SEQ_IN_INDEX
       | COLUMN_NAME  | is_last_column_in_index | incremental_row_per_key
       |
       +--------------+------------+----------------------+--------------
       +--------------+-------------------------+------------------------
       -+
       | sakila       | inventory  | PRIMARY              |            1
       | inventory_id |                       1 |                       1
       |
       | sakila       | inventory  | idx_fk_film_id       |            1
       | film_id      |                       1 |                       5
       |
       | sakila       | inventory  | idx_store_id_film_id |            1
       | store_id     |                       0 |                    4478
       |
       | sakila       | inventory  | idx_store_id_film_id |            2
       | film_id      |                       1 |                       2
       |
       +--------------+------------+----------------------+--------------
       +--------------+-------------------------+------------------------
       -+


Compare with call to INFORMATION_SCHEMA.INNODB_INDEX_STATS:


       mysql> SELECT * FROM INFORMATION_SCHEMA.INNODB_INDEX_STATS WHERE
       TABLE_SCHEMA=''sakila'' AND TABLE_NAME=''inventory'';
       +--------------+------------+----------------------+--------+-----
       ---------+-------------------+------------------+
       | table_schema | table_name | index_name           | fields |
       rows_per_key | index_total_pages | index_leaf_pages |
       +--------------+------------+----------------------+--------+-----
       ---------+-------------------+------------------+
       | sakila       | inventory  | PRIMARY              |      1 | 1
       |                10 |                9 |
       | sakila       | inventory  | idx_fk_film_id       |      2 | 5, 1
       |                 5 |                4 |
       | sakila       | inventory  | idx_store_id_film_id |      3 |
       4478, 2, 0   |                 7 |                6 |
       +--------------+------------+----------------------+--------+-----
       ---------+-------------------+------------------+


And compare with table definition:


       mysql> SHOW CREATE TABLE sakila.inventory \\G

              Table: inventory
       Create Table: CREATE TABLE `inventory` (
         `inventory_id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
         `film_id` smallint(5) unsigned NOT NULL,
         `store_id` tinyint(3) unsigned NOT NULL,
         `last_update` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON
       UPDATE CURRENT_TIMESTAMP,
         PRIMARY KEY (`inventory_id`),
         KEY `idx_fk_film_id` (`film_id`),
         KEY `idx_store_id_film_id` (`store_id`,`film_id`),
         CONSTRAINT `fk_inventory_store` FOREIGN KEY (`store_id`)
       REFERENCES `store` (`store_id`) ON UPDATE CASCADE,
         CONSTRAINT `fk_inventory_film` FOREIGN KEY (`film_id`)
       REFERENCES `film` (`film_id`) ON UPDATE CASCADE
       ) ENGINE=InnoDB AUTO_INCREMENT=4582 DEFAULT CHARSET=utf8


In the above example, note the following:

* The PRIMARY key is on inventory_id column, hence contains one column
  exactly. Since it is UNIQUE, it is certain to have 1 row per key.
* The idx_fk_film_id index is non unique. The
  INFORMATION_SCHEMA.INNODB_INDEX_STATS table lists two values for that
  column, although it only indexes one column only. This is because it
  implicitly includes the PRIMARY key for that table (as with all InnoDB
  keys). However, in innodb_index_rows only the explicitly indexed columns are
  listed.
* The idx_fk_film_id index provides with 5 rows per film_id value (this is of
  course an average estimation).
* The idx_store_id_film_id key is a compound index over two columns. If we use
  this index on filtering by store_id only, we expect to get 4478 per
  store_id. If we also filter by film_id, we expect to get fewer results: we
  only expect 2 rows per store_id:film_id combination.


ENVIRONMENT

Percona Server >= 5.5.8-20.0 with INNODB_INDEX_STATS_patch

SEE ALSO

innodb_index_stats

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('innodb_index_stats','
NAME

innodb_index_stats: Estimated InnoDB depth & split factor of key''s B+ Tree

TYPE

View

DESCRIPTION

innodb_index_stats extends the INNODB_INDEX_STATS patch in Percona Server, and
presents with estimated depth & split factor of InnoDB keys.
Estimations are optimistic, in that they assume condensed trees. It is
possible that the depth is larger than estimated, and that split factor is
lower than estimated.
Estimated values are presented as floating point values, although in reality
these are integer types.
This view is experimental and in BETA stage.
This view depends upon the INNODB_INDEX_STATS patch in Percona Server.
Note that Percona Server 5.5.8-20.0 version introduced changes to the
INNODB_INDEX_STATS schema. This view is compatible with the new schema, and is
incompatible with older releases.

STRUCTURE



       mysql> DESC common_schema.innodb_index_stats;
       +--------------+---------------------+------+-----+---------+-----
       --+
       | Field        | Type                | Null | Key | Default |
       Extra |
       +--------------+---------------------+------+-----+---------+-----
       --+
       | table_schema | varchar(192)        | NO   |     |         |
       |
       | table_name   | varchar(192)        | NO   |     |         |
       |
       | index_name   | varchar(192)        | NO   |     |         |
       |
       | fields       | bigint(21) unsigned | NO   |     | 0       |
       |
       | row_per_keys | varchar(256)        | NO   |     |         |
       |
       | index_size   | bigint(21) unsigned | NO   |     | 0       |
       |
       | leaf_pages   | bigint(21) unsigned | NO   |     | 0       |
       |
       | split_factor | decimal(23,1)       | NO   |     | 0.0     |
       |
       | index_depth  | double(18,1)        | NO   |     | 0.0     |
       |
       +--------------+---------------------+------+-----+---------+-----
       --+



SYNOPSIS

Columns of this view map directly to those of INNODB_INDEX_STATS, with the
addition of:

* split_factor: Estimated split factor of the index tree
* index_depth: Estimated depth of the index tree. Value is a floating point,
  though the depth of an index is an integer.


EXAMPLES

Examine index attributes on a specific table:


       mysql> SELECT * FROM common_schema.innodb_index_stats WHERE
       TABLE_NAME=''docs_template'';
       +--------------+---------------+-----------------+--------+-------
       -------------------+------------+------------+--------------+-----
       --------+
       | table_schema | table_name    | index_name      | fields |
       row_per_keys             | index_size | leaf_pages | split_factor
       | index_depth |
       +--------------+---------------+-----------------+--------+-------
       -------------------+------------+------------+--------------+-----
       --------+
       | databus      | docs_template | unique_docs_idx |      4 |
       28697340, 28697340, 1, 1 |     834310 |     725102 |          7.6
       |         7.6 |
       | databus      | docs_template | PRIMARY         |      1 | 1
       |   18851201 |   16485198 |          8.0 |         9.0 |
       | databus      | docs_template | doc_timestamp   |      2 | 12, 1
       |     127577 |     126428 |        111.0 |         3.5 |
       +--------------+---------------+-----------------+--------+-------
       -------------------+------------+------------+--------------+-----
       --------+



ENVIRONMENT

Percona Server >= 5.5.8-20.0 with INNODB_INDEX_STATS_patch

SEE ALSO

innodb_index_rows

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('innodb_locked_transactions','
NAME

innodb_locked_transactions: List locked transactions, the locks they are
waiting on and the transactions holding those locks.

TYPE

View

DESCRIPTION

InnoDB Plugin provides with easy to query INFORMATION_SCHEMA tables. In
particular, it offers information on running transactions, locked transactions
and locks.
innodb_locked_transactions makes the obvious connection for blocked
transactions: it lists blocked transactions, what they attempt to do, the
locks on which they block, the transactions holding those locks and the
queries they are executing.
The view makes for a simple analysis of "Why do I seem to have so many locks?
What''s locking what?"

STRUCTURE



       mysql> DESC common_schema.innodb_locked_transactions;
       +------------------------------+---------------------+------+-----
       +---------------------+-------+
       | Field                        | Type                | Null | Key
       | Default             | Extra |
       +------------------------------+---------------------+------+-----
       +---------------------+-------+
       | locked_trx_id                | varchar(18)         | NO   |
       |                     |       |
       | locked_trx_started           | datetime            | NO   |
       | 0000-00-00 00:00:00 |       |
       | locked_trx_wait_started      | datetime            | YES  |
       | NULL                |       |
       | locked_trx_mysql_thread_id   | bigint(21) unsigned | NO   |
       | 0                   |       |
       | locked_trx_query             | varchar(1024)       | YES  |
       | NULL                |       |
       | requested_lock_id            | varchar(81)         | NO   |
       |                     |       |
       | blocking_lock_id             | varchar(81)         | NO   |
       |                     |       |
       | locking_trx_id               | varchar(18)         | NO   |
       |                     |       |
       | locking_trx_started          | datetime            | NO   |
       | 0000-00-00 00:00:00 |       |
       | locking_trx_wait_started     | datetime            | YES  |
       | NULL                |       |
       | locking_trx_mysql_thread_id  | bigint(21) unsigned | NO   |
       | 0                   |       |
       | locking_trx_query            | varchar(1024)       | YES  |
       | NULL                |       |
       | trx_wait_seconds             | bigint(21)          | YES  |
       | NULL                |       |
       | sql_kill_blocking_query      | varbinary(31)       | NO   |
       |                     |       |
       | sql_kill_blocking_connection | varbinary(25)       | NO   |
       |                     |       |
       +------------------------------+---------------------+------+-----
       +---------------------+-------+



SYNOPSIS

Columns of this view:

* locked_trx_id: InnoDB locked transaction ID
* locked_trx_started: time at which locked transaction started
* locked_trx_wait_started: time at which locked transaction got blocked on
  this lock
* locked_trx_mysql_thread_id: thread ID (mapped to PROCESSLIST)
* locked_trx_query: current blocked query
* requested_lock_id: ID of lock on which transaction is blocked
* blocking_lock_id: ID of lock preventing transaction from getting requested
  lock
* locking_trx_id: InnoDB blocking transaction ID
* locking_trx_started: time at which blocking transaction started
* locking_trx_wait_started: time at which blocking transaction got blocked
  (it, too, may be blocked)
* locking_trx_mysql_thread_id: blocking thread ID (mapped to PROCESSLIST)
* locking_trx_query: current blocking query
* trx_wait_seconds: number of seconds blocked transaction is waiting
* sql_kill_blocking_query: a KILL QUERY statement for the blocking
  transaction.
  Use with eval() to apply statement.
* sql_kill_blocking_connection: a KILL statement for the blocking transaction.

  Use with eval() to apply statement.


EXAMPLES

Show info on locked transactions:


       mysql> SELECT * FROM common_schema.innodb_locked_transactions;
       +---------------+---------------------+-------------------------+-
       ---------------------------+--------------------------------------
       ------------+-------------------------+-------------------------+-
       ---------------+---------------------+--------------------------+-
       ----------------------------+-------------------+-----------------
       -+-------------------------+------------------------------+
       | locked_trx_id | locked_trx_started  | locked_trx_wait_started |
       locked_trx_mysql_thread_id | locked_trx_query
       | requested_lock_id       | blocking_lock_id        |
       locking_trx_id | locking_trx_started | locking_trx_wait_started |
       locking_trx_mysql_thread_id | locking_trx_query | trx_wait_seconds
       | sql_kill_blocking_query | sql_kill_blocking_connection |
       +---------------+---------------------+-------------------------+-
       ---------------------------+--------------------------------------
       ------------+-------------------------+-------------------------+-
       ---------------+---------------------+--------------------------+-
       ----------------------------+-------------------+-----------------
       -+-------------------------+------------------------------+
       | 9AD2D1811     | 2012-09-28 10:40:25 | 2012-09-28 10:40:25     |
       609205 | NULL                                             |
       9AD2D1811:499850:82:113 | 9AD2D0E1A:499850:82:113 | 9AD2D0E1A
       | 2012-09-28 10:40:01 | NULL                     |
       609159 | NULL              |                1 | KILL QUERY 609159
       | KILL 609159                  |
       | 9AD2D0FBA     | 2012-09-28 10:40:03 | 2012-09-28 10:40:03     |
       609196 | UPDATE events SET ts = NOW() WHERE alias = ''all'' |
       9AD2D0FBA:499850:88:108 | 9AD2D0E1A:499850:88:108 | 9AD2D0E1A
       | 2012-09-28 10:40:01 | NULL                     |
       609159 | NULL              |               23 | KILL QUERY 609159
       | KILL 609159                  |
       +---------------+---------------------+-------------------------+-
       ---------------------------+--------------------------------------
       ------------+-------------------------+-------------------------+-
       ---------------+---------------------+--------------------------+-
       ----------------------------+-------------------+-----------------
       -+-------------------------+------------------------------+


In the above example we are unable to catch the query blocking the 2rd
transaction. In the first transaction we are also unable to realize the
blocked query. We don''t always get all we want...
See which transactions are blocking, and how many are being blocked:


       mysql> SELECT locking_trx_id, COUNT(*) FROM
       innodb_locked_transactions GROUP BY locking_trx_id;
       +----------------+----------+
       | locking_trx_id | COUNT(*) |
       +----------------+----------+
       | 9AD30296C      |        2 |
       | 9AD30296E      |        1 |
       +----------------+----------+


Kill transactions causing other transactions to block for 30 seconds or more:


       mysql> CALL eval(''SELECT sql_kill_blocking_query FROM
       innodb_locked_transactions WHERE trx_wait_seconds >= 30 GROUP BY
       sql_kill_blocking_query'');



ENVIRONMENT

MySQL 5.1 with InnoDB Plugin installed (with InnoDB INFORMATION_SCHEMA plugins
enabled), or MySQL >= 5.5

SEE ALSO

innodb_simple_locks, innodb_transactions, innodb_transactions_summary

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('innodb_plugin_views','
SYNOPSIS

InnoDB Plugin views: informational views on InnoDB Plugin.

* innodb_locked_transactions: List locked transactions, the locks they are
  waiting on and the transactions holding those locks.
* innodb_simple_locks: Listing of locks, simplifying
  INFORMATION_SCHEMA.INNODB_LOCKS
* innodb_transactions: Listing of active (InnoDB Plugin) transactions, which
  are currently performing queries
* innodb_transactions_summary: A one line summary of InnoDB''s transactions:
  count, state, locks


DESCRIPTION

All views in this category require InnoDB Plugin to be installed along with
all related INFORMATION_SCHEMA plugins.
If you are using MySQL >= 5.5, then you are using InnoDB plugin (and it is
simply refered to as plain InnoDB).
If you are using MySQL 5.1 then you are either using the "old", built-in
InnoDB, or, upon proper configuration, the InnoDB Plugin. See this_page from
the manual for InnoDB Plugin setup for MySQL 5.1.

EXAMPLES

Show info on locked transactions:


       mysql> SELECT * FROM common_schema.innodb_locked_transactions;
       +---------------+---------------------+-------------------------+-
       ---------------------------+--------------------------------------
       ------------+-------------------------+-------------------------+-
       ---------------+---------------------+--------------------------+-
       ----------------------------+-------------------+-----------------
       -+-------------------------+------------------------------+
       | locked_trx_id | locked_trx_started  | locked_trx_wait_started |
       locked_trx_mysql_thread_id | locked_trx_query
       | requested_lock_id       | blocking_lock_id        |
       locking_trx_id | locking_trx_started | locking_trx_wait_started |
       locking_trx_mysql_thread_id | locking_trx_query | trx_wait_seconds
       | sql_kill_blocking_query | sql_kill_blocking_connection |
       +---------------+---------------------+-------------------------+-
       ---------------------------+--------------------------------------
       ------------+-------------------------+-------------------------+-
       ---------------+---------------------+--------------------------+-
       ----------------------------+-------------------+-----------------
       -+-------------------------+------------------------------+
       | 9AD2D1811     | 2012-09-28 10:40:25 | 2012-09-28 10:40:25     |
       609205 | NULL                                             |
       9AD2D1811:499850:82:113 | 9AD2D0E1A:499850:82:113 | 9AD2D0E1A
       | 2012-09-28 10:40:01 | NULL                     |
       609159 | NULL              |                1 | KILL QUERY 609159
       | KILL 609159                  |
       | 9AD2D0FBA     | 2012-09-28 10:40:03 | 2012-09-28 10:40:03     |
       609196 | UPDATE events SET ts = NOW() WHERE alias = ''all'' |
       9AD2D0FBA:499850:88:108 | 9AD2D0E1A:499850:88:108 | 9AD2D0E1A
       | 2012-09-28 10:40:01 | NULL                     |
       609159 | NULL              |               23 | KILL QUERY 609159
       | KILL 609159                  |
       +---------------+---------------------+-------------------------+-
       ---------------------------+--------------------------------------
       ------------+-------------------------+-------------------------+-
       ---------------+---------------------+--------------------------+-
       ----------------------------+-------------------+-----------------
       -+-------------------------+------------------------------+


Kill transactions blocking cause other transactions to block for 30 seconds or
more:


       mysql> CALL eval(''SELECT sql_kill_blocking_query FROM
       innodb_locked_transactions WHERE trx_wait_seconds >= 30 GROUP BY
       sql_kill_blocking_query'');


Kill transactions idle for 30 seconds or more:


       mysql> CALL eval("SELECT sql_kill_query FROM
       common_schema.innodb_transactions WHERE trx_idle_seconds >= 30");


');
		
			INSERT INTO common_schema.help_content VALUES ('innodb_simple_locks','
NAME

innodb_simple_locks: Listing of locks, simplifying
INFORMATION_SCHEMA.INNODB_LOCKS

TYPE

View

DESCRIPTION

innodb_simple_locks is a simplification of INFORMATION_SCHEMA.INNODB_LOCKS. It
merely provides with "the good parts" in the form of selected columns. No rows
are filtered by this view.

STRUCTURE



       mysql> DESC common_schema.innodb_simple_locks;
       +-------------+---------------+------+-----+---------+-------+
       | Field       | Type          | Null | Key | Default | Extra |
       +-------------+---------------+------+-----+---------+-------+
       | lock_id     | varchar(81)   | NO   |     |         |       |
       | lock_trx_id | varchar(18)   | NO   |     |         |       |
       | lock_type   | varchar(32)   | NO   |     |         |       |
       | lock_table  | varchar(1024) | NO   |     |         |       |
       | lock_index  | varchar(1024) | YES  |     | NULL    |       |
       | lock_data   | varchar(8192) | YES  |     | NULL    |       |
       +-------------+---------------+------+-----+---------+-------+



SYNOPSIS

Columns of this view map directly to those of INFORMATION_SCHEMA.INNODB_LOCKS
table

EXAMPLES

Show current locks:


       mysql> SELECT * FROM common_schema.innodb_simple_locks;
       +----------------+-------------+-----------+----------------------
       ----+------------+-----------+
       | lock_id        | lock_trx_id | lock_type | lock_table
       | lock_index | lock_data |
       +----------------+-------------+-----------+----------------------
       ----+------------+-----------+
       | 313C57443:1027 | 313C57443   | TABLE     |
       `deps_db`.`pending_deps` | NULL       | NULL      |
       | 313C57442:1027 | 313C57442   | TABLE     |
       `deps_db`.`pending_deps` | NULL       | NULL      |
       +----------------+-------------+-----------+----------------------
       ----+------------+-----------+



ENVIRONMENT

MySQL 5.1 with InnoDB Plugin installed (with InnoDB INFORMATION_SCHEMA plugins
enabled), or MySQL >= 5.5

SEE ALSO

innodb_locked_transactions, innodb_transactions, innodb_transactions_summary

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('innodb_transactions','
NAME

innodb_transactions: Listing of open (InnoDB Plugin) transactions

TYPE

View

DESCRIPTION

innodb_transactions is a simplification of INFORMATION_SCHEMA.INNODB_TRX.
CHANGE: up to common_schema 1.1, this view would only show transactions that
are executing statements. It now lists all open transactions, and offers the
trx_idle_seconds columns to help finding sleeping open transactions.
The connection calling upon this view is never listed.

STRUCTURE



       mysql> DESC common_schema.innodb_transactions;
       +-----------------------+---------------------+------+-----+------
       ---------------+-------+
       | Field                 | Type                | Null | Key |
       Default             | Extra |
       +-----------------------+---------------------+------+-----+------
       ---------------+-------+
       | trx_id                | varchar(18)         | NO   |     |
       |       |
       | trx_state             | varchar(13)         | NO   |     |
       |       |
       | trx_started           | datetime            | NO   |     | 0000-
       00-00 00:00:00 |       |
       | trx_requested_lock_id | varchar(81)         | YES  |     | NULL
       |       |
       | trx_wait_started      | datetime            | YES  |     | NULL
       |       |
       | trx_weight            | bigint(21) unsigned | NO   |     | 0
       |       |
       | trx_mysql_thread_id   | bigint(21) unsigned | NO   |     | 0
       |       |
       | trx_query             | varchar(1024)       | YES  |     | NULL
       |       |
       | INFO                  | longtext            | YES  |     | NULL
       |       |
       | trx_runtime_seconds   | bigint(21)          | YES  |     | NULL
       |       |
       | trx_wait_seconds      | bigint(21)          | YES  |     | NULL
       |       |
       | trx_idle_seconds      | bigint(11)          | YES  |     | NULL
       |       |
       | sql_kill_query        | varbinary(31)       | NO   |     |
       |       |
       | sql_kill_connection   | varbinary(25)       | NO   |     |
       |       |
       +-----------------------+---------------------+------+-----+------
       ---------------+-------+



SYNOPSIS

Structure of this view derives from that of INFORMATION_SCHEMA.INNODB_TRX
table.
Additional columns are:

* INFO: Query being executed right now by this transaction, as seen on
  PROCESSLIST.
* trx_runtime_seconds: number of seconds elapsed since beginning of this
  transaction.
* trx_wait_seconds: number of seconds this transaction is waiting on lock, or
  NULL if not currently waiting.
* trx_idle_seconds: number of seconds this transaction is idle. 0 if not idle.
* sql_kill_query: a KILL QUERY statement for current thread.
  Use with eval() to apply statement.
* sql_kill_connection: a KILL statement for current thread.
  Use with eval() to apply statement.


EXAMPLES

Show all active transactions:


       mysql> SELECT * FROM common_schema.innodb_transactions;
       +-----------+-----------+---------------------+-------------------
       ----+------------------+------------+---------------------+-------
       ----+-------------------------------------------------------------
       ----------------------+---------------------+------------------+--
       ----------------+-------------------+---------------------+
       | trx_id    | trx_state | trx_started         |
       trx_requested_lock_id | trx_wait_started | trx_weight |
       trx_mysql_thread_id | trx_query | INFO
       | trx_runtime_seconds | trx_wait_seconds | trx_idle_seconds |
       sql_kill_query    | sql_kill_connection |
       +-----------+-----------+---------------------+-------------------
       ----+------------------+------------+---------------------+-------
       ----+-------------------------------------------------------------
       ----------------------+---------------------+------------------+--
       ----------------+-------------------+---------------------+
       | 9AA6213B4 | RUNNING   | 2012-09-27 15:46:36 | NULL
       | NULL             |         13 |              858223 | NULL
       | DELETE FROM tbl_lock WHERE id = ''planner'' AND expiryTime <
       ''2012-09-27 15:46:36''  |                   0 |             NULL |
       0 | KILL QUERY 858223 | KILL 858223         |
       | 9AA6213B2 | RUNNING   | 2012-09-27 15:46:36 | NULL
       | NULL             |          3 |              858216 | NULL
       | NULL
       |                   0 |             NULL |                0 | KILL
       QUERY 858216 | KILL 858216         |
       | 9AA6213B2 | RUNNING   | 2012-09-27 15:46:36 | NULL
       | NULL             |          3 |              858219 | NULL
       | UPDATE tbl_scount SET count = count + 1 WHERE element=''php''
       |                   0 |             NULL |                0 | KILL
       QUERY 858219 | KILL 858219         |
       +-----------+-----------+---------------------+-------------------
       ----+------------------+------------+---------------------+-------
       ----+-------------------------------------------------------------
       ----------------------+---------------------+------------------+--
       ----------------+-------------------+---------------------+


In the above no transaction is waiting and no transaction is idle.
Kill transactions idle for 30 seconds or more:


       mysql> CALL eval("SELECT sql_kill_query FROM
       common_schema.innodb_transactions WHERE trx_idle_seconds >= 30");


In the above no transaction is waiting and no transaction is idle.

ENVIRONMENT

MySQL 5.1 with InnoDB Plugin installed (with InnoDB INFORMATION_SCHEMA plugins
enabled), or MySQL >= 5.5

SEE ALSO

innodb_locked_transactions, innodb_simple_locks, innodb_transactions_summary

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('innodb_transactions_summary','
NAME

innodb_transactions_summary: A one line summary of InnoDB''s transactions:
count, state, locks

TYPE

View

DESCRIPTION

innodb_transactions_summary provides a quick summary of InnoDB Plugin''s
current transactions state: number of running transactions, of which how many
are executing or locked, on how many locks.
The connection calling upon this view is never listed.

STRUCTURE



       mysql> DESC common_schema.innodb_transactions_summary;
       +----------------------+---------------+------+-----+---------+---
       ----+
       | Field                | Type          | Null | Key | Default |
       Extra |
       +----------------------+---------------+------+-----+---------+---
       ----+
       | count_transactions   | bigint(21)    | NO   |     | 0       |
       |
       | running_transactions | decimal(23,0) | NO   |     | 0       |
       |
       | locked_transactions  | decimal(23,0) | NO   |     | 0       |
       |
       | distinct_locks       | bigint(21)    | NO   |     | 0       |
       |
       +----------------------+---------------+------+-----+---------+---
       ----+



SYNOPSIS

Columns of this view:

* count_transactions: number of current transactions
* running_transactions: number of transactions executing a query
* locked_transactions: number of transactions waiting on some lock
* distinct_locks: number of distinct locks transactions are waiting on, or 0
  when no transaction is locked


EXAMPLES

Get transactions summary:


       mysql> SELECT * FROM common_schema.innodb_transactions_summary;
       +--------------------+----------------------+---------------------
       +----------------+
       | count_transactions | running_transactions | locked_transactions
       | distinct_locks |
       +--------------------+----------------------+---------------------
       +----------------+
       |                  9 |                    7 |                   2
       |              2 |
       +--------------------+----------------------+---------------------
       +----------------+


In the above server, 9 transactions are open, of which 7 are executing a query
(the other two are "in between queries"). Of the 7 executing queries, 5 are
running normally, but 2 are blocked.

ENVIRONMENT

MySQL 5.1 with InnoDB Plugin installed (with InnoDB INFORMATION_SCHEMA plugins
enabled), or MySQL >= 5.5

SEE ALSO

innodb_locked_transactions, innodb_simple_locks, innodb_transactions

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('is_datetime','
NAME

is_datetime(): Check whether given string is a valid DATETIME.

TYPE

Function

DESCRIPTION

Test if given text makes for a valid DATETIME object. Returns TRUE (1) when it
does, or FALSE (0) when it does not,

SYNOPSIS



       is_datetime(txt TINYTEXT)
         RETURNS TINYINT UNSIGNED


Input:

* txt: text to validate


EXAMPLES



       mysql> SELECT is_datetime(''2012-01-01'') as result1, is_datetime
       (''20120101123456'') as result2;
       +---------+---------+
       | result1 | result2 |
       +---------+---------+
       |       1 |       1 |
       +---------+---------+




       mysql> SELECT is_datetime(''abc'') as result1, is_datetime(17) as
       result2;
       +---------+---------+
       | result1 | result2 |
       +---------+---------+
       |       0 |       0 |
       +---------+---------+



ENVIRONMENT

MySQL 5.1 or newer

AUTHOR

Shlomi Noach, based on contribution by Roland Bouman
');
		
			INSERT INTO common_schema.help_content VALUES ('json_to_xml','
NAME

json_to_xml(): Convert valid JSON to equivalent XML

TYPE

Function

DESCRIPTION

json_to_xml() accepts text in JSON format, and converts it to its XML
equivalent.
Both JSON and XML are commonly used to describe objects and properties; both
allow for tree-like structure. Both are strict (to some level) in data
definition.
json_to_xml() assumes a valid JSON input, and returns its XML equivalent, such
that:

* Internal structural tests on JSON format apply. In any case of failure the
  function returns NULL
* Produced XML is consisted of elements and text. No attributes generated.
* Names are mapped to nodes. Simple values are mapped to text. Object values
  to subnodes. Arrays to multiple nodes.
* XML text is automatically encoded (e.g. the ">" character converted to
  "&gt;"). XML node names are not encoded.
* Result XML is not beautified (no spaces or indentation between elements)

NOTE: this function is CPU intensive. This solution should ideally be
implemented through built-in functions, not stored routines.

SYNOPSIS



       json_to_xml(
           json_text TEXT CHARSET utf8
       ) RETURNS TEXT CHARSET utf8


Input:

* json_text: a valid JSON formatted text.


EXAMPLES

Convert JSON to XML:


       mysql> SET @json := ''
       {
         "menu": {
           "id": "file",
           "value": "File",
           "popup": {
             "menuitem": [
               {"value": "New", "onclick": "CreateNewDoc()"},
               {"value": "Open", "onclick": "OpenDoc()"},
               {"value": "Close", "onclick": "CloseDoc()"}
             ]
           }
         }
       }
       '';

       mysql> SELECT json_to_xml(@json) AS xml \\G
       *************************** 1. row ***************************
       xml: <menu><id>file</id><value>File</
       value><popup><menuitem><value>New</value><onclick>CreateNewDoc()</
       onclick></menuitem><menuitem><value>Open</value><onclick>OpenDoc
       ()</onclick></menuitem><menuitem><value>Close</
       value><onclick>CloseDoc()</onclick></menuitem></popup></menu>


Beautified form of the above result:


       <menu>
         <id>file</id>
         <value>File</value>
         <popup>
           <menuitem>
             <value>New</value>
             <onclick>CreateNewDoc()</onclick>
           </menuitem>
           <menuitem>
             <value>Open</value>
             <onclick>OpenDoc()</onclick>
           </menuitem>
           <menuitem>
             <value>Close</value>
             <onclick>CloseDoc()</onclick>
           </menuitem>
         </popup>
       </menu>



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

encode_xml(), extract_json_value()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('killall','
NAME

killall(): Kill connections with by matching GRANTEE, user or host

TYPE

Procedure

DESCRIPTION

Kill connections by matching connection GRANTEE, user or host with given
input. This routine provides with a quick "kill those connections right now"
solution, which is otherwise achieved by looking up connection IDs from SHOW
PROCESSLIST, or by evaluating the processlist_grantees view.
killall(), similar to unix'' killall command, kills by name rather than by ID.
killall() accepts a grantee_term input, which may be either a fully qualified
GRANTEE (e.g. ''gromit''@''webhost.local''), a relaxed GRANTEE (e.g.
gromit@localhost), a username only (e.g. ''gromit'') or a hostname only (e.g.
''analytics_server.localdomain'').
Thus, it makes it easy to quickly kill, for example, all connections by a
given user, wherever that user may connect from.
killall() allows killing of all connections, including those of users with the
SUPER privilege, as well as replication. However, killall() is guaranteed
never to kill the current connection - the very one invoking the routine.
Whatever the grantee_term is, it is compared against GRANTEE accounts, and NOT
against particular connections. Thus, the following:


       call killall(''192.168.0.%'');


will kill all connections of accounts where the host part of the account
equals ''192.168.0.%''. It will NOT necessarily kill all connections from hosts
matching the pattern. killall() does not do pattern matching. To illustrate,
it will NOT kill a connection by the GRANTEE ''gromit''@''192.168.0.10''. It will
kill connections by ''preston''@''192.168.0.%''.
killall() does not provide the mechanism to kill queries which are slow, or
include a given text. Use eval() and processlist_grantees for that.

SYNOPSIS



       killall(IN grantee_term TINYTEXT CHARSET utf8)
         READS SQL DATA


Input:

* grantee_term: a GRANTEE, qualified or unqualified, or the user or host parts
  of a GRANTEE.


EXAMPLES

Kill all connections by user ''apps'':


       mysql> SHOW PROCESSLIST;
       +----+------+-----------+---------------+---------+------+--------
       ----+---------------------+
       | Id | User | Host      | db            | Command | Time | State
       | Info                |
       +----+------+-----------+---------------+---------+------+--------
       ----+---------------------+
       |  7 | root | localhost | common_schema | Query   |    0 | NULL
       | SHOW PROCESSLIST    |
       | 78 | apps | localhost | NULL          | Query   |   31 | User
       sleep | select sleep(10000) |
       +----+------+-----------+---------------+---------+------+--------
       ----+---------------------+
       2 rows in set (0.00 sec)

       mysql> CALL killall(''apps'');

       mysql> SHOW PROCESSLIST;
       +----+------+-----------+---------------+---------+------+-------
       +------------------+
       | Id | User | Host      | db            | Command | Time | State |
       Info             |
       +----+------+-----------+---------------+---------+------+-------
       +------------------+
       |  7 | root | localhost | common_schema | Query   |    0 | NULL  |
       SHOW PROCESSLIST |
       +----+------+-----------+---------------+---------+------+-------
       +------------------+
       1 row in set (0.00 sec)


Kill all ''localhost'' connections:


       mysql> SHOW PROCESSLIST;
       +----+------+-----------+---------------+---------+------+--------
       ----+---------------------+
       | Id | User | Host      | db            | Command | Time | State
       | Info                |
       +----+------+-----------+---------------+---------+------+--------
       ----+---------------------+
       |  7 | root | localhost | common_schema | Query   |    0 | NULL
       | SHOW PROCESSLIST    |
       | 81 | apps | localhost | NULL          | Query   |   18 | User
       sleep | select sleep(10000) |
       +----+------+-----------+---------------+---------+------+--------
       ----+---------------------+
       2 rows in set (0.00 sec)

       mysql> CALL killall(''localhost'');

       mysql> SHOW PROCESSLIST;
       +----+------+-----------+---------------+---------+------+-------
       +------------------+
       | Id | User | Host      | db            | Command | Time | State |
       Info             |
       +----+------+-----------+---------------+---------+------+-------
       +------------------+
       |  7 | root | localhost | common_schema | Query   |    0 | NULL  |
       SHOW PROCESSLIST |
       +----+------+-----------+---------------+---------+------+-------
       +------------------+
       1 row in set (0.00 sec)


Note that process #7 is not killed since it is the one executing the kill.

ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

eval, eval(), processlist_grantees, processlist_top, sql_accounts

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('last_query_profiling','
NAME

last_query_profiling: Last query''s profiling info, aggregated by query''s
states

TYPE

View

DESCRIPTION

last_query_profiling presents with pretty profiling info for last executed
query.
Based on the INFORMATION_SCHEMA.PROFILING table, this view aggregates data by
query state, and presents with more easy to comprehend details, such as the
total runtime for the various states and the time ration per state of the
total query runtime.
To populate this view, one must enable profiling. This is done by:


       mysql> SET PROFILING := 1;


This code is based on queries presented on How_to_convert_MySQL’s_SHOW
PROFILES_into_a_real_profile and in the book High Performance MySQL, 3nd
Edition, By Baron Schwartz et al., published by O''REILLY

STRUCTURE



       mysql> DESC common_schema.last_query_profiling;
       +-------------------------+----------------+------+-----+---------
       +-------+
       | Field                   | Type           | Null | Key | Default
       | Extra |
       +-------------------------+----------------+------+-----+---------
       +-------+
       | QUERY_ID                | int(20)        | NO   |     | 0
       |       |
       | STATE                   | varchar(30)    | NO   |     |
       |       |
       | state_calls             | bigint(21)     | NO   |     | 0
       |       |
       | state_sum_duration      | decimal(31,6)  | YES  |     | NULL
       |       |
       | state_duration_per_call | decimal(35,10) | YES  |     | NULL
       |       |
       | state_duration_pct      | decimal(37,2)  | YES  |     | NULL
       |       |
       | state_seqs              | longblob       | YES  |     | NULL
       |       |
       +-------------------------+----------------+------+-----+---------
       +-------+



SYNOPSIS

Structure of this view is identical to that of the query_profiling view.

EXAMPLES

Profile a query over a complex view:


       mysql> SET PROFILING := 1;

       mysql> SELECT COUNT(*) FROM sakila.nicer_but_slower_film_list INTO
       @dummy;

       mysql> SELECT * FROM last_query_profiling;
       +----------+----------------------+-------------+-----------------
       ---+-------------------------+--------------------+------------+
       | QUERY_ID | STATE                | state_calls |
       state_sum_duration | state_duration_per_call | state_duration_pct
       | state_seqs |
       +----------+----------------------+-------------+-----------------
       ---+-------------------------+--------------------+------------+
       |       41 | checking permissions |           5 |
       0.000320 |            0.0000640000 |               0.33 |
       5,6,7,8,9  |
       |       41 | cleaning up          |           1 |
       0.000007 |            0.0000070000 |               0.01 | 31
       |
       |       41 | closing tables       |           1 |
       0.000016 |            0.0000160000 |               0.02 | 29
       |
       |       41 | Copying to tmp table |           1 |
       0.042363 |            0.0423630000 |              44.34 | 15
       |
       |       41 | Creating tmp table   |           1 |
       0.000123 |            0.0001230000 |               0.13 | 13
       |
       |       41 | end                  |           1 |
       0.000004 |            0.0000040000 |               0.00 | 23
       |
       |       41 | executing            |           2 |
       0.000014 |            0.0000070000 |               0.01 | 14,22
       |
       |       41 | freeing items        |           2 |
       0.000216 |            0.0001080000 |               0.23 | 25,27
       |
       |       41 | init                 |           1 |
       0.000012 |            0.0000120000 |               0.01 | 20
       |
       |       41 | logging slow query   |           1 |
       0.000004 |            0.0000040000 |               0.00 | 30
       |
       |       41 | Opening tables       |           1 |
       0.028909 |            0.0289090000 |              30.26 | 2
       |
       |       41 | optimizing           |           2 |
       0.000026 |            0.0000130000 |               0.03 | 10,21
       |
       |       41 | preparing            |           1 |
       0.000018 |            0.0000180000 |               0.02 | 12
       |
       |       41 | query end            |           1 |
       0.000004 |            0.0000040000 |               0.00 | 24
       |
       |       41 | removing tmp table   |           3 |
       0.000130 |            0.0000433333 |               0.14 | 18,26,28
       |
       |       41 | Sending data         |           2 |
       0.016823 |            0.0084115000 |              17.61 | 17,19
       |
       |       41 | Sorting result       |           1 |
       0.006302 |            0.0063020000 |               6.60 | 16
       |
       |       41 | starting             |           1 |
       0.000163 |            0.0001630000 |               0.17 | 1
       |
       |       41 | statistics           |           1 |
       0.000048 |            0.0000480000 |               0.05 | 11
       |
       |       41 | System lock          |           1 |
       0.000017 |            0.0000170000 |               0.02 | 3
       |
       |       41 | Table lock           |           1 |
       0.000018 |            0.0000180000 |               0.02 | 4
       |
       +----------+----------------------+-------------+-----------------
       ---+-------------------------+--------------------+------------+


From the above we can see that "Copying to tmp table", "Opening tables" and
"Sending data" are the major states impacting the query runtime.
Similar to the above, simplify results:


       mysql> SET PROFILING := 1;

       mysql> SELECT COUNT(*) FROM sakila.nicer_but_slower_film_list INTO
       @dummy;

       mysql> SELECT STATE, state_duration_pct, state_calls
                 FROM last_query_profiling
                 ORDER BY state_duration_pct DESC;
       +----------------------+--------------------+-------------+
       | STATE                | state_duration_pct | state_calls |
       +----------------------+--------------------+-------------+
       | Copying to tmp table |              61.42 |           1 |
       | Sending data         |              25.96 |           2 |
       | Sorting result       |               9.56 |           1 |
       | checking permissions |               0.84 |           5 |
       | Opening tables       |               0.77 |           1 |
       | Creating tmp table   |               0.51 |           1 |
       | starting             |               0.21 |           1 |
       | removing tmp table   |               0.18 |           3 |
       | statistics           |               0.18 |           1 |
       | freeing items        |               0.08 |           2 |
       | optimizing           |               0.07 |           2 |
       | preparing            |               0.06 |           1 |
       | Table lock           |               0.04 |           1 |
       | executing            |               0.03 |           2 |
       | closing tables       |               0.02 |           1 |
       | init                 |               0.02 |           1 |
       | System lock          |               0.02 |           1 |
       | cleaning up          |               0.01 |           1 |
       | end                  |               0.01 |           1 |
       | logging slow query   |               0.01 |           1 |
       | query end            |               0.01 |           1 |
       +----------------------+--------------------+-------------+


As a point of interest, we can see that "Opening tables" is no longer a major
impacting state.

ENVIRONMENT

MySQL 5.1 or newer.

SEE ALSO

query_profiling

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('like_to_rlike','
NAME

like_to_rlike(): Convert a LIKE expression to an RLIKE (REGEXP) expression.

TYPE

Function

DESCRIPTION

This function modifies a LIKE expression into a compatible expression to work
with RLIKE (REGEXP).
LIKE expressions use "_" for single character pattern mapping, and "%" for
multiple characters (zero or more) pattern mapping.
Regular expressions use "." and ".*" instead. The routine translates to a
matching regular expression pattern, while taking care to escape some (this is
incomplete) characters which are special characters in regular expression,
that may have appeared in the LIKE expression.

SYNOPSIS



       like_to_rlike(expression TEXT CHARSET utf8)
         RETURNS TEXT CHARSET utf8


Input:

* expression: a LIKE expression


EXAMPLES



       mysql> SELECT like_to_rlike(''customer%'');
       +----------------------------+
       | like_to_rlike(''customer%'') |
       +----------------------------+
       | ^customer.*$               |
       +----------------------------+




       mysql> SELECT like_to_rlike(''c_oun%'');
       +-------------------------+
       | like_to_rlike(''c_oun%'') |
       +-------------------------+
       | ^c.oun.*$               |
       +-------------------------+



ENVIRONMENT

MySQL 5.1 or newer

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('match_grantee','
NAME

match_grantee(): Match an existing account based on user+host.

TYPE

Function

DESCRIPTION

MySQL does not provide with identification of logged in accounts. It only
provides with user + host:port combination within processlist. Alas, these do
not directly map to accounts, as MySQL lists the host:port from which the
connection is made, but not the (possibly wildcard) user or host.
This function matches a user+host combination against the known accounts,
using the same matching method as the MySQL server, to detect the account
which MySQL identifies as the one matching. It is similar in essence to
CURRENT_USER(), only it works for all sessions, not just for the current
session.

SYNOPSIS



       match_grantee(connection_user char(16) CHARSET utf8,
       connection_host char(70) CHARSET utf8)
         RETURNS VARCHAR(100) CHARSET utf8


Input:

* connection_user: user login (e.g. as specified by PROCESSLIST)
* connection_host: login host. May optionally specify port number (e.g.
  webhost:12345), which is discarded by the function. This is to support
  immediate input from as specified by PROCESSLIST.


EXAMPLES

Find an account matching the given use+host combination:


       mysql> SELECT match_grantee(''apps'', ''192.128.0.1:12345'') AS
       grantee;
       +------------+
       | grantee    |
       +------------+
       | ''apps''@''%'' |
       +------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

processlist_grantees

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('metadata','
NAME

metadata: Information about the common_schema project.

TYPE

Table

DESCRIPTION

metadata is a two-columns table, in key-value format, which lists some
internal and general information on the project.
Information includes distribution version, repository, license and author
info.

STRUCTURE



       mysql> DESC common_schema.metadata;
       +-----------------+---------------+------+-----+---------+-------+
       | Field           | Type          | Null | Key | Default | Extra |
       +-----------------+---------------+------+-----+---------+-------+
       | attribute_name  | varchar(32)   | NO   | PRI | NULL    |       |
       | attribute_value | varchar(2048) | NO   |     | NULL    |       |
       +-----------------+---------------+------+-----+---------+-------+



SYNOPSIS

Columns of this table:

* attribute_name: metadata key
* attribute_value: metadata value


EXAMPLES

Get repository information:


       mysql> SELECT * FROM metadata WHERE attribute_name like
       ''%repository%'';
       +-------------------------+---------------------------------------
       ----------+
       | attribute_name          | attribute_value
       |
       +-------------------------+---------------------------------------
       ----------+
       | project_repository      | https://common-schema.googlecode.com/
       svn/trunk/ |
       | project_repository_type | svn
       |
       +-------------------------+---------------------------------------
       ----------+



ENVIRONMENT

MySQL 5.1 or newer.

SEE ALSO

help()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('monitoring_views','
SYNOPSIS

Monitoring views: views providing with simple monitoring capabilities

* global_status_diff: Status variables difference over time, with
  interpolation and extrapolation per time unit
* global_status_diff_clean: Status variables difference over time, with spaces
  where zero diff encountered
* global_status_diff_nonzero: Status variables difference over time, only
  nonzero findings listed


DESCRIPTION

It is possible to construct queries which monitor your MySQL server for
changes. While this provides with very basic status monitoring, it relieves
one from depending on external tools, client connectors, operating system and
otherwise package dependencies.

EXAMPLES

Show GLOBAL STATUS changes (analyzing a QA server):


       mysql> SELECT * FROM common_schema.global_status_diff_nonzero;
       +-----------------------------------+------------------+----------
       --------+---------------------+---------------------+-------------
       -----------+
       | variable_name                     | variable_value_0 |
       variable_value_1 | variable_value_diff | variable_value_psec |
       variable_value_pminute |
       +-----------------------------------+------------------+----------
       --------+---------------------+---------------------+-------------
       -----------+
       | aborted_clients                   | 2308192          | 2308200
       |                   8 |                 0.8 |
       48 |
       | bytes_received                    | 48781508357      |
       48781571162      |               62805 |              6280.5 |
       376830 |
       | bytes_sent                        | 404710036897     |
       404712641950     |             2605053 |            260505.3 |
       15630318 |
       | com_change_db                     | 3813988          | 3813997
       |                   9 |                 0.9 |
       54 |
       | com_delete                        | 5823865          | 5823897
       |                  32 |                 3.2 |
       192 |
       | com_insert                        | 50395791         | 50395868
       |                  77 |                 7.7 |
       462 |
       | com_insert_select                 | 11840815         | 11840832
       |                  17 |                 1.7 |
       102 |
       | com_select                        | 45527485         | 45527537
       |                  52 |                 5.2 |
       312 |
       | com_set_option                    | 100093882        | 100094023
       |                 141 |                14.1 |
       846 |
       | com_show_collations               | 3813977          | 3813986
       |                   9 |                 0.9 |
       54 |
       | com_show_variables                | 3813980          | 3813989
       |                   9 |                 0.9 |
       54 |
       | com_update                        | 5671892          | 5671897
       |                   5 |                 0.5 |
       30 |
       | connections                       | 3839731          | 3839740
       |                   9 |                 0.9 |
       54 |
       | created_tmp_disk_tables           | 859679           | 859681
       |                   2 |                 0.2 |
       12 |
       | created_tmp_tables                | 8731648          | 8731669
       |                  21 |                 2.1 |
       126 |
       | handler_commit                    | 114182717        | 114182891
       |                 174 |                17.4 |
       1044 |
       | handler_delete                    | 10772896         | 10772927
       |                  31 |                 3.1 |
       186 |
       | handler_read_first                | 5913266          | 5913293
       |                  27 |                 2.7 |
       162 |
       | handler_read_key                  | 788386238        | 788387730
       |                1492 |               149.2 |
       8952 |
       | handler_read_next                 | 255429456        | 255469852
       |               40396 |              4039.6 |
       242376 |
       | handler_read_rnd                  | 410066910        | 410068623
       |                1713 |               171.3 |
       10278 |
       | handler_read_rnd_next             | 2530187881       |
       2530208075       |               20194 |              2019.4 |
       121164 |
       | handler_update                    | 25384145         | 25384216
       |                  71 |                 7.1 |
       426 |
       | handler_write                     | 2054152644       |
       2054159103       |                6459 |               645.9 |
       38754 |
       | innodb_buffer_pool_pages_data     | 30052            | 30057
       |                   5 |                 0.5 |
       30 |
       | innodb_buffer_pool_pages_dirty    | 183              | 204
       |                  21 |                 2.1 |
       126 |
       | innodb_buffer_pool_pages_flushed  | 38805231         | 38805438
       |                 207 |                20.7 |
       1242 |
       | innodb_buffer_pool_pages_free     | 4                | 1
       |                  -3 |                -0.3 |                    -
       18 |
       | innodb_buffer_pool_pages_misc     | 1943             | 1941
       |                  -2 |                -0.2 |                    -
       12 |
       | innodb_buffer_pool_read_requests  | 2205096023       |
       2205140951       |               44928 |              4492.8 |
       269568 |
       | innodb_buffer_pool_reads          | 9070710          | 9070712
       |                   2 |                 0.2 |
       12 |
       | innodb_buffer_pool_write_requests | 1009629688       |
       1009632455       |                2767 |               276.7 |
       16602 |
       | innodb_data_fsyncs                | 5691358          | 5691388
       |                  30 |                   3 |
       180 |
       | innodb_data_read                  | 3709091840       |
       3709104128       |               12288 |              1228.8 |
       73728 |
       | innodb_data_reads                 | 9526208          | 9526211
       |                   3 |                 0.3 |
       18 |
       | innodb_data_writes                | 101457695        | 101457999
       |                 304 |                30.4 |
       1824 |
       | innodb_data_written               | 1160983040       |
       1165887488       |             4904448 |            490444.8 |
       29426688 |
       | innodb_dblwr_pages_written        | 38805231         | 38805438
       |                 207 |                20.7 |
       1242 |
       | innodb_dblwr_writes               | 610255           | 610258
       |                   3 |                 0.3 |
       18 |
       | innodb_log_write_requests         | 341450412        | 341451248
       |                 836 |                83.6 |
       5016 |
       | innodb_log_writes                 | 70075432         | 70075559
       |                 127 |                12.7 |
       762 |
       | innodb_os_log_fsyncs              | 2336505          | 2336517
       |                  12 |                 1.2 |
       72 |
       | innodb_os_log_written             | 2583788544       |
       2584199168       |              410624 |             41062.4 |
       2463744 |
       | innodb_pages_created              | 1152396          | 1152398
       |                   2 |                 0.2 |
       12 |
       | innodb_pages_read                 | 9846270          | 9846273
       |                   3 |                 0.3 |
       18 |
       | innodb_pages_written              | 38805231         | 38805438
       |                 207 |                20.7 |
       1242 |
       | innodb_rows_deleted               | 10772886         | 10772917
       |                  31 |                 3.1 |
       186 |
       | innodb_rows_inserted              | 35117242         | 35117332
       |                  90 |                   9 |
       540 |
       | innodb_rows_read                  | 1197149081       |
       1197203914       |               54833 |              5483.3 |
       328998 |
       | innodb_rows_updated               | 22474281         | 22474351
       |                  70 |                   7 |
       420 |
       | key_read_requests                 | 21689837         | 21689845
       |                   8 |                 0.8 |
       48 |
       | open_files                        | 7                | 5
       |                  -2 |                -0.2 |                    -
       12 |
       | opened_files                      | 3666398          | 3666406
       |                   8 |                 0.8 |
       48 |
       | questions                         | 232437302        | 232437654
       |                 352 |                35.2 |
       2112 |
       | select_full_join                  | 99               | 100
       |                   1 |                 0.1 |
       6 |
       | select_range                      | 753753           | 753754
       |                   1 |                 0.1 |
       6 |
       | select_scan                       | 13123762         | 13123808
       |                  46 |                 4.6 |
       276 |
       | sort_rows                         | 409565982        | 409567695
       |                1713 |               171.3 |
       10278 |
       | sort_scan                         | 801869           | 801872
       |                   3 |                 0.3 |
       18 |
       | table_locks_immediate             | 129542449        | 129542648
       |                 199 |                19.9 |
       1194 |
       | threads_cached                    | 7                | 8
       |                   1 |                 0.1 |
       6 |
       | threads_created                   | 838815           | 838817
       |                   2 |                 0.2 |
       12 |
       +-----------------------------------+------------------+----------
       --------+---------------------+---------------------+-------------
       -----------+


');
		
			INSERT INTO common_schema.help_content VALUES ('mysql_grantee','
NAME

mysql_grantee(): Return a qualified MySQL grantee (account) based on user and
host.

TYPE

Function

DESCRIPTION

MySQL is inconsistent in its reference to user accounts. At times, a user+host
combination is used (e.g. the mysql.user table, or the even fuzzier
PROCESSLIST). Other times, a grantee is used (e.g. with INFORMATION_SCHEMA
tables).
This function is a simple text wrapper function, which is useful in automation
of SQL query generation, or otherwise in comparing and recognizing accounts in
different formats (user+host vs. grantee formats).

SYNOPSIS



       mysql_grantee(mysql_user char(16) CHARSET utf8, mysql_host char
       (60) CHARSET utf8)
         RETURNS VARCHAR(100) CHARSET utf8


Input:

* mysql_user: name of user.
* mysql_host: name of host.

Output: fully qualified GRANTEE name

EXAMPLES

Qualify a GRANTEE:


       SELECT common_schema.mysql_grantee(''web_user'', ''192.128.0.%'') AS
       grantee;
       +--------------------------+
       | grantee                  |
       +--------------------------+
       | ''web_user''@''192.128.0.%'' |
       +--------------------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

match_grantee()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('mysql_qualify','
NAME

mysql_qualify(): Return a qualified MySQL object name.

TYPE

Function

DESCRIPTION

A qualified MySQL object name is its name surrounded by backticks, e.g.
`sakila`. The function wraps the given text with backticks, if it is not
already qualified as such. It handles cases where a backtick is part of the
object''s name (though this is considered poor practice).

SYNOPSIS



       mysql_qualify(name TINYTEXT CHARSET utf8)
         RETURNS TINYTEXT CHARSET utf8


Input:

* name: an object''s name. An object is a schema, table, column, index, foreign
  key, view, trigger, etc.


EXAMPLES

Qualify a simple name:


       mysql> SELECT common_schema.mysql_qualify(''film_actor'') AS
       qualified;
       +--------------+
       | qualified    |
       +--------------+
       | `film_actor` |
       +--------------+



ENVIRONMENT

MySQL 5.1 or newer

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('no_pk_innodb_tables','
NAME

no_pk_innodb_tables: List InnoDB tables where no PRIMARY KEY is defined

TYPE

View

DESCRIPTION

InnoDB uses a clustered B+ tree as underlying data structure. Data is
clustered via clustering index, which is the PRIMARY KEY in InnoDB. It follows
that any InnoDB table has a PRIMARY KEY, whether one was explicitly defined or
not.
When no PRIMARY KEY is defined, InnoDB chooses an existing UNIQUE KEY on the
table (but does not let us know which). When no such key is available, it
creates an internal PRIMARY KEY, based on row id. However, it does not provide
access to this data. This leads to a table clustered by some value we cannot
access, control, nor define. It is generally bad practice to create an InnoDB
table with no explicit PRIMARY KEY.
no_pk_innodb_tables lists InnoDB tables where PRIMARY KEY is not explicitly
created. It offers a list of candidate keys: UNIQUE keys already defined,
which are eligible to take the part of PRIMARY KEY.

STRUCTURE



       mysql> DESC common_schema.no_pk_innodb_tables;
       +----------------+-------------+------+-----+---------+-------+
       | Field          | Type        | Null | Key | Default | Extra |
       +----------------+-------------+------+-----+---------+-------+
       | TABLE_SCHEMA   | varchar(64) | NO   |     |         |       |
       | TABLE_NAME     | varchar(64) | NO   |     |         |       |
       | ENGINE         | varchar(64) | YES  |     | NULL    |       |
       | candidate_keys | longtext    | YES  |     | NULL    |       |
       +----------------+-------------+------+-----+---------+-------+



SYNOPSIS

Columns of this view:

* TABLE_SCHEMA: schema of InnoDB table missing PRIMARY KEY
* TABLE_NAME: InnoDB table missing PRIMARY KEY
* ENGINE: currently the constant ''InnoDB''
* candidate_keys: Comma seperated list of candidate (UNIQUE) keys, or NULL if
  no such keys are available.


EXAMPLES

Show foreign keys create/drop statements for `sakila`.`film_actor` (depends on
`film` and `actor` tables)


       mysql> ALTER TABLE `sakila`.`rental` MODIFY rental_id INT NOT
       NULL, DROP PRIMARY KEY, ADD UNIQUE KEY(rental_id);
       mysql> CREATE TABLE `test`.`no_pk` (id INT) ENGINE=InnoDB;

       mysql> SELECT * FROM common_schema.no_pk_innodb_tables;
       +--------------+------------+--------+-----------------------+
       | TABLE_SCHEMA | TABLE_NAME | ENGINE | candidate_keys        |
       +--------------+------------+--------+-----------------------+
       | sakila       | rental     | InnoDB | rental_date,rental_id |
       | test         | no_pk      | InnoDB | NULL                  |
       +--------------+------------+--------+-----------------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

candidate_keys, redundant_keys

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('numbers','
NAME

numbers: Listing of numbers in the range 0..4095

TYPE

Table

DESCRIPTION

numbers provides with a reliable source of indexed numbers. Values range
[0..4095]. This table is utilized by a few of common_schema''s views.

STRUCTURE



       mysql> DESC common_schema.numbers;
       +-------+----------------------+------+-----+---------+-------+
       | Field | Type                 | Null | Key | Default | Extra |
       +-------+----------------------+------+-----+---------+-------+
       | n     | smallint(5) unsigned | NO   | PRI | NULL    |       |
       +-------+----------------------+------+-----+---------+-------+



SYNOPSIS

Columns of this table:

* n: an unsigned integer. Numbers are sequential, ascending


EXAMPLES

Get 10 lowest values:


       mysql> SELECT * FROM common_schema.numbers WHERE n < 10;
       +---+
       | n |
       +---+
       | 0 |
       | 1 |
       | 2 |
       | 3 |
       | 4 |
       | 5 |
       | 6 |
       | 7 |
       | 8 |
       | 9 |
       +---+



ENVIRONMENT

MySQL 5.1 or newer.

SEE ALSO


AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('percona_server_views','
SYNOPSIS

Percona server views: views enhancing INFORMATION_SCHEMA tables available in
Percona Server.

* innodb_index_rows: number of row cardinality per keys per columns in InnoDB
  tables
* innodb_index_stats: estimated InnoDB depth & split factor of key''s B+ Tree


DESCRIPTION

These views rely on the INNODB_INDEX_STATS feature to be enabled. The views
are compatible with recent versions of Percona Server (due to changes to
INNODB_INDEX_STATS schema in Percona Server 5.5.8, these views are
incompatible with earlier versions).

EXAMPLES

Examine keys selectivity/cardinality on a specific table:


       mysql> SELECT * FROM common_schema.innodb_index_rows WHERE
       TABLE_SCHEMA=''sakila'' AND TABLE_NAME=''inventory'';
       +--------------+------------+----------------------+--------------
       +--------------+-------------------------+------------------------
       -+
       | TABLE_SCHEMA | TABLE_NAME | INDEX_NAME           | SEQ_IN_INDEX
       | COLUMN_NAME  | is_last_column_in_index | incremental_row_per_key
       |
       +--------------+------------+----------------------+--------------
       +--------------+-------------------------+------------------------
       -+
       | sakila       | inventory  | PRIMARY              |            1
       | inventory_id |                       1 |                       1
       |
       | sakila       | inventory  | idx_fk_film_id       |            1
       | film_id      |                       1 |                       5
       |
       | sakila       | inventory  | idx_store_id_film_id |            1
       | store_id     |                       0 |                    4478
       |
       | sakila       | inventory  | idx_store_id_film_id |            2
       | film_id      |                       1 |                       2
       |
       +--------------+------------+----------------------+--------------
       +--------------+-------------------------+------------------------
       -+


');
		
			INSERT INTO common_schema.help_content VALUES ('prettify_message','
NAME

prettify_message(): Outputs a prettified text message, one row per line in
text

TYPE

Procedure

DESCRIPTION

This procedure returns a result set of a single column and of a dynamic number
of rows, consisting of given text and titled by given header.
In essence, it breaks the given text to lines using the ''\\n'' delimiter, and
outputs each such line in its own row.
The help() system uses this routine internally.

SYNOPSIS



       prettify_message(title TINYTEXT CHARSET utf8, msg MEDIUMTEXT
       CHARSET utf8)


Input:

* title: header, displayed as name of column
* msg: message to be displayed, possibly including line breaks (the ''\\n''
  character)


EXAMPLES

Prettify a message:


       mysql> call prettify_message(''success'', ''Execution
       complete.\\nPlease follow next instructions.\\n\\nThank you for
       testing!'');
       +----------------------------------+
       | success                          |
       +----------------------------------+
       | Execution complete.              |
       | Please follow next instructions. |
       |                                  |
       | Thank you for testing!           |
       +----------------------------------+
       4 rows in set (0.01 sec)



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

get_num_tokens(), split_token(), tokenize()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('process_routines','
SYNOPSIS

Process routines: stored routines managing query, session and process
information & workflow.

* query_laptime(): Number of seconds this query has been running for since
  last invocation of this function.
* query_runtime(): Number of seconds this query has been running for so far.
* session_unique_id(): Returns an integer unique to this session.
* this_query(): Returns the current query executed by this thread.
* throttle(): Throttle current query by periodically sleeping throughout its
  execution.


DESCRIPTION

Process routines act on, or provide information on the current session. A
MySQL connection is assigned with a unique session, which is isolated from
other sessions in terms of temporary tables, user defined variables, process
ID, credentials and some memory buffers. The process routines utilize some of
these properties.

EXAMPLES

Throttle a heavy weight query, doubling its total runtime by injecting sleep
periods:


       mysql> SELECT Id, Name, throttle(1) from my_schema.huge_table
       ORDER BY Population DESC;
       	


Show query runtime and query laptime for a long running query:


       mysql> SELECT Id, Name, sleep(0.3) AS s, SYSDATE(), query_runtime
       (), query_laptime() from world.City limit 30;
       +----+-------------------+---+---------------------+--------------
       ---+-----------------+
       | Id | Name              | s | SYSDATE()           | query_runtime
       () | query_laptime() |
       +----+-------------------+---+---------------------+--------------
       ---+-----------------+
       |  1 | Kabul             | 0 | 2012-01-22 12:25:41 |
       1 |               1 |
       |  2 | Qandahar          | 0 | 2012-01-22 12:25:41 |
       1 |               0 |
       |  3 | Herat             | 0 | 2012-01-22 12:25:41 |
       1 |               0 |
       |  4 | Mazar-e-Sharif    | 0 | 2012-01-22 12:25:41 |
       1 |               0 |
       |  5 | Amsterdam         | 0 | 2012-01-22 12:25:42 |
       2 |               1 |
       |  6 | Rotterdam         | 0 | 2012-01-22 12:25:42 |
       2 |               0 |
       |  7 | Haag              | 0 | 2012-01-22 12:25:42 |
       2 |               0 |
       |  8 | Utrecht           | 0 | 2012-01-22 12:25:43 |
       3 |               1 |
       |  9 | Eindhoven         | 0 | 2012-01-22 12:25:43 |
       3 |               0 |
       | 10 | Tilburg           | 0 | 2012-01-22 12:25:43 |
       3 |               0 |
       | 11 | Groningen         | 0 | 2012-01-22 12:25:44 |
       4 |               1 |
       | 12 | Breda             | 0 | 2012-01-22 12:25:44 |
       4 |               0 |
       | 13 | Apeldoorn         | 0 | 2012-01-22 12:25:44 |
       4 |               0 |
       | 14 | Nijmegen          | 0 | 2012-01-22 12:25:44 |
       4 |               0 |
       | 15 | Enschede          | 0 | 2012-01-22 12:25:45 |
       5 |               1 |
       | 16 | Haarlem           | 0 | 2012-01-22 12:25:45 |
       5 |               0 |
       | 17 | Almere            | 0 | 2012-01-22 12:25:45 |
       5 |               0 |
       | 18 | Arnhem            | 0 | 2012-01-22 12:25:46 |
       6 |               1 |
       | 19 | Zaanstad          | 0 | 2012-01-22 12:25:46 |
       6 |               0 |
       | 20 | ´s-Hertogenbosch  | 0 | 2012-01-22 12:25:46 |
       6 |               0 |
       | 21 | Amersfoort        | 0 | 2012-01-22 12:25:47 |
       7 |               1 |
       | 22 | Maastricht        | 0 | 2012-01-22 12:25:47 |
       7 |               0 |
       | 23 | Dordrecht         | 0 | 2012-01-22 12:25:47 |
       7 |               0 |
       | 24 | Leiden            | 0 | 2012-01-22 12:25:47 |
       7 |               0 |
       | 25 | Haarlemmermeer    | 0 | 2012-01-22 12:25:48 |
       8 |               1 |
       | 26 | Zoetermeer        | 0 | 2012-01-22 12:25:48 |
       8 |               0 |
       | 27 | Emmen             | 0 | 2012-01-22 12:25:48 |
       8 |               0 |
       | 28 | Zwolle            | 0 | 2012-01-22 12:25:49 |
       9 |               1 |
       | 29 | Ede               | 0 | 2012-01-22 12:25:49 |
       9 |               0 |
       | 30 | Delft             | 0 | 2012-01-22 12:25:49 |
       9 |               0 |
       +----+-------------------+---+---------------------+--------------
       ---+-----------------+


');
		
			INSERT INTO common_schema.help_content VALUES ('process_views','
SYNOPSIS

Process views: informational views on processes and accounts

* last_query_profiling: Last query''s profiling info, aggregated by query''s
  states
* processlist_grantees: Assigning of GRANTEEs for connected processes
* processlist_per_userhost: State of processes per user/host: connected,
  executing, average execution time
* processlist_repl: Listing of replication processes: the server''s slave
  threads and any replicating slaves
* processlist_states: Summary of processlist states and their run time
* processlist_summary: Number of connected, sleeping, running connections and
  slow query count
* processlist_top: Listing of active processes sorted by current query
  runtime, desc (longest first)
* query_profiling: Per query profiling info, aggregated by query states
* slave_hosts: Listing of hosts replicating from current server
* slave_status: Provide with slave status info


DESCRIPTION

These views complement and enhance upon INFORMATION_SCHEMA.PROCESSLIST, and
provide with such benefits as matching GRANTEEs to a process IDs, getting
process summaries, listing only active processes, prioritized.

EXAMPLES

Show grantees for all processes:


       mysql> SELECT * FROM common_schema.processlist_grantees;
       +--------+------------+---------------------+---------------------
       ---+--------------+--------------+----------+---------+-----------
       --------+---------------------+
       | ID     | USER       | HOST                | GRANTEE
       | grantee_user | grantee_host | is_super | is_repl |
       sql_kill_query    | sql_kill_connection |
       +--------+------------+---------------------+---------------------
       ---+--------------+--------------+----------+---------+-----------
       --------+---------------------+
       | 650472 | replica    | jboss00.myweb:34266 | ''replica''@''%.myweb''
       | replica      | %.myweb      |        0 |       1 | KILL QUERY
       650472 | KILL 650472         |
       | 692346 | openarkkit | jboss02.myweb:43740 |
       ''openarkkit''@''%.myweb'' | openarkkit   | %.myweb      |        0 |
       0 | KILL QUERY 692346 | KILL 692346         |
       | 842853 | root       | localhost           | ''root''@''localhost''
       | root         | localhost    |        1 |       0 | KILL QUERY
       842853 | KILL 842853         |
       | 843443 | jboss      | jboss03.myweb:40007 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       843443 | KILL 843443         |
       | 843444 | jboss      | jboss03.myweb:40012 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       843444 | KILL 843444         |
       | 843510 | jboss      | jboss00.myweb:49850 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       843510 | KILL 843510         |
       | 844559 | jboss      | jboss01.myweb:37031 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844559 | KILL 844559         |
       | 844577 | jboss      | jboss03.myweb:38238 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844577 | KILL 844577         |
       | 844592 | jboss      | jboss02.myweb:34405 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844592 | KILL 844592         |
       | 844593 | jboss      | jboss01.myweb:37089 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844593 | KILL 844593         |
       | 844595 | jboss      | jboss04.myweb:46488 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844595 | KILL 844595         |
       | 844596 | jboss      | jboss00.myweb:41046 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844596 | KILL 844596         |
       | 844600 | jboss      | jboss01.myweb:37108 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844600 | KILL 844600         |
       | 844614 | jboss      | jboss04.myweb:46500 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844614 | KILL 844614         |
       | 844618 | jboss      | jboss02.myweb:44449 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844618 | KILL 844618         |
       | 844620 | jboss      | jboss02.myweb:44456 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844620 | KILL 844620         |
       | 844626 | jboss      | jboss04.myweb:46526 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844626 | KILL 844626         |
       | 844628 | jboss      | jboss02.myweb:44466 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844628 | KILL 844628         |
       | 844631 | jboss      | jboss03.myweb:38291 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844631 | KILL 844631         |
       +--------+------------+---------------------+---------------------
       ---+--------------+--------------+----------+---------+-----------
       --------+---------------------+


Show all active processes:


       mysql> SELECT * FROM common_schema.processlist_top;
       +----------+-------------+--------------+-----------+-------------
       +---------+-------------------------------------------------------
       -----------+------------------------------------------------------
       -----------------------------------------------------------------
       +------------+
       | ID       | USER        | HOST         | DB        | COMMAND
       | TIME    | STATE
       | INFO
       | TIME_MS    |
       +----------+-------------+--------------+-----------+-------------
       +---------+-------------------------------------------------------
       -----------+------------------------------------------------------
       -----------------------------------------------------------------
       +------------+
       |  3598334 | system user |              | NULL      | Connect
       | 4281883 | Waiting for master to send event
       | NULL
       | 4281883102 |
       |  3598469 | replica     | sql01:51157  | NULL      | Binlog Dump
       | 4281878 | Has sent all binlog to slave; waiting for binlog to be
       updated   | NULL
       | 4281877707 |
       | 31066726 | replica     | sql02:48924  | NULL      | Binlog Dump
       | 1041758 | Has sent all binlog to slave; waiting for binlog to be
       updated   | NULL
       | 1041758134 |
       |  3598335 | system user |              | NULL      | Connect
       |  195747 | Has read all relay log; waiting for the slave I/
       O thread to upda | NULL
       |          0 |
       | 39946702 | store       | app03:46795  | datastore | Query
       |       0 | Writing to net
       | SELECT * FROM store_location
       |         27 |
       | 39946693 | store       | app05:51090  | datastore | Query
       |       0 | Writing to net
       | SELECT store.store_id, store_location.zip_code FROM store JOIN
       store_location USING (store_id) WHERE store_class = 5  |
       54 |
       | 39946692 | store       | sql01:47849  | datastore | Query
       |       0 | Writing to net
       | SELECT store.store_id, store_location.zip_code FROM store JOIN
       store_location USING (store_id) WHERE store_class = 34 |
       350 |
       +----------+-------------+--------------+-----------+-------------
       +---------+-------------------------------------------------------
       -----------+------------------------------------------------------
       -----------------------------------------------------------------
       +------------+


');
		
			INSERT INTO common_schema.help_content VALUES ('processlist_grantees','
NAME

processlist_grantees: Assigning of GRANTEEs for connected processes

TYPE

View

DESCRIPTION

processlist_grantees Lists connected processes, as with PROCESSLIST. For each
process, it analyzes the connected GRANTEE. It does so by inspecting the
user+host presented by PROCESSLIST, and matches those values, in a similar
algorithm to that of the MySQL server, to the list of known accounts.
MySQL''s PROCESSLIST fails to make the connection between a process ID and the
account for which this process is assigned. It only tells us the connection''s
HOST and the specified USER. But these do not necessarily map directly to the
known grantees: MySQL accounts can specify wildcards for both user and host.
MySQL offers the USER() and CURRENT_USER() functions, which provide desired
data, but only for current connection.
processlist_grantees bridges the two by utilizing match_grantee() for each
process in the PROCESSLIST. It also provides with additional useful
information about the matched account.

STRUCTURE



       mysql> DESC common_schema.processlist_grantees;
       +---------------------+---------------+------+-----+---------+----
       ---+
       | Field               | Type          | Null | Key | Default |
       Extra |
       +---------------------+---------------+------+-----+---------+----
       ---+
       | ID                  | bigint(4)     | NO   |     | 0       |
       |
       | USER                | varchar(16)   | NO   |     |         |
       |
       | HOST                | varchar(64)   | NO   |     |         |
       |
       | DB                  | varchar(64)   | YES  |     | NULL    |
       |
       | COMMAND             | varchar(16)   | NO   |     |         |
       |
       | TIME                | int(7)        | NO   |     | 0       |
       |
       | STATE               | varchar(64)   | YES  |     | NULL    |
       |
       | INFO                | longtext      | YES  |     | NULL    |
       |
       | GRANTEE             | varchar(81)   | YES  |     |         |
       |
       | grantee_user        | char(16)      | YES  |     |         |
       |
       | grantee_host        | char(60)      | YES  |     |         |
       |
       | is_super            | decimal(23,0) | YES  |     | NULL    |
       |
       | is_repl             | int(1)        | NO   |     | 0       |
       |
       | is_current          | int(1)        | NO   |     | 0       |
       |
       | sql_kill_query      | varbinary(31) | NO   |     |         |
       |
       | sql_kill_connection | varbinary(25) | NO   |     |         |
       |
       +---------------------+---------------+------+-----+---------+----
       ---+



SYNOPSIS

Rows of this view map directly to rows in INFORMATION_SCHEMA.PROCESSLIST. This
view extends PROCESSLIST by including all existing columns, and adding some of
its own.
Columns of this view:

* ID: process ID, as in PROCESSLIST
* USER: name of connected user, as in PROCESSLIST
* HOST: connection''s host + port, as in PROCESSLIST
* DB: connection''s current schema, as in PROCESSLIST
* COMMAND: connection''s command, as in PROCESSLIST
* TIME: current command runtime in seconds, as in PROCESSLIST
* STATE: connection''s state, as in PROCESSLIST
* INFO: command info, as in PROCESSLIST
* GRANTEE: account which is calculated by match_grantee() to match this
  process.
* grantee_user: user part of the GRANTEE.
* grantee_host: host part of the GRANTEE. This does not include port
  specification.
* is_super: 1 if the grantee has the SUPER privilege; 0 if not.
* is_repl: 1 if the connection appears to be a replication thread; 0 if not.
* is_current: 1 if the process is the current connection; 0 if not.
* sql_kill_query: generated statement to kill current query.
  Use with eval() to apply query.
* sql_kill_connection: generated statement to kill current connection.
  Use with eval() to apply query.


EXAMPLES

Show grantees for all processes:


       mysql> SELECT ID, USER, HOST, GRANTEE, grantee_user, grantee_host,

           is_super, is_repl, sql_kill_query, sql_kill_connection
         FROM
           common_schema.processlist_grantees;
       +--------+------------+---------------------+---------------------
       ---+--------------+--------------+----------+---------+-----------
       --------+---------------------+
       | ID     | USER       | HOST                | GRANTEE
       | grantee_user | grantee_host | is_super | is_repl |
       sql_kill_query    | sql_kill_connection |
       +--------+------------+---------------------+---------------------
       ---+--------------+--------------+----------+---------+-----------
       --------+---------------------+
       | 650472 | replica    | jboss00.myweb:34266 | ''replica''@''%.myweb''
       | replica      | %.myweb      |        0 |       1 | KILL QUERY
       650472 | KILL 650472         |
       | 692346 | openarkkit | jboss02.myweb:43740 |
       ''openarkkit''@''%.myweb'' | openarkkit   | %.myweb      |        0 |
       0 | KILL QUERY 692346 | KILL 692346         |
       | 842853 | root       | localhost           | ''root''@''localhost''
       | root         | localhost    |        1 |       0 | KILL QUERY
       842853 | KILL 842853         |
       | 843443 | jboss      | jboss03.myweb:40007 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       843443 | KILL 843443         |
       | 843444 | jboss      | jboss03.myweb:40012 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       843444 | KILL 843444         |
       | 843510 | jboss      | jboss00.myweb:49850 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       843510 | KILL 843510         |
       | 844559 | jboss      | jboss01.myweb:37031 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844559 | KILL 844559         |
       | 844577 | jboss      | jboss03.myweb:38238 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844577 | KILL 844577         |
       | 844592 | jboss      | jboss02.myweb:34405 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844592 | KILL 844592         |
       | 844593 | jboss      | jboss01.myweb:37089 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844593 | KILL 844593         |
       | 844595 | jboss      | jboss04.myweb:46488 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844595 | KILL 844595         |
       | 844596 | jboss      | jboss00.myweb:41046 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844596 | KILL 844596         |
       | 844600 | jboss      | jboss01.myweb:37108 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844600 | KILL 844600         |
       | 844614 | jboss      | jboss04.myweb:46500 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844614 | KILL 844614         |
       | 844618 | jboss      | jboss02.myweb:44449 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844618 | KILL 844618         |
       | 844620 | jboss      | jboss02.myweb:44456 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844620 | KILL 844620         |
       | 844626 | jboss      | jboss04.myweb:46526 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844626 | KILL 844626         |
       | 844628 | jboss      | jboss02.myweb:44466 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844628 | KILL 844628         |
       | 844631 | jboss      | jboss03.myweb:38291 | ''jboss''@''%.myweb''
       | jboss        | %.myweb      |        0 |       0 | KILL QUERY
       844631 | KILL 844631         |
       +--------+------------+---------------------+---------------------
       ---+--------------+--------------+----------+---------+-----------
       --------+---------------------+


In the above, ''root''@''localhost'' is a trivial match, but other connections are
mapped to accounts based on wildcards. All jboss users are connected from
jboss??.myweb servers, and are matched to the ''jboss''@''%.myweb'' account.

ENVIRONMENT

MySQL 5.1 or newer.

SEE ALSO

match_grantee(), processlist_per_userhost, processlist_repl,
processlist_summary

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('processlist_per_userhost','
NAME

processlist_per_userhost: State of processes per user/host: connected,
executing, average execution time

TYPE

View

DESCRIPTION

processlist_per_userhost lists connected processes grouped by user & host
combination. It provides with aggregated data per such entry.
This view makes it easier to detect particular users who are causing for
longer running queries, or particular hosts from where heavy weight queries
are executed.

STRUCTURE



       mysql> DESC common_schema.processlist_per_userhost;
       +--------------------------+---------------+------+-----+---------
       +-------+
       | Field                    | Type          | Null | Key | Default
       | Extra |
       +--------------------------+---------------+------+-----+---------
       +-------+
       | user                     | varchar(16)   | NO   |     |
       |       |
       | host                     | varchar(64)   | YES  |     | NULL
       |       |
       | count_processes          | bigint(21)    | NO   |     | 0
       |       |
       | active_processes         | decimal(23,0) | YES  |     | NULL
       |       |
       | median_active_time       | decimal(10,2) | YES  |     | NULL
       |       |
       | median_95pct_active_time | decimal(10,2) | YES  |     | NULL
       |       |
       | max_active_time          | bigint(20)    | YES  |     | NULL
       |       |
       | average_active_time      | decimal(14,4) | YES  |     | NULL
       |       |
       +--------------------------+---------------+------+-----+---------
       +-------+



SYNOPSIS

Columns of this view:

* user: login name of running process
* host: connection host of origin. This excludes the connection port
* count_processes: number of connections for current user/host
* active_processes: number of connections executing queries for current user/
  host
* median_active_time: longest run time for an active process of this user/host
* median_95pct_active_time: run time at 95% point (95% processes run at this
  time or less) for active processes of this user/host
* max_active_time: longest run time for an active process of this user/host
* average_active_time: average time of currently executing queries for current
  user/host (excludes sleeping processes)

Processes, threads & connections have mixed terminology, but usually mean the
same thing in the MySQL world. Read MySQL_terminology:_processes,_threads_&
connections for more on this.

EXAMPLES



       mysql> SELECT * FROM common_schema.processlist_per_userhost;
       +------------+-----------+-----------------+------------------+---
       -----------------+--------------------------+-----------------+---
       ------------------+
       | user       | host      | count_processes | active_processes |
       median_active_time | median_95pct_active_time | max_active_time |
       average_active_time |
       +------------+-----------+-----------------+------------------+---
       -----------------+--------------------------+-----------------+---
       ------------------+
       | web_user   | apps01    |               9 |                4 |
       0.00 |                     2.00 |               2 |
       0.5000 |
       | web_user   | apps05    |               5 |                0 |
       NULL |                     NULL |            NULL |
       NULL |
       | web_user   | apps04    |              11 |                4 |
       0.00 |                     0.00 |               0 |
       0.0000 |
       | web_user   | sql00     |               1 |                0 |
       NULL |                     NULL |            NULL |
       NULL |
       | web_user   | sql01     |               1 |                0 |
       NULL |                     NULL |            NULL |
       NULL |
       | web_user   | sql02     |               3 |                1 |
       0.00 |                     0.00 |               0 |
       0.0000 |
       | web_user   | apps08    |              17 |               15 |
       0.00 |                     1.00 |               2 |
       0.4667 |
       | web_user   | apps03    |               2 |                0 |
       NULL |                     NULL |            NULL |
       NULL |
       | web_user   | apps06    |              12 |                5 |
       2.00 |                     2.00 |               2 |
       1.4000 |
       | web_user   | apps07    |               9 |                3 |
       0.00 |                     2.00 |               2 |
       0.6667 |
       | monitor    | localhost |               1 |                0 |
       NULL |                     NULL |            NULL |
       NULL |
       | monitor    | sql00     |               1 |                1 |
       0.00 |                     0.00 |               0 |
       0.0000 |
       | monitor    | sql01     |               1 |                1 |
       0.00 |                     0.00 |               0 |
       0.0000 |
       | monitor    | sql02     |               1 |                1 |
       0.00 |                     0.00 |               0 |
       0.0000 |
       | openarkkit | sql02     |               8 |                8 |
       0.00 |                     3.00 |               3 |
       0.8750 |
       | replicator | sql00     |               1 |                1 |
       41571.00 |                 41571.00 |           41571 |
       41571.0000 |
       | replicator | sql02     |               1 |                1 |
       41571.00 |                 41571.00 |           41571 |
       41571.0000 |
       +------------+-----------+-----------------+------------------+---
       -----------------+--------------------------+-----------------+---
       ------------------+



ENVIRONMENT

MySQL 5.1 or newer.

SEE ALSO

processlist_repl, processlist_states, processlist_summary, processlist_top

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('processlist_repl','
NAME

processlist_repl: Listing of replication processes: the server''s slave threads
and any replicating slaves

TYPE

View

DESCRIPTION

processlist_repl displays only replication processes. These may include:

* Connected slaves: when this server acts as a master, each slave connects
  using a single process. A slave with running IO thread will appear in this
  server''s processlist_repl
* IO thread: if this server is itself a replicating slave
* SQL thread: if this server is itself a replicating slave

This view provides with a quick look at replication status processlist-wise.

STRUCTURE



       mysql> DESC common_schema.processlist_repl;
       +---------------+-------------+------+-----+---------+-------+
       | Field         | Type        | Null | Key | Default | Extra |
       +---------------+-------------+------+-----+---------+-------+
       | ID            | bigint(4)   | NO   |     | 0       |       |
       | USER          | varchar(16) | NO   |     |         |       |
       | HOST          | varchar(64) | NO   |     |         |       |
       | DB            | varchar(64) | YES  |     | NULL    |       |
       | COMMAND       | varchar(16) | NO   |     |         |       |
       | TIME          | int(7)      | NO   |     | 0       |       |
       | STATE         | varchar(64) | YES  |     | NULL    |       |
       | INFO          | longtext    | YES  |     | NULL    |       |
       | is_system     | int(1)      | NO   |     | 0       |       |
       | is_io_thread  | int(1)      | NO   |     | 0       |       |
       | is_sql_thread | int(1)      | NO   |     | 0       |       |
       | is_slave      | int(1)      | NO   |     | 0       |       |
       +---------------+-------------+------+-----+---------+-------+



SYNOPSIS

Structure of this view derives from INFORMATION_SCHEMA.PROCESSLIST table
Additional columns are:

* is_system: 1 if this is the system user (SQL or IO slave threads); 0
  otherwise.
* is_io_thread: 1 if this is the slave IO thread, 0 otherwise.
* is_sql_thread: 1 if this is the slave SQL thread, 0 otherwise.
* is_slave: 1 if this is a replicating slave connection; 0 otherwise.

is_system and is_slave are mutually exclusive. In this view every process is
either is_system or is_slave.
An is_system process is either a slave IO thread or SQL thread, as denoted by
is_io_thread and is_sql_thread, respectively.
On Percona Server, this additional info is included:

* TIME_MS: execution time in milliseconds


EXAMPLES

Show all replication processes


       mysql> SELECT * FROM common_schema.processlist_repl;
       +--------+-------------+-------------+------+-------------+-------
       +-----------------------------------------------------------------
       -+------+----------+-----------+--------------+---------------+---
       -------+
       | ID     | USER        | HOST        | DB   | COMMAND     | TIME
       | STATE
       | INFO | TIME_MS  | is_system | is_io_thread | is_sql_thread |
       is_slave |
       +--------+-------------+-------------+------+-------------+-------
       +-----------------------------------------------------------------
       -+------+----------+-----------+--------------+---------------+---
       -------+
       | 805225 | system user |             | NULL | Connect     |     0
       | Has read all relay log; waiting for the slave I/O thread to upda
       | NULL |        0 |         1 |            0 |             1 |
       0 |
       | 805224 | system user |             | NULL | Connect     |     5
       | Waiting for master to send event
       | NULL |     4327 |         1 |            1 |             0 |
       0 |
       | 425707 | repl_user   | sql02:46645 | NULL | Binlog Dump | 38273
       | Has sent all binlog to slave; waiting for binlog to be updated
       | NULL | 38272802 |         0 |            0 |             0 |
       1 |
       |     88 | repl_user   | sql00:46485 | NULL | Binlog Dump | 79071
       | Has sent all binlog to slave; waiting for binlog to be updated
       | NULL | 79070732 |         0 |            0 |             0 |
       1 |
       +--------+-------------+-------------+------+-------------+-------
       +-----------------------------------------------------------------
       -+------+----------+-----------+--------------+---------------+---
       -------+


In the above example we see two slaves replicating from this server (sql02 &
sql00), and the two threads (IO thread, SQL thread) this server uses to
replication from its master

ENVIRONMENT

MySQL 5.1 or newer. Percona Server yields a different schema.

SEE ALSO

processlist_per_userhost, processlist_summary, processlist_top, slave_status

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('processlist_states','
NAME

processlist_states: Summary of processlist states and their run time

TYPE

View

DESCRIPTION

processlist_states aggregates the various thread_states and presents time
metrics for those states.
It makes for a general overview of "what is my MySQL server doing right now".

STRUCTURE



       mysql> DESC common_schema.processlist_states;
       +-------------------------+---------------+------+-----+---------
       +-------+
       | Field                   | Type          | Null | Key | Default |
       Extra |
       +-------------------------+---------------+------+-----+---------
       +-------+
       | state                   | varchar(64)   | YES  |     | NULL    |
       |
       | count_processes         | bigint(21)    | NO   |     | 0       |
       |
       | median_state_time       | decimal(10,2) | YES  |     | NULL    |
       |
       | median_95pct_state_time | decimal(10,2) | YES  |     | NULL    |
       |
       | max_state_time          | int(7)        | YES  |     | NULL    |
       |
       | sum_state_time          | decimal(32,0) | YES  |     | NULL    |
       |
       +-------------------------+---------------+------+-----+---------
       +-------+



SYNOPSIS

Columns of this view:

* state: a thread state which is currently running
* count_processes: number of threads (processes) in this state
* median_state_time: median run time processes in this state
* median_95pct_state_time: run time at 95% processes (95% processes run at
  this or under this time) in this state
* max_state_time: maximum run time for process in this state
* sum_state_time: sum of all run time seconds for processes in this state


EXAMPLES



       mysql> SELECT * FROM common_schema.processlist_states;
       +----------------------------------------------------------------
       +-----------------+-------------------+-------------------------+-
       ---------------+----------------+
       | state                                                          |
       count_processes | median_state_time | median_95pct_state_time |
       max_state_time | sum_state_time |
       +----------------------------------------------------------------
       +-----------------+-------------------+-------------------------+-
       ---------------+----------------+
       |                                                                |
       77 |              2.00 |                  203.00 |            500
       |           2475 |
       | NULL                                                           |
       2 |              0.00 |                    0.00 |              0 |
       0 |
       | Has sent all binlog to slave; waiting for binlog to be updated |
       2 |          38896.00 |                38896.00 |          38896 |
       77792 |
       | freeing items                                                  |
       1 |              0.00 |                    0.00 |              0 |
       0 |
       | Sending data                                                   |
       1 |              0.00 |                    0.00 |              0 |
       0 |
       +----------------------------------------------------------------
       +-----------------+-------------------+-------------------------+-
       ---------------+----------------+



ENVIRONMENT

MySQL 5.1 or newer.

SEE ALSO

processlist_summary, processlist_top

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('processlist_summary','
NAME

processlist_summary: Number of connected, sleeping, running connections and
slow query count

TYPE

View

DESCRIPTION

processlist_summary provides a one-line summary of PROCESSLIST status. It
presents with counters listing the number of connected, running, sleeping,
long-running processes.

STRUCTURE



       mysql> DESC common_schema.processlist_summary;
       +--------------------------+---------------+------+-----+---------
       +-------+
       | Field                    | Type          | Null | Key | Default
       | Extra |
       +--------------------------+---------------+------+-----+---------
       +-------+
       | count_processes          | bigint(21)    | NO   |     | 0
       |       |
       | active_processes         | decimal(23,0) | YES  |     | NULL
       |       |
       | sleeping_processes       | decimal(23,0) | YES  |     | NULL
       |       |
       | active_queries           | decimal(23,0) | YES  |     | NULL
       |       |
       | num_queries_over_1_sec   | decimal(23,0) | NO   |     | 0
       |       |
       | num_queries_over_10_sec  | decimal(23,0) | NO   |     | 0
       |       |
       | num_queries_over_60_sec  | decimal(23,0) | NO   |     | 0
       |       |
       | average_active_time      | decimal(14,4) | NO   |     | 0.0000
       |       |
       | median_95pct_active_time | decimal(10,2) | NO   |     | 0.00
       |       |
       +--------------------------+---------------+------+-----+---------
       +-------+



SYNOPSIS

Columns of this view:

* count_processes: total number of connected processes
* active_processes: number of processes not sleeping
* sleeping_processes: number of sleeping processes
* active_queries: number of non-replication, non-sleeping processes
* num_queries_over_1_sec: non-replication queries running at 1 second or more
* num_queries_over_10_sec: non-replication queries running at 10 second or
  more
* num_queries_over_60_sec: non-replication queries running at 60 second or
  more
* average_active_time: average query execution time for non-replication, non-
  sleeping queries queries
* median_95pct_active_time: run time at 95% (95% processes run at this or
  lower time) for active processes

All of the above counters exclude the connection from which the view is being
queried.
num_queries_over_10_sec include queries counted in num_queries_over_1_sec.
num_queries_over_60_sec include queries counted in num_queries_over_10_sec and
num_queries_over_1_sec.

EXAMPLES



       mysql> SELECT * FROM common_schema.processlist_summary where
       average_active_time > 0\\G
       *************************** 1. row ***************************
                count_processes: 123
               active_processes: 68
             sleeping_processes: 55
                 active_queries: 66
         num_queries_over_1_sec: 34
        num_queries_over_10_sec: 0
        num_queries_over_60_sec: 0
            average_active_time: 1.3939
       median_95pct_active_time: 4.00



ENVIRONMENT

MySQL 5.1 or newer.

SEE ALSO

processlist_per_userhost, processlist_repl, processlist_states,
processlist_top

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('processlist_top','
NAME

processlist_top: Listing of active processes sorted by current query runtime,
desc (longest first)

TYPE

View

DESCRIPTION

processlist_top displays only active processes (those not in Sleep mode, hence
actually performing some query); it lists longest running queries first.
When looking at running processes, we are many times interested in those
queries making trouble. We may look at PROCESSLIST when server seems to react
slowly. We may be looking for queries acquiring locks, blocking other queries,
or for extremely long queries which are wasting system resources. A good
heuristic would be to look for queries running the longest.
However, PROCESSLIST also lists down many other connections, including those
sleeping for long time. processlist_top provides with the short story: only
active, and longest first. This is similar to query listing as implemented in
mytop or innotop.
processlist_top does not list its own process (the process invoking the SELECT
on processlist_top)

STRUCTURE



       mysql> DESC common_schema.processlist_top;
       +---------------------+---------------+------+-----+---------+----
       ---+
       | Field               | Type          | Null | Key | Default |
       Extra |
       +---------------------+---------------+------+-----+---------+----
       ---+
       | ID                  | bigint(4)     | NO   |     | 0       |
       |
       | USER                | varchar(16)   | NO   |     |         |
       |
       | HOST                | varchar(64)   | NO   |     |         |
       |
       | DB                  | varchar(64)   | YES  |     | NULL    |
       |
       | COMMAND             | varchar(16)   | NO   |     |         |
       |
       | TIME                | int(7)        | NO   |     | 0       |
       |
       | STATE               | varchar(64)   | YES  |     | NULL    |
       |
       | INFO                | longtext      | YES  |     | NULL    |
       |
       | sql_kill_query      | varbinary(31) | NO   |     |         |
       |
       | sql_kill_connection | varbinary(25) | NO   |     |         |
       |
       +---------------------+---------------+------+-----+---------+----
       ---+



SYNOPSIS

Structure of this view is based to that of INFORMATION_SCHEMA.PROCESSLIST
table
Additional columns are:

* sql_kill_query: a KILL QUERY statement for current thread.
  Use with eval() to apply statement.
* sql_kill_connection: a KILL statement for current thread.
  Use with eval() to apply statement.

On Percona Server, this additional info is included:

* TIME_MS: execution time in milliseconds


EXAMPLES

Show all active processes:


       mysql> SELECT * FROM common_schema.processlist_top;
       +----------+-------------+--------------+-----------+-------------
       +---------+-------------------------------------------------------
       -----------+------------------------------------------------------
       -----------------------------------------------------------------
       +------------+---------------------+---------------------+
       | ID       | USER        | HOST         | DB        | COMMAND
       | TIME    | STATE
       | INFO
       | TIME_MS    | sql_kill_query      | sql_kill_connection |
       +----------+-------------+--------------+-----------+-------------
       +---------+-------------------------------------------------------
       -----------+------------------------------------------------------
       -----------------------------------------------------------------
       +------------+---------------------+---------------------+
       |  3598334 | system user |              | NULL      | Connect
       | 4281883 | Waiting for master to send event
       | NULL
       | 4281883102 | KILL QUERY 3598334  | KILL 3598334        |
       |  3598469 | replica     | sql01:51157  | NULL      | Binlog Dump
       | 4281878 | Has sent all binlog to slave; waiting for binlog to be
       updated   | NULL
       | 4281877707 | KILL QUERY 3598469  | KILL 3598469        |
       | 31066726 | replica     | sql02:48924  | NULL      | Binlog Dump
       | 1041758 | Has sent all binlog to slave; waiting for binlog to be
       updated   | NULL
       | 1041758134 | KILL QUERY 31066726 | KILL 31066726       |
       |  3598335 | system user |              | NULL      | Connect
       |  195747 | Has read all relay log; waiting for the slave I/
       O thread to upda | NULL
       |          0 | KILL QUERY 3598335  | KILL 3598335        |
       | 39946702 | store       | app03:46795  | datastore | Query
       |       0 | Writing to net
       | SELECT * FROM store_location
       |         27 | KILL QUERY 39946702 | KILL 39946702       |
       | 39946693 | store       | app05:51090  | datastore | Query
       |       0 | Writing to net
       | SELECT store.store_id, store_location.zip_code FROM store JOIN
       store_location USING (store_id) WHERE store_class = 5  |
       54 | KILL QUERY 39946693 | KILL 39946693       |
       | 39946692 | store       | sql01:47849  | datastore | Query
       |       0 | Writing to net
       | SELECT store.store_id, store_location.zip_code FROM store JOIN
       store_location USING (store_id) WHERE store_class = 34 |
       350 | KILL QUERY 39946692 | KILL 39946692       |
       +----------+-------------+--------------+-----------+-------------
       +---------+-------------------------------------------------------
       -----------+------------------------------------------------------
       -----------------------------------------------------------------
       +------------+---------------------+---------------------+


In the above example the last three processes seem to be running for 0
seconds. However, with Percona Server''s TIME_MS we see the sub-second runtime
for each process. As it turns out, these three processes are not strictly
order from oldest to newest. This is because we order them based on TIME,
which has a 1 second resolution.

ENVIRONMENT

MySQL 5.1 or newer. Percona Server yields a different schema.

SEE ALSO

processlist_per_userhost, processlist_repl, processlist_summary

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_analysis_routines','
SYNOPSIS

Query analysis routines (BETA): routines to parse and analyze query text,
including dependency analysis.

* get_event_dependencies(): Analyze and list the dependencies of a given
  event.
* get_routine_dependencies(): Analyze and list the dependencies of a given
  routine.
* get_sql_dependencies(): Analyze and list the dependencies of a given query.
* get_view_dependencies(): Analyze and list the dependencies of a given view.


DESCRIPTION

These routines parse a given SQL query''s text and detect its internal
structure and dependencies.
These are not full blown SQL parsers. At the moment the main intent is to be
able to realize the objects on which a query depends: tables, views, routines
etc.
The queries themselves can be of various types, including:

* CREATE VIEW statements.
* CREATE FUNCTION/PROCEDURE statements, including stored routine code within.
* CREATE EVENT statements, including stored routine code within.

The idea is to be able to quickly realize a dependency graph. For example, to
realize the tables/views a view depends on.
Query analysis routines are in BETA stage.
');
		
			INSERT INTO common_schema.help_content VALUES ('query_checksum','
NAME

query_checksum(): checksum the result set of a query

TYPE

Procedure

DESCRIPTION

Given a query, this procedure produces a deterministic checksum on the query''s
result set.
The query is subject to the following limitations:

* It must be a SELECT
* It is limited to 9 columns
* Columns must be explicitly indicated; thus, the "star" form (e.g. SELECT *
  FROM ...) is not allowed
* Columns are limited to 64K characters (values are translated as text)

Otherwise the query may produce any type of columns, use expressions,
functions, etc. Resulting values may be NULL.
The routine produces a checksum that is calculated via repetitive usage of the
MD5 algorithm. While the operation is deterministic, it uses some internal
heuristics (such as converting NULLs to ''\\0'' so as to be able to process the
MD5 calculation). Knowing the internal heuristics it is possible to
intentionally produce two different results sets which lead to same resulting
checksum. The incidental appearance of such queries, though, is unlikely.
Moral is that this routine is useful in checking for data integrity in terms
of possible errors, and is not suitable as a security threat elimination.
The resulting checksum is also written to the @query_checksum_result session
variable.

SYNOPSIS



       query_checksum(in query TEXT CHARSET utf8)
         READS SQL DATA


Input:

* query: query to execute; checksum run on result set


EXAMPLES

Checksum three queries. The first two return the exact same result:


       mysql> call query_checksum(''select distinct n from (select cast(n/
       10 as unsigned) as n from numbers) s1 order by n'');
       +----------------------------------+
       | checksum                         |
       +----------------------------------+
       | 314c86787aab14525759b29f81ac9664 |
       +----------------------------------+

       mysql> call query_checksum(''select n from (select cast(n/10 as
       unsigned) as n from numbers) s1 group by n order by n'');
       +----------------------------------+
       | checksum                         |
       +----------------------------------+
       | 314c86787aab14525759b29f81ac9664 |
       +----------------------------------+

       mysql> call query_checksum(''select distinct n+1 from (select cast
       (n/10 as unsigned) as n from numbers) s1 order by n'');
       +----------------------------------+
       | checksum                         |
       +----------------------------------+
       | f4ea2e7f04d6edd28e9dd3e9419ec92c |
       +----------------------------------+

       mysql> select @query_checksum_result;
       +----------------------------------+
       | @query_checksum_result           |
       +----------------------------------+
       | f4ea2e7f04d6edd28e9dd3e9419ec92c |
       +----------------------------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

crc64(), exec(), random_hash()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_laptime','
NAME

query_laptime(): Number of seconds this query has been running for since last
invocation of this function.

TYPE

Function

DESCRIPTION

This function measures time between "laps": recurring invocations of this
function from within the same query or same routine.
On servers supporting subsecond time resolution, query_laptime() returns with
a floating point value. On servers with single second resolution this results
with a truncated integer.

SYNOPSIS



       query_laptime()
         RETURNS DOUBLE



EXAMPLES

Show query runtime and query laptime for a long running query:


       mysql> SELECT Id, Name, sleep(0.3) AS s, SYSDATE(), query_runtime
       (), query_laptime() from world.City limit 30;
       +----+-------------------+---+---------------------+--------------
       ---+-----------------+
       | Id | Name              | s | SYSDATE()           | query_runtime
       () | query_laptime() |
       +----+-------------------+---+---------------------+--------------
       ---+-----------------+
       |  1 | Kabul             | 0 | 2012-01-22 12:25:41 |
       1 |               1 |
       |  2 | Qandahar          | 0 | 2012-01-22 12:25:41 |
       1 |               0 |
       |  3 | Herat             | 0 | 2012-01-22 12:25:41 |
       1 |               0 |
       |  4 | Mazar-e-Sharif    | 0 | 2012-01-22 12:25:41 |
       1 |               0 |
       |  5 | Amsterdam         | 0 | 2012-01-22 12:25:42 |
       2 |               1 |
       |  6 | Rotterdam         | 0 | 2012-01-22 12:25:42 |
       2 |               0 |
       |  7 | Haag              | 0 | 2012-01-22 12:25:42 |
       2 |               0 |
       |  8 | Utrecht           | 0 | 2012-01-22 12:25:43 |
       3 |               1 |
       |  9 | Eindhoven         | 0 | 2012-01-22 12:25:43 |
       3 |               0 |
       | 10 | Tilburg           | 0 | 2012-01-22 12:25:43 |
       3 |               0 |
       | 11 | Groningen         | 0 | 2012-01-22 12:25:44 |
       4 |               1 |
       | 12 | Breda             | 0 | 2012-01-22 12:25:44 |
       4 |               0 |
       | 13 | Apeldoorn         | 0 | 2012-01-22 12:25:44 |
       4 |               0 |
       | 14 | Nijmegen          | 0 | 2012-01-22 12:25:44 |
       4 |               0 |
       | 15 | Enschede          | 0 | 2012-01-22 12:25:45 |
       5 |               1 |
       | 16 | Haarlem           | 0 | 2012-01-22 12:25:45 |
       5 |               0 |
       | 17 | Almere            | 0 | 2012-01-22 12:25:45 |
       5 |               0 |
       | 18 | Arnhem            | 0 | 2012-01-22 12:25:46 |
       6 |               1 |
       | 19 | Zaanstad          | 0 | 2012-01-22 12:25:46 |
       6 |               0 |
       | 20 | ´s-Hertogenbosch  | 0 | 2012-01-22 12:25:46 |
       6 |               0 |
       | 21 | Amersfoort        | 0 | 2012-01-22 12:25:47 |
       7 |               1 |
       | 22 | Maastricht        | 0 | 2012-01-22 12:25:47 |
       7 |               0 |
       | 23 | Dordrecht         | 0 | 2012-01-22 12:25:47 |
       7 |               0 |
       | 24 | Leiden            | 0 | 2012-01-22 12:25:47 |
       7 |               0 |
       | 25 | Haarlemmermeer    | 0 | 2012-01-22 12:25:48 |
       8 |               1 |
       | 26 | Zoetermeer        | 0 | 2012-01-22 12:25:48 |
       8 |               0 |
       | 27 | Emmen             | 0 | 2012-01-22 12:25:48 |
       8 |               0 |
       | 28 | Zwolle            | 0 | 2012-01-22 12:25:49 |
       9 |               1 |
       | 29 | Ede               | 0 | 2012-01-22 12:25:49 |
       9 |               0 |
       | 30 | Delft             | 0 | 2012-01-22 12:25:49 |
       9 |               0 |
       +----+-------------------+---+---------------------+--------------
       ---+-----------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

query_laptime(), throttle()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_profiling','
NAME

query_profiling: Per query profiling info, aggregated by query states

TYPE

View

DESCRIPTION

query_profiling presents with pretty profiling info for queries executed
within the session.
Based on the INFORMATION_SCHEMA.PROFILING table, this view aggregates data by
query state, and presents with more easy to comprehend details, such as the
total runtime for the various states and the time ratio per state of the total
query runtime.
Most notable, the state_duration_pct column allows one to quickly analyze the
states which consumed most of a query''s runtime.
To populate this view, one must enable profiling. This is done by:


       mysql> SET PROFILING := 1;


This code is based on queries presented on How_to_convert_MySQL’s_SHOW
PROFILES_into_a_real_profile and in the book High Performance MySQL, 3nd
Edition, By Baron Schwartz et al., published by O''REILLY

STRUCTURE



       mysql> DESC common_schema.last_query_profiling;
       +-------------------------+----------------+------+-----+---------
       +-------+
       | Field                   | Type           | Null | Key | Default
       | Extra |
       +-------------------------+----------------+------+-----+---------
       +-------+
       | QUERY_ID                | int(20)        | NO   |     | 0
       |       |
       | STATE                   | varchar(30)    | NO   |     |
       |       |
       | state_calls             | bigint(21)     | NO   |     | 0
       |       |
       | state_sum_duration      | decimal(31,6)  | YES  |     | NULL
       |       |
       | state_duration_per_call | decimal(35,10) | YES  |     | NULL
       |       |
       | state_duration_pct      | decimal(37,2)  | YES  |     | NULL
       |       |
       | state_seqs              | longblob       | YES  |     | NULL
       |       |
       +-------------------------+----------------+------+-----+---------
       +-------+



SYNOPSIS

Columns of this view:

* QUERY_ID: identifier of a query, as presented on SHOW PROFILES
* STATE: a state in query execution
* state_calls: number of calls for this state in this query
* state_sum_duration: the total time calls to this state consumed in this
  query
* state_duration_per_call: the average time calls to this state consumed in
  this query
* state_duration_pct: the percentage of time consumed by calls to this state,
  of the total time consumed by this query
* state_seqs: sequence numbers of calls to this state


EXAMPLES

Issue a couple queries, view profiling info:


       mysql> SET PROFILING := 1;

       mysql> SELECT COUNT(*) FROM sakila.nicer_but_slower_film_list INTO
       @dummy;

       mysql> SELECT COUNT(*) FROM world.City INTO @dummy;

       mysql> SELECT * FROM query_profiling;
       +----------+----------------------+-------------+-----------------
       ---+-------------------------+--------------------+------------+
       | QUERY_ID | STATE                | state_calls |
       state_sum_duration | state_duration_per_call | state_duration_pct
       | state_seqs |
       +----------+----------------------+-------------+-----------------
       ---+-------------------------+--------------------+------------+
       |        1 | checking permissions |           5 |
       0.000342 |            0.0000684000 |               0.49 |
       5,6,7,8,9  |
       |        1 | cleaning up          |           1 |
       0.000008 |            0.0000080000 |               0.01 | 31
       |
       |        1 | closing tables       |           1 |
       0.000018 |            0.0000180000 |               0.03 | 29
       |
       |        1 | Copying to tmp table |           1 |
       0.044438 |            0.0444380000 |              63.34 | 15
       |
       |        1 | Creating tmp table   |           1 |
       0.000202 |            0.0002020000 |               0.29 | 13
       |
       |        1 | end                  |           1 |
       0.000005 |            0.0000050000 |               0.01 | 23
       |
       |        1 | executing            |           2 |
       0.000018 |            0.0000090000 |               0.03 | 14,22
       |
       |        1 | freeing items        |           2 |
       0.000227 |            0.0001135000 |               0.32 | 25,27
       |
       |        1 | init                 |           1 |
       0.000012 |            0.0000120000 |               0.02 | 20
       |
       |        1 | logging slow query   |           1 |
       0.000004 |            0.0000040000 |               0.01 | 30
       |
       |        1 | Opening tables       |           1 |
       0.000284 |            0.0002840000 |               0.40 | 2
       |
       |        1 | optimizing           |           2 |
       0.000033 |            0.0000165000 |               0.05 | 10,21
       |
       |        1 | preparing            |           1 |
       0.000025 |            0.0000250000 |               0.04 | 12
       |
       |        1 | query end            |           1 |
       0.000005 |            0.0000050000 |               0.01 | 24
       |
       |        1 | removing tmp table   |           3 |
       0.000149 |            0.0000496667 |               0.21 | 18,26,28
       |
       |        1 | Sending data         |           2 |
       0.017748 |            0.0088740000 |              25.30 | 17,19
       |
       |        1 | Sorting result       |           1 |
       0.006466 |            0.0064660000 |               9.22 | 16
       |
       |        1 | starting             |           1 |
       0.000076 |            0.0000760000 |               0.11 | 1
       |
       |        1 | statistics           |           1 |
       0.000075 |            0.0000750000 |               0.11 | 11
       |
       |        1 | System lock          |           1 |
       0.000010 |            0.0000100000 |               0.01 | 3
       |
       |        1 | Table lock           |           1 |
       0.000017 |            0.0000170000 |               0.02 | 4
       |
       |        2 | cleaning up          |           1 |
       0.000010 |            0.0000100000 |               2.90 | 12
       |
       |        2 | end                  |           1 |
       0.000012 |            0.0000120000 |               3.48 | 8
       |
       |        2 | executing            |           1 |
       0.000019 |            0.0000190000 |               5.51 | 7
       |
       |        2 | freeing items        |           1 |
       0.000038 |            0.0000380000 |              11.01 | 10
       |
       |        2 | init                 |           1 |
       0.000025 |            0.0000250000 |               7.25 | 5
       |
       |        2 | logging slow query   |           1 |
       0.000010 |            0.0000100000 |               2.90 | 11
       |
       |        2 | Opening tables       |           1 |
       0.000031 |            0.0000310000 |               8.99 | 2
       |
       |        2 | optimizing           |           1 |
       0.000016 |            0.0000160000 |               4.64 | 6
       |
       |        2 | query end            |           1 |
       0.000015 |            0.0000150000 |               4.35 | 9
       |
       |        2 | starting             |           1 |
       0.000135 |            0.0001350000 |              39.13 | 1
       |
       |        2 | System lock          |           1 |
       0.000014 |            0.0000140000 |               4.06 | 3
       |
       |        2 | Table lock           |           1 |
       0.000020 |            0.0000200000 |               5.80 | 4
       |
       +----------+----------------------+-------------+-----------------
       ---+-------------------------+--------------------+------------+


Similar to the above, simplify results:


       mysql> SET PROFILING := 1;

       mysql> SELECT COUNT(*) FROM sakila.nicer_but_slower_film_list INTO
       @dummy;

       mysql> SELECT query_id, state, state_duration_pct, state_calls
                 FROM query_profiling
                 ORDER BY query_id ASC, state_duration_pct DESC;
       +----------+----------------------+--------------------+----------
       ---+
       | query_id | state                | state_duration_pct |
       state_calls |
       +----------+----------------------+--------------------+----------
       ---+
       |        1 | Copying to tmp table |              69.63 |
       1 |
       |        1 | Sending data         |              20.00 |
       2 |
       |        1 | Sorting result       |               8.92 |
       1 |
       |        1 | freeing items        |               0.37 |
       2 |
       |        1 | checking permissions |               0.28 |
       5 |
       |        1 | Opening tables       |               0.22 |
       1 |
       |        1 | Creating tmp table   |               0.15 |
       1 |
       |        1 | removing tmp table   |               0.15 |
       3 |
       |        1 | starting             |               0.07 |
       1 |
       |        1 | statistics           |               0.05 |
       1 |
       |        1 | optimizing           |               0.03 |
       2 |
       |        1 | closing tables       |               0.02 |
       1 |
       |        1 | executing            |               0.02 |
       2 |
       |        1 | preparing            |               0.02 |
       1 |
       |        1 | cleaning up          |               0.01 |
       1 |
       |        1 | init                 |               0.01 |
       1 |
       |        1 | System lock          |               0.01 |
       1 |
       |        1 | Table lock           |               0.01 |
       1 |
       |        1 | end                  |               0.00 |
       1 |
       |        1 | logging slow query   |               0.00 |
       1 |
       |        1 | query end            |               0.00 |
       1 |
       |        2 | starting             |              37.39 |
       1 |
       |        2 | freeing items        |              12.16 |
       1 |
       |        2 | Opening tables       |               8.81 |
       1 |
       |        2 | init                 |               7.29 |
       1 |
       |        2 | executing            |               5.78 |
       1 |
       |        2 | Table lock           |               5.78 |
       1 |
       |        2 | optimizing           |               4.86 |
       1 |
       |        2 | System lock          |               4.26 |
       1 |
       |        2 | logging slow query   |               3.65 |
       1 |
       |        2 | cleaning up          |               3.34 |
       1 |
       |        2 | end                  |               3.34 |
       1 |
       |        2 | query end            |               3.34 |
       1 |
       +----------+----------------------+--------------------+----------
       ---+


As a point of interest, we can see that "Opening tables" is no longer a major
impacting state.

ENVIRONMENT

MySQL 5.1 or newer.

SEE ALSO

last_query_profiling

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_runtime','
NAME

query_runtime(): Number of seconds this query has been running for so far.

TYPE

Function

DESCRIPTION

This function returns the number of seconds elapsed since this query''s
execution begun. If query is executing from within a stored routine, the
function returns the number of seconds elapsed since routine began executing.
The function relies on the the behavior of NOW().
On servers supporting subsecond time resolution, query_runtime() returns with
a floating point value. On servers with single second resolution this results
with a truncated integer.

SYNOPSIS



       query_runtime()
         RETURNS DOUBLE



EXAMPLES

Show query runtime and query laptime for a long running query:


       mysql> SELECT Id, Name, sleep(0.3) AS s, SYSDATE(), query_runtime
       (), query_laptime() from world.City limit 30;
       +----+-------------------+---+---------------------+--------------
       ---+-----------------+
       | Id | Name              | s | SYSDATE()           | query_runtime
       () | query_laptime() |
       +----+-------------------+---+---------------------+--------------
       ---+-----------------+
       |  1 | Kabul             | 0 | 2012-01-22 12:25:41 |
       1 |               1 |
       |  2 | Qandahar          | 0 | 2012-01-22 12:25:41 |
       1 |               0 |
       |  3 | Herat             | 0 | 2012-01-22 12:25:41 |
       1 |               0 |
       |  4 | Mazar-e-Sharif    | 0 | 2012-01-22 12:25:41 |
       1 |               0 |
       |  5 | Amsterdam         | 0 | 2012-01-22 12:25:42 |
       2 |               1 |
       |  6 | Rotterdam         | 0 | 2012-01-22 12:25:42 |
       2 |               0 |
       |  7 | Haag              | 0 | 2012-01-22 12:25:42 |
       2 |               0 |
       |  8 | Utrecht           | 0 | 2012-01-22 12:25:43 |
       3 |               1 |
       |  9 | Eindhoven         | 0 | 2012-01-22 12:25:43 |
       3 |               0 |
       | 10 | Tilburg           | 0 | 2012-01-22 12:25:43 |
       3 |               0 |
       | 11 | Groningen         | 0 | 2012-01-22 12:25:44 |
       4 |               1 |
       | 12 | Breda             | 0 | 2012-01-22 12:25:44 |
       4 |               0 |
       | 13 | Apeldoorn         | 0 | 2012-01-22 12:25:44 |
       4 |               0 |
       | 14 | Nijmegen          | 0 | 2012-01-22 12:25:44 |
       4 |               0 |
       | 15 | Enschede          | 0 | 2012-01-22 12:25:45 |
       5 |               1 |
       | 16 | Haarlem           | 0 | 2012-01-22 12:25:45 |
       5 |               0 |
       | 17 | Almere            | 0 | 2012-01-22 12:25:45 |
       5 |               0 |
       | 18 | Arnhem            | 0 | 2012-01-22 12:25:46 |
       6 |               1 |
       | 19 | Zaanstad          | 0 | 2012-01-22 12:25:46 |
       6 |               0 |
       | 20 | ´s-Hertogenbosch  | 0 | 2012-01-22 12:25:46 |
       6 |               0 |
       | 21 | Amersfoort        | 0 | 2012-01-22 12:25:47 |
       7 |               1 |
       | 22 | Maastricht        | 0 | 2012-01-22 12:25:47 |
       7 |               0 |
       | 23 | Dordrecht         | 0 | 2012-01-22 12:25:47 |
       7 |               0 |
       | 24 | Leiden            | 0 | 2012-01-22 12:25:47 |
       7 |               0 |
       | 25 | Haarlemmermeer    | 0 | 2012-01-22 12:25:48 |
       8 |               1 |
       | 26 | Zoetermeer        | 0 | 2012-01-22 12:25:48 |
       8 |               0 |
       | 27 | Emmen             | 0 | 2012-01-22 12:25:48 |
       8 |               0 |
       | 28 | Zwolle            | 0 | 2012-01-22 12:25:49 |
       9 |               1 |
       | 29 | Ede               | 0 | 2012-01-22 12:25:49 |
       9 |               0 |
       | 30 | Delft             | 0 | 2012-01-22 12:25:49 |
       9 |               0 |
       +----+-------------------+---+---------------------+--------------
       ---+-----------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

query_laptime(), throttle()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script','
QueryScript is a scripting language for SQL

QueryScript is a programming language aimed for SQL scripting, seamlessly
combining scripting power such as flow control & variables with standard SQL
statements or RDBMS-specific commands.
common_schema implements QueryScript for MySQL: it provides the execution
mechanism for QueryScript code (see Execution).
What does QueryScript look like? Here are a couple examples:


       while (DELETE FROM world.Country WHERE Continent = ''Asia'' LIMIT
       10)
       {
         throttle 2;
       }




       foreach($table, $schema, $engine: table in sakila)
       {
         if ($engine = ''InnoDB'')
           ALTER TABLE :$schema.:$table ENGINE=InnoDB ROW_FORMAT=Compact;
       }


With QueryScript one can:

* Use familiar syntax to solve common DBA maintenance problems
* Loop through number sequences, constants, tables, schemata
* Easily iterate query results, providing cursor-like functionality with clean
  syntax
* Use conditional statements and statement blocks
* Create and use variables
* Expand variables in-place, turning them to constants in queries where
  variables are not allowed

QueryScript programs execute from within the server. As opposed to scripts
written with Perl, Python or PHP, QueryScript code does not need to specify
connections, logins nor passwords. There is no connector to install and use,
there is no driver setup. There are no plugins.

SEE ALSO

run(), Execution, Statements

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_break','break: quit loop execution

SYNOPSIS



       while (expression)
       {
         if (expression)
           break;
       }



DESCRIPTION

break is a QueryScript statement which, when invoked, aborts execution of
current loop.
break is typically used in an if-else statement, but does not necessarily has
to.
The break statements quits iteration of the closest wrapping loop, but not any
above it.
The following loops are all affected by break: while, loop-while, foreach.

EXAMPLES

Break on condition:


       set @x := 7;
       while (@x > 0)
       {
         set @x := @x - 1;
         if (@x = 3)
           break;
       }
       select @x;

       +------+
       | @x   |
       +------+
       |    3 |
       +------+


An immediate break:


       set @x := 7;
       while (true)
       {
         set @x := @x - 1;
         break;
       }
       select @x;

       +------+
       | @x   |
       +------+
       |    6 |
       +------+


Break from inner loop; outer loop unaffected


       set @x := 3;
       while (@x > 0)
       {
         set @x := @x - 1;
         set @y := 3;
         while (@y > 0)
         {
           set @y := @y -1;
           if (@y < @x)
             break;
           select @x, @y;
         }
       }

       +------+------+
       | @x   | @y   |
       +------+------+
       |    2 |    2 |
       +------+------+

       +------+------+
       | @x   | @y   |
       +------+------+
       |    1 |    2 |
       +------+------+

       +------+------+
       | @x   | @y   |
       +------+------+
       |    1 |    1 |
       +------+------+

       +------+------+
       | @x   | @y   |
       +------+------+
       |    0 |    2 |
       +------+------+

       +------+------+
       | @x   | @y   |
       +------+------+
       |    0 |    1 |
       +------+------+

       +------+------+
       | @x   | @y   |
       +------+------+
       |    0 |    0 |
       +------+------+



SEE ALSO

Flow_control

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_echo','echo: display a line of text as result set.

SYNOPSIS



       echo ''Starting'';
       echo Will now drop all tables called %name%;
       foreach ($table, $schema: table like %name%)
         echo DROP TABLE :${schema}.:${table};



DESCRIPTION

echo is a QueryScript statement which writes (echoes) back its argument text
as a message.
echo takes any number and type of arguments and treats them all as a string.
Expanded variables are evaluated (thus, the output replaces them with
contained values). Local variables (unexpanded) or user defined variables are
untouched.
echo is useful in showing progress messages, as well as testing dangerous
operations beforehand (echoing the dangerous statement, to be reviewed by a
human, before actually executing it).

EXAMPLES

Static text:


       echo ''Starting'';

       +------------+
       | echo       |
       +------------+
       | ''Starting'' |
       +------------+


Static text, no need to quote:


       echo Will now drop all tables called %name%;

       +----------------------------------------+
       | echo                                   |
       +----------------------------------------+
       | Will now drop all tables called %name% |
       +----------------------------------------+


Dynamic text, via expanded variables. Test DROP TABLE iteration before
actually invoking it.


       foreach ($table, $schema: table like %name%)
         echo DROP TABLE :${schema}.:${table};

       +-----------------------------------------+
       | echo                                    |
       +-----------------------------------------+
       | DROP TABLE common_schema._named_scripts |
       +-----------------------------------------+

       +---------------------------------+
       | echo                            |
       +---------------------------------+
       | DROP TABLE mysql.time_zone_name |
       +---------------------------------+



SEE ALSO

report, Statements

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_eval','eval: evaluate statement by dynamically invoking result set test.

SYNOPSIS



       eval select text_col ...;



DESCRIPTION

eval is a META statement, which executes a given statement, gets its text
output - assumed to be SQL, and invokes this resulting SQL.
That is, eval is given a statement as argument. eval expects a SELECT
statement which produces a single text column, and the text in that columns is
expected to be valid SQL statements.
The eval statement invokes the eval() routine, and therefore produces the same
result/output.
Many views in common_schema produce SQL statements as columns. Consider
processlist_grantees, redundant_keys, sql_alter_table, sql_foreign_keys,
sql_grants and more. It is possible, then, to eval directly on columns of
these views:


       eval SELECT sql_revoke FROM sql_grants WHERE user=''gromit'';


common_schema also offers programmatic alternatives to eval. For example,
instead of evaluating queries on INFORMATION_SCHEMA.TABLES, one can use the
foreach statement.

EXAMPLES

Drop foreign keys from the sakila database:


       eval SELECT drop_statement FROM sql_foreign_keys WHERE
       TABLE_SCHEMA=''sakila'';


KILL long running queries which were invoked by ''normal'' users:


       eval SELECT sql_kill_query FROM processlist_grantees WHERE COMMAND
       != ''Sleep'' AND TIME > 20 AND is_super = 0 AND is_repl = 0;



SEE ALSO

eval(), foreach, killall()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_execution','QueryScript Execution: script invocation

SYNOPSIS



       call run(''...script...'');



DESCRIPTION

A script is a text, interpreted by common_schema''s implementation of
QueryScript.
Being a text, the code of a script can be provided by a user defined variable,
a table column, a file, a function -- any construct which can produce a
string.
common_schema provides the following routines to execute a script:

* run(): run a script provided as text, or possibly run script from file
* run_file(): run a script from file.

And the following script managing routines:

* script_runtime(): number of seconds elapsed since since execution began.

Script execution is done in two steps:

  1. Dry run: the script is parsed and verified to be in good structure (so
     called compilation)
  2. Wet run: the script is executed

This means if you have a script error, no code is executed. Script is in good
shape, or nothing actually happens. The dry run phase checks for structure
problems (e.g. unmatched parenthesis, empty expression in if-else statement,
missing semicolon, unexpected tokens in var statement, etc.).
The script does not check the structure of your queries. This is left up for
MySQL to parse and validate. So, a "SELECT GROUP WHERE FROM x LIMIT HAVING;"
statement is just fine as far as QueryScript is concerned.

NOTES


Limitations

QueryScript statements are:

* Interpreted by a stored routine
* Executed via dynamic SQL

The two pose several limitations on the type of code which can be used from
within a script. A few limitations follow:

* One must adhere to the limitations of dynamic_SQL. Specifically, it is not
  allowed to issue the PREPARE statement from within QueryScript.
* One must adhere to limitations of stored routines. For example, it is
  impossible to disable sql_log_bin or change the statement_format from within
  a stored routine (the latter limitation as of MySQL 5.5).
* QueryScript itself cannot be issued from within QueryScript. Specifically,
  you may not call run() or run_file() from within a script. The results are
  unexpected. You must not call code which calls these routines, such as the
  foreach() routine (as opposed to the perfectly valid foreach statement).


Performance

Current implementation of QueryScript utilizes stored routines. That is, a
stored routine (e.g. run()) executes the script. To affirm the immediate
conclusion, scripts are being interpreted by common_schema. Moreover, since
current implementation of stored routines within MySQL is itself by way of
interpretation, it follows that a QueryScript code is interpreted by an
interpreted code. Stored routines alone are known to be slow in execution in
MySQL.
The above indicates that QueryScript should not be used for you OLTP
operations. Not for the standard SELECT/INSERT/DELETE/UPDATE issued by the
developer. However, QueryScript well fits the occasional maintenance work of
the DBA/developer.
Generally speaking, large operations can benefit from using QueryScript: the
overhead of interpreted code is usually neglectable in comparison with
operations on large amounts of data. Moreover, QueryScript adds notions such
as throttling to ease out on such large operations. General maintenance
operations (creation, alteration or destruction of tables, users, processes,
etc.) are also good candidates.

EXAMPLES

Create and run a script on the fly:


       mysql> call run("
         while (DELETE FROM world.Country WHERE Continent = ''Asia'' LIMIT
       10)
         {
           do sleep(1);
         }
       ");


The above assumes no ANSI_QUOTES in sql_mode.
Store a script in session variable:


       mysql> SET @script := ''foreach($t: table in world) {alter table
       world.:$t engine=InnoDB}'';
       mysql> call run(@script);


Run script from /tmp/sample.qs text file:


       bash$ cat /tmp/sample.qs
       create table test.many_numbers (n bigint unsigned auto_increment
       primary key);
       insert into test.many_numbers values(NULL);

       foreach($i: 1:10)
         insert into test.many_numbers select NULL from
       test.many_numbers;




       mysql> call run_file(''/tmp/sample.qs'');

       mysql> SELECT COUNT(*) FROM test.many_numbers;
       +----------+
       | COUNT(*) |
       +----------+
       |     1024 |
       +----------+


run() can also load scripts from file, if given input appears to indicate a
file name:


       mysql> call run(''/tmp/sample.qs'');

       mysql> SELECT COUNT(*) FROM test.many_numbers;
       +----------+
       | COUNT(*) |
       +----------+
       |     1024 |
       +----------+



SEE ALSO

run(), Flow_control, Statements

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_expressions','QueryScript Expressions: conditional truth values

SYNOPSIS



       while(expression)
       {
         if (expression)
           statement;
       }



DESCRIPTION

Expressions are truth valued clauses. QueryScript accepts any valid SQL
expression, and adds additional particular cases.
Expressions are used by flow control structures: if-else, while, loop-while.

Standard SQL expressions

Any expression on which SELECT expression IS TRUE can be used as a QueryScript
expression. The following are examples of valid expressions:

* TRUE
* NULL
* 0
* 4 < 5
* @x < 5
* (@x = 5) OR (COALESCE(@y, @z) BETWEEN 10 AND 20)
* @n IN (SELECT name FROM world.City)
* SELECT COUNT(*) > 100 FROM world.Country WHERE Continent=''Africa''


QueryScript valid expressions

In addition to any standard SQL expression, QueryScript also acknowledges the
following statements as valid expressions:

* INSERT [IGNORE]
* INSERT .. ON DUPLICATE KEY UPDATE
* UPDATE [IGNORE]
* DELETE [IGNORE]
* REPLACE

An expression in the above form is considered to hold a TRUE value, when the
number of rows affected by the DML query is non-zero. In particular, the value
of ROW_COUNT() is examined.
For example, consider the following:


       mysql> DELETE FROM world.Country WHERE Continent=''flatlandia''
       Query OK, 0 rows affected (0.00 sec)


The above query does not actually delete any row; hence its truth value is
FALSE.
Notes:

* A standard INSERT makes no sense to use, since it will either succeed
  (resolving to TRUE) or completely fail, aborting the evaluation. It only
  makes sense to use INSERT IGNORE or INSERT .. ON DUPLICATE KEY UPDATE.
* REPLACE always succeeds, and so will always resolve to TRUE. It is included
  for completeness.


EXAMPLES

DELETE statement as expression; delete all ''Asia'' records in small chunks:


       while (DELETE FROM world.Country WHERE Continent = ''Asia'' LIMIT
       10)
       {
         do sleep(1);
       }


SELECT and INSERT statements as expressions:


       if (SELECT COUNT(*) > 0 FROM world.Country WHERE Continent =
       ''Atlantis'')
       {
         INSERT INTO weird_logs VALUES (''Have found countries in
       Atlantis'');
         if (DELETE FROM world.Country WHERE Continent = ''Atlantis'')
           INSERT INTO weird_logs VALUES (''And now they''''re gone'');
       }


Simple arithmetic expression: generate Fibonacci sequence:


       var $n1, $n2, $n3, $seq;
       set $n1 := 1, $n2 := 0, $n3 := NULL;
       set $seq := '''';

       loop
       {
         set $n3 := $n1 + $n2;
         set $n1 := $n2;
         set $n2 := $n3;
         set $seq := CONCAT($seq, $n3, '', '');
       }
       while ($n3 < 100);

       SELECT $seq AS fibonacci_numbers;

       +---------------------------------------------+
       | fibonacci_numbers                           |
       +---------------------------------------------+
       | 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144,  |
       +---------------------------------------------+



SEE ALSO

if-else, while, loop-while

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_flow_control','
SYNOPSIS

QueryScript Flow Control: conditional execution via looping & branching.
QueryScript supports the following flow control structures:

* if-else: conditional branching
* foreach: iterating collections
* while: looping
* loop-while: looping
* split: splitting long operations into smaller tasks
* try-catch: error handling

And the following flow control statements :

* break: leave executing loop
* return: quit script execution


DESCRIPTION

The flow control structures are similar in nature to those of other common
programming language. Flow control works by evaluation an expression. The
truth value of the expression determines whether code will branch, loop,
break, etc.

EXAMPLES

Rebuild partitions for all NDB tables:


       foreach($table, $schema, $engine: table like ''%'')
         if ($engine = ''ndbcluster'')
           ALTER ONLINE TABLE :$schema.:$table REORGANIZE PARTITION;


Throttle deletion of rows:


       while (DELETE FROM world.Country WHERE Continent = ''Asia'' LIMIT
       10)
       {
         -- We remove 10 rows at a time, and throttle by waiting in
       between
         -- deletions twice the amount of time executed on deletion.
         throttle 2;
       }


Create or upgrade a table


       try
       {
         -- Try and create table:
         CREATE TABLE test.article (
           article_id int unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
           title varchar(128) CHARSET utf8,
           content text CHARSET utf8
         );
       }
       catch
       {
         -- Apparently table already exists. Upgrade it:
         ALTER TABLE test.article
           MODIFY COLUMN content text CHARSET utf8;
       }


');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_foreach','QueryScript Flow Control: foreach statement

SYNOPSIS



       foreach ($var1 [, $var2...] : collection)
       {
         statement;
         statement, typically using $var1 [, $var2...];
       }
       [otherwise
         statement;]



DESCRIPTION

foreach is a flow control looping structure. It iterates collections of
various types, assigns iterated values onto variables, and executes statements
per iteration.
foreach iterates all elements in given collection, and executes a statement
(or block of statements) per element. foreach terminates when all elements
have been processed. The break and return statements also break iteration
execution.
As opposed to the foreach() routine, foreach loops can be nested within other
flow control structures, such as if-else, while, loop-while and foreach itself
(see examples below). read more about the difference between the foreach
control flow and the foreach() routine following.
The otherwise clause is optional. It will execute once should no iteration
take place. That is, if at least one collection element exists, otherwise is
skipped.

Variables

The foreach construct is also a variable declaration point. Variables are
created and are assigned to, per loop iteration. As with the var statement, at
least one variable is expected on foreach clause.
Any variables declared in the foreach clause are assigned with values as per
iteration element. There are various types of collections, as described
following. These can vary from SELECT statements to number ranges. Elements
within collections can be single-valued or multi-valued. To illustrate,
consider these examples:


       foreach($counter: 1:1024)
       {
         -- Collection is of numbers-range type. It is single valued.
         -- Do something with $counter
       }


In the above example, a single variable, named $counter is declared. It is
assigned with the integer values 1, 2, 3, ..., 1024, one value per iteration.


       foreach($name, $pop: SELECT Name, Population FROM world.Country)
       {
         -- Collection is of query type. It may hold up to 9 values
       (generated by 9 first columns).
         -- Do something with $name and $pop.
       }


In this example, the SELECT query returns 2 columns: Name and Population,
which we assign onto the variables $name and $pop, respectively. This happens
per row in query''s result set.
At least one variable must be declared. However, it is OK to list less than
the amount of variables available from the collection. Hence, the following is
valid:


       foreach($name: SELECT Name, Population FROM world.Country)
       {
         -- Do something with $name. We never bother to actually read the
       Population value.
       }


Variable expansion is of importance, as it allows using variable names in
place of constants which are otherwise non-dynamic, such as schema or table
names. Read more on Variables before checking up on the examples.

Collection variables

Collections (described following) may themselves use local variables, as well
as expanded variables.

Collections

foreach accepts several types of collections. They are automatically
recognized by their pattern. The following collections are recognized (also
see EXAMPLES section below):

* A SELECT query: any SELECT statement makes for a collection, which is the
  result set of the query.
  Each row in the result set is an element.
  The query must specify result columns. That is, a SELECT * query is not
  valid.
  Otherwise any SELECT query is valid, with any result set. However, only
  first 9 columns in the result set can be assigned to variables. Variables
  are matched to columns by order of definition.
  Column values are treated as text, even though they may originally be of
  other types.
* Numbers range: a range of integers, both inclusive, e.g. ''1970:2038''.
  Negative values are allowed. The first (left) value should be smaller or
  equal to the second (right) value, or else no iteration is performed.
  One variable is assigned with value on this collection.
* Two dimensional numbers range: a double range of integers, e.g. ''-10:
  10,1970:2038''.
  Each one of the ranges answers to the same rules as for a single range.
  There will be m * n iterations on ranges of size m and n. For example, in
  the sample range above there will be 11 * 69 iterations (or elements).
  Two variables are assigned with values on this collection.
  This type of collection is maintained in compatibility with the foreach()
  routine. Script-wise, though, it is perfectly possible to nest two foreach
  number-ranges loops.
* A constants set: a predefined set of constant values, e.g. ''{red, green,
  blue}''.
  Constants are separated by either spaces or commas (or both).
  Constants can be quoted so as to allow spaces or commas within constant
  value. Quotes themselves are discarded.
  Empty constants are discarded.
  One variable is assigned with value on this collection.
* ''schema'': this is the collection of available schemata (e.g. as with SHOW
  DATABASES).
  One variable is assigned with value on this collection. This value is the
  name of the schema.
* ''schema like expr'': databases whose names match the given LIKE expression.
  One variable is assigned with value on this collection. This value is the
  name of the schema.
* ''schema ~ ''regexp'''': databases whose names match the given regular
  expression.
  One variable is assigned with value on this collection. This value is the
  name of the schema.
* ''table in schema_names'': collection of all tables in given schema. Only
  tables are included: views are not listed.
  This syntax is INFORMATION_SCHEMA friendly, in that it only scans and opens
  .frm files for given schema.
  An element of this collection has 4 values, which can be mapped up to 4
  variables:

    1. Table name
    2. Schema name
    3. Storage engine name
    4. Table''s create options

* ''table like expr'': all tables whose names match the given LIKE expression.
  These can be tables from different databases/schemata.
  This syntax is INFORMATION_SCHEMA friendly, in that it only scans and opens
  .frm files for a single schema at a time. This reduces locks and table cache
  entries, while potentially taking longer to complete.
  An element of this collection has 4 values, which can be mapped up to 4
  variables:

    1. Table name
    2. Schema name
    3. Storage engine name
    4. Table''s create options

* ''table ~ ''regexp'''': all tables whose names match the given regular
  expression. These can be tables from different databases/schemata.
  This syntax is INFORMATION_SCHEMA friendly, in that it only scans and opens
  .frm files for a single schema at a time. This reduces locks and table cache
  entries, while potentially taking longer to complete.
  An element of this collection has 4 values, which can be mapped up to 4
  variables:

    1. Table name
    2. Schema name
    3. Storage engine name
    4. Table''s create options


Any other type of input raises an error.
Following is a brief sample of valid foreach expressions:

Collection type               Example of valid input
SELECT query                  $id, $n: SELECT id, name FROM
                              INFORMATION_SCHEMA.PROCESSLIST WHERE time > 20
Numbers range                 $year: 1970:2038
Two dimensional numbers range $hr, $minute: 0:23,0:59
Constants set                 $country: {USA, "GREAT BRITAIN", FRA, IT, JP}
''schema''                      $schema_name: schema
''schema like expr''            $customer_schema_name: schema like customer_%
''schema ~ ''regexp''''           $customer_schema_name: schema ~ ''^customer_[0-
                              9]+$''
''table in schema_name''        $table_name, $schema_name, $engine,
                              $create_options: table in sakila
''table like expr''             $table_name, $schema_name, $engine: table like
                              wp_%
''table ~ ''regexp''''            $table_name, $schema_name: table ~ ''^state_[A-Z]
                              {2}$''


EXAMPLES


* SELECT query
  Kill queries for user ''analytics''.


         foreach($id: SELECT id FROM INFORMATION_SCHEMA.PROCESSLIST WHERE
         user = ''analytics'')
           KILL QUERY :$id;


  (But see also killall())
  Select multiple columns; execute multiple queries based on those columns:


         foreach($code, $name: SELECT Code, Name FROM world.Country WHERE
         Continent=''Europe'')
         {
           DELETE FROM world.CountryLanguage WHERE CountryCode = $code;
           DELETE FROM world.City WHERE CountryCode = $code;
           DELETE FROM world.Country WHERE Code = $code;
           INSERT INTO test.logs (msg) VALUES (CONCAT(''deleted country:
         name='', $name));
         }


* Numbers range:
  Delete records from July-August for years 2001 - 2009:


         foreach($year: 2001:2009)
           DELETE FROM sakila.rental WHERE rental_date >= CONCAT($year,
         ''-07-01'') AND rental_date < CONCAT($year, ''-09-01'');


  Generate tables:


         foreach($i: 1:8)
           CREATE TABLE test.t_:${i} (id INT);
         		
         SHOW TABLES FROM test;
         +----------------+
         | Tables_in_test |
         +----------------+
         | t_1            |
         | t_2            |
         | t_3            |
         | t_4            |
         | t_5            |
         | t_6            |
         | t_7            |
         | t_8            |
         +----------------+ 		


* Constants set:
  Generate databases:


         foreach($shard: {US, GB, Japan, FRA})
           CREATE DATABASE dbshard_:${shard};

         show databases LIKE ''dbshard_%'';
         +----------------------+
         | Database (dbshard_%) |
         +----------------------+
         | dbshard_FRA          |
         | dbshard_GB           |
         | dbshard_Japan        |
         | dbshard_US           |
         +----------------------+


* ''schema'':
  List full tables on all schemata:


         foreach($scm: schema)
           SHOW FULL TABLES FROM :$scm;
         +---------------------------------------+-------------+
         | Tables_in_information_schema          | Table_type  |
         +---------------------------------------+-------------+
         | CHARACTER_SETS                        | SYSTEM VIEW |
         | COLLATIONS                            | SYSTEM VIEW |
         | COLLATION_CHARACTER_SET_APPLICABILITY | SYSTEM VIEW |
         | COLUMNS                               | SYSTEM VIEW |
         | COLUMN_PRIVILEGES                     | SYSTEM VIEW |
         ...
         +---------------------------------------+-------------+

         ...
         		
         +-----------------+------------+
         | Tables_in_world | Table_type |
         +-----------------+------------+
         | City            | BASE TABLE |
         | Country         | BASE TABLE |
         | CountryLanguage | BASE TABLE |
         | Region          | BASE TABLE |
         +-----------------+------------+


* ''schema like expr'':
  Create a new table in all hosted WordPress schemata:


         foreach($scm: schema like wp%)
         {
           CREATE TABLE :$scm.wp_likes(id int, data VARCHAR(128));
         }
         		


* ''schema ~ ''regexp'''':
  Likewise, be more accurate on schema name:


         foreach ($scm: schema ~ ''^wp_[\\d]+$'')
         {
           CREATE TABLE :$scm.wp_likes(id int, data VARCHAR(128));
         }
         		


* ''table in schema_name'':
  Compress InnoDB tables in sakila. Leave other engines untouched.


         foreach($table, $schema, $engine: table in sakila)
           if ($engine = ''InnoDB'')
             ALTER TABLE :$schema.:$table ENGINE=InnoDB
         ROW_FORMAT=Compressed KEY_BLOCK_SIZE=8;
         		


* ''table like expr'':
  Add a column to all wp_posts tables in hosted WordPress databases:


         foreach($tbl, $scm: table like wp_posts)
           ALTER TABLE :$scm.:$tbl ADD COLUMN post_geo_location VARCHAR
         (128);
         		


* ''table ~ ''regexp'''':
  Add a column to tables whose name matches the given regular expression, in
  any database:


         foreach ($tbl, $scm: table ~ ''^customer_data_[\\d]+$'')
           ALTER TABLE :$scm.:$tbl ADD COLUMN customer_geo_location
         VARCHAR(128);
         		


* Use an otherwise clause:
  The following collection will not match any table:


         foreach ($table, $schema: table like non_existing_table_name_%)
           select $table, $schema;
         otherwise
           echo ''No tables found'';

         +-------------------+
         | echo              |
         +-------------------+
         | ''No tables found'' |
         +-------------------+
           		




NOTES


foreach vs. foreach()

The foreach flow control structure and the foreach() routine both iterate
collections, accept similar (but not identical) collection syntax, and invoke
scripts per loop iteration. They share some similar use cases, but are
nevertheless different.
Very briefly, in Geekish, the differences are:

* foreach() is more META.
* foreach() cannot be nested, nor called from within a script.
* foreach is more limited in terms of what it can do with iterated values.

To fully understand the differences, one must first be acquainted with
variables_expansion . Consider the following example:

* foreach() routine


         mysql> call foreach(
         	''2001:2009'',
         	"DELETE FROM sakila.rental WHERE rental_date >= ''${1}-07-01''
         AND rental_date < ''${1}-09-01''");


  Iterated values are integers in the range 2001 - 2009. The placeholder ${1}
  is assigned with iterated value. The script (a single query in this case)
  never sees ${1} because the text of the script gets manipulated before being
  invoked. Thus, there are 9 different looking scripts invoked. For example,
  the second iteration would execute the following script:


         DELETE FROM sakila.rental WHERE rental_date >= ''2002-07-01'' AND
         rental_date < ''2002-09-01''
         		


  Since placeholders make for text manipulation of the script even before it
  is invoked, the options are limit-less. There is no constraint on what can
  or cannot be used as placeholder, as long as the resulting manipulated text
  makes for a valid script.
  foreach flow control structure:


         foreach($year: 2001:2009)
           DELETE FROM sakila.rental WHERE rental_date >= CONCAT($year,
         ''-07-01'') AND rental_date < CONCAT($year, ''-09-01'');


  The $year variable has the same limitations as any user-defined variable. It
  cannot be used from within a quoted text: ''$year-07-01'' is just a string,
  and the fact the term $year appears inside this quoted text means nothing.
  Hence, we must use CONCAT in order to build the date.


SEE ALSO

Variables, while, break, foreach()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_if_else','QueryScript Flow Control: if-else statement

SYNOPSIS



       if (expression)
         statement;
       [else
         statement;]



DESCRIPTION

if-else is a flow control branching structure. It makes for a condition test
based on a given expression.
When the expression holds true, the statement (or block of statements)
following the if statement are executed. The else clause is optional, and it''s
statement(s) are executed when the expression does not hold true.
There is no built-in elseif clause. However, a chained if-else if-else
statement is valid.
Empty statements are not allowed in QueryScript. However, empty blocks are,
and a if or else clause may use an empty block statement, or by the do-nothing
pass statement.

EXAMPLES

Simple if-else condition:


       set @x := 17;
       if (@x mod 2 = 0)
         SELECT ''even'' AS answer;
       else
         SELECT ''odd'' AS answer;


DELETE statement as expression:


       set @country := ''USA'';
       if (DELETE FROM world.Country WHERE Code = @country)
       {
         -- We don''t have foreign keys on these tables; do a manual drill
       down:
         DELETE FROM world.City WHERE CountryCode = @country;
         DELETE FROM world.CountryLanguage WHERE CountryCode = @country;
       }


Using if to break out of a while loop:


       CREATE TEMPORARY TABLE test.numbers (n INT UNSIGNED NOT NULL
       PRIMARY KEY);
       INSERT INTO test.numbers (n) VALUES (17);

       set @n := 0;
       while (@n < 20)
       {
         if (INSERT IGNORE INTO test.numbers (n) VALUES (@n))
         {
         }
         else
         {
           break;
         }
         set @n := @n + 1;
       }
       SELECT @n AS inserted_up_to_this_value;

       +---------------------------+
       | inserted_up_to_this_value |
       +---------------------------+
       |                        17 |
       +---------------------------+



SEE ALSO

while, expressions

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_input','input: declaration and assignment of QueryScript local variables by externally
provided values

SYNOPSIS



       input $variable1 [, $variable2 ...];
       if ($variable1 = ''x'')
       {
         statement;
       }



DESCRIPTION

input is a QueryScript statement which declares local_variables, and assigns
them values as given from an external source.
The input statement is only expected to appears once, if at all, within a
script. It must not appear within a loop. The variables declared by input are
local variables as any other variable, and the same rules apply for them as
for all local variables.
input makes for an interface between external routines and QueryScript. A
routines which wishes to invoke a script based on some values, passes pre-
defined values via MySQL user defined variables, and these are assigned to the
input local variables.
In particular, when an input statement is encountered, the following MySQL
user defined variables are looked at:

* @_query_script_input_col1, assigned to 1st declared variable.
* @_query_script_input_col2, assigned to 2nd declared variable.
* ...
* @_query_script_input_col9, assigned to 9th declared variable.

While syntactically permitted, it makes no sense to declare more than 9 input
variables, as nothing will map to any variable exceeding the 9th.
To illustrate, consider:


       input $a, $b, $c;



$a will be assigned the value of @_query_script_input_col1.
$b will be assigned the value of @_query_script_input_col2.
$c will be assigned the value of @_query_script_input_col3.
The values of @_query_script_input_col[4..9] remain unread.
A routine which in fact sends input data to QueryScript is foreach() (not to
be confused with QueryScript''s own foreach flow control looping device). In
the following example:


       mysql> call foreach(''{USA, FRA, CAN}'', ''
         input $country;
         DELETE FROM world.City WHERE CountryCode = $country;
       '');


foreach sets @_query_script_input_col1 to the iterating value of ''USA'', ''FRA'',
''CAN'', each in turn, and calls upon the script which assigns the value onto
the $country variable.
For completeness, the above example is very simple, so as to illustrate the
workings of input. The following two code fragments perform the same operation
as the above:


       mysql> call foreach(''{USA, FRA, CAN}'', ''DELETE FROM world.City
       WHERE CountryCode = ''''${1}'''''');


Or, via QueryScript only:


       foreach($country: {USA, FRA, CAN})
       {
         DELETE FROM world.City WHERE CountryCode = $country;
       }


Developers who wish to integrate QueryScript execution into their code are
able to do so by providing the aforementioned user defined variables and by
using input.

SEE ALSO

var, Variables

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_loop_while','QueryScript Flow Control: loop-while statement

SYNOPSIS



       loop
         statement;
       while (expression);



DESCRIPTION

loop-while is a flow control looping structure. It makes for a condition test
based on a given expression.
As opposed to while, loop-while tests the expression after each statement
execution. As result, the loop iterates at least once.
The loop-while loop terminates in the following cases:

* The expression does not hold true
* A break statement is executed inside the loop (but not inside a nested loop)
* A return statement is executed inside the loop
* An uncaught error is raised (at the moment all errors are by default
  uncaught unless handled in user code)

Of course, any error terminates the entire script execution, including any
loops.
Empty statements are not allowed in QueryScript. However, empty blocks are,
and the loop-while clause may be followed by an empty block, or by the do-
nothing pass statement.

EXAMPLES

Generate Fibonacci sequence:


       var $n1, $n2, $n3, $seq;
       set $n1 := 1, $n2 := 0, $n3 := NULL;
       set $seq := '''';

       loop
       {
         set $n3 := $n1 + $n2;
         set $n1 := $n2;
         set $n2 := $n3;
         set $seq := CONCAT($seq, $n3, '', '');
       }
       while ($n3 < 100);

       SELECT $seq AS fibonacci_numbers;

       +---------------------------------------------+
       | fibonacci_numbers                           |
       +---------------------------------------------+
       | 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144,  |
       +---------------------------------------------+



SEE ALSO

if-else, while, foreach, expressions, break

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_pass','pass: a do-nothing statement.

SYNOPSIS



       if (expression)
         pass
       else {
         statement;
       }



DESCRIPTION

pass is a QueryScript statement which does nothing. It can be used as a
placeholder for empty statements.
QueryScript does not allow an empty statement (the standalone semicolon ;
character). The programmer may choose to use the pass statement:


       while (delete from world.City limit 10)
         pass;


Alternatively, the programmer may use an empty block as in the following:


       while (delete from world.City limit 10)
       {
       }


The pass statement serves as a convenience statement.
pass accepts no arguments.

SEE ALSO

Statements

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_report','report: generate formatted report at end of script execution

SYNOPSIS



       report h1 ''My title'';
       report ''concatenated '', ''text, numbers, '', @user_variables, '' and
       '', $local_variables;
       report p ''Starting paragraph, '', @name, '' review'';
       report li $x, '' is validated, bullet'';
       report code ''SET $x := 5'';
       report hr;



DESCRIPTION

report builds a fancy report throughout execution of the script. The report
itself is only presented as the script terminates gracefully (without error).
Thus, invocation of report statements aggregate report messages in the
background, and do not immediately prompt or otherwise affect execution and
output of script.
report concatenates its arguments into a single string. Anything that is valid
within a CONCAT() function is accepted by report. This includes user defined
variables, local variables and expanded variables.
Line breaks (\\n) will make for distinct rows in the resulting report.
report accepts formatting hints, in an HTML-like format. These are:

* h1: title (prettified by underline)
* p: begin paragraph
* li: bullet (prefix with "- ")
* code: source code (prefixed with "> ")
* hr: horizontal line

The formatting hint is optional, and only one hint per report statement is
accepted.

EXAMPLES

A built-in report in common_schema is security_audit.
Analyze and report some common_schema objects:


       report h1 ''common_schema overview'';

       report p ''common_schema offers:'';

       var $num_public_prodecures, $num_public_functions;

       select
         SUM(routine_type = ''PROCEDURE''), SUM(routine_type = ''FUNCTION'')
       FROM
         information_schema.ROUTINES
       WHERE
         routine_schema=''common_schema'' AND routine_name NOT LIKE ''\\_%''
       INTO
         $num_public_prodecures, $num_public_functions;

       report li $num_public_prodecures, '' public procedures'';
       report li $num_public_functions, '' public functions'';


       var $num_public_tables, $num_public_views;
       select
         SUM(table_type=''base table''), SUM(table_type=''view'')
       FROM
         information_schema.TABLES
       WHERE
         table_schema=''common_schema'' AND table_name NOT LIKE ''\\_%''
       INTO
         $num_public_tables, $num_public_views;

       report li $num_public_tables, '' public tables'';
       report li $num_public_views, '' public views'';

       report li (select count(*) from help_content), '' help pages'';


       +------------------------------------------+
       | report                                   |
       +------------------------------------------+
       |                                          |
       | common_schema overview                   |
       | ======================                   |
       |                                          |
       | common_schema offers:                    |
       | - 19 public procedures                   |
       | - 32 public functions                    |
       | - 3 public tables                        |
       | - 34 public views                        |
       | - 131 help pages                         |
       | ---                                      |
       | Report generated on ''2012-09-29 13:42:11 |
       +------------------------------------------+



SEE ALSO

echo, Statements

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_return','return: quit script execution

SYNOPSIS



       statement;
       statement;
       if (expression)
         return;
       statement;



DESCRIPTION

return is a QueryScript statement which, when invoked, aborts execution of
script.
return takes no parameters and does not provide with a value. It merely stops
execution of running script at point of invocation.

EXAMPLES

Return on condition:


       set @x := 3;
       while (@x > 0)
       {
         select @x;
         set @x := @x - 1;
         if (@x = 1)
           return;
       }
       select ''will never get here'';

       +------+
       | @x   |
       +------+
       |    3 |
       +------+

       +------+
       | @x   |
       +------+
       |    2 |
       +------+



SEE ALSO

Flow_control, break

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_sleep','sleep: suspend execution for a given number of seconds

SYNOPSIS



       sleep <number>;
       sleep $seconds;
       sleep @seconds;



DESCRIPTION

sleep is a QueryScript statement which, when invoked, makes for a non-busy
wait for a given period of time. Essentially, it is a convenience statement
making for a shortcut to a "DO SLEEP()" execution.
sleep takes a number as a parameter, which is the time, in seconds, for which
the script is to sleep. The number can be an integer or a floating point, and
it is interpreted as follows:

* 0 or less: no sleep is done. It makes no sense to provide such values
* x, a positive number: sleep for given number of seconds.

sleep also accepts a local variable or a MySQL user defined variable as
argument. Such argument is cast to a number and handled as specified above.

EXAMPLES

Purge rows from table, sleep for 2 seconds in between operations:


       while (delete from world.City limit 10)
       {
         sleep 2.0;
       }



SEE ALSO

script_runtime(), Statements, throttle

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_split','QueryScript Flow Control: split statement

SYNOPSIS

Single table operations, autodetect mode:


       split (statement operating on single table)
         statement;


Multiple tables operations; explicit_declaration of splitting table:


       split (schema_name.table_name: statement operating on multiple
       tables)
         statement;


Statementless split, manual mode:


       split (schema_name.table_name)
         statement;


Provide parameters to split operation:


       split ({foo:bar}: statement)
         statement;


Discussion on the various flavors of split follows.

DESCRIPTION

split automagically breaks a query into subparts -- smaller chunks -- and
works these in steps. It alleviates the load caused by large operations by
turning them into smaller ones.
Consider the following query: we realize we must UPDATE a column on all rows:


       split (UPDATE sakila.rental SET rental_date = rental_date +
       INTERVAL 6 HOUR)
         pass;


To execute a "normal" UPDATE of the above form would mean, assuming the table
is very large, issuing a very large transaction. Such transaction could take
hours to complete, by which time locks are accumulating, performance is
degrading, and an attempt attempt at rollback can make for an even larger
overhead.
A solution to such a problem is in the form of chunking: splitting the query
into many smaller ones, each operating on a distinct group of rows. Not only
the query, but the transaction itself (assuming AUTOCOMMIT=1) is broken into
smaller transactions. Each such transaction is quick to complete, and has
better chance at not making for any locks. One may choose to "rest" in between
chunks, making for the availability of system resources.
The above split code does just that: it automagically breaks the query, by:

* Analyzing the query, detecting, if possible, the table on which the split is
  done (with a multi-table query explicit instruction is required)
* Analyzing the table, detecting best method of splitting it up into smaller
  parts. This is done by choosing the best UNIQUE KEY by which to work out the
  splitting process.
* Rewriting the query so as to add a filtering condition placeholder: the
  expression which limits.
* Determining the particular chunks by running over the actual rows, and
  issuing query on each chunk.

Thus, split works by selecting a particular table used by the SQL action
statement, and by breaking it apart. This table is called the splitting table
or the chunking table.
split looks like a looping construct: the statement gets executed once per
each chunk of the original query. As with looping constructs, it respects,
among others, the following statements:

* break: terminate split execution: this means skipping any remaining chunks.
* throttle: control loop execution time by sleeping in between iterations,
  time of sleep proportional to time of execution.

split defaults to chunks of 1,000 rows each. This can be configured via the
size parameter.
Use of expanded_variables is allowed within the split statement, as well as
within the table definition and the query params. See EXAMPLES for more on
this.

Magic variables

split introduces magic variables, which are available within a split iteration
statement. These are:

* $split_columns: comma separated list of columns by which the split algorithm
  splits the table.
* $split_min: minimum values of $split_columns. This is the starting point for
  the split operation.
* $split_max: minimum values of $split_columns. This is the ending point for
  the split operation.
* $split_range_start: per chunk, values of $split_columns indicating chunk''s
  lower boundary.
* $split_range_end: per chunk, values of $split_columns indicating chunk''s
  upper boundary.
* $split_step: iteration counter. Value is 1 for 1st iteration 2 for 2nd
  iteration, etc.
* $split_rowcount: the number of rows affected by current split step.
* $split_total_rowcount: the total number of rows affected so far by the split
  statement.
  This is an accumulation of $split_rowcount
* $split_clause: the computed filtering clause. See following discussion.
* $split_total_elapsed_time: total number of seconds elapsed since split
  operation started. This includes possible throttling or sleeping time.
* $split_table_schema: schema for splitting table.
* $split_table_name: the splitting table, by which split works out the smaller
  steps.


Flavors


Single table, autodetect mode

split can analyze statements involving single table, and automatically
identify the referenced table. This makes for the simplest and cleanest
syntax:


       split (DELETE FROM sakila.rental WHERE rental_date < NOW() -
       INTERVAL 5 YEAR)
         SELECT $split_total_rowcount AS ''rows deleted so far'';




       create table world.City_dup like world.City;
       split (insert into world.City_dup select * from world.City)
       {
         throttle 2;
       }



Multiple tables operations; explicit declaration of splitting table

When multiple tables are involved, the user must specify the splitting table:


       split (sakila.film: UPDATE sakila.film, sakila.film_category SET
       film.rental_rate = film.rental_rate * 1.10 WHERE film.film_id =
       film_category.film_id AND film_category.category_id = 3)
         sleep 0.5;


The user is always allowed to specify the splitting table, even on single
table operations:


       split (sakila.rental: DELETE FROM sakila.rental WHERE rental_date
       < NOW() - INTERVAL 5 YEAR) {
         SELECT $split_total_rowcount AS ''rows deleted so far'';
       }


The user may still specify the splitting table even when the statement
operates on a single table; in which case the specified table must indeed be
the table being operated on. However, with statement operating on single table
it is best to let split() figure out the table name.

Statementless split, manual mode

split can also accept just the splitting table, without a query. In this
"manual mode" the table is being split and iterated, but no "actual" query is
issued.
The loop construct, however, is iterated, and the magic_variables are
available. This allows the user to manually execute what would have been
automatic, or otherwise act in unconventional manner. Consider:


       split (sakila.rental) {
         DELETE FROM sakila.rental WHERE rental_date < NOW() - INTERVAL 5
       YEAR AND :${split_statement};
       }


In the above example, the user builds the splitting of the DELETE query
manually.
In other use cases, the user may be interested in the metadata of the
splitting process (see EXAMPLES). The metadata is provided by split''s magic
variables.

Providing parameters

split accepts parameters for operation. Normally, split does everything on its
own, and does not require instruction. However, the user is given the choice
of fine tuning split''s operation by providing any combination of the following
paramaters:

* size: number of rows used in each step (minimum: 100; maximum: 10,000;
  default: 1,000)
* start: in the specific case where the operation utilizes a single column for
  splitting (as will be the case for the common AUTO_INCREMENT PRIMARY KEYs),
  the operation will only begin with given value (inclusive).
  An error is thrown when the splitting key uses two columns or more.
  All data types are supported, including textual.
* stop: in the specific case where the operation utilizes a single column for
  splitting (as will be the case for the common AUTO_INCREMENT PRIMARY KEYs),
  the operation will terminate with given value (inclusive).
  An error is thrown when the splitting key uses two columns or more.
  All data types are supported, including textual.
* table: explicit table & schema name, when multiple statements are used. This
  parameter is not required, though allowed, when the statement operates on a
  single table.

In the following example, the rental table has an AUTO_INCREMENT PRIMARY KEY
column called rental_id. The split operation starts with rental_id value of
1200, works till the end of table, and uses chunks of 500 rows at a time.


       split ({start: 1200, step: 500} : DELETE FROM sakila.rental WHERE
       rental_date < NOW() - INTERVAL 5 YEAR)
         throttle 2;


In the above example, the user builds the splitting of the DELETE query
manually.

LIMITATIONS

split accepts these types of statements:

* DELETE FROM table_name ...
* DELETE FROM table_name USING <multi table syntax> ...
* UPDATE table_name SET ...
* UPDATE <multiple tables> SET ...
* INSERT INTO some_table SELECT ... FROM <single or multiple tables> ...
* REPLACE INTO some_table SELECT ... FROM <single or multiple tables> ...
* SELECT ... FROM <multiple tables> ...

The following limitations apply to the split statement:

* You should avoid using index hints on the splitting table.
* At current, split does not accept the DELETE FROM tbl.* ... syntax. Use
  DELETE FROM tbl ... instead.
* Statements with DISTICT will probably result with unexpected results.
  Statements with GROUP BY may also behave unexpectedly, depending on the
  statement.

split is furthermore subject to the following limitations:

* A split statement cannot be nested within another split statement. To
  clarify, there is no problem with nesting other loop constructs such as
  while, foreach etc.
* Aliasing the splitting table is not allowed.
* For table_autodetection to work, the statement must work on a single table
  only, and must not contain index hints, derived tables or subqueries. You
  may always choose to explicitly declare the splitting table using the split
  (schema_name.table_name: the statement) {...} variation.


EXAMPLES

Mike is resigned. Assign all mike''s issues to Jon:


       call run("
         split (update sakila.rental set staff_id = 2 where staff_id = 1)
           select $split_total_rowcount as ''processed issues'';
       ");

       +------------------+
       | processed issues |
       +------------------+
       |              479 |
       +------------------+
       1 row in set (0.07 sec)

       +------------------+
       | processed issues |
       +------------------+
       |              983 |
       +------------------+
       1 row in set (0.09 sec)

       ...

       +------------------+
       | processed issues |
       +------------------+
       |             8040 |
       +------------------+
       1 row in set (0.40 sec)


Create denormalized table, fill it:


       CREATE TABLE sakila.denormalized_film_category (
         film_id smallint unsigned NOT NULL,
         category_id tinyint unsigned NOT NULL,
         last_update timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON
       UPDATE CURRENT_TIMESTAMP,
         film_title varchar(255),
         category_name varchar(255),
         PRIMARY KEY (film_id,category_id)
       );

       split (sakila.film_category:
         INSERT INTO sakila.denormalized_film_category
         SELECT
           film_id,
           category_id,
           film_category.last_update,
           film.title,
           category.name
         FROM
           sakila.film_category
           JOIN sakila.film USING (film_id)
           JOIN sakila.category USING (category_id)
         )
       {
         SELECT $split_total_rowcount AS ''total rows generated so far'';
         throttle 2;
       }


The above uses the sample sakila database. It just so happens that the number
of rows in sakila.film_category is exactly 1,000, which makes for a single
step.
Walk through a table (no particular statement to execute); watch the magic
variables:


       call run("
         split(sakila.film_actor) {
           select
             $split_step as step, $split_columns as columns,
             $split_min as min_value, $split_max as max_value,
             $split_range_start as range_start, $split_range_end as
       range_end
         }
       ");

       +------+----------------------+-----------+-------------+---------
       ----+------------+
       | step | columns              | min_value | max_value   |
       range_start | range_end  |
       +------+----------------------+-----------+-------------+---------
       ----+------------+
       |    1 | `actor_id`,`film_id` | ''1'',''1''   | ''200'',''993'' | ''1'',''1''
       | ''39'',''293'' |
       +------+----------------------+-----------+-------------+---------
       ----+------------+

       +------+----------------------+-----------+-------------+---------
       ----+------------+
       | step | columns              | min_value | max_value   |
       range_start | range_end  |
       +------+----------------------+-----------+-------------+---------
       ----+------------+
       |    2 | `actor_id`,`film_id` | ''1'',''1''   | ''200'',''993'' |
       ''39'',''293''  | ''76'',''234'' |
       +------+----------------------+-----------+-------------+---------
       ----+------------+

       +------+----------------------+-----------+-------------+---------
       ----+-------------+
       | step | columns              | min_value | max_value   |
       range_start | range_end   |
       +------+----------------------+-----------+-------------+---------
       ----+-------------+
       |    3 | `actor_id`,`film_id` | ''1'',''1''   | ''200'',''993'' |
       ''76'',''234''  | ''110'',''513'' |
       +------+----------------------+-----------+-------------+---------
       ----+-------------+

       +------+----------------------+-----------+-------------+---------
       ----+-------------+
       | step | columns              | min_value | max_value   |
       range_start | range_end   |
       +------+----------------------+-----------+-------------+---------
       ----+-------------+
       |    4 | `actor_id`,`film_id` | ''1'',''1''   | ''200'',''993'' |
       ''110'',''513'' | ''146'',''278'' |
       +------+----------------------+-----------+-------------+---------
       ----+-------------+

       +------+----------------------+-----------+-------------+---------
       ----+-------------+
       | step | columns              | min_value | max_value   |
       range_start | range_end   |
       +------+----------------------+-----------+-------------+---------
       ----+-------------+
       |    5 | `actor_id`,`film_id` | ''1'',''1''   | ''200'',''993'' |
       ''146'',''278'' | ''183'',''862'' |
       +------+----------------------+-----------+-------------+---------
       ----+-------------+

       +------+----------------------+-----------+-------------+---------
       ----+-------------+
       | step | columns              | min_value | max_value   |
       range_start | range_end   |
       +------+----------------------+-----------+-------------+---------
       ----+-------------+
       |    6 | `actor_id`,`film_id` | ''1'',''1''   | ''200'',''993'' |
       ''183'',''862'' | ''200'',''993'' |
       +------+----------------------+-----------+-------------+---------
       ----+-------------+


Use expanded variables as table & schema names in split statement. In this
example we update all tables called rental in any database.


       foreach($tbl, $scm: table like rental) {
         split(update :${scm}.:${tbl} set rental_date = rental_date +
       interval 1 day) {
           throttle 1;
         }
       }



SEE ALSO

foreach, break, throttle, candidate_keys

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_statements','QueryScript Statements: operations on data, schema or flow.

SYNOPSIS



       statement;
       {
           statement;
           statement;
       }


List_of_QueryScript_statements

DESCRIPTION

Statements are actions to be taken. QueryScript supports statements of the
following types:

* SQL statements: the usual DML (SELECT, INSERT, ...), DML (CREATE, ALTER,
  ...) and other various commands (KILL, GRANT, ...)
* Script statements: statements which affect flow and behavior of script
* Statement blocks


SQL statements

Most SQL statements which are accepted by MySQL are also accepted by
QueryScript. These include INSERT, UPDATE, DELETE, SELECT, CREATE, DROP,
ALTER, SET, FLUSH, and more.
Among the SQL statements which are in particular not allowed within
QueryScript are:

* Dynamic SQL statements (PREPARE, EXECUTE, DEALLOCATE)
* Plugin statements (INSTALL, UNINSTALL)
* Stored routines statements (DECLARE, LOOP, ...), for which QueryScript
  provides substitutes.

Transaction statements are handled by the QueryScript engine, as described
following.
Otherwise, any SQL statement which is not allowed to be executed via dynamic
SQL cannot be executed via QueryScript.
Execution of a SQL statement modifies the $rowcount and $found_rows variable.
See built-in_variables.

QueryScript statements

QueryScript adds and recognizes the following statements:

* echo
* eval
* input
* pass
* report
* sleep
* throttle
* throw
* var

And the following flow control statements :

* break
* return

In addition, the transaction statements start transaction, begin, commit,
rollback are managed by QueryScript and delegated immediately to MySQL.

Statement blocks

Statements can be grouped into blocks by using the curly braces, as follows:


       {
           statement;
           statement;
       }


The entire block is considered to be a statement, and is valid for use in flow
control structures, such as foreach, if-else, while, loop-while.

Statement delimiters

QueryScript statements are terminates by a semicolon (";"). The last query in
a block or script can optionally not be terminated by the semicolon. Thus, the
following are valid scripts:


           statement




           statement;




       {
           statement;
           statement
       }


A block statement ({...}) is not terminated by a delimiter. There is no way to
change the delimiter. In particular, QueryScript does not recognize the
DELIMITER statement.

Comments

Comments are allowed within QueryScript, as follows:

* Multi line comments are recognized by /* ... */
* Single line comments are recognized by --. Note that there is a space after
  the two dashes.

See following:


           set @x := 3;
           if (@x < 5 /* This is a comment */)
           {
             -- A single line comment
             select ''x is small'';
           }
           else
           {
             /* Another comment, this
                time multiline */
             select ''x is large'';
           }



SEE ALSO

expressions

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_throttle','throttle: regulate execution of script by sleep-suspend

SYNOPSIS



       while (expression)
       {
         statement;
         throttle <number>;
       }




       while (expression)
       {
         statement;
         throttle $throttle_ratio;
       }



DESCRIPTION

throttle is a QueryScript statement which, when invoked, may suspend execution
by invoking SLEEP().
throttle takes a number as a parameter, which is the ratio of throttling. The
number can be an integer or a floating point, and it is interpreted as
follows:

* 0 or less: no throttling is done. It makes no sense to provide such values
* x, a positive number: assuming an unthrottled operation would take s seconds
  to run, a throttled operation is expected to run s*(1 + x) seconds.

throttle also accepts a local variable or a MySQL user defined variable as
argument. Such argument is cast to a number and handled as specified above.
Consider the following code as example:


       while (delete from world.City limit 10)
       {
         throttle 1;
       }


The above deletes all rows from a table, 10 rows at a time. The throttle value
of 1 means doubling the runtime: if the original deletion loop would take 7
seconds to complete, the throttle statements adds one measure to that,
resulting with 14 seconds.
A throttle value of 2 would make the code run 3 times as long it it would
without throttling. A throttle value of 0.3 would make the code run 1.3 times
as long it it would without throttling.
Combined with loop iteration, throttling makes for heavy duty query put less
load on the system. That is, CPU or disk resources, which may be extensively
used during normal query or queries iteration, are given breathing space
during throttle suspension period. Throttling makes for a longer total
runtime, while making pauses in between operations. Throttling is also a
useful technique in avoiding replication lag: standard MySQL replication (5.1,
5.5) is single threaded. Throttling allows the slave to execute other queries,
interleaved with script statements.
While this statement is valid anywhere throughout the script, it mostly makes
sense when executed from within a loop, such that the iterations of the loop
are being throttled.

EXAMPLES

Duplicate a table: copy rows in small chunks, throttle:


       create table world.City2 like world.City;
       split (insert into world.City2 select * from world.City)
       {
         throttle 2;
       }



SEE ALSO

Execution, Flow_control, sleep

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_throw','throw: throw an exception

SYNOPSIS



       statement;
       if (expression)
         throw ''message'';
       statement;



DESCRIPTION

throw is a QueryScript statement which, when invoked, raises an error.
When executed from within a try statement, flow resumes at the matching catch
block.
Otherwise, it makes for the (ungraceful) termination of the script''s
execution. If an active transaction is in place, it is rolled back.
throw takes a text parameter, which is the error message. It is stored in the
@common_schema_error variable.
Since SIGNAL is only introduced in MySQL 5.5, current implementation of throw
uses a dirty trick to raise an error, in the form of attempting to SELECT from
a non-existent table. The result is a rather obscure error message, noting
that some table does not exist. The name of the non-existing table is actually
the error message.

EXAMPLES

Throw, get the error message:


       set @x := 3;
       while (@x > 0)
       {
         set @x := @x - 1;
         if (@x = 1)
           throw ''x is too low!'';
       }

       ERROR 1146 (42S02): Table ''error.''x is too low!'''' doesn''t exist

       mysql> select @common_schema_error;
       +----------------------+
       | @common_schema_error |
       +----------------------+
       | ''x is too low!''      |
       +----------------------+



SEE ALSO

Flow_control, try-catch, return

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_try_catch','QueryScript Flow Control: try-catch statement

SYNOPSIS



       try
         statement;
       catch
         statement;



DESCRIPTION

try-catch is an error handling flow control structure. Flow is determined
based on the appearance or non-appearance of execution errors.
The try statement (or block of statements) is executed. If no error occurs, it
completes, and the catch statement is never executed.
If an error is detected within execution of the try statement, the try
statement is aborted at the point of error (i.e. all statements following the
point of error are discarded), and the catch statement (or block of
statements) is executed.
An error thrown from within a catch is not further caught, unless surrounded
in itself by a nested try-catch statement.
The catch block executes upon any error thrown within the try statement. It is
not possible, at the moment, to explicitly specify a type of error for which
the catch block should operate. Nor is it possible to specify multiple catch
blocks as is common in various programming languages.
Furthermore, it is currently not possible to retrieve the exact error (or
error code) causing the catch block to operate. All that is known is that some
error has been raised.
Empty statements are not allowed in QueryScript. However, empty blocks are,
and the try-catch clause may be followed by an empty block, or by the do-
nothing pass statement.
Though syntactically valid, it makes no sense to use an empty try statement.
It does make perfect sense to use an empty catch statement, to the result of
silencing an error without termination of the script.

Nesting

It is possible to have nested try-catch statements. When nested, errors are
caught by the deepest catch block which applies to them. To illustrate,
consider:


       try {
         statement1;
         try {
           statement2;
         }
         catch {
           -- errors in statement2 are handled here
           statement 3;
         }
         statement 4;
       }
       catch {
         -- errors in statement1, statement3 and statement4 are handled
       here
         -- errors in statement2 are not handled here
         statement 5;
       }


Unlike other common implementations of try-catch, QueryScript does not require
block statements, i.e. braces. This allows for the following try all you can
syntax, which is very similar to a nested if-else-if-else construct:


       try {
         statement1;
       }
       catch try {
         -- We only get here if statement1 fails
         statement2;
       }
       catch try {
         -- We only get here if statement1 & statement2 fail
         statement3;
       }
       catch try {
         -- We only get here if all previous statements fail
         statement4;
       }
       catch {
         -- They all failed
         statement5;
       }



EXAMPLES

Simulate a schema upgrade process: try and create a table. If it already
exists, make sure a given column is upgraded to a desired type:


       try
       {
         -- Try and create table:
         CREATE TABLE test.article (
           article_id int unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
           title varchar(128) CHARSET utf8,
           content text CHARSET utf8
         );
       }
       catch
       {
         -- Apparently table already exists. Upgrade it:
         ALTER TABLE test.article
           MODIFY COLUMN content text CHARSET utf8;
       }


Repeat attempts for query which is expected to abort on deadlock: insist on
executing it until successful:


       while (true)
       {
         try
         {
           -- Attempt query which is expected to abort on deadlock:
           UPDATE some_table SET some_column = 1 WHERE some_condition;
           -- Got here? This means query is successful! We can leave now.
           break;
         }
         catch
         {
           -- Apparently there was a deadlock. Rest, then loop again
       until succeeds
           sleep 1;
         }
       }



NOTE

Since it is impossible to know the nature of the error causing the catch block
to execute, and since any error will cause it to execute, it is the user''s
responsibility to deduce the origin of the error. In particular, watch out for
plain syntax error, or otherwise SQL errors, such as misspelling table or
column names.

SEE ALSO

if-else, throw

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_var','var: declaration of QueryScript local variables

SYNOPSIS



       var $variable1 [, $variable2 ...];
       var $single_var := ''some_value'';
       while(expression)
       {
         var $variable3 [, $variable4 ...];
         var $pi := PI();
       }



DESCRIPTION

var is a QueryScript statement which declares local_variables.
var can appear anywhere within a script: within loops, if-else clauses, in
general scope or in sub statement blocks.
Variables declared by var are only visible at the scope in which they''re
declared. A local variable is known to be NULL at point of declaration, and is
cleared once out of scope (being reassigned as NULL).
var allows for two types of variable declaration:

* One or more variables, comma delimited. These variables are assigned with
  NULL.
* A single variable with assignment, as in var $area := PI() * POW($r, 2). The
  assigned value can be of any valid expression.

It is an error to re-declare a local variable within a script, regardless of
scope.

EXAMPLES

Declare variabels at different levels:


       var $a, $b;
       set $a := 4, $b := 17;
       var $c := $a;
       while ($c > 0)
       {
         var $d := $c - 1;
         set $c := $c - 1;
       }
       set $b := $c;



SEE ALSO

Variables, input

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_variables','QueryScript Variables: creation, assignment, expansion & cleanup

SYNOPSIS



       var $v1, $v2, $v3;
       set $v1 := 1;
       var $v_pi := 3.14;
       var $table_name := ''rental'';
       SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME =
       $table_name;
       ALTER TABLE sakila.:$table_name ENGINE=InnoDB;
       CREATE TABLE test.tmp_:${table_name}_tbl (n INT) ENGINE=InnoDB;
       INSERT INTO test.tmp_:${table_name}_tbl SELECT n FROM numbers;
       SELECT $rowcount, $found_rows;



DESCRIPTION

In addition to supporting MySQL''s user_defined_variables, QueryScript
introduces script local variables, with controlled creation and cleanup, and
with supported in-place expansion.

Declaration, usage and cleanup

The following code declares, sets and reads local variables:


       var $x := 3;
       while ($x > 0)
       {
         var $y := CONCAT(''Value of $x is: '', $x);
         SELECT $y AS msg;
         set $x := $x - 1;
       }


Multiple variables can be declared with a single var statement:


       var $x, $y, $z;


It is possible to declare and assign a variable within the var statement as
follows:


       var $x := ''declared!'';


However this is limited to a single variable. It is not possible to declare
and assign multiple variables from within the same var statement. Multiple var
statements would be required for that - one per variable.
QueryScript variables behave much like a user defined variable. They can be
assigned to, read from, used within a query:


       var $x := 3;
       SELECT $x, $x + 1 AS next_value;
       SET $x := POW($x, 2);
       SET @msg := CONCAT(''value is '', $x);


However, the following differentiates it from MySQL''s user defined variables:

* Variables must be declared by the var statement.
* At the point of declaration, they are known to be NULL (unless assigned with
  a value at point of declaration)
* Local variables are only recognized within their scope (see following).
* Once a variable''s scope terminates, the variable is reset to NULL. In the
  above while loop example, $y is being reset to null at the end of each loop
  iteration.

MySQL''s user defined variables, in contrast, retain their value throughout the
session, or until they are assigned a new one.
Variables can be declared at any point; they do not necessarily have to be
declared at the beginning of a block or script.
A foreach loop also declares variables, where the var statement is not
required.
Variable names are case-sensitive.
Note: current implementation uses MySQL''s user defined variables, using
variable names which are unique within the script and the session in which
they are declared.

Visibility & scope

A variable is only visible in the scope in which it is declared. In the above
example, $x is recognized throughout the script, but $y may only be accessed
from within the loop''s block.
One may use the above facts to force both cleanup and hiding of variables, by
creating sub-blocks of code:


       {
         var $x;
         set $x := 3;
       }
       -- $x is known to be cleared at this point, and will
       -- not be recognized from this point and on.
       {
         var $y := ''abc'';
       }
       -- $y is known to be cleared at this point, and will
       -- not be recognized from this point and on.


One may declare two variables of the same name, as long as they are invisible
to each other. In other words, they must be in non-overlapping scopes. For
example, the following is valid:


       {
         var $a := 3;
         var $b := 4;
       }
       var $a := 5;
       {
         var $b := ''6'';
       }


The second declaration point of $a appears after the first one went out of
scope, which makes this a valid declaration. The same goes for $b.

Expansion

A variable may be expanded in-place. Expansion means the variable is replaced
with the constant value it holds. Expansion allows the programmer to use
variables where variables are not allowed. To illustrate, we must first look
at the basics.
The value held by the local variable is interpreted as text, and is seamlessly
integrated with the surrounding statement or expression.
Expansion syntax:


       var $foo := 3;
       SELECT $foo, :$foo, :${foo};

       var $bar := ''Population > 1000000'';
       SELECT * FROM world.Country WHERE :$bar;


Consider the following code:


       var $x := 3;
       SELECT $x, :$x;

       +--------------------+---+
       | @__qs_local_var_16 | 3 |
       +--------------------+---+
       |                  3 | 3 |
       +--------------------+---+


The above is somewhat delicate: the $x variable is in fact implemented as a
MySQL user defined variable called @__qs_local_var_16. It has the value of 3.
However, the :$x value is the expansion of $x, and is the constant 3 (as is
evident from column''s name).
Both :$x and :${x} result with the expanded value of $x. The latter is a more
expressive form, and is useful in resolving ambiguities as in the following:


       var $table_name := ''links'';
       CREATE TABLE test.:$table_name;                 -- fine
       CREATE TABLE test.personal_:$table_name;        -- fine
       CREATE TABLE test.:$table_name_to_categories;   -- impossible to
       resolve variable name
       CREATE TABLE test.:${table_name}_to_categories; -- fine


Now consider cases where variables cannot be used, yet expansion allows for
seamless script approach:


       set @n := 2;
       var $x := @n + 1;

       -- An error: -- SELECT Name FROM world.City ORDER BY Population
       DESC LIMIT @n;
       -- An error: -- SELECT Name FROM world.City ORDER BY Population
       DESC LIMIT $x;
       --
       -- A valid statement:
       SELECT Name FROM world.City ORDER BY Population DESC LIMIT :$x;

       +-----------------+
       | Name            |
       +-----------------+
       | Mumbai (Bombay) |
       | Seoul           |
       | São Paulo       |
       +-----------------+


As another example, consider:


       set @t := ''City'';
       var $tbl;
       set $tbl := ''City'';

       -- An error: -- ALTER TABLE world.@t ENGINE=InnoDB;
       -- An error: -- ALTER TABLE world.$tbl ENGINE=InnoDB;
       --
       -- A valid statement:
       ALTER TABLE world.:$tbl ENGINE=InnoDB;


An ALTER TABLE does not accept variables for table names. However, when using
expansion, the last statement translates to ALTER TABLE world.City
ENGINE=InnoDB; before being sent to MySQL.
Expansion occurs just before query execution. It is therefore possible to
expand changing values, as follows:


       foreach($t: {City, Country, CountryLanguage})
       {
         ALTER TABLE world.:${t} ENGINE=InnoDB;
       }


Expansion limitations:

* Expansion applies for SQL_statements and expressions.
* Expansion does not apply to variables of QueryScript statements.
* Expansion in expressions only applies once. Thus, in a while(:${condition})
  {...} loop, the expansion of :${condition} occurs at one time only, before
  the first loop iteration. Future changes to the $condition local variable
  itself do not affect the expression.
* Expanded variables must not specify local variables. Expanding the variable
  var $some_var := ''$another_var'' will result in a runtime error. You may
  relate to MySQL''s user defined variables.


Built-in variables

The following variables are built into the system:

* $found_rows: number of rows returned by previous SELECT statement, if any.
  This value reflects MySQL''s FOUND_ROWS(). Due to the interpreted nature of
  QueryScript, the transient FOUND_ROWS() value is lost by the time next
  statement executes. Hence the use of this variable.
  This variable is transient, in that it only relates to the previously
  executed statement.
* $rowcount: number of rows changed, deleted, or inserted by the last
  statement, if applicable.
  This value reflects MySQL''s ROW_COUNT(). Due to the interpreted nature of
  QueryScript, the transient ROW_COUNT() value is lost by the time next
  statement executes. Hence the use of this variable.
  This variable is transient, in that it only relates to the previously
  executed statement.


SEE ALSO

foreach, input, var

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('query_script_while','QueryScript Flow Control: while statement

SYNOPSIS



       while (expression)
         statement;
       [otherwise
         statement;]



DESCRIPTION

while is a flow control looping structure. It makes for a condition test based
on a given expression.
As long as the expression holds true, the statement (or block of statements)
following the while statement are executed. The expression is evaluated before
each iteration of the loop.
The while loop terminates in the following cases:

* The expression does not hold true
* A break statement is executed inside the loop (but not inside a nested loop)
* A return statement is executed inside the loop
* An uncaught error is raised (at the moment all errors are by default
  uncaught unless handled in user code)

The otherwise clause is optional. It will execute once should no iteration
take place. That is, if at least one while iteration executes, otherwise is
skipped.
Empty statements are not allowed in QueryScript. However, empty blocks are,
and the while clause may be followed by an empty block, or by the do-nothing
pass statement.

EXAMPLES

Remove leading digits from text:


       set @txt := ''12864xyz'';
       while(left(@txt,1) in (''0'',''1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'',''9''))
         set @txt := substring(@txt, 2);

       SELECT @txt;

       +------+
       | @txt |
       +------+
       | xyz  |
       +------+


DELETE statement as expression:


       while (DELETE FROM world.Country WHERE Continent = ''Asia'' LIMIT
       10)
       {
         -- We remove 10 rows at a time, and throttle by waiting in
       between
         -- deletions twice the amount of time executed on deletion.
         throttle 2;
       }


Repeatedly issue a query for 60 seconds. Output number of repetitions:


       set @counter := 0;
       while(script_runtime() < 60)
       {
         SELECT Continent, COUNT(*) FROM world.Country GROUP BY
       Continent;
         set @counter := @counter + 1;
       }
       SELECT @counter;

       +----------+
       | @counter |
       +----------+
       |    15654 |
       +----------+


Use an otherwise clause:


       set @count := 0;
       while (@count > 22)
         set @count := @count-1;
       otherwise
         echo ''not a single iteration'';

       +--------------------------+
       | echo                     |
       +--------------------------+
       | ''not a single iteration'' |
       +--------------------------+



SEE ALSO

if-else, loop-while, foreach, expressions, break

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('random_hash','
NAME

random_hash(): Return a random hash code.

TYPE

Function

DESCRIPTION

This function generates a 40 hexadecimal characters long random hash code.
The function relies on the SHA1() digest function.
To provide diverse and large input, the function uses random values, time
stamp and global status data.

SYNOPSIS



       random_hash()
         RETURNS CHAR(40) CHARSET ascii



EXAMPLES

Generate a random hash:


       mysql> select random_hash() as hash;
       +------------------------------------------+
       | hash                                     |
       +------------------------------------------+
       | af89717a0a8d02830db8d172f3e35530e009b131 |
       +------------------------------------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

crc64(), query_checksum()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('redundant_keys','
NAME

redundant_keys: List indexes which are made redundant (or duplicate) by other
(dominant) keys.

TYPE

View

DESCRIPTION

redundant_keys finds and lists keys which are redundant; such that other
existing keys can take their functionality, or that provide no better
selectivity/cardinality than other existing keys.
It is in essence similar to Maatkit''s mk-duplicate-key-checker, but provides
information by utulizing a query instead of external scripts.
Exactly what a redundant or duplicate key is sometimes a matter of
perspective. Listed below are sample cases that make or do not make for
redundant keys. The trivial example where a key is redundant is when two
identical keys are created. For example: KEY idx_1 (a), KEY idx_2 (a).
There is no argument that one of the keys above is redundant. However, the
following case is somewhat different: KEY idx_1 (a), KEY idx_2 (a, b).
In the above, idx_1 is "covered" by idx_2. Anything idx_1 can do can also be
done with idx_2, which indexes column ''a'' and then some.
However, this is not the complete picture. While mathematically being
redundant, we may actually desire to explicitly have idx_1 for performance
reasons. Since idx_2 covers more columns, it is more bloated. For queries only
searching through ''a'', idx_1 may yield with better performance, since scanning
through the index required less I/O (less pages to be scanned).
Moreover, for queries where idx_1 makes for a covering index (e.g. SELECT a
FROM t WHERE a BETWEEN 200 AND 500, the difference may be even more
significant, since we now only scan the index idx_1 and do not require access
to the table. In the previous example, accessing the table added such overhead
that made the difference between the two indexes smaller in comparison to
total work.
The recommendations provided by redundant_keys only refer to the mathematical
definition, and leave performance to the discretion of the user.
Terms:

* KEY and INDEX are synonyms
* A redundant or duplicate index is an index which is not mathematically
  required.
* A dominant index is a key which makes another index redundant.

Important notes:

* The view provides with a sql_drop_index column, making for SQL statement
  which drop the redundant keys. Do NOT take them for granted, or automate
  them back into MySQL. User is advised to double check all recommendations.
* This view only considers B-Trees. This includes normal InnoDB & MyISAM
  indexes, and excludes FULLTEXT, HASH, GIS keys.
* Subpart keys (indexing a prefix of a text column, e.g. KEY `name_idx`
  (`name` (10))) are not supported by this view. It provides with the
  subpart_exists column, to notify that subpart indexing is in use, but does
  not validate if and how redundancy is affected. User is advised to double &
  triple check recommendations. See examples below.
* Circular listing of redundant keys may be possible and has not been
  thoroughly tested. That is, there may be groups of >= 3 keys, each making
  the other redundant, such that the view recommends to drop them all.

Sample cases where a key is redundant:

* KEY idx_1 (a), KEY idx_2 (a): the trivial case with two identical keys.
  Either one can be dropped.
* UNIQUE KEY idx_1 (a), KEY idx_2 (a): both index same column, but idx_1 also
  provides uniqueness. idx_2 is redundant.
* UNIQUE KEY idx_1 (a, b), KEY idx_2 (a, b): same as above.
* KEY idx_1 (a), KEY idx_2 (a, b): any query utilizing idx_1 can also utilize
  idx_2. idx_2 can answer for all ''a'' issues. This makes idx_1 redundant. See
  preliminary discussion on explicit redundant keys for more on this.
* KEY idx_1 (a), UNIQUE KEY idx_2 (a, b): same as above.
* UNIQUE KEY idx_1 (a), KEY idx_2 (a, b): interestingly, idx_2 is redundant.
  To see why, note that idx_1 is UNIQUE. Since a UNIQUE key poses a
  constraint, which is not provided otherwise, idx_1 cannot be redundant.
  However, since any ''a'' is unique, so is any (''a'', ''b'') combination. For any
  ''a'' there can only be one ''b'', since there can only be one ''a'' at most. This
  means there is no point in further indexing column ''b'' (unless for covering
  index purposes). There is no added value in terms of cardinality or
  selectivity.
* UNIQUE KEY idx_1 (a), UNIQUE KEY idx_2 (a, b): continuing the above case,
  there is no need to declare that (''a'', ''b'') is UNIQUE, since ''a'' is known to
  be unique. It follows that KEY suffices for idx_2. Thus it also follows that
  idx_2 is redundant.
* KEY idx_1 (a), KEY idx_2 (a(10)): idx_2 only indexes 1st 10 characters of
  ''a''. idx_1 indexes all characters. idx_2 is redundant.
* KEY idx_1 (a), UNIQUE KEY idx_2 (a(10)): idx_2 forces 1st 10 characters of
  ''a'' to be UNIQUE. There is no added value to idx_1 (see preliminary
  discussion). idx_1 is redundant.

Sample cases where no key is redundant:

* KEY idx_1 (a), KEY idx_2 (b): obviously, there''s nothing in common between
  the two keys.
* KEY idx_1 (a), KEY idx_2 (b, a): since order of column within an index is
  important, idx_2 cannot answer for ''a''-only queries (except by perhaps
  providing full index scan, outside our interest, see preliminary
  discussion). idx_1 therefore answers for queries not solvable by idx_2.
* KEY idx_1 (a, b), KEY idx_2 (b, a): both indexes answer for different cases.
  On some access types, there is some form of waste in definition: in a many-
  to-many connecting table, where all queries use equality filtering (i.e.
  ''WHERE a = ?'' as opposed to ''WHERE a > ?''), idx_1 may suffice with indexing
  ''a'' only. However, with range condition this changes and both keys may be
  required.
* UNIQUE KEY idx_1 (a, b), KEY idx_2 (b, a): same as above.
* UNIQUE KEY idx_1 (a, b), UNIQUE KEY idx_2 (b, a): the UNIQUE constraint on
  either key is not strictly required. However this does not make the index
  itself redundant. As a side note, UNIQUE constraints are extremely helpful
  for MySQL query optimizer.
* KEY idx_1 (a), KEY idx_2 (a(10), b): ''a'' is text column, and idx_2 only
  indexes 1st 10 characters (subpart index). If any row contains more than 10
  characters for ''a'', idx_1 provides with indexing not supported by idx_2, and
  is therefore not redundant.
* UNIQUE KEY idx_1 (a), KEY idx_2 (a(10), b): even stricter than the above.
* KEY idx_1 (a), UNIQUE KEY idx_2 (a(10), b): idx_2 does NOT force any
  uniqueness on ''a'' itself. It indexes less characters than idx_1. idx_1 is
  not redundant; nor is idx_2.


STRUCTURE



       mysql> DESC common_schema.redundant_keys;
       +----------------------------+--------------+------+-----+--------
       -+-------+
       | Field                      | Type         | Null | Key | Default
       | Extra |
       +----------------------------+--------------+------+-----+--------
       -+-------+
       | table_schema               | varchar(64)  | NO   |     |
       |       |
       | table_name                 | varchar(64)  | NO   |     |
       |       |
       | redundant_index_name       | varchar(64)  | NO   |     |
       |       |
       | redundant_index_columns    | longtext     | YES  |     | NULL
       |       |
       | redundant_index_non_unique | bigint(1)    | YES  |     | NULL
       |       |
       | dominant_index_name        | varchar(64)  | NO   |     |
       |       |
       | dominant_index_columns     | longtext     | YES  |     | NULL
       |       |
       | dominant_index_non_unique  | bigint(1)    | YES  |     | NULL
       |       |
       | subpart_exists             | int(1)       | NO   |     | 0
       |       |
       | sql_drop_index             | varchar(223) | YES  |     | NULL
       |       |
       +----------------------------+--------------+------+-----+--------
       -+-------+



SYNOPSIS

Columns of this view:

* table_schema: schema of table with redundant index
* table_name: table with redundant index
* redundant_index_name: name of index suspected as redundant
* redundant_index_columns: column covered by redundant index, comma separated,
  by order of definitions
* redundant_index_non_unique: 0 if redundant index is UNIQUE; 1 if non-unique
* dominant_index_name: name of index "covering for" the redundant index. This
  index is responsible for the redundant index to be redundant.
* dominant_index_columns: column covered by dominant index, comma separated,
  by order of definitions
* dominant_index_non_unique: 0 if dominant index is UNIQUE; 1 if non-unique
* subpart_exists: 1 if either redundant or dominant keys use string subpart
  (indexing a prefix of a textual column); this calls for triple-check on the
  nature of both keys.
* sql_drop_index: SQL statement to drop redundant index.
  Use with eval() to apply query.


EXAMPLES

Detect duplicate keys on sakila.actor:


       mysql> ALTER TABLE `sakila`.`actor` ADD INDEX `actor_id_idx`
       (`actor_id`);

       mysql> ALTER TABLE `sakila`.`actor` ADD INDEX
       `last_and_first_names_idx` (`last_name`, `first_name`);

       mysql> ALTER TABLE `sakila`.`film_actor` ADD UNIQUE KEY
       `film_and_actor_ids_idx` (`film_id`, `actor_id`);

       mysql> SELECT * FROM common_schema.redundant_keys \\G
       *************************** 1. row ***************************
                     table_schema: sakila
                       table_name: actor
             redundant_index_name: idx_actor_last_name
          redundant_index_columns: last_name
       redundant_index_non_unique: 1
              dominant_index_name: last_and_first_names_idx
           dominant_index_columns: last_name,first_name
        dominant_index_non_unique: 1
                   subpart_exists: 0
                   sql_drop_index: ALTER TABLE `sakila`.`actor` DROP
       INDEX `idx_actor_last_name`
       *************************** 2. row ***************************
                     table_schema: sakila
                       table_name: actor
             redundant_index_name: actor_id_idx
          redundant_index_columns: actor_id
       redundant_index_non_unique: 1
              dominant_index_name: PRIMARY
           dominant_index_columns: actor_id
        dominant_index_non_unique: 0
                   subpart_exists: 0
                   sql_drop_index: ALTER TABLE `sakila`.`actor` DROP
       INDEX `actor_id_idx`
       *************************** 3. row ***************************
                     table_schema: sakila
                       table_name: film_actor
             redundant_index_name: idx_fk_film_id
          redundant_index_columns: film_id
       redundant_index_non_unique: 1
              dominant_index_name: film_and_actor_ids_idx
           dominant_index_columns: film_id,actor_id
        dominant_index_non_unique: 0
                   subpart_exists: 0
                   sql_drop_index: ALTER TABLE `sakila`.`film_actor` DROP
       INDEX `idx_fk_film_id`



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

candidate_keys, no_pk_innodb_tables, sql_foreign_keys

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('repeat_exec','
NAME

repeat_exec(): Repeatedly executes given query or queries until some condition
holds.

TYPE

Procedure

DESCRIPTION

This procedure repeats execution of query or queries, on a given interval. It
terminates according to a given condition, which may be one of several types
(see following), including dynamic calculation.
The procedure is essentially a repeat-until looping device. It is tailored to
fit common use case scenarios, such as repeat-until no more rows are affected
or repeat-until some time has passed. Use cases range from breaking down huge
transactions to smaller ones, through load testing, to data access &
manipulation simulation.
It calls upon exec() for query execution. Queries may be of varying types
(DML, DDL, other commands). See exec().
Invoker of this procedure must have the privileges required for execution of
given queries.

SYNOPSIS



       repeat_exec(interval_seconds DOUBLE, execute_queries TEXT CHARSET
       utf8, stop_condition TEXT CHARSET utf8)


Input:

* interval_seconds: number of seconds to sleep between invocation of queries.
  This value can be a floating point number, e.g. 0.1 indicates one-tenth of a
  second.
  repeat_exec() begins with query execution, then follows on to sleeping. Once
  the stop_condition is met, no more sleeping is performed.
* execute_queries: one or more queries to execute per loop iteration.
  Queries are separated by semicolons (;). See exec() for details.
* stop_condition: the condition by which the loop terminates. Can be in one of
  several forms and formats:

  o NULL: no stop condition. The loop is infinite.
  o 0: The loop terminates when no rows are affected by query (if multiple
    queries specified, loop terminates when no rows are affected by last of
    queries). This is in particular useful for DELETE or UPDATE statements,
    see examples.
  o A positive integer (1, 2, 3, ...): loop terminates after given number of
    iterations.
  o Short time format (e.g. ''30s'', ''45m'', ''2h''): loop terminates after
    specified time has passed. See shorttime_to_seconds() for more on short
    time format.
  o a SELECT query: query is re-evaluated at the end of each iteration. Loop
    terminates when query evaluates to a TRUE value. The query must return
    with one single row and one single value.


Since the routines relies on exec(), it accepts the following input config:

* @common_schema_dryrun: when 1, queries are not executed, but rather printed.
* @common_schema_verbose: when 1, queries are verbosed.

Output:

* Whatever output the queries may produce.


EXAMPLES

DELETE all rows matching some condition. Break a potentially huge DELETE (e.g.
500,000 rows) into smaller chunks, as follows:

* sleep_time is 2 seconds
* execute_queries only deletes 1000 rows at a time
* stop_condition is set to 0, meaning the query terminates when no more rows
  are affected, i.e., all matching rows have been deleted.

This makes for smaller transactions, less locks, and better replication slave
catch-up:


       mysql> call repeat_exec(2,
       	  ''DELETE FROM sakila.rental WHERE customer_id=7 ORDER BY
       rental_id LIMIT 1000'',
       	  0);


Make a 15 seconds random INSERT, UPDATE and DELETE access pattern:


       mysql> call repeat_exec(0.01,
       	  ''UPDATE world.City SET Name=MD5(RAND()) WHERE id=FLOOR(RAND
       ()*4000); INSERT INTO world.City (Name, Population) VALUES (MD5
       (RAND()), 0); DELETE FROM world.City WHERE id=FLOOR(RAND
       ()*4000);'',
       	  ''15s'');


Execute a query until some dynamic condition holds:


       mysql> call repeat_exec(0.5,
       	  ''DELETE FROM sakila.rental WHERE customer_id=7 ORDER BY
       rental_id LIMIT 100'',
       	  ''SELECT SUM(customer_id = 7) < SUM(customer_id = 3) FROM
       sakila.rental'');



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

exec(), exec_single(), foreach()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('replace_all','
NAME

replace_all(): Replaces characters in a given text with a given replace-text.

TYPE

Function

DESCRIPTION

This function replaces any appearance of character within a given set, with a
replace-text.

SYNOPSIS



       replace_all(txt TEXT CHARSET utf8, from_characters VARCHAR(1024)
       CHARSET utf8, to_str TEXT CHARSET utf8)
         RETURNS TEXT CHARSET utf8


Input:

* txt: input text, on which to work the search/replace. It is unmodified.
* from_characters: a set of characters. Any appearance of any character within
  this set makes for a replace action.
* to_str: text to be injected in place of any character in from_characters.
  Can be an empty text, which makes for a deletion of any character in the
  set.


EXAMPLES

Replace any appearance of comma, colon & semicolon with a pipeline:


       SELECT replace_all(''common_schema: routines, views;tables'', '';:,'',
       ''|'') AS replaced_text;
       +---------------------------------------+
       | replaced_text                         |
       +---------------------------------------+
       | common_schema| routines| views|tables |
       +---------------------------------------+


As above, include whitespace (note that adjacent characters are NOT
compressed)


       SELECT replace_all(''common_schema: routines, views;tables'', '';:,
       \\t'', ''|'') AS replaced_text;
       +---------------------------------------+
       | replaced_text                         |
       +---------------------------------------+
       | common_schema||routines||views|tables |
       +---------------------------------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

trim_wspace()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('routine_privileges','
NAME

routine_privileges: INFORMATION_SCHEMA-like view on routines privileges

TYPE

View

DESCRIPTION

INFORMATION_SCHEMA maps the mysql privileges tables into *_PRIVILEGES views.
However, it only maps users, db, tables_priv, columns_priv, and it fails
mapping the procs_priv table. This is an inconsistency within
INFORMATION_SCHEMA (see bug_#61596).
routine_privileges implements what the author believes to be the definition of
ROUTINE_PRIVILEGES within INFORMATION_SCHEMA should be. It follows up on the
*_PRIVILEGES tables conventions.
The view presents with grantees, and their set of privileges on specific
routines (functions & procedures).

STRUCTURE



       mysql> DESC routine_privileges;
       +-----------------+------------------------------+------+-----+---
       ------+-------+
       | Field           | Type                         | Null | Key |
       Default | Extra |
       +-----------------+------------------------------+------+-----+---
       ------+-------+
       | GRANTEE         | varchar(81)                  | YES  |     |
       NULL    |       |
       | ROUTINE_CATALOG | binary(0)                    | YES  |     |
       NULL    |       |
       | ROUTINE_SCHEMA  | char(64)                     | NO   |     |
       |       |
       | ROUTINE_NAME    | char(64)                     | NO   |     |
       |       |
       | ROUTINE_TYPE    | enum(''FUNCTION'',''PROCEDURE'') | NO   |     |
       NULL    |       |
       | PRIVILEGE_TYPE  | varchar(27)                  | YES  |     |
       NULL    |       |
       | IS_GRANTABLE    | varchar(3)                   | NO   |     |
       |       |
       +-----------------+------------------------------+------+-----+---
       ------+-------+



SYNOPSIS

Columns of this view:

* GRANTEE: grantee''s account
* ROUTINE_CATALOG: unused; NULL
* ROUTINE_SCHEMA: schema in which routines is located
* ROUTINE_NAME: name of routine
* ROUTINE_TYPE: ''FUNCTION'' or ''PROECEDURE''
* PRIVILEGE_TYPE: single privilege (e.g. ''EXECUTE'' or ''ALTER ROUTINE'')
* IS_GRANTABLE: whether the grantee is grantable on this routine. This is a
  de-normalized column, following the convention of the *_PRIVILEGES tables in
  INFORMATION_SCHEMA

The view is denormalized. While the mysql.procs_privs table lists the set of
privileges per account in one row, this view breaks the privileges to distinct
rows. Also, the ''Grant'' privilege is not listed on its own, but rather as an
extra column.

EXAMPLES



       mysql> SELECT * FROM common_schema.routine_privileges ORDER BY
       GRANTEE, ROUTINE_SCHEMA, ROUTINE_NAME;
       +--------------------------+-----------------+----------------+---
       -------------------------+--------------+----------------+--------
       ------+
       | GRANTEE                  | ROUTINE_CATALOG | ROUTINE_SCHEMA |
       ROUTINE_NAME               | ROUTINE_TYPE | PRIVILEGE_TYPE |
       IS_GRANTABLE |
       +--------------------------+-----------------+----------------+---
       -------------------------+--------------+----------------+--------
       ------+
       | ''apps''@''%''               | NULL            | sakila         |
       get_customer_balance       | FUNCTION     | EXECUTE        | YES
       |
       | ''other_user''@''localhost'' | NULL            | sakila         |
       film_in_stock              | PROCEDURE    | ALTER ROUTINE  | NO
       |
       | ''other_user''@''localhost'' | NULL            | sakila         |
       film_in_stock              | PROCEDURE    | EXECUTE        | NO
       |
       | ''other_user''@''localhost'' | NULL            | sakila         |
       get_customer_balance       | FUNCTION     | ALTER ROUTINE  | NO
       |
       | ''other_user''@''localhost'' | NULL            | sakila         |
       get_customer_balance       | FUNCTION     | EXECUTE        | NO
       |
       | ''other_user''@''localhost'' | NULL            | sakila         |
       inventory_held_by_customer | FUNCTION     | ALTER ROUTINE  | NO
       |
       | ''other_user''@''localhost'' | NULL            | sakila         |
       inventory_held_by_customer | FUNCTION     | EXECUTE        | NO
       |
       | ''world_user''@''localhost'' | NULL            | sakila         |
       get_customer_balance       | FUNCTION     | EXECUTE        | YES
       |
       | ''world_user''@''localhost'' | NULL            | sakila         |
       get_customer_balance       | FUNCTION     | ALTER ROUTINE  | YES
       |
       +--------------------------+-----------------+----------------+---
       -------------------------+--------------+----------------+--------
       ------+


Compare with:


       mysql> SELECT * FROM mysql.procs_priv;
       +-----------+--------+------------+----------------------------+--
       ------------+----------------+-----------------------------+------
       ---------------+
       | Host      | Db     | User       | Routine_name               |
       Routine_type | Grantor        | Proc_priv                   |
       Timestamp           |
       +-----------+--------+------------+----------------------------+--
       ------------+----------------+-----------------------------+------
       ---------------+
       | %         | sakila | apps       | get_customer_balance       |
       FUNCTION     | root@localhost | Execute,Grant               |
       2011-06-22 14:29:01 |
       | localhost | sakila | world_user | get_customer_balance       |
       FUNCTION     | root@localhost | Execute,Alter Routine,Grant |
       2011-06-22 14:29:18 |
       | localhost | sakila | other_user | get_customer_balance       |
       FUNCTION     | root@localhost | Execute,Alter Routine       |
       2011-06-22 14:29:25 |
       | localhost | sakila | other_user | inventory_held_by_customer |
       FUNCTION     | root@localhost | Execute,Alter Routine       |
       2011-06-22 14:30:12 |
       | localhost | sakila | other_user | film_in_stock              |
       PROCEDURE    | root@localhost | Execute,Alter Routine       |
       2011-06-22 14:30:46 |
       +-----------+--------+------------+----------------------------+--
       ------------+----------------+-----------------------------+------
       ---------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

sql_grants

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('routines','
NAME

routines: Complement INFORMATION_SCHEMA.ROUTINES missing info.

TYPE

View

DESCRIPTION

routines complements the INFORMATION_SCHEMA.ROUTINES view by adding the
missing param_list column in version 5.1. This column denotes the parameters
provided to the routine.

STRUCTURE



       mysql> DESC routines;
       +----------------------+---------------+------+-----+-------------
       --------+-------+
       | Field                | Type          | Null | Key | Default
       | Extra |
       +----------------------+---------------+------+-----+-------------
       --------+-------+
       | SPECIFIC_NAME        | varchar(64)   | NO   |     |
       |       |
       | ROUTINE_CATALOG      | varchar(512)  | YES  |     | NULL
       |       |
       | ROUTINE_SCHEMA       | varchar(64)   | NO   |     |
       |       |
       | ROUTINE_NAME         | varchar(64)   | NO   |     |
       |       |
       | ROUTINE_TYPE         | varchar(9)    | NO   |     |
       |       |
       | DTD_IDENTIFIER       | varchar(64)   | YES  |     | NULL
       |       |
       | ROUTINE_BODY         | varchar(8)    | NO   |     |
       |       |
       | ROUTINE_DEFINITION   | longtext      | YES  |     | NULL
       |       |
       | EXTERNAL_NAME        | varchar(64)   | YES  |     | NULL
       |       |
       | EXTERNAL_LANGUAGE    | varchar(64)   | YES  |     | NULL
       |       |
       | PARAMETER_STYLE      | varchar(8)    | NO   |     |
       |       |
       | IS_DETERMINISTIC     | varchar(3)    | NO   |     |
       |       |
       | SQL_DATA_ACCESS      | varchar(64)   | NO   |     |
       |       |
       | SQL_PATH             | varchar(64)   | YES  |     | NULL
       |       |
       | SECURITY_TYPE        | varchar(7)    | NO   |     |
       |       |
       | CREATED              | datetime      | NO   |     | 0000-00-00
       00:00:00 |       |
       | LAST_ALTERED         | datetime      | NO   |     | 0000-00-00
       00:00:00 |       |
       | SQL_MODE             | varchar(8192) | NO   |     |
       |       |
       | ROUTINE_COMMENT      | varchar(64)   | NO   |     |
       |       |
       | DEFINER              | varchar(77)   | NO   |     |
       |       |
       | CHARACTER_SET_CLIENT | varchar(32)   | NO   |     |
       |       |
       | COLLATION_CONNECTION | varchar(32)   | NO   |     |
       |       |
       | DATABASE_COLLATION   | varchar(32)   | NO   |     |
       |       |
       | param_list           | blob          | NO   |     | NULL
       |       |
       +----------------------+---------------+------+-----+-------------
       --------+-------+



SYNOPSIS

Columns of this view are identical to those of INFORMATION_SCHEMA.ROUTINES,
with the addition of the param_list column

* param_list: parameters passed to routine


EXAMPLES



       mysql> SELECT ROUTINE_NAME, ROUTINE_TYPE, REPLACE(param_list,
       ''\\n'', '''') as params FROM routines WHERE ROUTINE_SCHEMA=''sakila'';
       +----------------------------+--------------+---------------------
       ------------------------------------------------------------------
       ------------------------------------------------+
       | ROUTINE_NAME               | ROUTINE_TYPE | params
       |
       +----------------------------+--------------+---------------------
       ------------------------------------------------------------------
       ------------------------------------------------+
       | film_in_stock              | PROCEDURE    | IN p_film_id INT, IN
       p_store_id INT, OUT p_film_count INT
       |
       | film_not_in_stock          | PROCEDURE    | IN p_film_id INT, IN
       p_store_id INT, OUT p_film_count INT
       |
       | get_customer_balance       | FUNCTION     | p_customer_id INT,
       p_effective_date DATETIME
       |
       | inventory_held_by_customer | FUNCTION     | p_inventory_id INT
       |
       | inventory_in_stock         | FUNCTION     | p_inventory_id INT
       |
       | rewards_report             | PROCEDURE    |     IN
       min_monthly_purchases TINYINT UNSIGNED    , IN
       min_dollar_amount_purchased DECIMAL(10,2) UNSIGNED    , OUT
       count_rewardees INT |
       +----------------------------+--------------+---------------------
       ------------------------------------------------------------------
       ------------------------------------------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

routine_privileges

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('run','
NAME

run(): Executes a QueryScript.

TYPE

Procedure

DESCRIPTION

This procedure accepts a QueryScript text, and invokes the script.
run() is the main entry point for QueryScript.
run() will first scan the code for script syntax errors. Any such error aborts
operation. Only when satisfied, is the code executed. Hence, although a
QueryScript code is interpreted, syntax errors are intercepted before any code
executes. It should be noted that SQL syntax errors are not examined, only
script syntax error. Read more on Execution.
Failure of execution or interpretation is prompted to the user. The
@common_schema_error variables is set with the relevant error message.
Invoker of this procedure must have the privileges required for execution of
queries in the script.

SYNOPSIS



       run(IN query_script text)
         MODIFIES SQL DATA


Input:

* query_script: a QueryScript text. run() also accepts a filename, if it
  starts with a slash (/) or a backslash (\\).

Invocation of run() is likely to generate many warnings. These should be
ignored, and are part of the general workflow (e.g. removing some temporary
tables if they exist).

EXAMPLES

Execute an inlined script:


       mysql> call run("
         foreach($x : 1:8)
         {
           CREATE DATABASE shard_:$x;
         }
         SHOW DATABASES LIKE ''shard_%'';
       ");

       +--------------------+
       | Database (shard_%) |
       +--------------------+
       | shard_1            |
       | shard_2            |
       | shard_3            |
       | shard_4            |
       | shard_5            |
       | shard_6            |
       | shard_7            |
       | shard_8            |
       +--------------------+


The above assumes no ANSI_QUOTES in sql_mode.
Run script stored in user defined text variable. Repeatedly execute random
queries until 5pm:


       mysql> SET @script := "
       while (TIME(SYSDATE()) < ''17:00:00'')
         SELECT * FROM world.City WHERE id = 1 + FLOOR((RAND()*4079));
       ";
       mysql> call run(@script);



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

Query_Script, run_file()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('run_file','
NAME

run_file(): Executes a QueryScript from file.

TYPE

Procedure

DESCRIPTION

This procedure accepts a server-side file name, containing a QueryScript text,
and invokes the script.
run_file() is a convenience method. It merely refers to run(). Also note that
run() may also accept file name as input, but has to guess that given input is
indeed file name, whereas run_file() trusts input to be file name. with
content of indicated file.
Invoker of this procedure must have the privileges required for execution of
queries in the script.

SYNOPSIS



       run_file(IN query_script_file_name TEXT)
         MODIFIES SQL DATA


Input: name of text file containing QueryScript code.

EXAMPLES

Execute script from file:


       mysql> call run_file(''/mount/scripts/maintain.qs'');



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

Query_Script, run()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('schema_analysis_routines','
SYNOPSIS

Schema analysis routines: stored routines providing information on schema
definitions

* table_exists(): Check if specified table exists.


DESCRIPTION

Schema analysis routines provide with direct and efficient access to schema
metadata.
');
		
			INSERT INTO common_schema.help_content VALUES ('schema_analysis_views','
SYNOPSIS

Schema analysis views: a collection of views, analyzing schema design, listing
design errors, generating SQL statements based on schema design

* candidate_keys: Listing of prioritized candidate keys: keys which are
  UNIQUE, by order of best-use.
* candidate_keys_recommended: Recommended candidate key per table.
* no_pk_innodb_tables: List InnoDB tables where no PRIMARY KEY is defined
* redundant_keys: List indexes which are made redundant (or duplicate) by
  other (dominant) keys.
* routines: Complement INFORMATION_SCHEMA.ROUTINES missing info.
* sql_alter_table: Generate ALTER TABLE SQL statements per table, with engine
  and create options
* sql_foreign_keys: Generate create/drop foreign key constraints SQL
  statements
* sql_range_partitions: Generate SQL statements for managing range partitions
* table_charset: List tables, their character sets and collations
* text_columns: List textual columns character sets & collations


DESCRIPTION

Views in this category perform various schema analysis operations or offer SQL
generation code cased on schema analysis.

EXAMPLES

Detect duplicate keys on sakila.actor:


       mysql> ALTER TABLE `sakila`.`actor` ADD INDEX `actor_id_idx`
       (`actor_id`);
       mysql> ALTER TABLE `sakila`.`actor` ADD INDEX
       `last_and_first_names_idx` (`last_name`, `first_name`);
       mysql> ALTER TABLE `sakila`.`film_actor` ADD UNIQUE KEY
       `film_and_actor_ids_idx` (`film_id`, `actor_id`);

       mysql> SELECT * FROM common_schema.redundant_keys \\G
       *************************** 1. row ***************************
                     table_schema: sakila
                       table_name: actor
             redundant_index_name: idx_actor_last_name
          redundant_index_columns: last_name
       redundant_index_non_unique: 1
              dominant_index_name: last_and_first_names_idx
           dominant_index_columns: last_name,first_name
        dominant_index_non_unique: 1
                   subpart_exists: 0
                   sql_drop_index: ALTER TABLE `sakila`.`actor` DROP
       INDEX `idx_actor_last_name`
       *************************** 2. row ***************************
                     table_schema: sakila
                       table_name: actor
             redundant_index_name: actor_id_idx
          redundant_index_columns: actor_id
       redundant_index_non_unique: 1
              dominant_index_name: PRIMARY
           dominant_index_columns: actor_id
        dominant_index_non_unique: 0
                   subpart_exists: 0
                   sql_drop_index: ALTER TABLE `sakila`.`actor` DROP
       INDEX `actor_id_idx`
       *************************** 3. row ***************************
                     table_schema: sakila
                       table_name: film_actor
             redundant_index_name: idx_fk_film_id
          redundant_index_columns: film_id
       redundant_index_non_unique: 1
              dominant_index_name: film_and_actor_ids_idx
           dominant_index_columns: film_id,actor_id
        dominant_index_non_unique: 0
                   subpart_exists: 0
                   sql_drop_index: ALTER TABLE `sakila`.`film_actor` DROP
       INDEX `idx_fk_film_id`


Show recommended candidate keys for tables in sakila


       mysql> SELECT * FROM common_schema.candidate_keys_recommended
       WHERE TABLE_SCHEMA=''sakila'';
       +--------------+---------------+------------------------+---------
       -----+------------+--------------+
       | table_schema | table_name    | recommended_index_name |
       has_nullable | is_primary | column_names |
       +--------------+---------------+------------------------+---------
       -----+------------+--------------+
       | sakila       | actor         | PRIMARY                |
       0 |          1 | actor_id     |
       | sakila       | address       | PRIMARY                |
       0 |          1 | address_id   |
       | sakila       | category      | PRIMARY                |
       0 |          1 | category_id  |
       | sakila       | city          | PRIMARY                |
       0 |          1 | city_id      |
       | sakila       | country       | PRIMARY                |
       0 |          1 | country_id   |
       | sakila       | customer      | PRIMARY                |
       0 |          1 | customer_id  |
       | sakila       | film          | PRIMARY                |
       0 |          1 | film_id      |
       | sakila       | film_actor    | PRIMARY                |
       0 |          1 | actor_id     |
       | sakila       | film_category | PRIMARY                |
       0 |          1 | film_id      |
       | sakila       | film_text     | PRIMARY                |
       0 |          1 | film_id      |
       | sakila       | inventory     | PRIMARY                |
       0 |          1 | inventory_id |
       | sakila       | language      | PRIMARY                |
       0 |          1 | language_id  |
       | sakila       | payment       | PRIMARY                |
       0 |          1 | payment_id   |
       | sakila       | rental        | PRIMARY                |
       0 |          1 | rental_id    |
       | sakila       | staff         | PRIMARY                |
       0 |          1 | staff_id     |
       | sakila       | store         | PRIMARY                |
       0 |          1 | store_id     |
       +--------------+---------------+------------------------+---------
       -----+------------+--------------+


');
		
			INSERT INTO common_schema.help_content VALUES ('script_runtime','
NAME

script_runtime(): return number of seconds elapsed since script execution
began.

TYPE

Function

DESCRIPTION

This function returns the number of seconds elapsed since current QueryScript
execution was launched.
It only makes sense to call this function from within a script (otherwise
results are undefined).
script_runtime() returns a DOUBLE value, to support MySQL versions with
subsecond resolution. Versions not supporting subsecond resolution (e.g.
standard MySQL 5.1) will return with round values, which have an error margin
of one second.

SYNOPSIS



       script_runtime()
         RETURNS DOUBLE



EXAMPLES

For 30 seconds, issue random queries against some table:


       while (script_runtime() < 30)
       {
         SELECT * FROM my_table WHERE id = RAND() * 100000;
       }



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

QueryScript

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('security_audit','
NAME

security_audit(): Generate a server''s security audit report.

TYPE

Procedure

DESCRIPTION

Audit a server''s security setup, including reviewing accounts and settings.
This audit generates a human readable report with recommendations on actions
to take so as to enhance server security. It does not take action nor modify
any data.
security_audit() reviews the following:

* Non-local root accounts
* Anonymous users
* Accounts accessible by any host
* Password-less accounts
* Accounts sharing same password
* Non-root accounts with admin privileges
* Non-root accounts with global DDL privileges
* Non-root accounts with global DML privileges
* sql_mode
* Old passwords


SYNOPSIS



       security_audit()
         READS SQL DATA


This procedure takes no input.

EXAMPLES

Audit a server:


       mysql> CALL security_audit();
       +-----------------------------------------------------------------
       -------------+
       | report
       |
       +-----------------------------------------------------------------
       -------------+
       |
       |
       | Checking for non-local root accounts
       |
       | ====================================
       |
       | Recommendation: limit following root accounts to local machines
       |
       | > rename ''root''@''central'' to ''root''@''localhost''
       |
       |
       |
       | Checking for anonymous users
       |
       | ============================
       |
       | OK
       |
       |
       |
       | Looking for accounts accessible from any host
       |
       | =============================================
       |
       | Recommendation: limit following accounts to specific hosts/
       subnet            |
       | > rename user ''apps''@''%'' to ''apps''@''<specific host>''
       |
       | > rename user ''world_user''@''%'' to ''world_user''@''<specific host>''
       |
       |
       |
       | Checking for accounts with empty passwords
       |
       | ==========================================
       |
       | Recommendation: set a decent password to these accounts.
       |
       | > set password for ''apps''@''%'' = PASSWORD(...)
       |
       | > set password for ''world_user''@''localhost'' = PASSWORD(...)
       |
       | > set password for ''wu''@''localhost'' = PASSWORD(...)
       |
       |
       |
       | Looking for accounts with identical (non empty) passwords
       |
       | =========================================================
       |
       | Different users should not share same password.
       |
       | Recommendation: Change passwords for accounts listed below.
       |
       |
       |
       | The following accounts share the same password:
       |
       | ''temp''@''10.0.%''
       |
       | ''temp''@''10.0.0.%''
       |
       | ''gromit''@''localhost''
       |
       |
       |
       | The following accounts share the same password:
       |
       | ''replication''@''10.0.0.%''
       |
       | ''shlomi''@''localhost''
       |
       |
       |
       | The following accounts share the same password:
       |
       | ''shlomi''@''127.0.0.1''
       |
       | ''monitoring_user''@''localhost''
       |
       |
       |
       | Looking for (non-root) accounts with admin privileges
       |
       | =====================================================
       |
       | Normal users should not have admin privileges, such as
       |
       | SUPER, SHUTDOWN, RELOAD, PROCESS, CREATE USER, REPLICATION
       CLIENT.           |
       | Recommendation: limit privileges to following accounts.
       |
       | > GRANT <non-admin-privileges> ON *.* TO
       ''monitoring_user''@''localhost''       |
       | > GRANT <non-admin-privileges> ON *.* TO ''shlomi''@''localhost''
       |
       |
       |
       | Looking for (non-root) accounts with global DDL privileges
       |
       | ==========================================================
       |
       | OK
       |
       |
       |
       | Looking for (non-root) accounts with global DML privileges
       |
       | ==========================================================
       |
       | OK
       |
       |
       |
       | Testing sql_mode
       |
       | ================
       |
       | Server''s sql_mode does not include NO_AUTO_CREATE_USER.
       |
       | This means users can be created with empty passwords.
       |
       | Recommendation: add NO_AUTO_CREATE_USER to sql_mode,
       |
       | both in config file as well as dynamically.
       |
       | > SET @@global.sql_mode := CONCAT(@@global.sql_mode,
       '',NO_AUTO_CREATE_USER'') |
       |
       |
       | Testing old_passwords
       |
       | =====================
       |
       | OK
       |
       |
       |
       | Checking for `test` database
       |
       | ============================
       |
       | `test` database has been found.
       |
       | `test` is a special database where any user can create, drop and
       manipulate  |
       | table data. Recommendation: drop it
       |
       | > DROP DATABASE `test`
       |
       | --
       -
       |
       | Report generated on ''2012-09-21 11:49:52
       |
       +-----------------------------------------------------------------
       -------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

killall, processlist_grantees, sql_accounts

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('security_routines','
SYNOPSIS

Security routines: stored functions managing security and privileges
information.

* duplicate_grantee(): Create new account (grantee), identical to given
  account.
* killall(): Kill connections with by matching GRANTEE, user or host.
* match_grantee(): Match an existing account based on user+host.
* mysql_grantee(): Return a qualified MySQL grantee (account) based on user
  and host.
* security_audit(): Generate a server''s security audit report.


EXAMPLES

Kill all connections made by the ''analytics` user:


       mysql> CALL killall(''analytics'');


Duplicate (Copy+Paste) an existing account into a new one:


       mysql> CALL duplicate_grantee(''apps@localhost'', ''apps@10.0.0.%'');


Audit server''s security:


       mysql> CALL security_audit();
       +-----------------------------------------------------------------
       -------------+
       | report
       |
       +-----------------------------------------------------------------
       -------------+
       |
       |
       | Checking for non-local root accounts
       |
       | ====================================
       |
       | Recommendation: limit following root accounts to local machines
       |
       | > rename ''root''@''central'' to ''root''@''localhost''
       |
       |
       |
       | Checking for anonymous users
       |
       | ============================
       |
       | OK
       |
       |
       |
       | Looking for accounts accessible from any host
       |
       | =============================================
       |
       | Recommendation: limit following accounts to specific hosts/
       subnet            |
       | > rename user ''apps''@''%'' to ''apps''@''<specific host>''
       |
       | > rename user ''world_user''@''%'' to ''world_user''@''<specific host>''
       |
       |
       |
       | Checking for accounts with empty passwords
       |
       | ==========================================
       |
       | Recommendation: set a decent password to these accounts.
       |
       | > set password for ''apps''@''%'' = PASSWORD(...)
       |
       | > set password for ''world_user''@''localhost'' = PASSWORD(...)
       |
       | > set password for ''wu''@''localhost'' = PASSWORD(...)
       |
       |
       |
       | Looking for accounts with identical (non empty) passwords
       |
       | =========================================================
       |
       | Different users should not share same password.
       |
       | Recommendation: Change passwords for accounts listed below.
       |
       |
       |
       | The following accounts share the same password:
       |
       | ''temp''@''10.0.%''
       |
       | ''temp''@''10.0.0.%''
       |
       | ''gromit''@''localhost''
       |
       |
       |
       | The following accounts share the same password:
       |
       | ''replication''@''10.0.0.%''
       |
       | ''shlomi''@''localhost''
       |
       |
       |
       | The following accounts share the same password:
       |
       | ''shlomi''@''127.0.0.1''
       |
       | ''monitoring_user''@''localhost''
       |
       |
       |
       | Looking for (non-root) accounts with admin privileges
       |
       | =====================================================
       |
       | Normal users should not have admin privileges, such as
       |
       | SUPER, SHUTDOWN, RELOAD, PROCESS, CREATE USER, REPLICATION
       CLIENT.           |
       | Recommendation: limit privileges to following accounts.
       |
       | > GRANT <non-admin-privileges> ON *.* TO
       ''monitoring_user''@''localhost''       |
       | > GRANT <non-admin-privileges> ON *.* TO ''shlomi''@''localhost''
       |
       |
       |
       | Looking for (non-root) accounts with global DDL privileges
       |
       | ==========================================================
       |
       | OK
       |
       |
       |
       | Looking for (non-root) accounts with global DML privileges
       |
       | ==========================================================
       |
       | OK
       |
       |
       |
       | Testing sql_mode
       |
       | ================
       |
       | Server''s sql_mode does not include NO_AUTO_CREATE_USER.
       |
       | This means users can be created with empty passwords.
       |
       | Recommendation: add NO_AUTO_CREATE_USER to sql_mode,
       |
       | both in config file as well as dynamically.
       |
       | > SET @@global.sql_mode := CONCAT(@@global.sql_mode,
       '',NO_AUTO_CREATE_USER'') |
       |
       |
       | Testing old_passwords
       |
       | =====================
       |
       | OK
       |
       | --
       -
       |
       | Report generated on ''2012-09-21 11:49:52
       |
       +-----------------------------------------------------------------
       -------------+


');
		
			INSERT INTO common_schema.help_content VALUES ('security_views','
SYNOPSIS

Security views: views providing information on grants and privileges.

* routine_privileges: INFORMATION_SCHEMA-like view on routines privileges
* similar_grants: similar_grants: Listing GRANTEEs sharing the same set of
  privileges (i.e. share same role)
* sql_accounts: Generate SQL statements to block/release accounts. Provide
  info on accounts
* sql_grants: Generate SQL GRANT/REVOKE statements for existing accounts;
  provide with GRANT metadata
* sql_show_grants: Generate complete accounts SHOW GRANTS FOR -like output


DESCRIPTION

There are several inconsistencies and missing pieces with regard to security
related information in MySQL. These views compensate for: missing
INFORMATION_SCHEMA routines privileges; missing SHOW GRANTS for all accounts;
SQL generation for GRANT and REVOKE statements.
Closely related are Security_routines and processlist_grantees.

EXAMPLES

Show grants for users called ''world_user'':


       mysql> SELECT sql_grants FROM common_schema.sql_show_grants WHERE
       user=''world_user'' \\G
       *************************** 1. row ***************************
       sql_grants: GRANT USAGE ON *.* TO ''world_user''@''localhost''
       IDENTIFIED BY PASSWORD '''';
       GRANT ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE
       TEMPORARY TABLES, CREATE VIEW, DELETE, DROP, EVENT, EXECUTE,
       INDEX, INSERT, LOCK TABLES, REFERENCES, SELECT, SHOW VIEW,
       TRIGGER, UPDATE ON `world`.* TO ''world_user''@''localhost'';


Block all accounts for user ''gromit'':


       mysql> CALL eval("SELECT sql_block_account FROM sql_accounts WHERE
       USER = ''gromit''");


');
		
			INSERT INTO common_schema.help_content VALUES ('session_unique_id','
NAME

session_unique_id(): Return a unique unsigned integer for this session

TYPE

Function

DESCRIPTION

This function returns unique values per session. That is, any two calls to
this function from within the same session, result with different, unique
values.
The function utilizes the fact that a session is managed serially (it it
generally unsafe and undesired to issue concurrent queries on same
connection). Therefore, it is known that any two calls on this function are
essentially serialized within the session
Current implementation of this function is to return incrementing unsigned
integer values. However, the user should not rely on this behavior, and should
not assume consecutive results on consecutive calls.

SYNOPSIS



       session_unique_id()
         RETURNS INT UNSIGNED


Output:

* A unique value within current session.


EXAMPLES

Get unique values:


       mysql> SELECT session_unique_id(), session_unique_id();
       +---------------------+---------------------+
       | session_unique_id() | session_unique_id() |
       +---------------------+---------------------+
       |                   1 |                   2 |
       +---------------------+---------------------+
       1 row in set (0.02 sec)

       mysql> SELECT session_unique_id();
       +---------------------+
       | session_unique_id() |
       +---------------------+
       |                   3 |
       +---------------------+



     ENVIRONMENT


     MySQL 5.1 or newer


     AUTHOR


     Shlomi Noach

');
		
			INSERT INTO common_schema.help_content VALUES ('shorttime_to_seconds','
NAME

shorttime_to_seconds(): Return the number of seconds represented by the given
short form

TYPE

Function

DESCRIPTION

This function evaluates the number of seconds expressed by the given input.
Input is expected to be in short time format (see following).
The function returns NULL on invalid input: any input which is not in short-
time format, including plain numbers (to emphasize: the input ''12'' is invalid)

SYNOPSIS



       shorttime_to_seconds(shorttime VARCHAR(16) CHARSET ascii)
         RETURNS INT UNSIGNED


Input:

* shorttime: short time format, denoted by a number followed by a unit. Valid
  units are:

  o s (seconds), e.g. ''30s'' makes for 30 seconds.
  o m (minutes), e.g. ''3m'' makes for 3 minutes, resulting with 180 seconds.
  o h (hours), e.g. ''2h'' makes for 2 hours, resulting with 7200 seconds.



EXAMPLES

Parse ''2h'', making for 2 hours:


       mysql> SELECT shorttime_to_seconds(''2h'') as seconds;
       +---------+
       | seconds |
       +---------+
       |    7200 |
       +---------+


Fail on invalid input:


       mysql> SELECT shorttime_to_seconds(''2'') as seconds;
       +---------+
       | seconds |
       +---------+
       |    NULL |
       +---------+



ENVIRONMENT

MySQL 5.1 or newer

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('similar_grants','
NAME

similar_grants: listing GRANTEEs sharing the same set of privileges (i.e.
share same role)

TYPE

View

DESCRIPTION

similar_grants analyzes the GRANTEEs on a server, and groups them by their set
of privileges. GRANTEEs with the exact same set of privileges will reside in
same group. Such groups are commonly referred to as "roles" (though MySQL does
not provide with roles per se).
The view merely presents the list of GRANTEEs within each role; for complete
listing of the privileges given to such GRANTEEs, join with sql_grants or
sql_show_grants.
Passwords are not taken into account when comparing GRANTEEs. It is possible
that GRANTEEs sharing the exact same set of privileges will have different
passwords.

STRUCTURE



       mysql> DESC similar_grants;
       +------------------+-------------+------+-----+---------+-------+
       | Field            | Type        | Null | Key | Default | Extra |
       +------------------+-------------+------+-----+---------+-------+
       | sample_grantee   | varchar(81) | YES  |     | NULL    |       |
       | count_grantees   | bigint(21)  | NO   |     | 0       |       |
       | similar_grantees | longtext    | YES  |     | NULL    |       |
       +------------------+-------------+------+-----+---------+-------+



SYNOPSIS

Columns of this view:

* sample_grantee: a single, representative GRANTEE, in a group of GRANTEEs
  sharing same set of privileges.
* count_grantees: number of GRANTEEs in group.
* similar_grantees: list of GRANTEEs sharing exact same set of privileges.
  This includes the sample_grantee.


EXAMPLES

List all similar grants on a server:


       mysql> SELECT * FROM similar_grants;
       +-------------------------------+----------------+----------------
       ---------------------------------------+
       | sample_grantee                | count_grantees |
       similar_grantees                                      |
       +-------------------------------+----------------+----------------
       ---------------------------------------+
       | ''root''@''127.0.0.1''            |              3 |
       ''root''@''127.0.0.1'',''root''@''myhost'',''root''@''localhost'' |
       | ''repl''@''10.%''                 |              2 |
       ''repl''@''10.%'',''replication''@''10.0.0.%''                |
       | ''apps''@''%''                    |              1 | ''apps''@''%''
       |
       | ''gromit''@''localhost''          |              1 |
       ''gromit''@''localhost''                                  |
       | ''monitoring_user''@''localhost'' |              1 |
       ''monitoring_user''@''localhost''                         |
       +-------------------------------+----------------+----------------
       ---------------------------------------+


In the above, three root accounts have identical grants (set of privileges);
two accounts, ''repl''@''10.%'' and ''replication''@''10.0.0.%'', share identical
grants; three other accounts have a distinct set privileges.

ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

duplicate_grantee(), sql_grants, sql_show_grants

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('slave_hosts','
NAME

slave_hosts: listing of hosts replicating from current server

TYPE

View

DESCRIPTION

slave_hosts lists host names where slaves of this server are located. The view
utilizes processlist_repl and looks for connections issued by replicating
slaves.
No information is provided on the ports on which replicating slaves listen on.

STRUCTURE



       mysql> DESC common_schema.slave_hosts;
       +-------+-------------+------+-----+---------+-------+
       | Field | Type        | Null | Key | Default | Extra |
       +-------+-------------+------+-----+---------+-------+
       | host  | varchar(64) | NO   |     |         |       |
       +-------+-------------+------+-----+---------+-------+



SYNOPSIS

Columns of this view:

* host: host name or IP address of replicating slave, as it appears on
  PROCESSLIST, without port number


EXAMPLES

Show slave hosts on a master machine:


       mysql> SELECT * FROM common_schema.slave_hosts;
       +-----------------+
       | host            |
       +-----------------+
       | sql00.mydomain  |
       | sql02.mydomain  |
       +-----------------+



ENVIRONMENT

MySQL 5.1 or newer.

SEE ALSO

match_grantee(), processlist_per_userhost, processlist_repl,
processlist_summary

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('slave_status','
NAME

slave_status: Provide with slave status info

TYPE

View

DESCRIPTION

slave_status displays minimal information about this server''s slave status.
Its information is generally a subset of SHOW SLAVE STATUS.
A problem with MySQL''s SHOW SLAVE STATUS is that it cannot be read nor used on
server side; one cannot open cursor on this statement. The slave_status view
attempts to provide with as much info (though minimal) about the status of
replication. In particular, the Seconds_Behind_Master value is provided by
this view.
NOTE, this view is experimental.

STRUCTURE



       mysql> DESC common_schema.slave_status;
       +-----------------------+---------------+------+-----+---------+--
       -----+
       | Field                 | Type          | Null | Key | Default |
       Extra |
       +-----------------------+---------------+------+-----+---------+--
       -----+
       | Slave_Connected_time  | decimal(32,0) | YES  |     | NULL    |
       |
       | Slave_IO_Running      | int(1)        | NO   |     | 0       |
       |
       | Slave_SQL_Running     | int(1)        | NO   |     | 0       |
       |
       | Slave_Running         | int(1)        | NO   |     | 0       |
       |
       | Seconds_Behind_Master | decimal(32,0) | YES  |     | NULL    |
       |
       +-----------------------+---------------+------+-----+---------+--
       -----+



SYNOPSIS

Columns of this view:

* Slave_Connected_time: Number of seconds this slave has been connected to its
  master, or NULL if not connected.
* Slave_IO_Running: 1 if the slave I/O thread is currently running, 0
  otherwise.
* Slave_SQL_Running: 1 if the slave SQL thread is currently running, 0
  otherwise.
* Slave_Running: 1 if both IO and SQL threads are running, 0 otherwise.
* Seconds_Behind_Master: number of seconds this server is lagging behind its
  master, or NULL if not replicating.


EXAMPLES

Get slave status on a replicating slave:


       mysql> SELECT * FROM slave_status \\G
       *************************** 1. row ***************************
        Slave_Connected_time: 82077
            Slave_IO_Running: 1
           Slave_SQL_Running: 1
               Slave_Running: 1
       Seconds_Behind_Master: 5


In the above the slave is lagging 5 seconds behind its master. Otherwise,
replication is up and running.

ENVIRONMENT

MySQL 5.1 or newer.

SEE ALSO

processlist_repl, processlist_top

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('split_token','
NAME

split_token(): Return substring by index in delimited text.

TYPE

Function

DESCRIPTION

This function splits the input text txt into tokens, according to given
delimiter_text. It returns a single token, indicated by the 1-based
token_index.
The function is a shortcut to the common pattern of using two SUBSTRING_INDEX
() invocations.

SYNOPSIS



       split_token(txt TEXT CHARSET utf8, delimiter_text VARCHAR(255)
       CHARSET utf8, token_index INT UNSIGNED)
         RETURNS TEXT CHARSET utf8


Input:

* txt: text to be parsed. When NULL, the result is NULL.
* delimiter_text: delimiter text; can be zero or more characters.
  When delimiter_text is the empty text (zero characters), function''s result
  is the character in the position of token_index.
* token_index: 1-based index. At current, there is no validation that given
  index is within tokenized text''s bounds.


EXAMPLES

Tokenize by space:


       mysql> SELECT common_schema.split_token(''the quick brown fox'', ''
       '', 3) AS token;
       +-------+
       | token |
       +-------+
       | brown |
       +-------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

get_num_tokens(), get_option()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('sql_accounts','
NAME

sql_accounts: Generate SQL statements to block/release accounts. Provide info
on accounts.

TYPE

View

DESCRIPTION

sql_accounts fills in a missing feature in MySQL: the ability to temporarily
block user accounts and release them, without tampering with their privileges.
It hacks its way by modifying and controlling accounts'' passwords in a
symmetric way.
To block an account, this view generates a SQL query which changes the
account''s password into a blocked-password value in such way that:

* It is impossible to log in to the account with the original password
* It is impossible to log in to the account with any other password
* It is possible to detect that the password is a blocked-password
* It is possible to recover the original password

The SQL query to release a blocked account is likewise generated by this view.
In fact, the view provides metadata for each account to explain accounts
status: is it blocked? Is it released? Is the password empty? Old?
By generating the SQL statement to modify the account this view fall well onto
use of eval() (see examples below).
One should note that blocking accounts does not terminate existing account
sessions. To kill existing sessions use the killall() routine.

STRUCTURE



       mysql> DESC common_schema.sql_accounts;
       +---------------------+--------------+------+-----+---------+-----
       --+
       | Field               | Type         | Null | Key | Default |
       Extra |
       +---------------------+--------------+------+-----+---------+-----
       --+
       | user                | char(16)     | NO   |     |         |
       |
       | host                | char(60)     | NO   |     |         |
       |
       | grantee             | varchar(100) | YES  |     | NULL    |
       |
       | password            | char(41)     | NO   |     |         |
       |
       | is_empty_password   | int(1)       | NO   |     | 0       |
       |
       | is_new_password     | int(1)       | NO   |     | 0       |
       |
       | is_old_password     | int(1)       | NO   |     | 0       |
       |
       | is_blocked          | int(1)       | NO   |     | 0       |
       |
       | sql_block_account   | longtext     | YES  |     | NULL    |
       |
       | sql_release_account | varchar(163) | YES  |     | NULL    |
       |
       +---------------------+--------------+------+-----+---------+-----
       --+



SYNOPSIS

Columns of this view:

* user: account user part
* host: account host part
* grantee: grantee name
* password: current password for grantee (as in mysql.user)
* is_empty_password: boolean, 1 if account''s password is empty, 0 otherwise.
* is_new_password: boolean, 1 if password is in new format, 0 otherwise.
* is_old_password: boolean, 1 if password is in old format, 0 otherwise. This
  is the opposite of is_new_password.
  The two columns are mostly informative.
* is_blocked: boolean, 1 if account is currently blocked (by logic of this
  very view), 0 otherwise.
* sql_block_account: A SQL (SET PASSWORD) query to block the account, making
  it inaccessible.
  The query has no effect on an account which is already blocked.
  Use with eval() to apply query.
* sql_release_account: A SQL (SET PASSWORD) query to release an account, re-
  enabling it.
  The query has no effect on an account which is not blocked.
  Use with eval() to apply query.


EXAMPLES

Show info for ''gromit''@''localhost'' account:


       mysql> SELECT * FROM sql_accounts WHERE USER = ''gromit'' \\G

                      user: gromit
                      host: localhost
                   grantee: ''gromit''@''localhost''
                  password: *23AE809DDACAF96AF0FD78ED04B6A265E05AA257
         is_empty_password: 0
           is_new_password: 1
           is_old_password: 0
                is_blocked: 0
         sql_block_account: SET PASSWORD FOR ''gromit''@''localhost'' =
       ''752AA50E562A6B40DE87DF0FA69FACADD908EA32*''
       sql_release_account: SET PASSWORD FOR ''gromit''@''localhost'' =
       ''*23AE809DDACAF96AF0FD78ED04B6A265E05AA257''


Block all accounts with user ''gromit''. Show info again:


       mysql> CALL eval("SELECT sql_block_account FROM sql_accounts WHERE
       USER = ''gromit''");

       mysql> SELECT * FROM sql_accounts WHERE USER = ''gromit'' \\G

                      user: gromit
                      host: localhost
                   grantee: ''gromit''@''localhost''
                  password: 752AA50E562A6B40DE87DF0FA69FACADD908EA32*
         is_empty_password: 0
           is_new_password: 1
           is_old_password: 0
                is_blocked: 1
         sql_block_account: SET PASSWORD FOR ''gromit''@''localhost'' =
       ''752AA50E562A6B40DE87DF0FA69FACADD908EA32*''
       sql_release_account: SET PASSWORD FOR ''gromit''@''localhost'' =
       ''*23AE809DDACAF96AF0FD78ED04B6A265E05AA257''


Note that account''s password is modified. It is modified to a value accepted
by MySQL, but which can never be generated by the PASSWORD() function.
However, it is easily reversible.
Release all blocked accounts. Check:


       mysql> CALL eval("SELECT sql_release_account FROM sql_accounts");

       mysql> SELECT COUNT(*) AS count_blocked_accounts FROM sql_accounts
       WHERE is_blocked;
       +------------------------+
       | count_blocked_accounts |
       +------------------------+
       |                      0 |
       +------------------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

eval(), security_audit(), sql_show_grants

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('sql_alter_table','
NAME

sql_alter_table: Generate ALTER TABLE SQL statements per table, with engine
and create options

TYPE

View

DESCRIPTION

sql_alter_table provides with SQL statements to alter a table to its current
form in terms of engine and create options.
This view is useful in generating a "resurrection" script to restore table to
its current engine state. For example, it may provide with the rollback script
for a database migration from MyISAM to InnoDB, or from InnoDB Antelope to
Barracuda format.

STRUCTURE



       mysql> DESC common_schema.sql_alter_table;
       +-----------------+--------------+------+-----+---------+-------+
       | Field           | Type         | Null | Key | Default | Extra |
       +-----------------+--------------+------+-----+---------+-------+
       | TABLE_SCHEMA    | varchar(64)  | NO   |     |         |       |
       | TABLE_NAME      | varchar(64)  | NO   |     |         |       |
       | ENGINE          | varchar(64)  | YES  |     | NULL    |       |
       | alter_statement | varchar(473) | YES  |     | NULL    |       |
       +-----------------+--------------+------+-----+---------+-------+



SYNOPSIS

Columns of this view:

* TABLE_SCHEMA: schema of current table
* TABLE_NAME: current table name
* ENGINE: current engine name
* alter_statement: A SQL statement which ALTERs current table to its current
  engine with create-options.
  Use with eval() to apply query.

The SQL statements are not terminated by '';''.

EXAMPLES

Generate ALTER TABLE statements for `sakila` tables:


       mysql> SELECT * FROM common_schema.sql_alter_table WHERE
       TABLE_SCHEMA=''sakila'';
       +--------------+---------------+--------+-------------------------
       ----------------------------+
       | TABLE_SCHEMA | TABLE_NAME    | ENGINE | alter_statement
       |
       +--------------+---------------+--------+-------------------------
       ----------------------------+
       | sakila       | actor         | InnoDB | ALTER TABLE
       `sakila`.`actor` ENGINE=InnoDB          |
       | sakila       | address       | InnoDB | ALTER TABLE
       `sakila`.`address` ENGINE=InnoDB        |
       | sakila       | category      | InnoDB | ALTER TABLE
       `sakila`.`category` ENGINE=InnoDB       |
       | sakila       | city          | InnoDB | ALTER TABLE
       `sakila`.`city` ENGINE=InnoDB           |
       | sakila       | country       | InnoDB | ALTER TABLE
       `sakila`.`country` ENGINE=InnoDB        |
       | sakila       | customer      | InnoDB | ALTER TABLE
       `sakila`.`customer` ENGINE=InnoDB       |
       | sakila       | film          | InnoDB | ALTER TABLE
       `sakila`.`film` ENGINE=InnoDB           |
       | sakila       | film_actor    | InnoDB | ALTER TABLE
       `sakila`.`film_actor` ENGINE=InnoDB     |
       | sakila       | film_category | InnoDB | ALTER TABLE
       `sakila`.`film_category` ENGINE=InnoDB  |
       | sakila       | film_text     | MyISAM | ALTER TABLE
       `sakila`.`film_text` ENGINE=MyISAM      |
       | sakila       | inventory     | InnoDB | ALTER TABLE
       `sakila`.`inventory` ENGINE=InnoDB      |
       | sakila       | language      | InnoDB | ALTER TABLE
       `sakila`.`language` ENGINE=InnoDB       |
       | sakila       | payment       | InnoDB | ALTER TABLE
       `sakila`.`payment` ENGINE=InnoDB        |
       | sakila       | rental        | InnoDB | ALTER TABLE
       `sakila`.`rental` ENGINE=InnoDB         |
       | sakila       | staff         | InnoDB | ALTER TABLE
       `sakila`.`staff` ENGINE=InnoDB          |
       | sakila       | store         | InnoDB | ALTER TABLE
       `sakila`.`store` ENGINE=InnoDB          |
       +--------------+---------------+--------+-------------------------
       ----------------------------+


Modify tables; again generate ALTER TABLE statements for `sakila` tables:


       mysql> ALTER TABLE sakila.film_text ENGINE=MyISAM
       ROW_FORMAT=FIXED;
       mysql> ALTER TABLE sakila.film_category ENGINE=InnoDB
       ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8;

       mysql> SELECT * FROM common_schema.sql_alter_table WHERE
       TABLE_SCHEMA=''sakila'';
       +--------------+---------------+--------+-------------------------
       ------------------------------------------------------------------
       +
       | TABLE_SCHEMA | TABLE_NAME    | ENGINE | alter_statement
       |
       +--------------+---------------+--------+-------------------------
       ------------------------------------------------------------------
       +
       | sakila       | actor         | InnoDB | ALTER TABLE
       `sakila`.`actor` ENGINE=InnoDB
       |
       | sakila       | address       | InnoDB | ALTER TABLE
       `sakila`.`address` ENGINE=InnoDB
       |
       | sakila       | category      | InnoDB | ALTER TABLE
       `sakila`.`category` ENGINE=InnoDB
       |
       | sakila       | city          | InnoDB | ALTER TABLE
       `sakila`.`city` ENGINE=InnoDB
       |
       | sakila       | country       | InnoDB | ALTER TABLE
       `sakila`.`country` ENGINE=InnoDB
       |
       | sakila       | customer      | InnoDB | ALTER TABLE
       `sakila`.`customer` ENGINE=InnoDB
       |
       | sakila       | film          | InnoDB | ALTER TABLE
       `sakila`.`film` ENGINE=InnoDB
       |
       | sakila       | film_actor    | InnoDB | ALTER TABLE
       `sakila`.`film_actor` ENGINE=InnoDB
       |
       | sakila       | film_category | InnoDB | ALTER TABLE
       `sakila`.`film_category` ENGINE=InnoDB row_format=COMPRESSED
       KEY_BLOCK_SIZE=8 |
       | sakila       | film_text     | MyISAM | ALTER TABLE
       `sakila`.`film_text` ENGINE=MyISAM row_format=FIXED
       |
       | sakila       | inventory     | InnoDB | ALTER TABLE
       `sakila`.`inventory` ENGINE=InnoDB
       |
       | sakila       | language      | InnoDB | ALTER TABLE
       `sakila`.`language` ENGINE=InnoDB
       |
       | sakila       | payment       | InnoDB | ALTER TABLE
       `sakila`.`payment` ENGINE=InnoDB
       |
       | sakila       | rental        | InnoDB | ALTER TABLE
       `sakila`.`rental` ENGINE=InnoDB
       |
       | sakila       | staff         | InnoDB | ALTER TABLE
       `sakila`.`staff` ENGINE=InnoDB
       |
       | sakila       | store         | InnoDB | ALTER TABLE
       `sakila`.`store` ENGINE=InnoDB
       |
       +--------------+---------------+--------+-------------------------
       ------------------------------------------------------------------
       +


Note again that the SQL statements are not terminated by '';''. Either CONCAT()
these beforehand, or use sed/awk afterwards.

ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

eval(), sql_foreign_keys, sql_range_partitions

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('sql_foreign_keys','
NAME

sql_foreign_keys: Generate create/drop foreign key constraints SQL statements

TYPE

View

DESCRIPTION

sql_foreign_keys provides with SQL statements to create/drop existing foreign
key constraints.
Currently, foreign keys are not implemented at MySQL, but rather at the
Storage Engine level. That is, MySQL does not manage foreign key constraints.
Instead, each storage engine manages integrity within the engine, if at all.
InnoDB provides foreign key support. MyISAM/MEMORY/ARCHIVE/others do not. 3rd
party engines may or may not implement foreign keys.
Unfortunately, not only does MySQL not manage the foreign keys, it also does
not manage their existence, nor their definitions. Thus, should we ALTER and
InnoDB table with foreign keys to MyISAM, all foreign key information is lost:
the definition itself ceases to exist. When ALTERing the table back to InnoDB
the foreign key remains lost.
It is useful to be able to generate the SQL required to "resurrect" foreign
key definitions, and sql_foreign_keys does just that. It builds upon the
INFORMATION_SCHEMA views which provides the foreign key metadata to generate
''ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY ...'' / ''ALTER TABLE ... DROP
FOREIGN KEY'' statement pairs.

STRUCTURE



       mysql> DESC common_schema.sql_foreign_keys;
       +------------------+--------------+------+-----+---------+-------+
       | Field            | Type         | Null | Key | Default | Extra |
       +------------------+--------------+------+-----+---------+-------+
       | TABLE_SCHEMA     | varchar(64)  | NO   |     |         |       |
       | TABLE_NAME       | varchar(64)  | NO   |     |         |       |
       | CONSTRAINT_NAME  | varchar(64)  | NO   |     |         |       |
       | drop_statement   | varchar(229) | YES  |     | NULL    |       |
       | create_statement | longtext     | YES  |     | NULL    |       |
       +------------------+--------------+------+-----+---------+-------+



SYNOPSIS

Columns of this view:

* TABLE_SCHEMA: schema of constraint''s table
* TABLE_NAME: table on which constraint is defined (this is child/dependent
  side of relation)
* CONSTRAINT_NAME: name of foreign key constraint (unique within its schema)
* drop_statement: A SQL statement which drops the constraint from this table
  (via ALTER TABLE)
  Use with eval() to apply query.
* create_statement: A SQL statement which creates this constraint (via ALTER
  TABLE)
  Use with eval() to apply query.

The SQL statements are not terminated by '';''.

EXAMPLES

Show foreign keys create/drop statements for `sakila`.`film_actor` (depends on
`film` and `actor` tables)


       mysql> SELECT * FROM common_schema.sql_foreign_keys WHERE
       TABLE_SCHEMA=''sakila'' AND table_name=''film_actor'' \\G
       *************************** 1. row ***************************
           TABLE_SCHEMA: sakila
             TABLE_NAME: film_actor
        CONSTRAINT_NAME: fk_film_actor_actor
         drop_statement: ALTER TABLE `sakila`.`film_actor` DROP FOREIGN
       KEY `fk_film_actor_actor`
       create_statement: ALTER TABLE `sakila`.`film_actor` ADD CONSTRAINT
       `fk_film_actor_actor` FOREIGN KEY (`actor_id`) REFERENCES
       `sakila`.`actor` (`actor_id`) ON DELETE RESTRICT ON UPDATE CASCADE
       *************************** 2. row ***************************
           TABLE_SCHEMA: sakila
             TABLE_NAME: film_actor
        CONSTRAINT_NAME: fk_film_actor_film
         drop_statement: ALTER TABLE `sakila`.`film_actor` DROP FOREIGN
       KEY `fk_film_actor_film`
       create_statement: ALTER TABLE `sakila`.`film_actor` ADD CONSTRAINT
       `fk_film_actor_film` FOREIGN KEY (`film_id`) REFERENCES
       `sakila`.`film` (`film_id`) ON DELETE RESTRICT ON UPDATE CASCADE


Save all of sakila''s foreign keys ADD CONSTRAINT statements to file:


       mysql> SELECT create_statement FROM common_schema.sql_foreign_keys
       WHERE TABLE_SCHEMA=''sakila'' INTO OUTFILE ''/tmp/
       create_sakila_foreign_keys.sql''

       bash$ cat /tmp/create_sakila_foreign_keys.sql
       ALTER TABLE `sakila`.`address` ADD CONSTRAINT `fk_address_city`
       FOREIGN KEY (`city_id`) REFERENCES `sakila`.`city` (`city_id`) ON
       DELETE RESTRICT ON UPDATE CASCADE
       ALTER TABLE `sakila`.`city` ADD CONSTRAINT `fk_city_country`
       FOREIGN KEY (`country_id`) REFERENCES `sakila`.`country`
       (`country_id`) ON DELETE RESTRICT ON UPDATE CASCADE
       ALTER TABLE `sakila`.`customer` ADD CONSTRAINT
       `fk_customer_address` FOREIGN KEY (`address_id`) REFERENCES
       `sakila`.`address` (`address_id`) ON DELETE RESTRICT ON UPDATE
       CASCADE
       ALTER TABLE `sakila`.`customer` ADD CONSTRAINT `fk_customer_store`
       FOREIGN KEY (`store_id`) REFERENCES `sakila`.`store` (`store_id`)
       ON DELETE RESTRICT ON UPDATE CASCADE
       ALTER TABLE `sakila`.`film` ADD CONSTRAINT `fk_film_language`
       FOREIGN KEY (`language_id`) REFERENCES `sakila`.`language`
       (`language_id`) ON DELETE RESTRICT ON UPDATE CASCADE
       ALTER TABLE `sakila`.`film` ADD CONSTRAINT
       `fk_film_language_original` FOREIGN KEY (`original_language_id`)
       REFERENCES `sakila`.`language` (`language_id`) ON DELETE RESTRICT
       ON UPDATE CASCADE
       ALTER TABLE `sakila`.`film_actor` ADD CONSTRAINT
       `fk_film_actor_actor` FOREIGN KEY (`actor_id`) REFERENCES
       `sakila`.`actor` (`actor_id`) ON DELETE RESTRICT ON UPDATE CASCADE
       ALTER TABLE `sakila`.`film_actor` ADD CONSTRAINT
       `fk_film_actor_film` FOREIGN KEY (`film_id`) REFERENCES
       `sakila`.`film` (`film_id`) ON DELETE RESTRICT ON UPDATE CASCADE
       ALTER TABLE `sakila`.`film_category` ADD CONSTRAINT
       `fk_film_category_category` FOREIGN KEY (`category_id`) REFERENCES
       `sakila`.`category` (`category_id`) ON DELETE RESTRICT ON UPDATE
       CASCADE
       ALTER TABLE `sakila`.`film_category` ADD CONSTRAINT
       `fk_film_category_film` FOREIGN KEY (`film_id`) REFERENCES
       `sakila`.`film` (`film_id`) ON DELETE RESTRICT ON UPDATE CASCADE
       ALTER TABLE `sakila`.`inventory` ADD CONSTRAINT
       `fk_inventory_film` FOREIGN KEY (`film_id`) REFERENCES
       `sakila`.`film` (`film_id`) ON DELETE RESTRICT ON UPDATE CASCADE
       ALTER TABLE `sakila`.`inventory` ADD CONSTRAINT
       `fk_inventory_store` FOREIGN KEY (`store_id`) REFERENCES
       `sakila`.`store` (`store_id`) ON DELETE RESTRICT ON UPDATE CASCADE
       ALTER TABLE `sakila`.`payment` ADD CONSTRAINT
       `fk_payment_customer` FOREIGN KEY (`customer_id`) REFERENCES
       `sakila`.`customer` (`customer_id`) ON DELETE RESTRICT ON UPDATE
       CASCADE
       ALTER TABLE `sakila`.`payment` ADD CONSTRAINT `fk_payment_rental`
       FOREIGN KEY (`rental_id`) REFERENCES `sakila`.`rental`
       (`rental_id`) ON DELETE SET NULL ON UPDATE CASCADE
       ALTER TABLE `sakila`.`payment` ADD CONSTRAINT `fk_payment_staff`
       FOREIGN KEY (`staff_id`) REFERENCES `sakila`.`staff` (`staff_id`)
       ON DELETE RESTRICT ON UPDATE CASCADE
       ALTER TABLE `sakila`.`rental` ADD CONSTRAINT `fk_rental_customer`
       FOREIGN KEY (`customer_id`) REFERENCES `sakila`.`customer`
       (`customer_id`) ON DELETE RESTRICT ON UPDATE CASCADE
       ALTER TABLE `sakila`.`rental` ADD CONSTRAINT `fk_rental_inventory`
       FOREIGN KEY (`inventory_id`) REFERENCES `sakila`.`inventory`
       (`inventory_id`) ON DELETE RESTRICT ON UPDATE CASCADE
       ALTER TABLE `sakila`.`rental` ADD CONSTRAINT `fk_rental_staff`
       FOREIGN KEY (`staff_id`) REFERENCES `sakila`.`staff` (`staff_id`)
       ON DELETE RESTRICT ON UPDATE CASCADE
       ALTER TABLE `sakila`.`staff` ADD CONSTRAINT `fk_staff_address`
       FOREIGN KEY (`address_id`) REFERENCES `sakila`.`address`
       (`address_id`) ON DELETE RESTRICT ON UPDATE CASCADE
       ALTER TABLE `sakila`.`staff` ADD CONSTRAINT `fk_staff_store`
       FOREIGN KEY (`store_id`) REFERENCES `sakila`.`store` (`store_id`)
       ON DELETE RESTRICT ON UPDATE CASCADE
       ALTER TABLE `sakila`.`store` ADD CONSTRAINT `fk_store_address`
       FOREIGN KEY (`address_id`) REFERENCES `sakila`.`address`
       (`address_id`) ON DELETE RESTRICT ON UPDATE CASCADE
       ALTER TABLE `sakila`.`store` ADD CONSTRAINT `fk_store_staff`
       FOREIGN KEY (`manager_staff_id`) REFERENCES `sakila`.`staff`
       (`staff_id`) ON DELETE RESTRICT ON UPDATE CASCADE


Note again that the SQL statements are not terminated by '';''. Either CONCAT()
these beforehand, or use sed/awk afterwards.

ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

eval(), sql_alter_table, sql_range_partitions

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('sql_grants','
NAME

sql_grants: generate SQL GRANT/REVOKE statements for existing accounts;
provide with GRANT metadata

TYPE

View

DESCRIPTION

sql_grants presents metadata for existing accounts, and generates SQL queries
for granting/revoking their privileges set.
It is a one-stop-shop for getting the set of privileges per account, per
privilege level (db, schema, table, column, routine). The view lists the set
of privileges per account in several formats:

* In comma delimited format (e.g. SELECT, INSERT, UPDATE, EXECUTE)
* In GRANT syntax
* In REVOKE syntax

The original mysql privileges tables, or the INFORMATION_SCHEMA *_PRIVILEGES
views make for a per-domain distinction of privileges: a table for per-schema
privileges; a table for per-table privileges, etc.
The only existing alternative to that is the SHOW GRANTS FOR command. Alas, it
is not a proper SQL query, and does not provide with structured result.
The sql_grants view provides with structured results, easily filtered or
searched.
This view builds on routine_privileges.

STRUCTURE



       mysql> DESC common_schema.sql_grants;
       +--------------------+--------------+------+-----+---------+------
       -+
       | Field              | Type         | Null | Key | Default | Extra
       |
       +--------------------+--------------+------+-----+---------+------
       -+
       | GRANTEE            | varchar(81)  | NO   |     |         |
       |
       | user               | char(16)     | NO   |     |         |
       |
       | host               | char(60)     | NO   |     |         |
       |
       | priv_level         | varchar(133) | NO   |     |         |
       |
       | priv_level_name    | varchar(7)   | NO   |     |         |
       |
       | object_schema      | varchar(64)  | YES  |     | NULL    |
       |
       | object_name        | varchar(64)  | YES  |     | NULL    |
       |
       | current_privileges | mediumtext   | YES  |     | NULL    |
       |
       | IS_GRANTABLE       | varchar(3)   | YES  |     | NULL    |
       |
       | sql_grant          | longtext     | YES  |     | NULL    |
       |
       | sql_revoke         | longtext     | YES  |     | NULL    |
       |
       | sql_drop_user      | varchar(91)  | NO   |     |         |
       |
       +--------------------+--------------+------+-----+---------+------
       -+



SYNOPSIS

Columns of this view:

* GRANTEE: grantee''s account
* user: account user part
* host: account host part
* priv_level: the domain on which the privileges are set (e.g. *.*, sakila.*)
* priv_level_name: description of priv_level: ''user'', ''schema'', ''table'',
  ''column'', ''routine''
* object_schema: name of schema in which object lies. Applies for table,
  column, routine; otherwise NULL
* object_name: name of object for which grants apply. Applies for schema,
  table, column, routine; otherwise NULL
* current_privileges: comma delimited list of privileges assigned to account
  on current privilege level
* IS_GRANTABLE: does current account have the GRANT privileges on this domain?
  ''Yes'' or ''NO''
* sql_grant: A GRANT query to generate current set of privileges.
  Use with eval() to apply query.
* sql_revoke: A REVOKE query to revoke current set of privileges.
  Use with eval() to apply query.
* sql_drop_user: A DROP USER query to drop account.
  Use with eval() to apply query.

The view is in 1st normal form. The sql_drop_user column applies to a grantee
in general, unrelated to the current domain.

EXAMPLES

Generate all content for the ''apps'' user:


       mysql> SELECT * FROM common_schema.sql_grants WHERE user =
       ''apps''\\G
       *************************** 1. row ***************************
                  GRANTEE: ''apps''@''%''
                     user: apps
                     host: %
               priv_level: *.*
          priv_level_name: user
            object_schema: NULL
              object_name: NULL
       current_privileges: USAGE
             IS_GRANTABLE: NO
                sql_grant: GRANT USAGE ON *.* TO ''apps''@''%'' IDENTIFIED BY
       PASSWORD ''''
               sql_revoke:
            sql_drop_user: DROP USER ''apps''@''%''
       *************************** 2. row ***************************
                  GRANTEE: ''apps''@''%''
                     user: apps
                     host: %
               priv_level: `test`.*
          priv_level_name: schema
            object_schema: NULL
              object_name: test
       current_privileges: DELETE, INSERT, SELECT, UPDATE
             IS_GRANTABLE: NO
                sql_grant: GRANT DELETE, INSERT, SELECT, UPDATE ON
       `test`.* TO ''apps''@''%''
               sql_revoke: REVOKE DELETE, INSERT, SELECT, UPDATE ON
       `test`.* FROM ''apps''@''%''
            sql_drop_user: DROP USER ''apps''@''%''
       *************************** 3. row ***************************
                  GRANTEE: ''apps''@''%''
                     user: apps
                     host: %
               priv_level: `sakila`.`film`
          priv_level_name: column
            object_schema: sakila
              object_name: film
       current_privileges: SELECT (description, film_id, title), UPDATE
       (description)
             IS_GRANTABLE: YES
                sql_grant: GRANT SELECT (description, film_id, title),
       UPDATE (description) ON `sakila`.`film` TO ''apps''@''%'' WITH GRANT
       OPTION
               sql_revoke: REVOKE SELECT (description, film_id, title),
       UPDATE (description), GRANT OPTION ON `sakila`.`film` FROM
       ''apps''@''%''
            sql_drop_user: DROP USER ''apps''@''%''


Show privileges per domain for ''other_user''@''localhost''


       mysql> SELECT priv_level, current_privileges FROM
       common_schema.sql_grants WHERE GRANTEE =
       ''\\''other_user\\''@\\''localhost\\'''';
       +------------+----------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ------+
       | priv_level | current_privileges
       |
       +------------+----------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ------+
       | *.*        | USAGE
       |
       | `world`.*  | ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE,
       CREATE TEMPORARY TABLES, CREATE VIEW, DELETE, DROP, EVENT,
       EXECUTE, INDEX, INSERT, LOCK TABLES, REFERENCES, SELECT, SHOW
       VIEW, TRIGGER, UPDATE |
       +------------+----------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ------+


Generate REVOKE statements for all users:


       mysql> SELECT sql_revoke FROM common_schema.sql_grants WHERE
       sql_revoke != '''';
       +-----------------------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ---------------------+
       | sql_revoke
       |
       +-----------------------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ---------------------+
       | REVOKE DELETE, INSERT, SELECT, UPDATE ON `test`.* FROM
       ''apps''@''%''
       |
       | REVOKE SELECT (description, film_id, title), UPDATE
       (description), GRANT OPTION ON `sakila`.`film` FROM ''apps''@''%''
       |
       | REVOKE PROCESS ON *.* FROM ''monitoring_user''@''localhost''
       |
       | REVOKE ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE
       TEMPORARY TABLES, CREATE VIEW, DELETE, DROP, EVENT, EXECUTE,
       INDEX, INSERT, LOCK TABLES, REFERENCES, SELECT, SHOW VIEW,
       TRIGGER, UPDATE ON `world`.* FROM ''other_user''@''localhost''
       |
       | REVOKE REPLICATION SLAVE ON *.* FROM ''replication''@''10.0.0.%''
       |
       | REVOKE ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE
       TEMPORARY TABLES, CREATE USER, CREATE VIEW, DELETE, DROP, EVENT,
       EXECUTE, FILE, INDEX, INSERT, LOCK TABLES, PROCESS, REFERENCES,
       RELOAD, REPLICATION CLIENT, REPLICATION SLAVE, SELECT, SHOW
       DATABASES, SHOW VIEW, SHUTDOWN, SUPER, TRIGGER, UPDATE, GRANT
       OPTION ON *.* FROM ''root''@''127.0.0.1'' |
       +-----------------------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ---------------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

routine_privileges, similar_grants, sql_show_grants

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('sql_range_partitions','
NAME

sql_range_partitions: Generate SQL statements for managing range partitions

TYPE

View

DESCRIPTION

sql_range_partitions provides with SQL statements to create/drop partitions in
a RANGE or RANGE COLUMNS partitioned table
It generates the DROP PARTITION statement required to drop the oldest
partition, and the ADD PARTITION or REORGANIZE PARTITION statement for
generating the next partition in sequence.
This view auto-deduces the "next in sequence" partition value. It handles
consistent partitioning schemes, where the interval of values between
partitions makes some sense. Such an interval can be a constant value, but can
also be a time-based interval.
The view supports MySQL 5.1 as well as 5.5. 5.1 requires an integer
partitioning key, thereby forcing users to convert such values as timestamps
to integers via UNIX_TIMESTAMP(), TO_DAYS() etc. sql_range_partitions reverse
engineers this conversion so as to compute the next in sequence LESS THAN
value.
It handles views with a LESS THAN MAXVALUE partition by reorganizing such
partition into a "normal" partition followed by a new LESS THAN MAXVALUE one.

STRUCTURE



       mysql> DESC common_schema.sql_range_partitions;
       +--------------------------+--------------+------+-----+---------
       +-------+
       | Field                    | Type         | Null | Key | Default |
       Extra |
       +--------------------------+--------------+------+-----+---------
       +-------+
       | table_schema             | varchar(64)  | NO   |     |         |
       |
       | table_name               | varchar(64)  | NO   |     |         |
       |
       | count_partitions         | bigint(21)   | NO   |     | 0       |
       |
       | sql_drop_first_partition | varchar(284) | YES  |     | NULL    |
       |
       | sql_add_next_partition   | longblob     | YES  |     | NULL    |
       |
       +--------------------------+--------------+------+-----+---------
       +-------+



SYNOPSIS

Columns of this view:

* table_schema: schema of partitioned table table
* table_name: table partitioned by RANGE or RANGE COLUMNS
* count_partitions: number of partitions in table
* sql_drop_first_partition: A SQL statement which drops the first partition.
  Use with eval() to apply query.
* sql_add_next_partition: A SQL statement which adds the "next in sequence"
  partition.
  Use with eval() to apply query.

The SQL statements are not terminated by '';''.

EXAMPLES

Show drop/reorganize statements for a partitioned table with MAXVALUE
partition:


       mysql> CREATE TABLE test.quarterly_report_status (
           report_id INT NOT NULL,
           report_status VARCHAR(20) NOT NULL,
           report_updated TIMESTAMP NOT NULL
       )
       PARTITION BY RANGE (UNIX_TIMESTAMP(report_updated)) (
           PARTITION p0 VALUES LESS THAN (UNIX_TIMESTAMP(''2008-01-01 00:
       00:00'')),
           PARTITION p1 VALUES LESS THAN (UNIX_TIMESTAMP(''2008-04-01 00:
       00:00'')),
           PARTITION p2 VALUES LESS THAN (UNIX_TIMESTAMP(''2008-07-01 00:
       00:00'')),
           PARTITION p3 VALUES LESS THAN (UNIX_TIMESTAMP(''2008-10-01 00:
       00:00'')),
           PARTITION p4 VALUES LESS THAN (UNIX_TIMESTAMP(''2009-01-01 00:
       00:00'')),
           PARTITION p5 VALUES LESS THAN (UNIX_TIMESTAMP(''2009-04-01 00:
       00:00'')),
           PARTITION p6 VALUES LESS THAN (MAXVALUE)
       );

       mysql> SELECT * FROM sql_range_partitions WHERE
       table_name=''quarterly_report_status'' \\G
       *************************** 1. row ***************************
                   table_schema: test
                     table_name: quarterly_report_status
               count_partitions: 7
       sql_drop_first_partition: alter table
       `test`.`quarterly_report_status` drop partition `p0`
         sql_add_next_partition: alter table
       `test`.`quarterly_report_status` reorganize partition `p6` into
       (partition `p_20090701000000` values less than (1246395600) /
       * 2009-07-01 00:00:00 */ , partition p_maxvalue values less than
       MAXVALUE)


Add next partition:


       mysql> call eval("SELECT sql_add_next_partition FROM
       sql_range_partitions WHERE table_name=''quarterly_report_status''");

       mysql> SHOW CREATE TABLE test.quarterly_report_status \\G

       Create Table: CREATE TABLE `quarterly_report_status` (
         `report_id` int(11) NOT NULL,
         `report_status` varchar(20) NOT NULL,
         `report_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON
       UPDATE CURRENT_TIMESTAMP
       ) ENGINE=MyISAM DEFAULT CHARSET=latin1
       /*!50100 PARTITION BY RANGE (UNIX_TIMESTAMP(report_updated))
       (PARTITION p0 VALUES LESS THAN (1199138400) ENGINE = MyISAM,
        PARTITION p1 VALUES LESS THAN (1206997200) ENGINE = MyISAM,
        PARTITION p2 VALUES LESS THAN (1214859600) ENGINE = MyISAM,
        PARTITION p3 VALUES LESS THAN (1222808400) ENGINE = MyISAM,
        PARTITION p4 VALUES LESS THAN (1230760800) ENGINE = MyISAM,
        PARTITION p5 VALUES LESS THAN (1238533200) ENGINE = MyISAM,
        PARTITION p_20090701000000 VALUES LESS THAN (1246395600) ENGINE =
       MyISAM,
        PARTITION p_maxvalue VALUES LESS THAN MAXVALUE ENGINE = MyISAM)
       */



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

eval(), sql_foreign_keys

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('sql_show_grants','
NAME

sql_show_grants: generate complete accounts SHOW GRANTS FOR -like output

TYPE

View

DESCRIPTION

sql_show_grants generates an output similar to that of SHOW GRANTS FOR..., for
all existing accounts. It also includes account information, hence it is easy
to filter results by account properties.
MySQL does not provide with a similar feature. It only provides SHOW GRANTS
FOR for a given account, and does not provide with the complete grants table.
Also, it is not an SQL query, and so cannot be subjected to filtering,
grouping, ordering, etc.
In fact, 3rd party tools, such as mk-show-grants are often used to interrogate
MySQL as for the set of accounts, then listing the grants for those accounts.
This view generates similar output.
This view builds upon the sql_grants results.

STRUCTURE



       mysql> DESC common_schema.sql_show_grants;
       +------------+-------------+------+-----+---------+-------+
       | Field      | Type        | Null | Key | Default | Extra |
       +------------+-------------+------+-----+---------+-------+
       | GRANTEE    | varchar(81) | NO   |     |         |       |
       | user       | char(16)    | NO   |     |         |       |
       | host       | char(60)    | NO   |     |         |       |
       | sql_grants | longtext    | YES  |     | NULL    |       |
       +------------+-------------+------+-----+---------+-------+



SYNOPSIS

Columns of this view:

* GRANTEE: grantee''s account
* user: account user part
* host: account host part
* sql_grants: The entire GRANT set of privileges for building the account;
  similar to the output of SHOW GRANTS FOR


EXAMPLES

Show grants for users called ''world_user'':


       mysql> SELECT * FROM common_schema.sql_show_grants WHERE
       user=''world_user'';
       +--------------------------+------------+-----------+-------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       -----------------------------------+
       | GRANTEE                  | user       | host      | sql_grants
       |
       +--------------------------+------------+-----------+-------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       -----------------------------------+
       | ''world_user''@''localhost'' | world_user | localhost | GRANT USAGE
       ON *.* TO ''world_user''@''localhost'' IDENTIFIED BY PASSWORD '''';
       GRANT ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE
       TEMPORARY TABLES, CREATE VIEW, DELETE, DROP, EVENT, EXECUTE,
       INDEX, INSERT, LOCK TABLES, REFERENCES, SELECT, SHOW VIEW,
       TRIGGER, UPDATE ON `world`.* TO ''world_user''@''localhost''; |
       +--------------------------+------------+-----------+-------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       ------------------------------------------------------------------
       -----------------------------------+


Dump grants into external file:


       mysql> SELECT sql_grants FROM common_schema.sql_show_grants INTO
       OUTFILE ''/tmp/grants.sql'';

       bash$ cat /tmp/grants.sql
       GRANT USAGE ON *.* TO ''apps''@''%'' IDENTIFIED BY PASSWORD '''';
       GRANT DELETE, INSERT, SELECT, UPDATE ON `test`.* TO ''apps''@''%'';
       GRANT SELECT (description, film_id, title), UPDATE (description)
       ON `sakila`.`film` TO ''apps''@''%'' WITH GRANT OPTION;
       GRANT USAGE ON *.* TO ''gromit''@''localhost'' IDENTIFIED BY PASSWORD
       '''';
       GRANT DELETE, INSERT, SELECT, UPDATE ON `world`.`City` TO
       ''gromit''@''localhost'' WITH GRANT OPTION;
       GRANT USAGE ON *.* TO ''monitoring_user''@''localhost'' IDENTIFIED BY
       PASSWORD ''*6BB4837EB74329105EE4568DDA7DC67ED2CA2AD9'';
       GRANT PROCESS ON *.* TO ''monitoring_user''@''localhost'';



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

duplicate_grantee(), similar_grants, sql_grants

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('start_of_hour','
NAME

start_of_hour(): Returns DATETIME of beginning of round hour of given
DATETIME.

TYPE

Function

DESCRIPTION

Returns DATETIME of beginning of round hour of given DATETIME, i.e. seconds
and minutes are stripped off the given value.

SYNOPSIS



       start_of_hour(dt DATETIME)
         RETURNS DATETIME


Input:

* dt: a DATETIME object, from which to extract round hour.


EXAMPLES



       mysql> SELECT common_schema.start_of_hour(''2011-03-24 11:17:08'')
       as dt;
       +---------------------+
       | dt                  |
       +---------------------+
       | 2011-03-24 11:00:00 |
       +---------------------+



ENVIRONMENT

MySQL 5.1 or newer

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('start_of_month','
NAME

start_of_month(): Returns first day of month of given DATETIME, as DATE
object.

TYPE

Function

DESCRIPTION

Returns first day of month of given DATETIME, as DATE object (equivalent to
midnight, the first second of given DATETIME''s month).

SYNOPSIS



       start_of_month(dt DATETIME)
         RETURNS DATE


Input:

* dt: a DATETIME object, from which to extract start of month.


EXAMPLES



       mysql> SELECT common_schema.start_of_month(''2011-03-24 11:17:08'')
       as dt;
       +------------+
       | dt         |
       +------------+
       | 2011-03-01 |
       +------------+



ENVIRONMENT

MySQL 5.1 or newer

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('start_of_quarter','
NAME

start_of_quarter(): Returns first day of quarter of given datetime, as DATE
object.

TYPE

Function

DESCRIPTION

Returns first day of quarter of given DATETIME, as DATE object (equivalent to
midnight, first second entering quarter of given DATETIME).

SYNOPSIS



       start_of_quarter(dt DATETIME)
         RETURNS DATE


Input:

* dt: a DATETIME object, from which to extract start of quarter.


EXAMPLES



       mysql> SELECT common_schema.start_of_quarter(''2011-06-17 18:29:
       03'') as dt;
       +------------+
       | dt         |
       +------------+
       | 2011-04-01 |
       +------------+



ENVIRONMENT

MySQL 5.1 or newer

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('start_of_week','
NAME

start_of_week(): Returns first day of week of given DATETIME (i.e. start of
Monday), as DATE object

TYPE

Function

DESCRIPTION

Returns midnight, starting Monday in same week as given DATETIME.

SYNOPSIS



       start_of_week(dt DATETIME)
         RETURNS DATE


Input:

* dt: a DATETIME object, from which to extract same week''s Monday.


EXAMPLES



       mysql> SELECT common_schema.start_of_week(''2011-03-24 11:17:08'')
       as dt;
       +------------+
       | dt         |
       +------------+
       | 2011-03-21 |
       +------------+



ENVIRONMENT

MySQL 5.1 or newer

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('start_of_week_sunday','
NAME

start_of_week_sunday(): Returns first day of week, Sunday based, of given
datetime, as DATE object

TYPE

Function

DESCRIPTION

Returns midnight, starting Sunday in same week as given DATETIME. Some
calendars (i.e. Jewish/Israeli calendar) begin the working week on Sunday.

SYNOPSIS



       start_of_week_sunday(dt DATETIME)
         RETURNS DATE


Input:

* dt: a DATETIME object, from which to extract same week''s Sunday (the Sunday
  just before or at the given DATETIME).


EXAMPLES



       mysql> SELECT common_schema.start_of_week_sunday(''2011-03-24 11:
       17:08'') as dt;
       +------------+
       | dt         |
       +------------+
       | 2011-03-20 |
       +------------+



ENVIRONMENT

MySQL 5.1 or newer

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('start_of_year','
NAME

start_of_year(): Returns first day of year of given DATETIME, as DATE object.

TYPE

Function

DESCRIPTION

Returns starting midnight of January 1st, in same year as in given DATETIME.

SYNOPSIS



       start_of_year(dt DATETIME)
         RETURNS DATE


Input:

* dt: a DATETIME object, from which to extract start of year.


EXAMPLES



       mysql> SELECT common_schema.start_of_year(''2011-03-24 11:17:08'')
       as dt;
       +------------+
       | dt         |
       +------------+
       | 2011-01-01 |
       +------------+



ENVIRONMENT

MySQL 5.1 or newer

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('starts_with','
NAME

starts_with(): Checks whether given text starts with given prefix..

TYPE

Function

DESCRIPTION

A string p is a prefix of s if there is a string t such that CONCAT(p, t) = s.

SYNOPSIS



       starts_with(txt TEXT CHARSET utf8, prefix TEXT CHARSET utf8)
         RETURNS INT UNSIGNED


Input:

* txt: an arbitrary text.
* prefix: the string suspected/expected to be a prefix as txt.

If txt does indeed start with prefix, starts_with returns the number of
characters in the prefix. That is, the length of prefix.
In case of mismatch (not a prefix), the function returns 0.
One should note that a positive number holds in SQL as a TRUE value, whereas 0
holds as FALSE. Also note that in the particular case of the empty string
being the prefix, the value 0 is always returned.

EXAMPLES

Trim text (spaces between literals are unaffected):


       SELECT starts_with(''The quick brown fox'', ''The quick'') as
       is_prefix;
       +-----------+
       | is_prefix |
       +-----------+
       |         9 |
       +-----------+


Similar to the above, quoted for clarity:


       SELECT starts_with(''The quick brown fox'', ''fox'') as is_prefix;
       +-----------+
       | is_prefix |
       +-----------+
       |         0 |
       +-----------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

get_num_tokens(), split_token()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('status','
NAME

status: General metadata/status of common_schema

TYPE

View

DESCRIPTION

status provides with metadata/status information on common_schema internals.
The metadata provided by the status view can be essential for:

* Integrity/versioning: by knowing the exact version/revision of common_schema
* Diagnostics: as an essential information in a bug report
* More diagnostics: knowing the envorinment in which common_schema runs


STRUCTURE



       mysql> desc common_schema.status;
       +-------------------------------------+----------+------+-----+---
       ------+-------+
       | Field                               | Type     | Null | Key |
       Default | Extra |
       +-------------------------------------+----------+------+-----+---
       ------+-------+
       | project_name                        | longtext | YES  |     |
       NULL    |       |
       | version                             | longtext | YES  |     |
       NULL    |       |
       | revision                            | longtext | YES  |     |
       NULL    |       |
       | install_time                        | longtext | YES  |     |
       NULL    |       |
       | install_success                     | longtext | YES  |     |
       NULL    |       |
       | base_components_installed           | longtext | YES  |     |
       NULL    |       |
       | innodb_plugin_components_installed  | longtext | YES  |     |
       NULL    |       |
       | percona_server_components_installed | longtext | YES  |     |
       NULL    |       |
       | install_mysql_version               | longtext | YES  |     |
       NULL    |       |
       | install_sql_mode                    | longtext | YES  |     |
       NULL    |       |
       +-------------------------------------+----------+------+-----+---
       ------+-------+



SYNOPSIS

Columns of this view:

* project_name: this is the text "common_schema"
* version: external version number
* revision: internal revision number (more granular than version)
* install_time: TIMESTAMP at which common_schema as installed
* install_success: boolean, installation result. "1" indicates success
* base_components_installed: boolean. "1" indicates that base components were
  installed.
* innodb_plugin_components_installed: boolean. "1" indicates InnoDB Plugin
  components were installed.
* percona_server_components_installed: boolean. "1" indicates Percona Server
  components were installed.
* install_mysql_version: version of MySQL at the time of common_schema
  installation.
* install_sql_mode: the sql_mode used when creation common_schema. This
  applies to stored routines even though the DBA may change the global
  sql_mode, as MySQL''s stored routines retain the snapshot of sql_mode by
  which they were created.


EXAMPLES



       mysql> SELECT * FROM status \\G
       *************************** 1. row ***************************
                              project_name: common_schema
                                   version: 1.1
                                  revision: 243
                              install_time: 2012-07-04 08:35:13
                           install_success: 1
                 base_components_installed: 1
        innodb_plugin_components_installed: 1
       percona_server_components_installed: 0
                     install_mysql_version: 5.1.51-log
                          install_sql_mode:
       ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,TRADITIONAL,NO_AUTO_CREATE_USER



ENVIRONMENT

MySQL 5.1 or newer.

SEE ALSO

help()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('strip_urls','
NAME

strip_urls(): Strips URLs from given text, replacing them with an empty
string.

TYPE

Function

DESCRIPTION

Strip out http:// and https:// URLs from given text. URLs are replaced with
the empty string. Otherwise the text is untouched, and in particular, spaces
are not compressed.

SYNOPSIS



       strip_urls(txt TEXT CHARSET utf8)
         RETURNS TEXT CHARSET utf8


Input:

* txt: an arbitrary text, possibly containing URLs


EXAMPLES

Strip both http:// and https:// URLs from text:


       mysql> SELECT strip_urls(''Check out common_schema: http://bit.ly/
       xKc8k3, an awesome project! https://bit.ly/Nd57HS'') AS stripped;
       +------------------------------------------------+
       | stripped                                       |
       +------------------------------------------------+
       | Check out common_schema:  an awesome project!  |
       +------------------------------------------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

replace_all()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('table_charset','
NAME

table_charset: list tables, their character sets and collations

TYPE

View

DESCRIPTION

A table is associated with a character set and a collation. Surprisingly,
INFORMATION_SCHEMA''s TABLES table only lists a table''s collation, and neglects
to provide with the character set.
A character set is easily deduced by given collation, since a collation
relates to a single character set.
table_charset provides this convenient connection.

STRUCTURE



       mysql> DESC common_schema.table_charset;
       +--------------------+-------------+------+-----+---------+-------
       +
       | Field              | Type        | Null | Key | Default | Extra
       |
       +--------------------+-------------+------+-----+---------+-------
       +
       | TABLE_SCHEMA       | varchar(64) | NO   |     |         |
       |
       | TABLE_NAME         | varchar(64) | NO   |     |         |
       |
       | CHARACTER_SET_NAME | varchar(32) | NO   |     |         |
       |
       | TABLE_COLLATION    | varchar(32) | YES  |     | NULL    |
       |
       +--------------------+-------------+------+-----+---------+-------
       +



SYNOPSIS

Columns of this view:

* TABLE_SCHEMA: name of schema (database)
* TABLE_NAME: name of table
* CHARACTER_SET_NAME: table''s defined character set
* TABLE_COLLATION: table''s collation


EXAMPLES



       mysql> SELECT * FROM common_schema.table_charset WHERE
       TABLE_SCHEMA IN (''sakila'', ''world'');
       +--------------+-----------------+--------------------+-----------
       --------+
       | TABLE_SCHEMA | TABLE_NAME      | CHARACTER_SET_NAME |
       TABLE_COLLATION   |
       +--------------+-----------------+--------------------+-----------
       --------+
       | world        | City            | latin1             |
       latin1_swedish_ci |
       | world        | Country         | latin1             |
       latin1_swedish_ci |
       | world        | CountryLanguage | latin1             |
       latin1_swedish_ci |
       | sakila       | actor           | utf8               |
       utf8_general_ci   |
       | sakila       | address         | utf8               |
       utf8_general_ci   |
       | sakila       | category        | utf8               |
       utf8_general_ci   |
       | sakila       | city            | utf8               |
       utf8_general_ci   |
       | sakila       | country         | utf8               |
       utf8_general_ci   |
       | sakila       | customer        | utf8               |
       utf8_general_ci   |
       | sakila       | film            | utf8               |
       utf8_general_ci   |
       | sakila       | film_actor      | utf8               |
       utf8_general_ci   |
       | sakila       | film_category   | utf8               |
       utf8_general_ci   |
       | sakila       | film_text       | utf8               |
       utf8_general_ci   |
       | sakila       | inventory       | utf8               |
       utf8_general_ci   |
       | sakila       | language        | utf8               |
       utf8_general_ci   |
       | sakila       | payment         | utf8               |
       utf8_general_ci   |
       | sakila       | rental          | utf8               |
       utf8_general_ci   |
       | sakila       | staff           | utf8               |
       utf8_general_ci   |
       | sakila       | store           | utf8               |
       utf8_general_ci   |
       +--------------+-----------------+--------------------+-----------
       --------+



ENVIRONMENT

MySQL 5.1 or newer.

SEE ALSO

text_columns

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('table_exists','
NAME

table_exists(): Check if specified table exists

TYPE

Function

DESCRIPTION

table_exists() provides with a quick and efficient boolean check for existence
of a table or a view.
It requires both input parameters to identify existing object (no wildcards,
NULLs or empty strings allowed), and uses INFORMATION_SCHEMA_optimizations to
look them up. In particular, no directories are scanned and no tables are
opened by the execution of this function.
The function makes no distinction between a table and a view. Any such
distinction would require opening the table definition file.

SYNOPSIS



       table_exists(lookup_table_schema varchar(64) charset utf8,
       lookup_table_name varchar(64) charset utf8)
         RETURNS TINYINT UNSIGNED


Input:

* lookup_table_schema: name of schema (database)
* lookup_table_name: name of table to look for within said schema

Output: boolean: 1 is indicated table/view exists, 0 otherwise.

EXAMPLES

Qualify a GRANTEE:


       mysql> SELECT table_exists(''sakila'', ''rental'') AS does_it_exist;
       +---------------+
       | does_it_exist |
       +---------------+
       |             1 |
       +---------------+

       mysql> SELECT table_exists(''sakila'', ''zzzztttt'') AS does_it_exist;
       +---------------+
       | does_it_exist |
       +---------------+
       |             0 |
       +---------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

Schema_analysis

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('tables','
SYNOPSIS

Tables: static data

* numbers: listing of unsigned integers


DESCRIPTION

common_schema is a stateless schema. Data provided is static, unmodified by
common_schema code.
');
		
			INSERT INTO common_schema.help_content VALUES ('temporal_routines','
SYNOPSIS

Temporal routines: stored functions managing temporal values. All functions
are DETERMINISTIC, NO SQL.

* easter_day(): Returns DATE of easter day in given DATETIME''s year.
* is_datetime(): Check whether given string is a valid DATETIME.
* start_of_hour(): Returns DATETIME of beginning of round hour of given
  DATETIME.
* start_of_month(): Returns first day of month of given datetime, as DATE
  object
* start_of_quarter(): Returns first day of quarter of given datetime, as DATE
  object
* start_of_week(): Returns first day of week of given datetime (i.e. start of
  Monday), as DATE object
* start_of_week_sunday(): Returns first day of week, Sunday based, of given
  datetime, as DATE object
* start_of_year(): Returns first day of year of given datetime, as DATE object

');
		
			INSERT INTO common_schema.help_content VALUES ('text_columns','
NAME

text_columns: list textual columns character sets & collations

TYPE

View

DESCRIPTION

text_columns builds upon INFORMATION_SCHEMA''s COLUMNS table to present with
textual columns, their character sets and collations.
Textual columns are columns of types CHAR, VARCHAR, TINYTEXT, MEDIUMTEXT,
TEXT, LONGTEXT.
ENUM and SET types are excluded, although they, too, are associated with
character sets and collations. Internal representation of ENUM & SET is
numeric.

STRUCTURE



       mysql> DESC common_schema.text_columns;
       +--------------------+-------------+------+-----+---------+-------
       +
       | Field              | Type        | Null | Key | Default | Extra
       |
       +--------------------+-------------+------+-----+---------+-------
       +
       | TABLE_SCHEMA       | varchar(64) | NO   |     |         |
       |
       | TABLE_NAME         | varchar(64) | NO   |     |         |
       |
       | COLUMN_NAME        | varchar(64) | NO   |     |         |
       |
       | COLUMN_TYPE        | longtext    | NO   |     | NULL    |
       |
       | CHARACTER_SET_NAME | varchar(32) | YES  |     | NULL    |
       |
       | COLLATION_NAME     | varchar(32) | YES  |     | NULL    |
       |
       +--------------------+-------------+------+-----+---------+-------
       +



SYNOPSIS

Columns of this view directly map to those of INFORMATION_SCHEMA.COLUMNS

EXAMPLES



       mysql> SELECT * FROM common_schema.text_columns WHERE TABLE_SCHEMA
       IN (''sakila'', ''world'');
       +--------------+----------------------------+----------------+----
       ----------+--------------------+-------------------+
       | TABLE_SCHEMA | TABLE_NAME                 | COLUMN_NAME    |
       COLUMN_TYPE  | CHARACTER_SET_NAME | COLLATION_NAME    |
       +--------------+----------------------------+----------------+----
       ----------+--------------------+-------------------+
       | sakila       | actor                      | first_name     |
       varchar(45)  | utf8               | utf8_general_ci   |
       | sakila       | actor                      | last_name      |
       varchar(45)  | utf8               | utf8_general_ci   |
       | sakila       | actor_info                 | first_name     |
       varchar(45)  | utf8               | utf8_general_ci   |
       | sakila       | actor_info                 | last_name      |
       varchar(45)  | utf8               | utf8_general_ci   |
       | sakila       | actor_info                 | film_info      |
       longtext     | utf8               | utf8_general_ci   |
       | sakila       | address                    | address        |
       varchar(50)  | utf8               | utf8_general_ci   |
       | sakila       | address                    | address2       |
       varchar(50)  | utf8               | utf8_general_ci   |
       | sakila       | address                    | district       |
       varchar(20)  | utf8               | utf8_general_ci   |
       | sakila       | address                    | postal_code    |
       varchar(10)  | utf8               | utf8_general_ci   |
       | sakila       | address                    | phone          |
       varchar(20)  | utf8               | utf8_general_ci   |
       | sakila       | category                   | name           |
       varchar(25)  | utf8               | utf8_general_ci   |
       | sakila       | city                       | city           |
       varchar(50)  | utf8               | utf8_general_ci   |
       | sakila       | country                    | country        |
       varchar(50)  | utf8               | utf8_general_ci   |
       | sakila       | customer                   | first_name     |
       varchar(45)  | utf8               | utf8_general_ci   |
       | sakila       | customer                   | last_name      |
       varchar(45)  | utf8               | utf8_general_ci   |
       | sakila       | customer                   | email          |
       varchar(50)  | utf8               | utf8_general_ci   |
       | sakila       | customer_list              | name           |
       varchar(91)  | utf8               | utf8_general_ci   |
       | sakila       | customer_list              | address        |
       varchar(50)  | utf8               | utf8_general_ci   |
       | sakila       | customer_list              | zip code       |
       varchar(10)  | utf8               | utf8_general_ci   |
       | sakila       | customer_list              | phone          |
       varchar(20)  | utf8               | utf8_general_ci   |
       | sakila       | customer_list              | city           |
       varchar(50)  | utf8               | utf8_general_ci   |
       | sakila       | customer_list              | country        |
       varchar(50)  | utf8               | utf8_general_ci   |
       | sakila       | customer_list              | notes          |
       varchar(6)   | utf8               | utf8_general_ci   |
       | sakila       | film                       | title          |
       varchar(255) | utf8               | utf8_general_ci   |
       | sakila       | film                       | description    |
       text         | utf8               | utf8_general_ci   |
       | sakila       | film_list                  | title          |
       varchar(255) | utf8               | utf8_general_ci   |
       | sakila       | film_list                  | description    |
       text         | utf8               | utf8_general_ci   |
       | sakila       | film_list                  | category       |
       varchar(25)  | utf8               | utf8_general_ci   |
       | sakila       | film_list                  | actors         |
       longtext     | utf8               | utf8_general_ci   |
       | sakila       | film_text                  | title          |
       varchar(255) | utf8               | utf8_general_ci   |
       | sakila       | film_text                  | description    |
       text         | utf8               | utf8_general_ci   |
       | sakila       | language                   | name           |
       char(20)     | utf8               | utf8_general_ci   |
       | sakila       | nicer_but_slower_film_list | title          |
       varchar(255) | utf8               | utf8_general_ci   |
       | sakila       | nicer_but_slower_film_list | description    |
       text         | utf8               | utf8_general_ci   |
       | sakila       | nicer_but_slower_film_list | category       |
       varchar(25)  | utf8               | utf8_general_ci   |
       | sakila       | nicer_but_slower_film_list | actors         |
       longtext     | utf8               | utf8_general_ci   |
       | sakila       | sales_by_film_category     | category       |
       varchar(25)  | utf8               | utf8_general_ci   |
       | sakila       | sales_by_store             | store          |
       varchar(101) | utf8               | utf8_general_ci   |
       | sakila       | sales_by_store             | manager        |
       varchar(91)  | utf8               | utf8_general_ci   |
       | sakila       | staff                      | first_name     |
       varchar(45)  | utf8               | utf8_general_ci   |
       | sakila       | staff                      | last_name      |
       varchar(45)  | utf8               | utf8_general_ci   |
       | sakila       | staff                      | email          |
       varchar(50)  | utf8               | utf8_general_ci   |
       | sakila       | staff                      | username       |
       varchar(16)  | utf8               | utf8_general_ci   |
       | sakila       | staff                      | password       |
       varchar(40)  | utf8               | utf8_bin          |
       | sakila       | staff_list                 | name           |
       varchar(91)  | utf8               | utf8_general_ci   |
       | sakila       | staff_list                 | address        |
       varchar(50)  | utf8               | utf8_general_ci   |
       | sakila       | staff_list                 | zip code       |
       varchar(10)  | utf8               | utf8_general_ci   |
       | sakila       | staff_list                 | phone          |
       varchar(20)  | utf8               | utf8_general_ci   |
       | sakila       | staff_list                 | city           |
       varchar(50)  | utf8               | utf8_general_ci   |
       | sakila       | staff_list                 | country        |
       varchar(50)  | utf8               | utf8_general_ci   |
       | world        | City                       | Name           |
       char(35)     | latin1             | latin1_swedish_ci |
       | world        | City                       | CountryCode    |
       char(3)      | latin1             | latin1_swedish_ci |
       | world        | City                       | District       |
       char(20)     | latin1             | latin1_swedish_ci |
       | world        | Country                    | Code           |
       char(3)      | latin1             | latin1_swedish_ci |
       | world        | Country                    | Name           |
       char(52)     | latin1             | latin1_swedish_ci |
       | world        | Country                    | Region         |
       char(26)     | latin1             | latin1_swedish_ci |
       | world        | Country                    | LocalName      |
       char(45)     | latin1             | latin1_swedish_ci |
       | world        | Country                    | GovernmentForm |
       char(45)     | latin1             | latin1_swedish_ci |
       | world        | Country                    | HeadOfState    |
       char(60)     | latin1             | latin1_swedish_ci |
       | world        | Country                    | Code2          |
       char(2)      | latin1             | latin1_swedish_ci |
       | world        | CountryLanguage            | CountryCode    |
       char(3)      | latin1             | latin1_swedish_ci |
       | world        | CountryLanguage            | Language       |
       char(30)     | latin1             | latin1_swedish_ci |
       +--------------+----------------------------+----------------+----
       ----------+--------------------+-------------------+



ENVIRONMENT

MySQL 5.1 or newer.

SEE ALSO

table_charset

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('text_routines','
SYNOPSIS

Text routines: string operations

* decode_xml(): Decode XML characters in text.
* encode_xml(): Encode a given text for XML.
* extract_json_value(): Extract value from JSON notation via XPath.
* get_num_tokens(): Return number of tokens in delimited text.
* get_option(): Extract value from options dictionary based on key.
* json_to_xml(): Convert valid JSON to equivalent XML.
* like_to_rlike(): Convert a LIKE expression to an RLIKE (REGEXP) expression.
* mysql_qualify(): Return a qualified MySQL object name.
* prettify_message(): Outputs a prettified text message, one row per line in
  text
* replace_all(): Replaces characters in a given text with a given replace-
  text.
* split_token(): Return substring by index in delimited text.
* starts_with(): Checks whether given text starts with given prefix.
* strip_urls(): Strips URLs from given text, replacing them with an empty
  string.
* tokenize(): Outputs ordered result set of tokens of given text.
* trim_wspace(): Trim white space characters on both sides of text.


EXAMPLES

Calculate 64 bit CRC for some text:


       mysql> SELECT common_schema.crc64(''mysql'') AS crc64;
       +---------------------+
       | crc64               |
       +---------------------+
       | 9350511318824990686 |
       +---------------------+


Use shorttime_to_seconds() to parse ''2h'', making for 2 hours:


       mysql> SELECT shorttime_to_seconds(''2h'') as seconds;
       +---------+
       | seconds |
       +---------+
       |    7200 |
       +---------+


Extract value from dictionary:


       mysql> SELECT get_option(''{width: 100, height: 180, color:
       #ffa030}'', ''height'') AS result;
       +--------+
       | result |
       +--------+
       | 180    |
       +--------+


');
		
			INSERT INTO common_schema.help_content VALUES ('this_query','
NAME

this_query(): Returns the current query executed by this thread.

TYPE

Function

DESCRIPTION

This function returns the text of query which is now executing under the
current process.
Essentially, it is the very same query which invoked this function. That it,
the call to this_query() is expected to be found within the result''s text.
The function is provided as ground for future query/text analysis routines
which would be able to modify query behavior according to query''s text.

SYNOPSIS



       this_query()
         RETURNS LONGTEXT CHARSET utf8



EXAMPLES

The most simplistic form:


       mysql> SELECT this_query();
       +---------------------+
       | this_query()        |
       +---------------------+
       | SELECT this_query() |
       +---------------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

Execution_&_flow_control

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('throttle','
NAME

throttle(): Throttle current query by periodically sleeping throughout its
execution.

TYPE

Function

DESCRIPTION

This function sleeps an amount of time proportional to the time the query
executes, on a per-lap basis. That is, time is measured between two
invocations of this function, and that time is multiplied by throttle_ratio to
conclude the extent of throttling.
The throttle() function is introduced as an easy means to alleviate the load
of a heavy-weight query, by injecting sleep time periods into the query''s
execution; periods where query is not consuming CPU nor performing I/
O operations. During such sleep periods, other queries can more easily compete
for such resources.
The function essentially increases the total runtime of the query.
Due to the fact throttling is done within the query itself, some resources
taken by query''s execution are not released throughout the sleep periods.
Namely, no locks nor memory are released for the entire duration of the query.
Whether the function should in fact throttle depends on current query
execution time, and, so as to alleviate the overhead of this function itself,
only computed once in a 1,000 runs.
throttle() returns the number of seconds spent sleeping on this call of the
function. The number may be 0 if no throttling took place (either the like
event of not being a one in a 1,000 execution, or the case where query lap
time is too small to consider throttling).

SYNOPSIS



       throttle(throttle_ratio DOUBLE)
         RETURNS DOUBLE


Input:

* throttle_ratio: ratio by which to throttle, or extend total query time.
  Query time is extended by multiplying given arguemnt with original query
  time.
  For example, throttle_ratio value of 1 will double the total execution time,
  since it adds one unit of query execution time.
  throttle_ratio of 0.3 will make the query execute for 30% more time, to the
  total of 130% the original time.


EXAMPLES

Compare query runtime with and without throttling. Roughly double the query''s
execution time by providing with a throttle_ratio value of 1.


       mysql> SELECT Id, Name, sleep(0.001) from world.City ORDER BY
       Population DESC;
       +------+------------------------------------+--------------+
       | Id   | Name                               | sleep(0.001) |
       +------+------------------------------------+--------------+
       | 1024 | Mumbai (Bombay)                    |            0 |
       | 2331 | Seoul                              |            0 |
       |  206 | São Paulo                          |            0 |
       | 1890 | Shanghai                           |            0 |
       |  939 | Jakarta                            |            0 |
       ...
       | 2316 | Bantam                             |            0 |
       | 3538 | Citt�  del Vaticano                 |            0 |
       | 3333 | Fakaofo                            |            0 |
       | 2317 | West Island                        |            0 |
       | 2912 | Adamstown                          |            0 |
       +------+------------------------------------+--------------+
       4079 rows in set (4.53 sec)




       mysql> SELECT Id, Name, sleep(0.001), throttle(1) from world.City
       ORDER BY Population DESC;
       +------+------------------------------------+--------------+------
       -------+
       | Id   | Name                               | sleep(0.001) |
       throttle(1) |
       +------+------------------------------------+--------------+------
       -------+
       | 1024 | Mumbai (Bombay)                    |            0 |
       0 |
       | 2331 | Seoul                              |            0 |
       0 |
       |  206 | São Paulo                          |            0 |
       0 |
       | 1890 | Shanghai                           |            0 |
       0 |
       |  939 | Jakarta                            |            0 |
       0 |
       ...
       | 2316 | Bantam                             |            0 |
       0 |
       | 3538 | Citt�  del Vaticano                 |            0 |
       0 |
       | 3333 | Fakaofo                            |            0 |
       0 |
       | 2317 | West Island                        |            0 |
       0 |
       | 2912 | Adamstown                          |            0 |
       0 |
       +------+------------------------------------+--------------+------
       -------+
       4079 rows in set (8.69 sec)



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

query_laptime(), query_runtime(), QueryScript_throttle

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('throw','
NAME

throw(): Disrupt execution with error

TYPE

Procedure

DESCRIPTION

Issues an error at the point of invocation, providing with an error message.
This is done by invoking an invalid command on the server. The result of such
invocation will break execution of calling code. If this routine is invoked
from another routine, the entire call stack is aborted. If this routine is
called during a transaction, the transaction aborts and rolls back.

SYNOPSIS



       throw(error_message VARCHAR(1024) CHARSET utf8)
         NO SQL


Input:

* error_message: a message to be displayed within error statement.

Output:

* @common_schema_error: The procedure sets this variable to the error_message
  supplied.


EXAMPLES

Invoke throw() directly:


       mysql> call throw(''Unknown variable type'');
       ERROR 1146 (42S02): Table ''error.Unknown variable type'' doesn''t
       exist

       mysql> SELECT @common_schema_error;
       +-----------------------+
       | @common_schema_error  |
       +-----------------------+
       | Unknown variable type |
       +-----------------------+


Invoke a syntactically invalid script; the run() routine and subroutines
validate script syntax and call upon throw():


       mysql> call run(''{set @x := 3; ; ; }'');
       ERROR 1103 (42000): Incorrect table name ''QueryScript error:
       [Empty statement not allowed. Use {} instead] at 16: "; ; }"''

       mysql> SELECT @common_schema_error;
       +-----------------------------------------------------------------
       ----------------+
       | @common_schema_error
       |
       +-----------------------------------------------------------------
       ----------------+
       | QueryScript error: [Empty statement not allowed. Use {} instead]
       at 16: "; ; }" |
       +-----------------------------------------------------------------
       ----------------+



ENVIRONMENT

MySQL 5.1 or newer

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('tokenize','
NAME

tokenize(): Outputs ordered result set of tokens of given text

TYPE

Procedure

DESCRIPTION

This procedure splits given text using given delimiter, and returns to tokens
as a result set.
The number of tokens is limited by the number of values in the numbers table.

SYNOPSIS



       tokenize(txt TEXT CHARSET utf8, delimiter_text VARCHAR(255)
       CHARSET utf8)


Input:

* txt: text to be tokenized.
* delimiter_text: delimiter by which to tokenize (can be of any length,
  including an empty text).


EXAMPLES

Tokenize a given text:


       call tokenize(''the quick brown fox'', '' '');
       +---+-------+
       | n | token |
       +---+-------+
       | 1 | the   |
       | 2 | quick |
       | 3 | brown |
       | 4 | fox   |
       +---+-------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

get_num_tokens(), split_token(), prettify_message()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('trim_wspace','
NAME

trim_wspace(): Trim white space characters on both sides of text.

TYPE

Function

DESCRIPTION

As opposed to the standard TRIM() function, which only trims strict space
characters ('' ''), trim_wspace() also trims new line, tab and backspace
characters.

SYNOPSIS



       trim_wspace(txt TEXT CHARSET utf8)
         RETURNS TEXT CHARSET utf8


Input:

* txt: text to trim In case of NULL, the function returns NULL.


EXAMPLES

Trim text (spaces between literals are unaffected):


       SELECT trim_wspace(''\\n a b c \\n   '') AS res;
       +-------+
       | res   |
       +-------+
       | a b c |
       +-------+


Similar to the above, quoted for clarity:


       SELECT CONCAT(''"'', trim_wspace(''\\n the quick brown fox \\n   ''),
       ''"'') AS res;
       +-----------------------+
       | res                   |
       +-----------------------+
       | "the quick brown fox" |
       +-----------------------+



ENVIRONMENT

MySQL 5.1 or newer

SEE ALSO

replace_all()

AUTHOR

Shlomi Noach
');
		
			INSERT INTO common_schema.help_content VALUES ('variables','
SYNOPSIS

User defined variables used as input to common_schema routines, or are the
output of routines.
Input variables:

* @common_schema_verbose: set verbose messages
* @common_schema_dryrun: avoid dynamic query execution
* @common_schema_debug: set debug mode

Output variables:

* @common_schema_rowcount: number of rows affected by last dynamic query
* @common_schema_error: latest error message


DESCRIPTION

@common_schema_verbose and @common_schema_dryrun both serve as input to
exec_single(), which is a basic function in common_schema for dynamic query
execution. eval(), exec(), foreach(), repeat_exec(), run() -- all rely on
exec_single(), hence these two params affect all aforementioned functions.
Setting @common_schema_dryrun := 1 avoids executing dynamic queries issues by
exec_single(). This makes for a way to test your code before execution.
Setting @common_schema_verbose := 1 prints out executed queries, and serves as
a verbose mode for your code''s activity.
Setting @common_schema_debug := 1 will enable some internal debugging code.
The particulars are subject to change, but you may find it useful.
When issuing queries such as INSERT, DELETE, UPDATE via dynamic SQL, the
ROW_COUNT() function does not behave as expected, since the DEALLOCATE
statement resets it. This is why after each invocation of dynamic query via
exec_single(), the @common_schema_rowcount variable is set so as to reflect
the ROW_COUNT() as read immediately after invocation.
@common_schema_error can be set by various functionality upon error. In
particular, it is set by the throw() routine to the error message provided.

NOTES

common_schema utilized many more variables, internally. Internal user defined
variables are named, by convention, @_common_schema_*. You should refrain from
depending on the output of any such variable, nor should you modify such
variables.
');
		

--
-- Check up on installation success:
--
UPDATE 
  metadata
SET 
  attribute_value = '1'
WHERE 
  attribute_name = 'install_success'
;

UPDATE 
  metadata
SET 
  attribute_value = '1'
WHERE 
  attribute_name = 'base_components_installed'
;

UPDATE 
  metadata
SET 
  attribute_value = ((@common_schema_innodb_plugin_installed > 0) AND (@common_schema_innodb_plugin_installed = @common_schema_innodb_plugin_expected))
WHERE 
  attribute_name = 'innodb_plugin_components_installed'
;

UPDATE 
  metadata
SET 
  attribute_value = ((@common_schema_percona_server_installed > 0) AND (@common_schema_percona_server_installed = @common_schema_percona_server_expected))
WHERE 
  attribute_name = 'percona_server_components_installed'
;

FLUSH TABLES mysql.db;
FLUSH TABLES mysql.proc;

set @notes_message := '';
SET @notes_message := CONCAT(@notes_message, 
  CASE
	WHEN @@global.thread_stack < 256*1024 THEN '\n- Please set ''thread_stack = 256K'' in your config file and apply, in order for QueryScript to run properly'
    ELSE ''	
  END
);
SET @notes_message := CONCAT(@notes_message, 
  CASE
	WHEN @@global.innodb_stats_on_metadata = 1 THEN '\n- Please set ''innodb_stats_on_metadata = 0'' for INFORMATION_SCHEMA related views to respond timely'
    ELSE ''	
  END
);

SET @message := '';
SET @message := CONCAT(@message, '\n- Base components: ', IF(TRUE, 'installed', 'not installed'));
SET @message := CONCAT(@message, '\n- InnoDB Plugin components: ', 
  CASE @common_schema_innodb_plugin_installed
	WHEN 0 THEN 'not installed'
	WHEN @common_schema_innodb_plugin_expected THEN 'installed'
    ELSE CONCAT('partial install: ', @common_schema_innodb_plugin_installed, '/', @common_schema_innodb_plugin_expected)	
  END
);
SET @message := CONCAT(@message, '\n- Percona Server components: ', 
  CASE @common_schema_percona_server_installed
	WHEN 0 THEN 'not installed'
	WHEN @common_schema_percona_server_expected THEN 'installed'
    ELSE CONCAT('partial install: ', @common_schema_percona_server_installed, '/', @common_schema_percona_server_expected)	
  END
);
SET @message := CONCAT(@message, '\n');
SET @message := CONCAT(@message, '\nInstallation complete. Thank you for using common_schema!');

call prettify_message('notes', trim_wspace(@notes_message));
call prettify_message('complete', trim_wspace(@message));

set @@sql_mode := @current_sql_mode;

--
-- End of common_schema build file
--
