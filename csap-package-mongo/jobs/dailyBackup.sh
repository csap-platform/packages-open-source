#!/bin/bash

function printIt() { echo; echo; echo =========; echo == $* ; echo =========; }

mongoTargetHost=`hostname`


printIt user: $mongoUser


#targetFrom="2016-07-11"
#targetTo="2016-07-17"

targetFrom=`date --date="1 days ago" +%Y-%m-%d`
targetTo=`date --date="1 days ago"  +%Y-%m-%d`

mongoBin="$csapWorkingDir/mongodatabase/bin"

printIt Note script timeouts need to be extended. Using $mongoBin on $mongoTargetHost

dailyBackupDir="/data/backup/daily"

printIt removing items older then 5 days in $dailyBackupDir 
find $dailyBackupDir -mindepth 1 -mtime +5 -delete


NOW=$(date +"%h-%d-%I-%M-%S")

backupDir=$dailyBackupDir/$mongoTargetHost-$NOW

printIt Creating  $backupDir
mkdir -p $backupDir ; cd $backupDir ; touch _from_"$targetFrom"_to_"$targetTo"

	
printIt "Settings: mongodump using $mongoTargetHost from $targetFrom to $targetTo"

if [ "$IsMaster" == "1" ] ; then 
	printIt Job skipped, it is only run on non-master
	exit;
fi;

printIt "backing up: event records:"
$mongoBin/mongodump --host $mongoTargetHost \
	-d event -c eventRecords \
	-u $mongoUser -p $mongoPassword --authenticationDatabase admin \
	-q "{\"createdOn.date\":{\$gte:\"$targetFrom\", \$lte:\"$targetTo\"}}" \
	2>&1 --gzip --archive=eventRecords.gz

du -h $backupDir/e*.gz

printIt "backing up: metrics attributes"
$mongoBin/mongodump --host $mongoTargetHost \
	-d metricsDb -c metricsAttributes \
	-u $mongoUser -p $mongoPassword --authenticationDatabase admin \
	-q "{\"createdOn.date\":{\$gte:\"$targetFrom\", \$lte:\"$targetTo\"}}" \
	2>&1 --gzip --archive=metricsAttributes.gz

du -h $backupDir/m*.gz	

printIt "backing up:metrics data"
$mongoBin/mongodump --host $mongoTargetHost \
	-d metricsDb -c metrics \
	-u $mongoUser -p $mongoPassword --authenticationDatabase admin \
	-q "{\"createdOn.date\":{\$gte:\"$targetFrom\", \$lte:\"$targetTo\"}}" \
	2>&1 --gzip --archive=metrics.gz 

	
#du -h *
#printIt Building compressed tar and removing dump
#tar -cvzf  dump.tar.gz dump
#\rm -rf dump


printIt Backup Completed
du -h $backupDir/*.gz


printIt Flag to exit read loop in AdminController.java XXXYYYZZZ_AdminController ;
	
	