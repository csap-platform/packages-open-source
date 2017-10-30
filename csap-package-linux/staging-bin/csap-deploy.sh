#!/bin/bash
#
#
#
scriptDir=`dirname $0`
scriptName=`basename $0`


#
# because this script may be updating itself, it is always copied and run from /tmp
#
if [ $scriptName == "csap-deploy.sh" ] || [ $scriptName == "rebuildAndDeploySvc.sh" ] ; then
	 rebuildFile="/tmp/rebuildFile"`date +%s` ;
	 # copying $0 to $rebuildFile to allow script upgrades
	 \cp -f $0 $rebuildFile ;
	 chmod 755 $rebuildFile ;
	 $rebuildFile $@;
	 exit ;
fi ;
	
echo "...."

# Defaults
isNoLogout="0" ;
needClean="-x clean" # we clean out folders on source build only

SCM_BRANCH="HEAD"

mavenBuildCommand="-Dmaven.test.skip=true clean package" ;
export MAVEN_OPTS="-Xms128m -Xmx1024m -XX:PermSize=128m -XX:MaxPermSize=256m"
SCM_USER="" ;
hosts="" ;
svcInstance="" ;

# getopts is great parser, ref: http://wiki.bash-hackers.org/howto/getopts_tutorial
# alternative impl to getopt: isNoLogout=`expr match "$* " '.*-noLogout' != 0`
mavenWarPath="" ;

source $STAGING/bin/csap-env.sh

startTime=`date +%s%N`
if [[ "$waitForPrimaryFile" != "none" && "$waitForPrimaryFile" != "" ]] ; then 	
	# deployCompleteFile="$csapPackageFolder/$csapName.$primaryHost";
	printIt "Waiting for deployment files to be synce'ed from $waitForPrimaryFile"
	# 
	original=`stat -c %y $waitForPrimaryFile 2>&1`;
	while [ ! -f $waitForPrimaryFile ]
	do
		sleep 5 ;
		numSeconds=$((($(date +%s%N) - $startTime)/1000000000))
		echo "$numSeconds seconds"
		
	done
	
	echo == deployment complete: `cat $waitForPrimaryFile`
	
	exit;
fi;

showIfDebug Running $0 : dir is $scriptDir
showIfDebug param count: $#
showIfDebug params: $@

if [ "$SCM_USER" == "" ] || [ "$svcInstance" == "" ]; then
	echo usage $0 -n \<service_name\>  -p \<service_port\> -u \<SCM_USER\> optional: -b \<SCM_BRANCH\> -w \<warDir\> 
	echo exiting
	exit ;
fi ;


showIfDebug ==  SCM_USER is "$SCM_USER"
if [ ! -e $STAGING/build ] ; then 
	mkdir -p $STAGING/build
fi;

if [ "$serverRuntime" == "" ] ; then
	echo ==
	echo == Error: unable to get value from config file for $serverRuntime
	echo ==
	exit ;
fi ;

showIfDebug == CHecking for  mavenWarPath
mavenWarDeploy=`echo $mavenBuildCommand | grep -c :war`
mavenZipDeploy=`echo $mavenBuildCommand | grep -c :zip`
mavenJarDeploy=`echo $mavenBuildCommand | grep -c :jar`

mavenArtVersion=""

generateMavenCommand() {
	itemToParse=$1
	showIfDebug == Parsing $itemToParse for maven artifact attributes
	
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
	
	mavenWarPath=$(echo $mavenGroupName|sed 's/\./\//g') ;
	mavenWarPath="$STAGING/mavenRepo/$mavenWarPath/$mavenArtName/$mavenArtVersion"
#	mavenArtName=`basename $mavenArtPre`
#	mavenGroupName=`dirname $mavenArtPre`
#	mavenGroupName=$(echo $mavenGroupName|sed 's/\//\./g') ;
	#mavenWarPath="$STAGING/mavenRepo/$mavenArtPre/$mavenArtVersion"
	showIfDebug  == mavenWarPath is $mavenWarPath
	# Note the short form has bugs with snapshot versions. here is the long form for get
	# 
	# mavenBuildCommand="-B org.apache.maven.plugins:maven-dependency-plugin:2.8:get -DrepoUrl=$svcRepo "
	mavenBuildCommand="-B org.apache.maven.plugins:maven-dependency-plugin:3.0.1:get -DremoteRepositories=1_repo::::file:///$STAGING/mavenRepo,$svcRepo "
	mavenBuildCommand="$mavenBuildCommand -Dtransitive=false -DgroupId=$mavenGroupName -DartifactId=$mavenArtName -Dversion=$mavenArtVersion -Dpackaging=$mavenArtPackage"
	showIfDebug == mavenBuildCommand: $mavenBuildCommand
}
if [  $mavenWarDeploy != 0 ] || [  $mavenZipDeploy != 0 ] || [  $mavenJarDeploy != 0 ] ; then 
	generateMavenCommand $mavenBuildCommand
