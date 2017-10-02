spool csapSetup_sql.log


prompt creating temp
create directory TEMP as '/home/oracle/temp';

prompt creating tablespaces

--------------------------------------------------------------------------
prompt csap test tables

CREATE TABLESPACE CSAP_DATA DATAFILE 
  '/home/oracle/base/oradata/ORACLE_SID/cspdata01.dbf' SIZE 10240M AUTOEXTEND OFF,
  '/home/oracle/base/oradata/ORACLE_SID/cspdata02.dbf' SIZE 5120M AUTOEXTEND OFF
LOGGING
ONLINE
PERMANENT
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
BLOCKSIZE 8K
SEGMENT SPACE MANAGEMENT MANUAL
FLASHBACK ON;

CREATE USER CSAP_TEST
  IDENTIFIED BY CSAP_TEST
  DEFAULT TABLESPACE CSAP_DATA
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT
  ACCOUNT UNLOCK;
  -- 2 Roles for CSAP_TEST 
  GRANT CONNECT TO CSAP_TEST;
  GRANT RESOURCE TO CSAP_TEST;
  ALTER USER CSAP_TEST DEFAULT ROLE ALL;
  -- 1 System Privilege for CSAP_TEST 
  GRANT UNLIMITED TABLESPACE TO CSAP_TEST;
GRANT CREATE DATABASE LINK TO CSAP_TEST;

----------------------------------------------
Prompt Creating Role MY_USER

CREATE ROLE MY_USER NOT IDENTIFIED;

GRANT CREATE SESSION TO MY_USER;
GRANT CREATE SYNONYM TO MY_USER;

Prompt Creating Role MY_USER_ADMIN

CREATE ROLE MY_USER_ADMIN NOT IDENTIFIED;

GRANT CREATE DATABASE LINK TO MY_USER_ADMIN;
GRANT CREATE PROCEDURE TO MY_USER_ADMIN;
GRANT CREATE ROLE TO MY_USER_ADMIN;
GRANT CREATE SEQUENCE TO MY_USER_ADMIN;
GRANT CREATE SESSION TO MY_USER_ADMIN;
GRANT CREATE SNAPSHOT TO MY_USER_ADMIN;
GRANT CREATE SYNONYM TO MY_USER_ADMIN;
GRANT CREATE TABLE TO MY_USER_ADMIN;
GRANT CREATE TRIGGER TO MY_USER_ADMIN;
GRANT CREATE TYPE TO MY_USER_ADMIN;
GRANT CREATE VIEW TO MY_USER_ADMIN;
GRANT ON COMMIT REFRESH TO MY_USER_ADMIN;
GRANT QUERY REWRITE TO MY_USER_ADMIN;

Prompt Granting Roles to all users in the DB

grant MY_USER_ADMIN to CSAP_TEST ;

----------------------------------------------
Prompt Removing Case sensitive passwords

ALTER SYSTEM SET SEC_CASE_SENSITIVE_LOGON = FALSE;
ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME UNLIMITED;
ALTER PROFILE DEFAULT LIMIT PASSWORD_GRACE_TIME UNLIMITED;
ALTER PROFILE DEFAULT LIMIT  PASSWORD_LOCK_TIME UNLIMITED;
ALTER PROFILE DEFAULT LIMIT  FAILED_LOGIN_ATTEMPTS UNLIMITED;

----------------------------------------------
Prompt Setting undo and temp data sizes
alter database tempfile '/home/oracle/base/oradata/ORACLE_SID/temp01.dbf' resize 6000M;
 alter database tempfile '/home/oracle/base/oradata/ORACLE_SID/temp01.dbf' autoextend off;
 alter database datafile '/home/oracle/base/oradata/ORACLE_SID/undotbs01.dbf' resize 8000M;
alter database datafile '/home/oracle/base/oradata/ORACLE_SID/undotbs01.dbf' autoextend off;


----------------------------------------------
Prompt Setting tuning parameters

alter system set processes=1000 scope=spfile;
alter system set open_cursors=2000 scope=both;
alter system set cursor_sharing=FORCE scope=both;
alter system set session_cached_cursors = 250 scope=spfile;
alter system set sessions=1000 scope=spfile;
alter system set memory_target=0 scope=spfile;
alter system set memory_max_target=0 scope=spfile;
alter system set sga_target=10000M scope=spfile;  
alter system set pga_aggregate_target=4000M scope=spfile;  
alter system reset memory_target scope=spfile;
alter system reset memory_max_target scope=spfile; 

----------------------------------------------
Prompt unlocking CSAP_TEST
ALTER USER CSAP_TEST ACCOUNT UNLOCK;

----------------------------------------------


spool off

exit;

