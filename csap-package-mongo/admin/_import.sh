#!/bin/bash

function printIt() { echo; echo; echo =========; echo == $* ; echo =========; }

targetHost="csap-dev01"
targetPass="password"


restoreDir="/data/backup/changeme"
cd $restoreDir

mongoBin="/home/ssadmin/processing/mongoDb_27017/mongodatabase/bin"

printIt `pwd` Note script timeouts need to be extended

NOW=$(date +"%h-%d-%I-%M-%S")


printIt "$NOW $mongoBin/mongorestore: restoring to $targetHost using $restoreDir"

du -h $restoreDir/*

printIt tail restoreProgress.txt to monitor progress as restore is done in background



$mongoBin/mongoimport -v --host $targetHost \
	-d metricsDb -c metrics \
	-u dataBaseReadWriteUser -p $targetPass --authenticationDatabase admin \
	--file metrics.json
#	--gzip --archive=$restoreDir/metrics.gz \
#	2> $restoreDir/restoreProgress.txt &
	
echo Flag to exit read loop in AdminController.java XXXYYYZZZ_AdminController ;	
exit