fi ;


#
# SCM integration always uses the following folder for source
#
export SOURCE_CODE_LOCATION="$STAGING/build/$serviceName"_"$csapHttpPort$buildSubDir"

showIfDebug
showIfDebug Current directory is `pwd`
showIfDebug

#Assume a war
deployItem=$serviceName.war
buildItem=target/$deployItem
#suffixTestEval="suffixMatch=target/$serviceName*.war"
suffixTestEval="suffixMatch=target/*.war"
# start by checking if this is a Ear build
earFolder=./$serviceName"Ear"
if [ -e $earFolder ]; then
	echo Found earFolder
	deployItem=$serviceName"Ear.ear" 
	buildItem=$serviceName"Ear/target/"$deployItem
	suffixTestEval="suffixMatch=$serviceName\"Ear/target/$serviceName\"*.ear"
fi ;

if [ "$serverRuntime" == "wrapper" ] ; then
	showIfDebug ==
	showIfDebug == Found a wrapper, using zip deploy
	showIfDebug ==
	deployItem=$serviceName.zip
	buildItem=target/$deployItem
	suffixTestEval="suffixMatch=target/*.zip"
fi ;

if [ "$serverRuntime" == "SpringBoot" ] ; then
	showIfDebug ==
	showIfDebug == SpringBoot jar deploy 
	showIfDebug ==
	deployItem=$serviceName.jar
	buildItem=target/$deployItem
	suffixTestEval="suffixMatch=target/*.jar"
fi ;

showIfDebug =====================================================================================
showIfDebug deployItem is $deployItem, buildItem is $buildItem, suffixTestEval is $suffixTestEval
showIfDebug =====================================================================================

showIfDebug ====================================================================
showIfDebug Switching back to build dir $SOURCE_CODE_LOCATION
showIfDebug ====================================================================


if [ -e $SOURCE_CODE_LOCATION ] ; then
	cd $SOURCE_CODE_LOCATION
fi ;

function run_the_build() {
	
	printIt "starting build in location: $SOURCE_CODE_LOCATION"
	
	isJavaBuildOnly=${javaBuildOnly:-false} ;
	
	if $isJavaBuildOnly ; then 
		printIt "javaBuildOnly is true " ;
		mavenBuildCommand="$mavenBuildCommand install" ; 
	fi;
	
	mBuild="$mavenBuildCommand"
		
	if [[ "$mavenBuildCommand" == *deploy* ]] ; then 
		if [ "$serverRuntime" == "wrapper" ] ||  [ "$serverRuntime" == "SpringBoot" ] ; then  
			printIt "Stripping off maven deploy param if it is specified, maven deploy will run separately after csapApi deploy"
			mBuild=`echo $mavenBuildCommand | sed -e "s/deploy/  /g"`
		fi
	fi ;
	
	showIfDebug "Build command: $mBuild"
	
	mavenSettings="$STAGING/bin/settings.xml" ;
	if [ -e "$serviceConfig/settings.xml" ] ; then
		mavenSettings="$serviceConfig/settings.xml"
	else
		printIt "Warning: $serviceConfig/settings.xml not found - best practice is to include one in capability/propertyOverride folder"
	fi
	printIt "Starting: mvn -s $mavenSettings  $mBuild"
	mvn -s $mavenSettings  $mBuild  2>&1
	
	buildReturnCode="$?" ;
	if [ $buildReturnCode != "0" ] ; then
		printIt "Found Error RC from build: $buildReturnCode"
		echo __ERROR: Maven build exited with none 0 return code
		exit 99 ;
	fi ;

	if $isJavaBuildOnly ; then 	
		if [ -e "csap-starter-parent" ] ; then
			cd csap-starter-parent ;
			printIt "running parent build" ;
			printIt "Starting: mvn -s $mavenSettings  $mBuild"
			mvn -s $mavenSettings  $mBuild  2>&1
		fi;
		printIt "javaBuildOnly is true; exiting" ;
		exit 95 ;
	fi;
}

