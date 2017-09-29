#!/bin/bash

function printIt() { echo; echo; echo =========; echo == $* ; echo =========; }


mongoBase="CSAP_WORKING"
mongoBin="$mongoBase/mongodatabase/bin"
cd $mongoBase


# secured env
mongoPassword=""


# postRestartWarmup.js replicaStatus.js migrationToNewDb.js setup1-users.js setup2-csap-db.js setup3-replication.js
mongoScript="replicaStatus.js"

# set to true
runInBackground="false"
NOW=$(date +"%h-%d-%I-%M-%S") 
outputFile="$mongoBase/logs/$mongoScript-$NOW.txt"

mongoScriptPath="$mongoBase/mongoJs/$mongoScript"


printIt Invoking $mongoBin/mongo  $mongoScriptPath

if [ "$mongoPassword" == "" ] ; then
	
	printIt "password is not set, running command unsecured. If security is enabled this will hang until process is killed"
	$mongoBin/mongo  $mongoScriptPath 
		
elif [ "$runInBackground" == "true" ] ; then
	
	printIt "running in background, results stored in $outputFile"
	$mongoBin/mongo  $mongoScriptPath \
		-u dataBaseReadWriteUser -p $mongoPassword --authenticationDatabase admin\
		2>&1 >$outputFile &
		
else
	
	printIt "running in foreground"
	$mongoBin/mongo  $mongoScriptPath \
		-u dataBaseReadWriteUser -p $mongoPassword --authenticationDatabase admin
fi;
	
	
printIt Flag to exit read loop in AdminController.java XXXYYYZZZ_AdminController ;
	
#_MONGOPATH_/mongo replicastatus.js