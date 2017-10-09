#!/bin/bash


#
# Simple script to load 1 or more sql files. You could load these from svn, or you could use wget to get from a filer
#

echo invoking sqlplus using job_schedule.sql
sqlplus '/ as sysdba' @job_schedule.sql

echo == completed scripts but adding a sleep for testing

sleep 60

echo == final exit