run_the_build ;
	

function update_build_version_file() {
	
	printIt "Updating buid version file"
	
	if [  "$mavenWarPath" != "" ] ; then 
		buildItem="$mavenWarPath/$mavenArtName-$mavenArtVersion.war"
		if [  $mavenZipDeploy != 0 ] ; then 
			buildItem="$mavenWarPath/$mavenArtName-$mavenArtVersion.zip"
		fi ;
		if [  $mavenJarDeploy != 0 ] ; then 
			buildItem="$mavenWarPath/$mavenArtName-$mavenArtVersion.jar"
		fi ;
		
		showIfDebug == buildItem set to $buildItem ;
		echo " $SCM_USER $mavenArtVersion" > $buildItem.txt ;
	else
	
		echo "Host Build Only: $SCM_USER $2" > $buildItem.txt
		showIfDebug checking for versioned service
		
		eval $suffixTestEval
		
		showIfDebug buildItem: $buildItem suffixMatch: $suffixMatch
		numMatches=`ls $suffixMatch | wc -w`
		
		if [ $numMatches != 1 ] ; then
			printIt "ERROR: csap-deploy.sh requires exactly a single matching artifact to be build, but found: $numMatches"
			printLine "If your maven files is doing dependency copy or other commands that put matching artifacts"
			printLine "into target folder, put them into a subfolder."
			printIt "exiting"
			exit 94; 
		fi ; 
		
		if [ $buildItem != $suffixMatch ]; then
			showIfDebug copying $suffixMatch to $buildItem for deployment
			\cp -f $suffixMatch $buildItem
		fi
	fi ;

}

update_build_version_file


