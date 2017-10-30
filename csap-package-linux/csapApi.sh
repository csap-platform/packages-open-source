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

#
#  legacy installs will not have new variables.
#

legacy="false";
if [ "$csapPackageDependencies" == "" ] ; then
	
	legacy="true";
	csapSavedFolder="$STAGING/saved" ;
	csapPackageFolder="$STAGING/csap-packages"
	csapPackageDependencies="$csapPackageFolder/$csapName.secondary" ;
	
	printIt "LEGACY INSTALL: setting csapSavedFolder: $csapSavedFolder, csapPackageFolder: $csapPackageFolder, csapPackageDependencies: $csapPackageDependencies" ;
	\mkdir -p $csapSavedFolder
	
fi;
	
function buildAdditionalPackages() {
	
	displayHeader "no source packages to build"

}

function getAdditionalBinaryPackages() {
	
	displayHeader "Getting maven"
	
	printIt removing $csapPackageDependencies
	\rm -rf $csapPackageDependencies
	
	printIt Getting maven binary
	mkdir -p $csapPackageDependencies
	cd $csapPackageDependencies
	wget -nv http://$toolsServer/csap/apache-maven-3.3.3-bin.zip
	
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
# startWrapper should always check if $csapWorkingDir exists, if not then create it using $csapPackageDependencies
# 
#
function startWrapper() {

	displayHeader START


	createVersion ;
	
	createLogs ;
	
	deployScripts ;
	
	updateSudo ;
		
	migrate-to-csap6 ;
	
	install-maven ;
		

}

function install-maven() {
	
	printIt "Installing maven"
	
	\rm -rf $STAGING/apache-maven*
	unzip -qq -o $csapPackageDependencies/apache*.zip -d $STAGING


}

function migrate-to-csap6() {
	
	if [ ! -e "$csapPackageFolder" ] ; then 
		
		printIt "Renaming $STAGING/warDist to $csapPackageFolder "
		\mv -v $STAGING/warDist $csapPackageFolder
		
		#ln -s $newPackageFolder $STAGING/warDist
		
	else
		printLine "Found: $csapPackageFolder , already migrated"	
	fi ;
	
	if [ -e "$STAGING/conf.old" ] ; then
		printIt "Moving $STAGING/conf.old $csapSavedFolder"
		\mv -v $STAGING/conf.old $csapSavedFolder ;
		\mv -v $STAGING/conf.previous $csapSavedFolder ;
	fi;
	
}

function updateSudo() {
	# update hosts to latest set of sudo commands
	if  [ "$CSAP_NO_ROOT" != "yes" ]; then
		
		sudoScript="$csapWorkingDir/scripts/configureSudo.sh" ;
		printIt "Updating sudo using $sudoScript, updating CSAP_USER with $USER"
			
		# rootDeploy is configured by the host installer
		\rm -rf $STAGING/bin/rootDeploy.sh ;
		cat $sudoScript > $STAGING/bin/rootDeploy.sh ;
		chmod 755 $STAGING/bin/rootDeploy.sh ;
		sed -i "s/CSAP_USER/$USER/g" /etc/init.d/csap
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



	if [ "$legacy" == "true" ] ; then 
		printIt "adding legacy links for previous releases"
		
		cd $currentBin
		ln -s csap-start.sh startInstance.sh
		ln -s csap-kill.sh killInstance.sh
		ln -s csap-deploy.sh rebuildAndDeploySvc.sh
		ln -s admin-restart.sh restartAdmin.sh 
		ln -s admin-kill-all.sh kills.sh
	fi ;

	cd $csapWorkingDir
	
}







