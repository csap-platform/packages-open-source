#!/bin/bash



distDir="$1"	
toolsServer="$2"

scriptDir=`dirname $0`
scriptName=`basename $0`

debug() {
	echo;echo; echo =
	echo = $scriptName ; 
	echo = $*
	echo = 
	
}

debug  Running $scriptName with distDir $distDir and tools server $toolsServer

	
source $HOME/oraenv.sh

debug Getting patch from $toolsServer

cd $ORAUSER_HOME/11.2.0.2
wget http://$toolsServer/oracle/p6880880_112000_Linux-x86-64.zip
wget http://$toolsServer/oracle/p13343424_112020_Linux-x86-64.zip

cp p6880880_112000_Linux-x86-64.zip $ORACLE_HOME/.
cd $ORACLE_HOME
mv OPatch OPatch.old
unzip p6880880_112000_Linux-x86-64.zip

/home/oracle/base/product/11.2/db_1/OPatch/opatch version >> opatchversion.txt

grep "11.2.0.4.0" opatchversion.txt
if [ $? -eq 0 ]
then
 echo version is correct
else
 echo version is not correct
return 1
fi

debug Stopping Listener
lsnrctl stop



debug killing oracle db
 echo shutdown immediate > /home/oracle/shutdown.sql
 echo exit >> /home/oracle/shutdown.sql
 chmod 755 /home/oracle/shutdown.sql
       
sqlplus '/ as sysdba' @/home/oracle/shutdown.sql

cd /home/oracle/11.2.0.2
unzip p13343424_112020_Linux-x86-64.zip 
cd /home/oracle/11.2.0.2/13343424/


debug Applying patches

/home/oracle/base/product/11.2/db_1/OPatch/opatch apply -silent -ocmrf $ORAUSER_HOME/ocm.rsp


debug Starting Oracle

 echo startup > /home/oracle/startup.sql
 echo exit >> /home/oracle/startup.sql
 chmod 755 /home/oracle/startup.sql
 
sqlplus '/ as sysdba' @/home/oracle/startup.sql


debug Starting Listener

lsnrctl start

cd $ORACLE_HOME/rdbms/admin

debug invoking catbundle

sqlplus '/ as sysdba' << EOF 
@catbundle.sql psu apply
exit
EOF


debug Exiting