if  [ "$csapPackageFolder" != "" ]  ; then
	showIfDebug 
	showIfDebug ====================================================================
	showIfDebug copying  $buildItem $csapPackageFolder
	showIfDebug ====================================================================
	showIfDebug 

	
	
	#
	#  Note that the staging folder stores the artifacts using the process name, versus the original artifact name
	# This establishes the relationship between process and specific deployment version.
	#
	destWar=$csapPackageFolder/$deployItem
	if [ ! -f "$buildItem" ] ; then 
		pwd
			echo == WARNING: DID not find "$buildItem"
	fi
	\cp -f $buildItem $destWar
	

	# echo "$SCM_USER $SCM_BRANCH" > $destWar.txt
	echo "Deployment Notes" > $destWar.txt
	# sed -n '/modelVersion/,/packaging/p' pom.xml | head -5 >> $csapPackageFolder/$deployItem.txt
	
	showIfDebug == Getting version info
	
	# Critical Note version string is parsed during deployments to determine extract dir for tomcat
	deployTime=$(date +"%b %d %H:%M")
	if [ "$mavenArtVersion" != "" ] ; then 
		echo  "Maven Deploy of $mavenArtName" >> $destWar.txt
		echo  \<version\>$mavenArtVersion\</version\>>> $destWar.txt
		echo "Maven Deploy by $SCM_USER at $deployTime using $mavenArtName" >> $destWar.txt
	else 
		
		if [ -e "pom.xml" ]; then
			grep \<groupId pom.xml | head -1 >> $destWar.txt
			grep \<artifactId pom.xml | head -1 >> $destWar.txt
			s=`grep \<version pom.xml | head -1`
			if [[ "$s" == *{version}* ]] ; then
					echo "<version>0.0-none</version>" >> $destWar.txt ;
			else 
				grep \<version pom.xml | head -1 >> $destWar.txt 
			fi
			
		fi
		echo "Source build by $SCM_USER at $deployTime  on $SCM_BRANCH" >> $destWar.txt
	fi ;

	if  [ "$secondary" != "" ]  ; then
		echo 
		echo == found secondary deployment artifacts
		echo
		IFS=","
		\rm -rf $csapPackageFolder/$serviceName.secondary
		mkdir $csapPackageFolder/$serviceName.secondary
		for artifactId in $secondary ; do
			IFS=" "
			echo == Running secondary installer on $artifactId
			echo  \<secondary\>$artifactId\</secondary\>>> $destWar.txt
			echo
			generateMavenCommand $artifactId
			mvn -s $serviceConfig/settings.xml $mavenBuildCommand  2>&1
			buildItem="$mavenWarPath/$mavenArtName-$mavenArtVersion.war"
			echo
			echo == copying $buildItem to $csapPackageFolder/$serviceName.secondary
			cp $buildItem  $csapPackageFolder/$serviceName.secondary
			IFS=","
			echo 
		done;
		IFS=" "
		echo == completed secondary artifact installation
		echo 
	fi ;

	
	#
	# Wrappers need to rename their artifact to $serviceName in order for installs to work
	#
	if [ "$serverRuntime" == "SpringBoot" ] && [ "$mavenArtVersion" == "" ] ; then
		showIfDebug ==
		showIfDebug == Found a SpringBoot... Running  commands
		showIfDebug ==
		
		source csap-integration-springboot.sh
		deployBoot
		
		# getting to the correct folder so that remaining commands can be executed.
		cd $SOURCE_CODE_LOCATION
		
	
		# CS-AP console will do the clean package automatically, but not the deploy to allow custom packaging.
		if [[ "$mavenBuildCommand" == *deploy* ]] ; then
	        # An explicity deploy is done here to finalize
			echo
			echo ===== csap post deploy executing  mvn deploy skiptests
			echo
			mvn -B -s $serviceConfig/settings.xml -Dmaven.test.skip=true deploy  2>&1
			
			if [ $? != "0" ] ; then
				echo
				echo
				echo =========== CSSP Abort ===========================
				echo __ERROR: Maven build exited with none 0 return code
				echo == Build errors need to be fixed
				exit 99 ;
			fi ;
		fi; 
		
		
	fi
	#
	# Wrappers need to rename their artifact to $serviceName in order for installs to work
	#
	if [ "$serverRuntime" == "wrapper" ] && [ "$mavenArtVersion" == "" ] ; then
		showIfDebug ==
		showIfDebug == Found a wrapper... Running pre wrapper commands
		showIfDebug ==
		
		rm -rf $STAGING/temp
		mkdir $STAGING/temp
		showIfDebug == /usr/bin/unzip $csapPackageFolder/$serviceName.zip -d $STAGING/temp
		/usr/bin/unzip -uq $csapPackageFolder/$serviceName.zip -d $STAGING/temp
		showIfDebug == find $STAGING/temp/scripts
		find $STAGING/temp/scripts/* -name "*.*" -exec native2ascii '{}' '{}' \;
		
		showIfDebug == loading custom $STAGING/temp/scripts/consoleCommands.sh
		#source $STAGING/temp/scripts/consoleCommands.sh
		savedWorking="$csapWorkingDir"
		csapWorkingDir="$STAGING/temp" ;
		source csap-integration-api.sh
		csapWorkingDir=$savedWorking
		
		
		showIfDebug == Switch to temp folder so wrappers can do builds in a temp folder
		cd $STAGING/temp
		
		showIfDebug ==
		showIfDebug == Now invoking provided deployWrapper
		showIfDebug ==
		
		if [ -n "$(type -t buildAdditionalPackages)" ] && [ "$(type -t buildAdditionalPackages)" = function ]; then 
			#printIt  Invoking getPackages
			buildAdditionalPackages
		else 
			deployWrapper
		fi
		
		
		
		showIfDebug ==
		showIfDebug == Wrapper completed
		showIfDebug ==
		
		# getting to the correct folder so that remaining commands can be executed.
		cd $SOURCE_CODE_LOCATION
		
	
		# CS-AP console will do the clean package automatically, but not the deploy to allow custom packaging.
		if [[ "$mavenBuildCommand" == *deploy* ]] ; then
	        # An explicity deploy is done here to finalize
			echo
			echo ===== csap post deploy executing  mvn deploy skipTests
			echo
			mvn -B -s $serviceConfig/settings.xml  -Dmaven.test.skip=true deploy  2>&1
			
			if [ $? != "0" ] ; then
				echo
				echo
				echo =========== CSSP Abort ===========================
				echo __ERROR: Maven build exited with none 0 return code
				echo == Build errors need to be fixed
				exit 99 ;
			fi ;
		fi; 
	
	fi ;
	
fi ;

if [ "$serverRuntime" == "wrapper" ]  ; then  
	# set -x
	rm -rf $STAGING/temp
	mkdir $STAGING/temp
	showIfDebug == /usr/bin/unzip $csapPackageFolder/$serviceName.zip -d $STAGING/temp
	/usr/bin/unzip -uq $csapPackageFolder/$serviceName.zip -d $STAGING/temp
	showIfDebug == find $STAGING/temp/scripts
	find $STAGING/temp/scripts/* -name "*.*" -exec native2ascii '{}' '{}' \;
	
	showIfDebug == loading custom $STAGING/temp/scripts/consoleCommands.sh
	#source $STAGING/temp/scripts/consoleCommands.sh
	savedWorking="$csapWorkingDir"
	csapWorkingDir="$STAGING/temp" ;
	source csap-integration-api.sh
	csapWorkingDir=$savedWorking
		
	showIfDebug == Switch to temp folder so wrappers can do builds in a temp folder
	cd $STAGING/temp
	
	showIfDebug ==
	showIfDebug == Now invoking provided deployWrapper
	showIfDebug ==
	
	#printIt getPackages found:  `type -t getPackages`
	if [ -n "$(type -t getAdditionalBinaryPackages)" ] && [ "$(type -t getAdditionalBinaryPackages)" = function ]; then 
		#printIt  Invoking getPackages
		getAdditionalBinaryPackages
	else 
		printIt Did Not find getAdditionalBinaryPackages interface for wrapper
	fi
fi

showIfDebug ==
showIfDebug == pwd is `pwd`
showIfDebug

showIfDebug ====================================================================
showIfDebug Checking for $SOURCE_CODE_LOCATION/buildCommand.sh
showIfDebug ====================================================================
if [ -e "$SOURCE_CODE_LOCATION/buildCommand.sh" ] ; then 
	echo === buildCommand found = contents:
	cat $SOURCE_CODE_LOCATION/buildCommand.sh;
	native2ascii $SOURCE_CODE_LOCATION/buildCommand.sh $SOURCE_CODE_LOCATION/buildCommand.sh 
	chmod 755 $SOURCE_CODE_LOCATION/buildCommand.sh ;
	$SOURCE_CODE_LOCATION/buildCommand.sh
	
	echo == 
	echo == Assuming $SOURCE_CODE_LOCATION/buildCommand.sh did everything needed - exiting ;
	exit ;
fi;



if [ $csapName == "CsAgent" ] ; then
	
	csapScriptDir="BOOT-INF/classes/shellScripts"
	
	showIfDebug ====================================================================
	showIfDebug Checking for scripts in $buildItem
	showIfDebug ====================================================================
	scriptCheck=`unzip -l $buildItem | grep $csapScriptDir/_newAgent.txt | wc -m`
	if [[ $csapParams == *skipPlatformEscape* ]] ; then
		echo == WARNING: mavenBuildCommand contains skipPlatformEscape
		echo ==== platform runtimes are not being extracted
	fi;
	
	if [  ! $scriptCheck == "0" ] && [[ $csapParams != *skipPlatformEscape* ]] && [[ $csapParams != *mgrUi* ]]; then
		
		
		printIt Extracting platform Scripts from $csapPackageFolder/CsAgent.jar into $STAGING/bin
		
		echo == Deleteing files in $STAGING/bin
		rm -rf $STAGING/bin
	
		if [ ! -e "$STAGING/bin" ]; then
			mkdir $STAGING/bin
		fi ;
		
		printIt Extracting $csapScriptDir to $STAGING/bin
		/usr/bin/unzip -o -j -d $STAGING/bin $csapPackageFolder/CsAgent.jar $csapScriptDir/* -x *defaultConf*
		
		
		printIt Extracting $csapScriptDir/defaultConf to $STAGING/bin/temp
		mkdir -p $STAGING/bin/temp
		/usr/bin/unzip -o -d $STAGING/bin/temp $csapPackageFolder/CsAgent.jar $csapScriptDir/defaultConf/*
		# Boot 1.4 pushes files under BOOT-INF. Because defaultConf is nested folder, -j cannot be used to flatten
		mv $STAGING/bin/temp/BOOT-INF/classes/shellScripts/defaultConf $STAGING/bin/defaultConf
		rm -rf $STAGING/bin/temp
	
	
		cd $STAGING/bin
	# *.* is a ez way to bypass bin files such as keystores
		find * -name "*.*" -exec native2ascii '{}' '{}' \;
		chmod 755 $STAGING/bin/*
	
	else 
		showIfDebug == csap platform not detected as shellScripts/_newAgent.txt is not in $buildItem, 
	fi
fi

cd $STAGING

echo;echo;
echo ====================================================================
echo Finished Build, $buildItem is now in $csapPackageFolder
echo ====================================================================
echo;echo;

showIfDebug getting rid of $0
rm $0 ;
# The following must be the final line to trigger start to occur in ServiceController
echo == BUILD__SUCCESS