spool job_schedule.log

prompt creating job schedule table 
@Job_Schedule_table_script.sql


prompt populating job schedule seed data
@Job_Schedule_seed_data.sql


spool off;
exit;
