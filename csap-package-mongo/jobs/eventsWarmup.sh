#!/bin/bash

function printIt() { echo; echo; echo =========; echo == $* ; echo =========; }


mongoBase="$csapWorkingDir"
mongoBin="$mongoBase/mongodatabase/bin"

scriptToRun="$mongoBase/mongoJs/postRestartWarmup.js" ;


printIt Need to update
	

printIt Invoking $scriptToRun using $mongoUser

$mongoBin/mongo \
	event \
	-u $mongoUser -p $mongoPassword --authenticationDatabase admin \
	$scriptToRun
	
exit
