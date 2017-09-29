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


	
	linuxVersion=`uname -r`
	linuxShortVersion=${linuxVersion:0:8}
	
	printIt "creating logs in $csapLogDir, and linking /var/log/messages"
	mkdir -p $csapLogDir
	cd $csapLogDir
	ln -s /var/log/messages var-log-messages
		
	cat /etc/redhat-release
		
	if [ -e /etc/os-release ] ; then
		
		cat /etc/os-release
		source /etc/os-release
		myVersion="$ID-$VERSION_ID"
		
		myVersion=$(echo $myVersion | tr -d ' ') ;
	else
		myVersion="no-etc-os-release"
	fi;
	
	printIt "Creating version folder: $csapWorkingDir/version/$myVersion"
	mkdir -p "$csapWorkingDir/version/$myVersion" 
	touch "$csapWorkingDir/version/$myVersion/empty.txt"
	
    

	
}
