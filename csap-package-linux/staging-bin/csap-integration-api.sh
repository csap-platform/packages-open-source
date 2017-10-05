#!/bin/bash 


printIt "checking for CSAP package API"


if [ "$skipApiExtract" == "" ] && [ ! -e $csapWorkingDir/scripts/consoleCommands.sh ] &&  [ ! -e $csapWorkingDir/csapApi.sh ] ; then
	
	printIt "Did not find api, extracting $csapPackageFolder/$serviceName.zip to $csapWorkingDir"
	
	if [ -e $csapWorkingDir/version ] ; then
		printLine "Removing $csapWorkingDir/version"
		\rm -rf  $csapWorkingDir/version
	fi;

	/usr/bin/unzip -o -qq $csapPackageFolder/$serviceName.zip -d $csapWorkingDir
	
	if [ -e $csapWorkingDir/version ] ; then
		printIt "Found: $csapWorkingDir/scripts - running native2ascii. Use a different folder name to bypass"
		find $csapWorkingDir/scripts/* -name "*.*" -exec native2ascii '{}' '{}' \;
	fi ;
	chmod -R 755 $csapWorkingDir
fi ;

if [ -e $csapWorkingDir/csapApi.sh ] ; then 
	printIt "Loading: $csapWorkingDir/csapApi.sh" ;
	source $csapWorkingDir/csapApi.sh ;
	apiFound="true";
	
elif [ -e $csapWorkingDir/scripts/consoleCommands.sh ] ; then 
	printIt "Legacy api in use: $csapWorkingDir/scripts/consoleCommands.sh,  switch to csapApi.sh" ;
	source $csapWorkingDir/scripts/consoleCommands.sh ;
	apiFound="true";
		
else 
	printIt "Warning: did not find $csapWorkingDir/csapApi.sh"
	apiFound="false";
fi;