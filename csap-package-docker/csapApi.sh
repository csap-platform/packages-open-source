#!/bin/bash

function displayHeader() {
	echo
	echo
	echo	
	echo ====================================================================
	echo == 
	echo == CSAP DOCKER Package: $*
	echo ==
	echo ====================================================================
	
}


function printIt() {
	echo;echo;
	echo = 
	echo = $*
	echo = 
}



#
# Use this for any software "build" operations. Typically used for building c/c++ code
# -  eg. apache httpd, redis
# -  This method should also upload into a repository (usually maven)
# - Note: most software packages are available as prebuilt distributions, in which case no implementation is required
#
function buildAdditionalPackages() {
	
	displayHeader buildAdditionalPackages - none


}

#
# Use this for getting binary packages - either prebuilt by distributions (tomcat, mongodb, cassandra,etc.)
#   or built using buildAdditionalPackages() above
#   Note that CSAP deploy will invoke this on the primary host selected during deployment, and then automatically
#   - synchronize the packageDir to all the other hosts (via local network copy) for much faster distribution
#
function getAdditionalBinaryPackages() {
	
	displayHeader getAdditionalBinaryPackages - none
	
}




#
# CSAP agent will always kill -9 after this command
#
function killWrapper() {

	displayHeader KILL 
	if [ $isClean == "1" ] ||  [ $isSuperClean == "1"  ] ; then
		
		run-docker clean ;
		
	fi ;
	
	run-docker stop
}

#
# CSAP agent will always kill -9 after this command. For data sources - it is recommended to use the 
# shutdown command provided by the stack to ensure caches, etc. are flushed to disk.
#
function stopWrapper() {

	displayHeader stop 

	run-docker stop
	
}


#
# startWrapper should always check if $csapWorkingDir exists, if not then create it using $packageDir
# 
#
function startWrapper() {
	displayHeader START
	
     
	# install only occurs if not already present 
	run-docker install
	
	run-docker start
	
	dockerConfig="$csapWorkingDir/osConfiguration" ;
	
	if [ ! -e $dockerConfig ] ; then 
		
		printIt "creating logs in $csapLogDir, and linking /var/log/messages"
		mkdir -p $csapLogDir
		cd $csapLogDir
		ln -s /var/log/messages var-log-messages
		printIt "Creating configuration shortcuts in $dockerConfig"
		mkdir -p $dockerConfig ;
		cd $dockerConfig ;
			
		set -x
		ln -s /usr/lib/docker-storage-setup .
		ln -s /etc/sysconfig/docker sysconfig-docker
		
		ln -s /usr/lib/docker-latest-storage-setup .
		ln -s /etc/sysconfig/docker-latest sysconfig-docker-latest
		
		ln -s /var/lib/docker lib-docker
		
		set +x
	fi ;
	
	  
	cd $csapWorkingDir ;
    

	
}


#
#  use root to run docker commands
#
function run-docker() {
	
	command="$1" ;
	rm -rf $STAGING/bin/rootDeploy.sh
	
	helperFunctionsFile="$csapWorkingDir/scripts/dockerCommands.sh" ;
	if [ ! -f "$helperFunctionsFile" ] ; then 
		helperFunctionsFile="scripts/dockerCommands.sh" ;
	fi;
	
	cat $helperFunctionsFile >  $STAGING/bin/rootDeploy.sh

	if [ "$dockerStorage" == "" ] ; then 
		dockerStorage="$HOME/docker-default-storage";
	fi ;
	
	chmod 755 /home/ssadmin/staging/bin/rootDeploy.sh
	sudo /home/ssadmin/staging/bin/rootDeploy.sh $command $dockerStorage $allowRemote $csapVersion
		
		# "$csapWorkingDir" "$version" "$packageDir"	
}
