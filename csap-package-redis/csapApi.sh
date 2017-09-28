#!/bin/bash

#
# NOTE: CSAP will set "$redisCredential" $redisMaster $redisSentinels
#       based on application definition
#



displayHeader() {
	echo
	echo
	echo	
	echo ====================================================================
	echo == 
	echo == CSAP redis Package: $*
	echo ==
	echo ====================================================================
	
}

printIt() {
	echo;echo;
	echo = 
	echo = $*
	echo = 
}

buildAdditionalPackages() {
	
	displayHeader buildAdditionalPackages
	
	#printIt Debug mode, skipping deploy
	#return
	printIt Deploy, Current directory is `pwd` , csapWorkingDir is $csapWorkingDir
	
	printIt  console has built wrapper to $STAGING/warDist/$csapName.zip
	
	#ls -l $STAGING/warDist
	
	printIt removing previous csapWorkingDir as it is the target for build: $csapWorkingDir
	rm -rf $csapWorkingDir ;

	printIt Getting source distribution http://$toolsServer/csap/redis-3.2.4.tar.gz 
	wget -nv http://$toolsServer/csap/redis-3.2.4.tar.gz 


	printIt Extracting redis to `pwd`
	tar -xvzf redis*.gz 
	chmod -R 755 redis*
	cd redis*
	
	printIt Building redis in `pwd`
	#make 
	make PREFIX=$csapWorkingDir install
	printIt Redis compile completed, now zipping
	
	cd $csapWorkingDir ; # need to zip in a relative folder
	echo == zipping binary in $csapWorkingDir
	zip -q -r redisBinary bin
	
	printIt copying redisBinary.zip $SOURCE_CODE_LOCATION so it will be included by assembly.xml into zip uploaded to maven
	cp redisBinary.zip $SOURCE_CODE_LOCATION
	
	# echo == Adding apacheBinary.zip to $STAGING/warDist/$csapName.zip
	# zip -q -r $STAGING/warDist/$csapName apacheBinary.zip
	
	# list out the files in the zip
	# unzip -l $STAGING/warDist/$csapName.zip
	
	printIt checking for deploy in $mavenBuildCommand
	if [[ "$mavenBuildCommand" == *package* ]] ; then
		
		printIt Detected source build - performing maven package. Deploy is done by console
		 
		cd $SOURCE_CODE_LOCATION
		mvn -s $serviceConfig/settings.xml clean package  2>&1

		printIt pushing built item into $STAGING/warDist/$csapName.zip
		cp target/*.zip $STAGING/warDist/$csapName.zip
	
		printIt hook for csap console change artifact to deploy name
		cp target/*.zip target/$csapName.zip
	fi ;

	
	printIt === Server setup complete: use redi-cli to start or stop
}


getAdditionalBinaryPackages() {
	
	displayHeader "getAdditionalBinaryPackages: no other packages to deploy"
}

killWrapper() {
	displayHeader kill
	cd $csapWorkingDir
	stopWrapper
}



stopWrapper() {

	displayHeader stop
	cd $csapWorkingDir
	echo  == Current directory is `pwd` 
	echo == trying a graceful shutdown first in the background
	bin/redis-cli -a "$redisCredential" shutdown 
	
	
	echo == completed redis stop, waiting 3 seconds to give redis shutdown to complete  
	sleep 2
	
	echo == doing a ping to confirm shutdown
	bin/redis-cli -a "$redisCredential" ping  
	
	printIt killall on redis-sentinel
	killall -v redis-sentinel
	
}

startWrapper() {
	displayHeader start 
	
	echo == console has set redisMaster to: $redisMaster and redisCredental: MASKED
	echo == console has set csapWorkingDir to: $csapWorkingDir
	echo == Redis will be running on port $csapHttpPort
	
	cd $csapWorkingDir ;
	
	
	printIt Starting redis in $csapWorkingDir
	
	
	if [ ! -e  "$csapWorkingDir/bin" ] ; then
		
		unzip -qq -o redisBinary.zip
		
		if [ -e "$serviceConfig/$csapName/resources/$csapLife" ]; then
			printIt Found Overide properties: $serviceConfig/$csapName/$csapLife, copying to  conf
			\cp -fr $serviceConfig/$csapName/resources/$csapLife conf
		else
			printIt Did not find custom resources: $serviceConfig/$csapName/resources/$csapLife
			printIt The default policy is a 20MB in memory with replication but no persistence 
			printIt It is strongly recommended you review , customize, and checkin. 
		fi ;
		
	else
		
		printIt Found bin, skipping extraction of redis 
		
	fi ;
	
		

	configureLogging
	
	
	if [ -e "$serviceConfig/$csapName/resources/$csapLife" ]; then
		printIt Found csapLife Overide properties: $serviceConfig/$csapName/resources/$csapLife, copying to  conf
		\cp -fr $serviceConfig/$csapName/resources/$csapLife/* conf
	else
		printIt Did not find csapLife override resources: $serviceConfig/$csapName/resources/$csapLife
	fi ;
	
	redisConfigFile="conf/master.conf"
	
	if [ $HOSTNAME != $redisMaster ] ; then 
		redisConfigFile="conf/slave.conf"
		cp conf/slaveTemplate.conf conf/slave.conf
		sed -i "s=MASTER_HOST=$redisMaster=g" conf/slave.conf
		sed -i "s=MASTER_PORT=$csapHttpPort=g" conf/slave.conf
	fi ;

	printIt Starting redis-server with $redisConfigFile and logs/consoleLogs.txt 
	bin/redis-server $redisConfigFile >> logs/consoleLogs.txt 2>&1 &
	
	sleep 3
	printIt Setting password on redis server
	bin/redis-cli config set requirepass "$redisCredential"
	
	printIt Setting password to access peers
	bin/redis-cli -a "$redisCredential" config set masterauth "$redisCredential"
	
	printIt Starting sentinel with default port 26379 conf/sentinel.conf and logs/sentinelLogs.txt 
	cp conf/sentinelTemplate.conf conf/sentinel.conf
	
	sed -i "s=MASTER_HOST=$redisMaster=g" conf/sentinel.conf
	sed -i "s=MASTER_PORT=$csapHttpPort=g" conf/sentinel.conf
	sed -i "s=MASTER_CREDENTIAL=$redisCredential=g" conf/sentinel.conf
	
	printIt "Added protected-mode no to sentinel to allow connections"
	bin/redis-sentinel  conf/sentinel.conf >> logs/sentinelLogs.txt 2>&1 &
	sleep 2
	
	printIt sentintel master information
	bin/redis-cli -p 26379 sentinel master mymaster
	
	printIt == completed redis startup, runing redis-cli ping
	bin/redis-cli -a "$redisCredential" ping
	
	
}


configureLogging() {
	
	if [ -e $csapWorkingDir/logs ] ; then 
		
		printIt log folder already exists, skipping
		return;
		 	
	fi;
	
	printIt == creating $csapWorkingDir/logs
	mkdir -p $csapWorkingDir/logs

			
	echo == creating $csapWorkingDir/logs/logRotate.config
			
	echo "#created by csap redis package" > $csapWorkingDir/logs/logRotate.config
	echo "$csapWorkingDir/logs/consoleLogs.txt {" >> $csapWorkingDir/logs/logRotate.config
	echo "copytruncate" >> $csapWorkingDir/logs/logRotate.config
	echo "weekly" >> $csapWorkingDir/logs/logRotate.config
	echo "rotate 3" >> $csapWorkingDir/logs/logRotate.config
	echo "compress" >> $csapWorkingDir/logs/logRotate.config
	echo "missingok" >> $csapWorkingDir/logs/logRotate.config
	echo "size 10M" >> $csapWorkingDir/logs/logRotate.config
	echo "}" >> $csapWorkingDir/logs/logRotate.config
	echo "" >> $csapWorkingDir/logs/logRotate.config
		
	
}
