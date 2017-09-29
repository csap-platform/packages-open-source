#!/bin/bash


function displayHeader() {
	echo
	echo
	echo	
	echo ====================================================================
	echo == 
	echo == CSAP mongo Package: $*
	echo ==
	echo ====================================================================
	
}

function printIt() {
	echo;echo;
	echo = 
	echo = $*
	echo = 
}

packageDir=$STAGING/warDist/$csapName.secondary
version="77" ;
mongoConf=$csapWorkingDir/conf

function buildAdditionalPackages() {
	
	displayHeader buildAdditionalPackages: no additional packages to build

}

function getAdditionalBinaryPackages() {
	
	displayHeader getAdditionalBinaryPackages $mongoVersion.tgz
	
	printIt removing $packageDir
	\rm -rf $packageDir
	
	printIt Getting mongo binaries from $toolsServer and storing in $packageDir
	mkdir -p $packageDir
	cd $packageDir
	
	localDir="/media/sf_workspace/packages"
	if [ -e $localDir ] ; then 
		printIt using local copies from $localDir
		cp $localDir/* .
	else
		wget -nv http://$toolsServer/mongo/$mongoVersion.tgz
	fi;
	
}

function killWrapper() {

	stopWrapper
	#MONGOPID=`ps -ef | grep '_csapWorkingDir_/mongodatabase/bin/mongod' | grep -v grep | awk '{print $2}'`
	#echo == mongodb pid $MONGOPID	
	#kill $MONGOPID	

	
}

function stopWrapper() {
	displayHeader "stopWrapper: triggering mongo --shutdown"

	printIt invoking "$csapWorkingDir/mongodatabase/bin/mongod -f $mongoConf/mongodb.conf --shutdown"
	if [ -e $csapWorkingDir/mongodatabase/bin/mongod ] ; then 
		$csapWorkingDir/mongodatabase/bin/mongod -f $mongoConf/mongodb.conf --shutdown
		printIt sleeping for 2 seconds
		sleep 2 ;
	fi ;
}


function startWrapper() {
	displayHeader "starting mongo in $csapWorkingDir"
	
	isSkipDeploy=`expr match "$svcSkipDeployment" 'yes' != 0`
	
	if [ $isSkip == "0"  ]  ; then
		
		if [ -d  $csapWorkingDir/mongodatabase ] ; then
			printIt === skipping deployment
		else		
			installMongo			
		fi
		
		
		#
		#echo == Kicking off mongoDbDeploy.sh
		#rm -rf $STAGING/bin/mongoDbDeploy.sh				
		#cat scripts/mongoDbInstall.sh >  $STAGING/bin/mongoDbDeploy.sh
		#chmod 755 $HOME/staging/bin/mongoDbDeploy.sh		
		#source $HOME/staging/bin/mongoDbDeploy.sh
	else
		printIt Info: Skipping Deployment 

		
	fi;
	
	chmod 700 $mongoConf/*
	

	
	# $csapWorkingDir/mongodatabase/bin/mongod --config $mongoConf/mongodb.conf &

	
	printIt Copying default log rotation policy to  $csapWorkingDir/logs
	cp $csapWorkingDir/scripts/logRotate.config $csapWorkingDir/logs
	sed -i "s|_RUNTIME_|$csapWorkingDir|g" $csapWorkingDir/logs/logRotate.config
	
	printIt invoking "$csapWorkingDir/mongodatabase/bin/mongod --config $mongoConf/mongodb.conf  csapParams: $csapParams"
	$csapWorkingDir/mongodatabase/bin/mongod --config $mongoConf/mongodb.conf $csapParams >> $csapWorkingDir/logs/console.log  2>&1 &
	
	printIt "Startup complete: $csapName data is stored at: $mongoData"
}



function installMongo() {
	
	
	printIt "Installing mongodb to $csapWorkingDir"
	
	cd $csapWorkingDir
	tar -xzf $packageDir/$mongoVersion*.tgz
	
	printIt "Moving extracted contents to  $csapWorkingDir/mongodatabase"
	rm -rf mongodatabase
	mv $mongoVersion mongodatabase
	
	printIt Creating configuration in $mongoConf
	mkdir -p $mongoConf
	cp $csapWorkingDir/scripts/mongodb.conf $mongoConf
	cp $csapWorkingDir/scripts/mongodb-keyfile $mongoConf 
	chmod 600 $mongoConf/mongodb-keyfile
	
	mkdir -p $csapWorkingDir/logs
		
					
	sed -i "s/_MONGOPORT_/$csapHttpPort/g" $mongoConf/mongodb.conf
	export logpath=$csapWorkingDir/logs/mongodb.log
	sed -i "s|_LOGPATH_|$logpath|g" $mongoConf/mongodb.conf
	sed -i "s|_CONFDIR_|$mongoConf|g" $mongoConf/mongodb.conf
	
	
	printIt "updating variables in $csapWorkingDir/admin/*.sh"
	sed -i "s|CSAP_WORKING|$csapWorkingDir|g" $csapWorkingDir/admin/*.sh
	sed -i "s|_LBURL_|$csapLbUrl|g" $csapWorkingDir/admin/*.sh
	sed -i "s|_LIFECYCLE_|$csapLife|g" $csapWorkingDir/admin/*.sh
	
	printIt "Use csap job runner to invoke with required environment variables."
	
	printIt Updating $mongoConf/mongodb.conf with data location $mongoData
	sed -i "s|_DBPATH_|$mongoData|g" $mongoConf/mongodb.conf
	mkdir  -p $mongoData
	
	chmod 700 $mongoConf/*
	cd $csapWorkingDir
}
