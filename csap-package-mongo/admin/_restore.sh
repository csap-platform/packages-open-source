#!/bin/bash

function printIt() { echo; echo; echo =========; echo == $* ; echo =========; }

targetHost="csap-dev01"
targetPass="password"


restoreDir="/data/backup/replaceThis"
cd $restoreDir

mongoBin="/home/ssadmin/processing/mongoDb_27017/mongodatabase/bin"

printIt `pwd` Note script timeouts need to be extended

NOW=$(date +"%h-%d-%I-%M-%S")


printIt "$NOW $mongoBin/mongorestore: restoring to $targetHost using $restoreDir"

du -h $restoreDir/*.gz

printIt tail restoreProgress.txt to monitor progress as restore is done in background



$mongoBin/mongorestore -v --host $targetHost \
	-d metricsDb -c metrics \
	-u dataBaseReadWriteUser -p $targetPass --authenticationDatabase admin \
	--gzip --archive=$restoreDir/metrics.gz \
	2> $restoreDir/restoreProgress.txt &
	
echo Flag to exit read loop in AdminController.java XXXYYYZZZ_AdminController ;	
exit

# Tips
#  make sure indexs are created
# capped size = 15 * 1024 * 1024 * 1024 = 1073741824 * GB 3000 assuming 5 to 1 compression = 600GB compresses
# Make sure lots of swap is configured to avoid aborts



$mongoBin/mongorestore --host $targetHost \
	-d event -c eventRecords \
	-u dataBaseReadWriteUser -p $targetPass --authenticationDatabase admin \
	--gzip --archive=$restoreDir/eventRecords.gz
	


$mongoBin/mongorestore --host $targetHost \
	-d metricsDb -c metricsNew \
	-u dataBaseReadWriteUser -p $targetPass --authenticationDatabase admin \
	--gzip --archive=$restoreDir/metrics.gz \
	2> $restoreDir/restoreProgress.txt &
	
exit

	
printIt "event records: mongorestor	using $targetHost from $targetFrom to $targetTo"
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