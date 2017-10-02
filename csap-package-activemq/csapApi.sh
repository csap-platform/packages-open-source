#!/bin/bash

function displayHeader() {
	echo
	echo
	echo	
	echo ====================================================================
	echo == 
	echo == CSAP activemq Package: $*
	echo ==
	echo ====================================================================
	
}


function printIt() {
	echo;echo;
	echo = 
	echo = $*
	echo = 
}


function deployWrapper() {
	displayHeader

	
}


function killWrapper() {

	displayHeader kill
	
	stopWrapper
	
	printIt "matching processes for mquser echo `pgrep -l -u mquser` , running pkill"
	
	sudo /usr/bin/pkill -u mquser
	
	isClean=`expr match "$svcClean" 'clean' != 0`
	if [ $isClean == "1" ] ||  [ $isSuperClean == "1"  ] ; then
		printIt "Clean specified , deleting /home/mquser contents"
		
		sudo /bin/rm -rf /home/mquser/*
		rm -rf $csapWorkingDir
	fi ;
	
}

function stopWrapper() {

	displayHeader stop
	
	
	printIt "running: /sbin/service activemq stop"
	
	sudo /sbin/service activemq stop
	
}


function startWrapper() {
	
	
	displayHeader start
	
	
	isSkipDeploy=`expr match "$svcSkipDeployment" 'yes' != 0`
	
	
	if [ $isSkip == "0"  ]  ; then
		
		printIt  "Deploying $serviceName using $STAGING/warDist/$serviceName.zip"
	
		rm -rf $STAGING/bin/rootDeploy.sh
		cat scripts/activemqRootInstall.sh >  $STAGING/bin/rootDeploy.sh
		chmod 755 /home/ssadmin/staging/bin/rootDeploy.sh
		
		printIt "Copying scripts/activemqRootInstall.sh and running as root"
		sudo /home/ssadmin/staging/bin/rootDeploy.sh
	else
		
		printIt "Skipping Deployment"
		
	fi;
	
	cd $csapWorkingDir ;

	
	printIt "starting service: /sbin/service activemq start/stop/restart"
	sudo /sbin/service activemq start
	
}
