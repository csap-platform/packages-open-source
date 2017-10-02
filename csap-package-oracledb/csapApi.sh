#!/bin/bash


# org.csap:Oracle:11.2.0.4.6:zip

function displayHeader() {
	echo
	echo
	echo	
	echo ====================================================================
	echo == 
	echo == CSAP Oracle Package: $*
	echo ==
	echo ====================================================================
	
}

function printIt() {
	echo;echo;
	echo = 
	echo = $*
	echo = 
}

function checkInstalled() { 
	packageName="$1"
	rpm -q $packageName
	if [ $? != 0 ] ; then 
		printIt error: $packageName not found, install using yum -y install; 
		exit; 
	fi   
}


function buildAdditionalPackages() {
	
	displayHeader buildAdditionalPackages: no additional packages to build

}


function getAdditionalBinaryPackages() {
	
	displayHeader binaries are retrieved during initial start from $toolsServer
	
	# rm -rf $runDir ;
	
}




function killWrapper() {


	displayHeader killWrapper
	# change to 1 in order to delete. Note that the delete might take some time as fs is large
	mustSetThisToClean="1" ;

	isClean=`expr match "$svcClean" 'clean' != 0`
	
	if [ $isClean == "1" ] && [ "$mustSetThisToClean" == "" ] ; then
	
		printIt Oracle is protected from accidental deployments
		echo Use the console editor to set mustSetThisToClean on line 43 in consoleCommands.sh
		echo ; echo ;
		sleep 10 ; # give console a chance to view
		
	fi ;
	
	if [ $isClean == "1" ]   && [ "$mustSetThisToClean" == "1" ] ; then
	
	
		printIt matching processes for oracle echo `pgrep -l -u oracle`
		echo == Running a pkill on oracle to do any final cleanup
		sudo /usr/bin/pkill -9 -u oracle
	
		printIt Clean specified , deleting /home/oracle contents
		wipeOracleOffDisk
		

		
		#
	 	# Oracle is stateful in the OS. 
		#
		
		wipeOracleFromSharedMemory

	else 
		printIt Attempting a graceful shutdown
		stopWrapper
		sudo /usr/bin/pkill -9 -u oracle
	fi ;
	
}

function wipeOracleOffDisk() {
	
	printIt "cleaning oracle file references"
	
	sudo /bin/rm -rf /home/oracle/*
	sudo /bin/rm -rf /tmp/*
	sudo /bin/rm -rf /tmp/.oracle
	sudo /bin/rm -rf /var/tmp/.oracle
	sudo /bin/rm -rf /etc/ora*
}

function wipeOracleFromSharedMemory() {
	
	printIt "cleaning oracle shared memory references"
	
	rm -rf $STAGING/bin/rootDeploy.sh
		
	# 
	# ssadmin user has sudo root on file: /home/ssadmin/staging/bin/rootDeploy.sh
	# So content is put in there for execution as root
	#
	echo 'for semid in `ipcs -s | grep -v -e - -e key  -e "^$" | cut -f2 -d" "`; do ipcrm -s $semid; done' >>  $STAGING/bin/rootDeploy.sh
	echo 'for semid in `ipcs -m | grep -v -e - -e key  -e "^$" | cut -f2 -d" "`; do ipcrm -m $semid; done' >>  $STAGING/bin/rootDeploy.sh
	
	chmod 755 /home/ssadmin/staging/bin/rootDeploy.sh
	sudo /home/ssadmin/staging/bin/rootDeploy.sh $runDir/scripts
		
	
	printIt "ipcs output, note that oracle install will fail if ipcs is still showing semaphores"
	ipcs -a
	
	numLeft=`ipcs | grep -v -e - -e key -e root -e "^$" | wc -l`
	
	if [ $numLeft != "0" ] ; then
		echo ; echo ; echo =====
		echo ===== Error : oracle is not ok with semaphores on system. Use ipcs to list and ipcsrm to delete
		sleep 10 ; # give console a chance to view
	fi
}

function stopWrapper() {

	displayHeader stop
	
	printIt running /sbin/service oracle stop
	sudo /sbin/service oracle stop
	
}


function startWrapper() {
	
	displayHeader start
	
	checkInstalled make
	
	isSkipDeploy=`expr match "$svcSkipDeployment" 'yes' != 0`
	

	wipeOracleFromSharedMemory
		
	if [ $isSkip == "0"  ]  ; then
	
		if [ -e /home/oracle/base  ]  ; then
			printIt Info: Found /home/oracle/base. Skipping oracle deployment

		else 
			
			printIt "updating configuration files with companyDomain $companyDomain"
			sed -i -- "s/yourcompany/$companyDomain/g" scripts/bootStrapData/*
			sed -i -- "s/yourcompany/$companyDomain/g" scripts/dbca.rsp
			
			if [ -e "$serviceConfig/$csapName/ocm.rsp" ]; then
				printIt "copying: $serviceConfig/$csapName/ocm.rsp to scripts"
				\cp -fr $serviceConfig/$csapName/ocm.rsp scripts
			else
				printIt Did not find common override resources: $serviceConfig/$serviceName/resources/common
				exit 99
			fi ;
			
			printIt Redeploying Oracle - making sure that nothing is left behind
			
			wipeOracleOffDisk 
			
			printIt Info: Deploying $serviceName using $STAGING/warDist/$serviceName.zip

		
			printIt "Kicking off oracleMasterInstaller.sh"
		
			rm -rf $STAGING/bin/rootDeploy.sh
			
			# 
			# ssadmin user has sudo root on file: /home/ssadmin/staging/bin/rootDeploy.sh
			# So content is put in there for execution as root
			#
			cat $runDir/scripts/oracleMasterInstaller.sh >  $STAGING/bin/rootDeploy.sh
			chmod 755 /home/ssadmin/staging/bin/rootDeploy.sh
			
			sudo /home/ssadmin/staging/bin/rootDeploy.sh $runDir/scripts
		fi ;
	else
		printIt "Info: Skipping Deployment"
	fi;
	
	
	
	printIt Usually this method would extract the binary for target, but oracle is a special case
	
	printIt service is managed by OS via /sbin/service oracle start/stop/restart
	sudo /sbin/service oracle start
	
	printIt Note: Oracle takes at least a couple of minutes to fully initialize. Use test app or toad to test for connection.
}
