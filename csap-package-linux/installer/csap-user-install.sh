#!/bin/bash
function installCsapJavaPackage() {
	
	
	#printIt Placing  JDK confg package in $csapWorkingDir, source: $csapDefaultJdk 
	#\rm -rf JavaDevKitPackage-8u*.zip
	#wgetWrapper $csapDefaultJdk

	unzip -qo $csapPackageFolder/jdk.zip
	
	printIt "loading $csapWorkingDir/csapApi.sh"
	source $csapWorkingDir/csapApi.sh
	
	#cd $targetFs/csap
	cd $csapWorkingDir
	printIt "Runing start in dir: `pwd`"
	startWrapper

}

# Placed at top for ez updating of package
function javaInstall() {
	prompt "Installing CSAP JDK package"
	mkdir -p $STAGING/temp
	cd $STAGING/temp
	
	csapName="jdk";
	csapWorkingDir=`pwd`;
	
	printIt "Loading $STAGING/bin/csap-env.sh, with messages hidden"
	source $STAGING/bin/csap-env.sh >/dev/null

	installCsapJavaPackage

	
	#printIt Exiting ; exit
}
#export JAVA_HOME=/opt/java/jdk1.8.0_101


#
# Note: this is a common installer used for both gen 1 and gen 2 installs; Changes need to be tested in both envs
#

if [ ! -f  $HOME/.cafEnv ] ; then 

	echo == creating Csap  $HOME/.cafEnv, assuming this is a gen2 vm that is being reImaged

	echo  export STAGING=$HOME/staging >> $HOME/.cafEnv
	echo  export PROCESSING=$HOME/processing >> $HOME/.cafEnv
	
	if [ "$isMemoryAuth"  == "1" ] ; then
		echo == Security Setup is using Memory only settings, update CsAgent users.txt file
		echo  export csapAuth="memory" >> $HOME/.cafEnv
	else
		echo == using default settings
	fi;
fi

# load variables for access to staging and processing contents
source $HOME/.cafEnv

scriptDir=`dirname $0`
scriptName=`basename $0`
source $scriptDir/installFunctions.sh

csapPackageUrl="http://$toolsServer/csap/csap6.0.0$allInOnePackage.zip"

prompt == Starting $0 : params are $*

if [ -d $STAGING ] ; then
	printIt "ERROR: Found existing application: $STAGING. Confirm disks have been wiped or previous version removed, and all previous processes killed, and retry" ;
	exit 66;
fi;


# Note that this includes staging in zip
#\rm -rf csap*.zip


