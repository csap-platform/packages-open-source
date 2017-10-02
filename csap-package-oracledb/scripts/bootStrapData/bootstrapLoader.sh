#!/bin/bash
# must be run as Oracle DBA user
# set all Oracle env variables 
# This is executed using the factory installer
# 
#Steps :
#   after ftping these scripts to cstgtools:db , run find * -name "*.*" -exec dos2unix '{}' '{}' \;
#1. Entries in TNS names for CAFI2STG, SCNGSTG  -- send the master list
#1. Run the script " " to create tablespaces, users
#2. Run the seed data scripts (Denodo Ref app and job schedule)
#3. scp the dump file from the CS depot to the dump_dir location
#4. unzip the dump file
#5. import the dump file using DBA acount with impdp utility

# replacing ORACLE_SID variable in the sql files to the actual ORACLE Instance name
sed -i "s/ORACLE_SID/$ORACLE_SID/g" *.sql *.ora
sed -i "s/ORACLE_HOSTNAME/$HOSTNAME/g" *.sql *.ora

echo ==
echo == copying master tnsnames and sqlnet.ora from cstgtools to the factory
echo == 

cp ./tnsnames.ora $ORACLE_HOME/network/admin/.
cp ./sqlnet.ora $ORACLE_HOME/network/admin/.
cp ./ldap.ora $ORACLE_HOME/network/admin/.

echo == Adding Security fix for $ORACLE_HOME/network/admin/listener.ora
echo "SECURE_REGISTER_LISTENER = (IPC,TCP)" >> $ORACLE_HOME/network/admin/listener.ora

echo == reloading listener
lsnrctl reload


echo ==
echo == Running csapSetup.sql
echo == 
sqlplus '/ as sysdba' @csapSetup.sql



#import the dump that was exported and is in the cstgtools host

#you have to be oracle user

#Seed Data


echo ==
echo == Creating csap test schema using job_schedule.sql
echo == 

sqlplus CSAP_TEST/CSAP_TEST @job_schedule.sql

# need export from dba admin in toad
# sqlplus POC_ADMIN/POC_ADMIN @POC_ADMIN_Seed_data.sql


