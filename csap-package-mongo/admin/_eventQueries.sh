#!/bin/bash

function printIt() { echo; echo; echo =========; echo == $* ; echo =========; }


mongoBase="CSAP_WORKING"
mongoBin="$mongoBase/mongodatabase/bin"
cd $mongoBase


printIt Daily events using script

$mongoBin/mongo \
	event \
	-u dataBaseReadWriteUser -p password --authenticationDatabase admin \
	$mongoBase/mongoJs/eventSamples.js

printIt Daily event count
$mongoBin/mongo \
	event \
	-u dataBaseReadWriteUser -p password --authenticationDatabase admin \
	--eval 'db.eventRecords.count({"createdOn.date":{$gte:"2016-03-02",$lt:"2016-03-03"}})'



	
printIt mongo server status
$mongoBin/mongo \
	event \
	-u dataBaseReadWriteUser -p password --authenticationDatabase admin \
	--eval "printjson(db.serverStatus())"
	
exit

# print event records on day
$mongoBin/mongo \
	event \
	-u dataBaseReadWriteUser -p password --authenticationDatabase admin \
	--eval 'printjson( db.eventRecords.find({"createdOn.date":{$gte:"2016-03-02",$lt:"2016-03-03"}}).toArray() )'

# sample dump
$mongoBin/mongodump --host $targetHost \
	-d event -c eventRecords \
	-u dataBaseReadWriteUser -p $targetPass --authenticationDatabase admin \
	-q "{\"createdOn.date\":{\$gt:\"$targetFrom\"}}" 


