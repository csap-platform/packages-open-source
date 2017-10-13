#!/bin/sh
#
#
#

scriptDir=`dirname $0`

function printIt() { echo; echo; echo =========; echo == $* ; echo =========; }


printIt "Running $0 $*"
printIt "add param \"includePackages\" to build a standalone. By default not done due to size"

if [ $# -eq 0 ] ; then
	printIt "param 1 is release and is required param 2 is optional: includePackages : use to indicate if binaries are to be retrieved"
	printIt "Exiting Script. Run again with params"
	exit
fi

relNumber="$1"
includePackages="$2"
includeMavenRepo="$3"
targetHost="$4"

csapPackageFolder="$STAGING/csap-packages"

releaseZipFile="csap$relNumber.zip"
scriptsRel="csapInstall$relNumber.zip"

printIt "Starting build..."

#echo == removing old stuff from repo




printIt "Copying files to $HOME/temp"
cd $HOME
rm -rf temp
mkdir -p temp/staging
cd temp

mkdir staging/build
mkdir staging/csap-packages


function addBasePackages() {
	
	basePackages="$@" ;
	for package in $basePackages ; do
		printIt "Including $csapPackageFolder/$package"
		cp -rvp $csapPackageFolder/$package* staging/csap-packages
	done ;
}

# note jdk also wildcards to match jdk.secondary
addBasePackages CsAgent.jar jdk linux CsapSimple.jar CsapTest.jar SimpleServlet.war


if  [ "$includePackages" == "yes" ] ; then
	printIt "includePackages requested, will run maven dependencies to transfer into maven repo"
	
	printIt "removing $STAGING/mavenRepo files to slim down distribution"
	\rm -rf $STAGING/mavenRepo/*
	
	mavenBuildCommand=""
	function generateMavenCommand() {
		itemToParse=$1
		
		# do not wipe out history for non source deployments
		needClean="" 
		# set uses the IFS var to split
		oldIFS=$IFS
		IFS=":"
		mvnNameArray=( $itemToParse )
		IFS="$oldIFS"
		mavenGroupName=${mvnNameArray[0]}
		mavenArtName=${mvnNameArray[1]}
		mavenArtVersion=${mvnNameArray[2]}
		mavenArtPackage=${mvnNameArray[3]}
		
		# filter packages
		mavenBuildCommand="skipped" ;
		if [[ "$mavenArtName" =~ ^(BootEnterprise|BootReference|agent|RedHatLinux|Servlet3Sample|docker|HttpdWrapper|JavaDevKitPackage|TomcatPackage)$ ]]; then
			mavenWarPath=$(echo $mavenGroupName|sed 's/\./\//g') ;
			mavenWarPath="$STAGING/mavenRepo/$mavenWarPath/$mavenArtName/$mavenArtVersion"
		
			#echo  == mavenWarPath is $mavenWarPath
			# Note the short form has bugs with snapshot versions. here is the long form for get
			mavenBuildCommand="-B org.apache.maven.plugins:maven-dependency-plugin:3.0.1:get  -Dtransitive=false -DremoteRepositories=1myrepo::default::file:///$STAGING/mavenRepo,http://maven.yourcompany.com/artifactory/cstg-smartservices-group "
			mavenBuildCommand="$mavenBuildCommand -DgroupId=$mavenGroupName -DartifactId=$mavenArtName -Dversion=$mavenArtVersion -Dpackaging=$mavenArtPackage"
		fi
		#echo "== mavenBuildCommand: $mavenBuildCommand"
		
	}
	
	#printIt "Getting old maven "
	#oldDep="-B org.apache.maven.plugins:maven-dependency-plugin:2.8:get -Dtransitive=false -DremoteRepositories=myrepo::::file:////home/ssadmin/staging/mavenRepo,http://maven.yourcompany.com/artifactory/cstg-smartservices-group -DgroupId=org.csap -DartifactId=BootEnterprise -Dversion=1.0.33 -Dpackaging=jar"
	#mvn -s $STAGING/conf/propertyOverride/settings.xml $oldDep
	
	
	#developmentPackages=`csap.sh -lab http://localhost:8911/admin -api model/mavenArtifacts -script` ;
	developmentPackages=`csap.sh -lab http://localhost:8011/CsAgent -api model/mavenArtifacts -script` ;
	printIt "Development Packages: $developmentPackages"
	for package in $developmentPackages ; do
		# echo == found package: $package
		
		generateMavenCommand $package
		printIt "$package buildCommand: $mavenBuildCommand"
		if [[ "$mavenBuildCommand" != "skipped" ]] ; then
			mvn -s $STAGING/conf/propertyOverride/settings.xml $mavenBuildCommand ;
		fi;
	done 
	
	
else
	printIt "Skipping packages"
fi ;
#set -o verbose #echo on

printIt "copying $STAGING/bin"
rsync --recursive --perms $STAGING/bin $HOME/temp/staging

printIt "copying $STAGING/apache-maven"
rsync --recursive --perms $STAGING/apache-maven* $HOME/temp/staging

if  [ "$includeMavenRepo" == "yes" ] ; then
	printIt "Including maven repo"
	rsync --recursive --perms $STAGING/mavenRepo  $HOME/temp/staging
	
	printIt 'Removing maven _remote* files from repo - otherwise they are ignored'
	find $HOME/temp/staging/mavenRepo/ -name _remote* -exec rm -f {} \;
else 
	printIt "Skipping maven repo"
	mkdir -p  $HOME/temp/staging/mavenRepo
fi;

printIt Build item sizes
du -sh $HOME/temp/staging/*

printIt "Building $releaseZipFile"
zip -qr $releaseZipFile staging

printIt "Transferring $releaseZipFile $targetHost:web/csap size `ls -l --block-size=M $releaseZipFile |  awk '{print $5}'`"
scp -o BatchMode=yes -o StrictHostKeyChecking=no $releaseZipFile $targetHost:web/csap

printIt "Go to $targetHost to sync upload to other hosts"

exit


# add this to your definition folder /scripts/release-csap.sh
# invoke using csap command runner (/scripts/* will be added to end of templates)

function printIt() { echo; echo; echo =========; echo == $* ; echo =========; }

# change timer to 300 seconds or more
release="updateThis";

includePackages="no" ; # set to yes to include dev lab artifacts
includeMavenRepo="no" ; # set to yes to include maven Repo
targetHost="yourhost"


if [ $release != "updateThis" ] ; then
	printIt Building $release , rember to use ui on csaptools to sync release file to other vm
	$STAGING/bin/mkcsap.sh $release $includePackages $includeMavenRepo $targetHost
	
	includePackages="yes" ; # set to yes to include dev lab artifacts
	includeMavenRepo="yes" ; # set to yes to include maven Repo
	release="$release-full"
	
	printIt Building $release , rember to use ui on csaptools to sync release file to other vm
	$STAGING/bin/mkcsap.sh $release $includePackages $includeMavenRepo $targetHost
	
else
	printIt update release variable and timer
fi
