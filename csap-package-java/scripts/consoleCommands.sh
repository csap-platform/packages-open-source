#!/bin/bash

function displayHeader() {
	echo
	echo
	echo	
	echo ====================================================================
	echo == 
	echo == CSAP JDK Package: $*
	echo ==
	echo ====================================================================
	
}


function printIt() {
	echo;echo;
	echo = 
	echo = $*
	echo = 
}


# CSAP will always autosync all files in packageDir to hosts in service cluster
packageDir=$STAGING/warDist/$csapName.secondary
version="141" ;
if [ "$jdkVersion" != "" ] ; then
	version="$jdkVersion"
fi;

#
# Use this for any software "build" operations. Typically used for building c/c++ code
# -  eg. apache httpd, redis
# -  This method should also upload into a repository (usually maven)
# - Note: most software packages are available as prebuilt distributions, in which case no implementation is required
#
function buildAdditionalPackages() {
	
	displayHeader buildAdditionalPackages: no additional packages to build

	# most packages are most often managed via a staging host eg. http://csaptools.yourcompany.com/ is used for java
	# if binaries are built - it may or may not be convenient to upload to maven. 	
	# mvn deploy:deploy-file -DartifactId=apacheTomcat -Dfile=apache-tomcat-8.0.26.zip ^ \
	#	-DgroupId=com.yourcompany.xxx -Durl=http://maven.yourcompany.com/artifactory/yourartifaoty ^ \
	#	-DrepositoryId=yourartifaoty -Dpackaging=zip -Dversion=8.0.26

}

#
# Use this for getting binary packages - either prebuilt by distributions (tomcat, mongodb, cassandra,etc.)
#   or built using buildAdditionalPackages() above
#   Note that CSAP deploy will invoke this on the primary host selected during deployment, and then automatically
#   - synchronize the packageDir to all the other hosts (via local network copy) for much faster distribution
#
function getAdditionalBinaryPackages() {
	
	displayHeader getAdditionalBinaryPackages
	
	printIt removing $packageDir
	\rm -rf $packageDir
	
	printIt Getting Java binaries
	mkdir -p $packageDir
	cd $packageDir
	
	localDir="/media/sf_workspace/packages"
	if [ -e $localDir ] ; then 
		printIt using local copies from $localDir
		cp $localDir/* .
	else		
		printIt "using toolsServer: $toolsServer"
		wget -nv http://$toolsServer/java/jdk-8u$version-linux-x64.tar.gz
		wget -nv http://$toolsServer/java/jce_policy-8.zip
	fi;
	
}




#
# CSAP agent will always kill -9 after this command
#
function killWrapper() {

	
	displayHeader KILL 
	echo == skipped , this is an install only package
	
}

#
# CSAP agent will always kill -9 after this command. For data sources - it is recommended to use the 
# shutdown command provided by the stack to ensure caches, etc. are flushed to disk.
#
function stopWrapper() {


	displayHeader STOP 
	echo == skipped , this is an install only package
	
}


#
# startWrapper should always check if $csapWorkingDir exists, if not then create it using $packageDir
# 
#
function startWrapper() {
	displayHeader START
	

	echo =====
	echo == Info: Deploying $csapName using $packageDir, current dir: `pwd`
	echo ==== 
	
	#
	# We add serviceName to params so that process state is reflected in UI
     
    if [ "$CSAP_NO_ROOT" == "yes" ]; then 	
    	# hook for running on non root systems
    	scripts/rootInstall.sh "$csapWorkingDir" "$version" "$packageDir"
	else
		rm -rf $STAGING/bin/rootDeploy.sh
		cat scripts/rootInstall.sh >  $STAGING/bin/rootDeploy.sh
		chmod 755 /home/ssadmin/staging/bin/rootDeploy.sh
		sudo /home/ssadmin/staging/bin/rootDeploy.sh "$csapWorkingDir" "$version" "$packageDir"
			
		echo == adding link to: `pwd` from: $csapWorkingDir/JAVA_HOME
		ln -s /opt/java $csapWorkingDir/JAVA_HOME
	fi;
	  

    
	cd $csapWorkingDir ;
    

	
}
