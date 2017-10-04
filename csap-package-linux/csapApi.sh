#!/bin/bash



function displayHeader() {
	echo
	echo
	echo	
	echo ====================================================================
	echo == 
	echo "== CSAP java $majorVersion.$minorVersion Package: $*"
	echo ==
	echo ====================================================================
	
}


function printIt() {
	echo;echo;
	echo = 
	echo = $*
	echo = 
}


function buildAdditionalPackages() {
	
	displayHeader buildAdditionalPackages: no additional packages to build

	# most packages are most often managed via a staging host eg. http://csaptools.yourcompany.com/ is used for java
	# if binaries are built - it may or may not be convenient to upload to maven. 	
	# mvn deploy:deploy-file -DartifactId=apacheTomcat -Dfile=apache-tomcat-8.0.26.zip ^ \
	#	-DgroupId=com.yourcompany.xxx -Durl=http://maven.yourcompany.com/artifactory/yourartifaoty ^ \
	#	-DrepositoryId=yourartifaoty -Dpackaging=zip -DminorVersion=8.0.26

}

#
# Use this for getting binary packages - either prebuilt by distributions (tomcat, mongodb, cassandra,etc.)
#   or built using buildAdditionalPackages() above
#   Note that CSAP deploy will invoke this on the primary host selected during deployment, and then automatically
#   - synchronize the packageDir to all the other hosts (via local network copy) for much faster distribution
#
function getAdditionalBinaryPackages() {
	
	displayHeader getAdditionalBinaryPackages - skipped , this is an install only package
	
}




#
# CSAP agent will always kill -9 after this command
#
function killWrapper() {

	
	displayHeader KILL - skipped , this is an install only package
	
}

#
# CSAP agent will always kill -9 after this command. For data sources - it is recommended to use the 
# shutdown command provided by the stack to ensure caches, etc. are flushed to disk.
#
function stopWrapper() {


	displayHeader STOP - skipped , this is an install only package
	
}


#
# startWrapper should always check if $csapWorkingDir exists, if not then create it using $packageDir
# 
#
function startWrapper() {

	displayHeader START


	createVersion ;
	
	createLogs ;
	
	deployScripts ;
	
	updateSudo ;
		
	switchToCsapPackages ;
		

}

function switchToCsapPackages() {
	
	newPackageFolder="$STAGING/csap-packages" ;
	
	if [ ! -e "$newPackageFolder" ] ; then 
		
		printIt "Renaming $STAGING/warDist to $newPackageFolder "
		\mv -v $STAGING/warDist $newPackageFolder
		
		ln -s $newPackageFolder $STAGING/warDist
		
	else
		# in future release
		# \rm -f $STAGING/warDist
		printLine "Found: $newPackageFolder , already migrated"	
	fi ;
}

function updateSudo() {
	# update hosts to latest set of sudo commands
	if  [ "$CSAP_NO_ROOT" != "yes" ]; then
		
		sudoScript="$csapWorkingDir/scripts/configureSudo.sh" ;
		printIt "Updating sudo using $sudoScript"
			
		# rootDeploy is configured by the host installer
		\rm -rf $STAGING/bin/rootDeploy.sh ;
		cat $sudoScript > $STAGING/bin/rootDeploy.sh ;
		chmod 755 $STAGING/bin/rootDeploy.sh ;
		
		sudo $STAGING/bin/rootDeploy.sh 
		
	fi ;	
}

function createVersion() {
	
	packageVersion=`ls $csapWorkingDir/version | head -n 1`
	
	printIt "Appending linux version to package version"
	
	linuxVersion=`uname -r`
	linuxShortVersion=${linuxVersion:0:8}
	
	cat /etc/redhat-release
		
	if [ -e /etc/os-release ] ; then
		
		cat /etc/os-release
		source /etc/os-release
		myVersion="$ID-$VERSION_ID"
		
	elif [ -e /etc/redhat-release ] ; then 
		myVersion=`cat /etc/redhat-release | awk '{ print "rh-"$7}'`
			
	else
		myVersion="no-etc-os-release"
		
	fi;
	
	myVersion="$myVersion-$packageVersion"
	myVersion=$(echo $myVersion | tr -d ' ') ;
	
	printIt "Renaming version folder: $csapWorkingDir/version/$packageVersion to $myVersion"
	
	\mv -v "$csapWorkingDir/version/$packageVersion" "$csapWorkingDir/version/$myVersion" 

	
}


function createLogs() {

	printIt "creating logs in $csapLogDir, and linking /var/log/messages"
	mkdir -p $csapLogDir
	cd $csapLogDir
	ln -s /var/log/messages var-log-messages

	cd $csapWorkingDir
		
}

function deployScripts() {
	
	if [ "$csapSavedFolder" == "" ] ; then
		csapSavedFolder="$STAGING/saved" ;
		printIt "setting csapSavedFolder: $csapSavedFolder, and creating folder" ;
		\mkdir -p $csapSavedFolder
	fi;
	
	if [ -e "$STAGING/scripts" ] ; then
		printIt "moving $STAGING/scripts $csapSavedFolder/scripts"
		\mv -v $STAGING/scripts $csapSavedFolder/scripts
	fi ;
	
	currentBin="$STAGING/bin"
	previousBin="$csapSavedFolder/bin.old"

	if [ -e $previousBin ] ; then
		
		printIt "Removing previous backup: $previousBin"
		\rm -rf $previousBin
			
	fi
	
	printIt "moving $currentBin $previousBin"
	\mv -v $currentBin $previousBin
	
	
	
	printIt "copying $csapWorkingDir/staging-bin $currentBin"
	\cp -rp $csapWorkingDir/staging-bin $currentBin


	printIt "adding legacy links for previous releases"
	
	cd $currentBin
	ln -s csap-start.sh startInstance.sh
	ln -s csap-kill.sh killInstance.sh
	ln -s csap-deploy.sh rebuildAndDeploySvc.sh
	ln -s admin-restart.sh restartAdmin.sh 
	ln -s admin-kill-all.sh kills.sh

	cd $csapWorkingDir
	
}







