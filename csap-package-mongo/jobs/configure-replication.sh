#!/bin/bash

function printIt() { echo; echo; echo =========; echo == $* ; echo =========; }


mongoBase="$csapWorkingDir"
mongoBin="$mongoBase/mongodatabase/bin"


printIt Need to update
	

printIt Daily events using $mongoBase/mongoJs/eventSamples.js

$mongoBin/mongo \
	event \
	-u $mongoUser -p $mongoPassword --authenticationDatabase admin \
	$mongoBase/mongoJs/eventSamples.js
	
exit
