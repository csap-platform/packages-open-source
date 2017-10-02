#!/bin/bash


scriptDir=`dirname $0`
scriptName=`basename $0`

debug() {
	echo;echo; echo =
	echo = $scriptName ; 
	echo = $*
	echo = 
	
}

distDir="$1"


echo adding $distDir/oraenv.sh into /etc/bashrc
cat $distDir/oraenv.sh >> /etc/bashrc
	
source /etc/bashrc

echo ==  toolsServer should be set in /etc/bashrc, value is: $toolsServer
echo == 



debug  Running $scriptName with distDir $distDir and tools server $toolsServer

	
debug starting oracleRootInstall
$distDir/oracleRootInstall.sh $distDir $toolsServer

debug starting oracle user oracleInstall
su - oracle -c "$ORAUSER_HOME/oracleInstall.sh" 

sleep 10 

debug  WARNING: After a few minutes the following message should appear "Successfully Setup Software Message" 
debug  Polling for completion of Oracle 
# read progress
echo == note that this loop greps for oracle. It will continue until it finds 1 or fewer instances running
echo == instance 1 will be the grep,  any others means install is still running
while [ `ps -u oracle | wc -l`  -gt  1 ]; do  echo sleeping for 30 second;sleep 30 ; done

debug   Saw success - continuing with oracleRootInstall2 
cd $HOME

debug launching oracleRootInstall2
$distDir/oracleRootInstall2.sh $distDir $toolsServer


debug  setting up /etc/init.d/oracle
\cp -f $distDir/oracle.sh /etc/init.d/oracle
chmod 755 /etc/init.d/oracle
/sbin/chkconfig --add oracle


# echo == CS-AP will autostart oracle
#	chkconfig oracle on
# echo == Oracle added - and is started via the install above


debug  Invoking dataLoad.sh script
$distDir/dataLoad.sh $distDir $toolsServer

debug Install Completed. Review output in runtime folder, and check every log file as oracle install can silently fail.


	

