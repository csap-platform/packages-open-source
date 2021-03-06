spool job_schedule.log

-- Fun way of testing on your desktop without updating tns
-- sqlplus user/pass@'(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=yourdb)(PORT=1521)))(CONNECT_DATA=(SID=dev01)))'
-- @JOB_SCHEDULE.sql

prompt deleting previous contents of job_schedule
delete from CSAP_TEST.JOB_SCHEDULE ;


prompt now inserting test data

Insert into IMS_WKF_ADMIN.JOB_SCHEDULE
   (SCHEDULE_OBJID, JNDI_NAME, MESSAGE_SELECTOR_TEXT, EVENT_MESSAGE_TEXT, EVENT_DESCRIPTION, NEXT_RUN_INTERVAL_TEXT, LAST_INVOKE_TIME, NEXT_RUN_TIME, CREATE_DATE, CREATE_ORA_LOGIN, UPDATE_DATE, UPDATE_ORA_LOGIN, STATUS_CD)
 Values
    
    (1, 'somejndi', 'SchedulerMessage', 'myMessage', 'my test event', 'sysdate+1/(24*60)', 
    TO_DATE('06/13/2017 01:32:59', 'MM/DD/YYYY HH24:MI:SS'), TO_DATE('05/30/2017 21:46:33', 'MM/DD/YYYY HH24:MI:SS'), 
    TO_DATE('10/18/2017 04:14:48', 'MM/DD/YYYY HH24:MI:SS'), 'NLS_APPL', TO_DATE('06/13/2017 01:32:59', 'MM/DD/YYYY HH24:MI:SS'), 
    'someid', 'INACTIVE');
    
 spool off ;
exit;