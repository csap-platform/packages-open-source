#!/bin/bash



function displayHeader() {
	echo
	echo
	echo	
	echo ====================================================================
	echo == 
	echo "== CSAP jstatsd package: $*"
	echo ==
	echo ====================================================================
	
}


function printIt() {
	echo;echo;
	echo = 
	echo = $*
	echo = 
}



function buildAdditionalPackages() { displayHeader "No Source Packages" }


function getAdditionalBinaryPackages() { displayHeader "No Binary Packages" }




function killWrapper() {

	displayHeader Attempting a graceful shutdown
	stopWrapper
	
	# Not killing script
	# sudo /usr/bin/pkill -u mquser
	
	isClean=`expr match "$svcClean" 'clean' != 0`
	if [ $isClean == "1" ] ||  [ $isSuperClean == "1"  ] ; then
		echo 
		echo == Clean specified , deleting /home/mquser contents
		sudo /bin/rm -rf /home/oracle/scripts*
		rm -rf $csapWorkingDir
	fi ;
	
	echo == 
	exit ;
}

function stopWrapper() { displayHeader "No Stop command" }


function startWrapper() {
	displayHeader "Kicking off dataLoadAsRoot.sh"
	
	rm -rf $STAGING/bin/rootDeploy.sh
	cat scripts/dataLoadAsRoot.sh >  $STAGING/bin/rootDeploy.sh
	chmod 755 /home/ssadmin/staging/bin/rootDeploy.sh
	
	#
	# We add serviceName to params so that process state is reflected in UI
	
	sudo /home/ssadmin/staging/bin/rootDeploy.sh "$serviceName"

	
	cd $csapWorkingDir ;

	
	
}
