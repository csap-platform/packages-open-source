#!/bin/bash

function printIt() { echo; echo; echo =========; echo == $* ; echo =========; }


mongoBase="CSAP_WORKING"
mongoBin="$mongoBase/mongodatabase/bin"
cd $mongoBase

mongoTopSeconds=5

printIt mongotop output every $mongoTopSeconds seconds

$mongoBin/mongotop \
	event \
	-u dataBaseReadWriteUser -p password --authenticationDatabase admin \
	$mongoTopSeconds
