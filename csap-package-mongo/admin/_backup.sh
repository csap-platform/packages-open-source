#!/bin/bash

function printIt() { echo; echo; echo =========; echo == $* ; echo =========; }


mongoBase="CSAP_WORKING"
mongoBin="$mongoBase/mongodatabase/bin"
cd $mongoBase


targetHost="csap-dev01"
targetPass="password"


targetFrom="2016-07-11"
targetTo="2016-07-17"


printIt Note script timeouts need to be extended. Using $mongoBin

NOW=$(date +"%h-%d-%I-%M-%S")

onDemandBackupDir="/data/backup/onDemand"

printIt removing previous backups

\rm -rf $onDemandBackupDir/$targetHost*

backupDir=$onDemandBackupDir/$targetHost-$NOW

printIt Creating  $backupDir

mkdir -p $backupDir ; cd $backupDir ; touch _from_"$targetFrom"_to_"$targetTo"

	
printIt "event records: mongodump	using $targetHost from $targetFrom to $targetTo"
$mongoBin/mongodump --host $targetHost \
	-d event -c eventRecords \
	-u dataBaseReadWriteUser -p $targetPass --authenticationDatabase admin \
	-q "{\"createdOn.date\":{\$gte:\"$targetFrom\", \$lte:\"$targetTo\"}}" \
	--gzip --archive=eventRecords.gz

du -h $backupDir/*.gz

printIt "metrics attributes:  mongodump	using $targetHost from $targetFrom to $targetTo"
$mongoBin/mongodump --host $targetHost \
	-d metricsDb -c metricsAttributes \
	-u dataBaseReadWriteUser -p $targetPass --authenticationDatabase admin \
	-q "{\"createdOn.date\":{\$gte:\"$targetFrom\", \$lte:\"$targetTo\"}}" \
	--gzip --archive=metricsAttributes.gz

du -h $backupDir/*.gz	

printIt "metrics data: background dump - use metricsProgress.txt   mongodump	using $targetHost from $targetFrom to $targetTo"
$mongoBin/mongodump --host $targetHost \
	-d metricsDb -c metrics \
	-u dataBaseReadWriteUser -p $targetPass --authenticationDatabase admin \
	-q "{\"createdOn.date\":{\$gte:\"$targetFrom\", \$lte:\"$targetTo\"}}" \
	--gzip --archive=metrics.gz \
	2> metricsProgress.txt &

	
#du -h *
#printIt Building compressed tar and removing dump
#tar -cvzf  dump.tar.gz dump
#\rm -rf dump


printIt Backup Still in progress, monitor $backupDir
sleep 5 
du -h *
	
#	--query "{\"ts\":{\"\$gt\":{\"\$date\":`date -d $targetFrom +%s`000},\"\$lte\":{\"\$date\":`date -d 2016-04-01 +%s`000}}}"
	
echo Flag to exit read loop in AdminController.java XXXYYYZZZ_AdminController ;

exit


printIt Running mongoexport script
$mongoBin/mongoexport --host $targetHost \
	-d event  -c eventRecords \
	-q "{\"createdOn.date\":{\$gt:\"$targetFrom\"}}" \
	-u dataBaseReadWriteUser -p $targetPass --authenticationDatabase admin \
	--out events.json
	

printIt Running mongoexport script
$mongoBin/mongoexport --host $targetHost \
	-d event  -c eventRecords \
	-q "{\"createdOn.date\":{\$gt:\"$targetFrom\"}}" \
	-u dataBaseReadWriteUser -p $targetPass --authenticationDatabase admin \
	--out events.json