function extract-staging-contents() {

	if [ "$localPackages" != "" ] ; then
		printIt "Running local setup, copying $localPackages/staging-bin $STAGING/bin"
		
		# extract csap linux commands
		mkdir -p $STAGING
		\cp -r $localPackages/staging-bin $STAGING/bin
		
		PACKAGES=$STAGING/csap-packages
		mkdir -p $PACKAGES
		
		printIt "copying $localPackages/csap-core-service-*.jar $PACKAGES/CsAgent.jar"
		cp -v $localPackages/csap-core-service-*.jar $PACKAGES/CsAgent.jar
		cp -v $localPackages/csap-core-service-*.jar $PACKAGES/admin.jar
		
		
		printIt "copying $localPackages/csap-package-linux-*.zip $PACKAGES/linux.zip"
		cp -v $localPackages/csap-package-linux-*.zip $PACKAGES/linux.zip
		
		# getting linux dependencies (maven)
		mkdir -p $PACKAGES/linux.secondary
		printIt "copying $localPackages/apache-maven-*-bin.zip $PACKAGES/linux.secondary"
		cp -v $localPackages/apache-maven-*-bin.zip $PACKAGES/linux.secondary

		printIt "copying $localPackages/csap-package-java-*.zip $PACKAGES/jdk.zip"
		cp -v $localPackages/csap-package-java-*.zip $PACKAGES/jdk.zip
		
		# getting linux dependencies (maven)
		mkdir -p $PACKAGES/jdk.secondary
		printIt "copying $localPackages/jdk-*-linux-x64.tar.gz $PACKAGES/jdk.secondary"
		cp -v $localPackages/jdk-*-linux-x64.tar.gz $PACKAGES/jdk.secondary
		
		
		
	else
		printIt "Running normal install `pwd`"
		numberPackagesLocal=`ls -l csap*.zip | wc -l`
		localDir="/media/sf_workspace/packages"
		
		if [ -e $localDir ] ; then 
			
			printIt using local copies from $localDir
			cp $localDir/* .
			
		elif (( $numberPackagesLocal == 1 )) ; then
			
			printIt "Found a local package, using csap*zip";
			
		else
			
			printIt "Getting csap install from $csapPackageUrl"
			wgetWrapper $csapPackageUrl
			
		fi;
		printIt "Unzipping `pwd` csap*.zip"
		unzip -q csap*.zip
	fi ;
	
	
	printIt "Updating $HOME/.bashrc using $STAGING/bin/admin.bashrc"
	echo  source $STAGING/bin/admin.bashrc >> $HOME/.bashrc
	source ~/.bashrc
}

extract-staging-contents

javaInstall


printIt "Creating $PROCESSING"
mkdir $PROCESSING


function setup-default-application () {
	
	
	applicationFolder="$STAGING/conf";
	\rm -rf $STAGING/conf;
	printIt "Creating default cluster using defaults extracted to csapSavedFolder $csapSavedFolder"
	unzip -o -d $csapSavedFolder $csapPackageFolder/CsAgent.jar BOOT-INF/classes/defaultConf/*
 	\cp -rv $csapSavedFolder/BOOT-INF/classes/defaultConf $applicationFolder;
 	
 	if [ $mavenSettingsUrl != "default" ] ; then
		printIt "downloading :  $mavenSettingsUrl"
		wgetWrapper $mavenSettingsUrl
		\mv settings.xml $applicationFolder/propertyOverride
	else 
		printIt " mavenSettingsUrl was not specified in installer, public spring repo is the default"
	fi
	
	if [ $mavenRepoUrl != "default" ] ; then
		printIt "updating $applicationFolder/Application.json with $mavenRepoUrl"
		sed -i "s=http://repo.spring.io/libs-release=$mavenRepoUrl=g" $applicationFolder/Application.json
	else 
		printIt " mavenRepoUrl was not specified in installer, public spring repo is the default"
	fi	
	
	company=`dnsdomainname`
	if [ "$company" != "" ] ; then
		printIt "Replacing yourcompany.com with: $company in $applicationFolder/Application.json" ;
		sed -i "s=yourcompany.com=$company=g" $applicationFolder/Application.json
	else
		 printIt "ERROR: dnsdomainname did not resolve host. Update: $applicationFolder/Application.json by replacing yourcompany.com" 
	fi ;
	
	memoryOnHostInKb=$(free|awk '/^Mem:/{print $2}');
	memoryOnHostInMb=$((memoryOnHostInKb / 1024 ))
	printIt memoryOnHostInMb $memoryOnHostInMb
	
	if [[ "$memoryOnHostInMb" -lt 1000 ]] ; then 
		
		printIt "Host has less then 1GB configured memory: $memoryOnHostInMb Mb. Removing non-essential services from Application.json...."
		sed -i '/"admin": \[/{N;N;d}' $applicationFolder/Application.json
		sed -i '/"CsapTest": \[/{N;N;d}' $applicationFolder/Application.json
		sed -i '/"SimpleServlet": \[/{N;N;d}' $applicationFolder/Application.json
	fi ;
}

cd $HOME
# staging/bin/buildAndInstall.sh

printIt "Setting up CSAP Application using $cloneHost"

if [ "$starterUrl" != "" ] ; then
	printIt "Getting Starter configuration: $starterUrl"
 	\rm -rf $STAGING/conf getConfigZip*
 	wget $starterUrl
 	unzip  -q -o -d $STAGING/conf getConfigZip*

 	
elif [ $cloneHost == "default" ] ; then

	setup-default-application ;
 	
else
	printIt "Getting configuration using host: http://$cloneHost:8011/CsAgent/os/getConfigZip"
 	\rm -rf $STAGING/conf
 	# scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -oBatchmode="yes" -p -r $cloneHost:staging/conf $HOME/staging
 	wget http://$cloneHost:8011/CsAgent/os/getConfigZip
 	unzip  -q -o -d $STAGING/conf getConfigZip
fi ;

printIt "Copying agent jar to admin as they use the same binary "
cp -v $csapPackageFolder/CsAgent.jar $csapPackageFolder/admin.jar

printIt ssadmin install completed

