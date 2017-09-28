#!/bin/bash

function displayHeader() {
	echo
	echo
	echo	
	echo ====================================================================
	echo == 
	echo == CSAP httpd Package: $*
	echo ==
	echo ====================================================================
	
}

function printIt() {
	echo;echo;
	echo = 
	echo = $*
	echo = 
}

function checkInstalled() { 
	packageName="$1"
	rpm -q $packageName
	if [ $? != 0 ] ; then 
		printIt error: $packageName not found, install using yum -y install; 
		exit; 
	fi   
}

function getSourcePackages() {
	
	printIt "Getting source packages from $toolsServer/httpd"
	wget -nv http://$toolsServer/httpd/apr-1.5.2.zip
	wget -nv http://$toolsServer/httpd/apr-util-1.5.2.zip
	wget -nv http://$toolsServer/httpd/httpd-2.4.23.zip
	wget -nv http://$toolsServer/httpd/pcre-8.37.zip
	wget -nv http://$toolsServer/httpd/tomcat-connectors-1.2.42.zip

}


function buildAdditionalPackages() {
	
	printIt "Verifying required packages installed on host..."
	checkInstalled make ;
	checkInstalled zlib-devel ;
	checkInstalled zip ;
	checkInstalled unzip ;
	
	displayHeader buildAdditionalPackages
	
	printIt Current directory is `pwd` 
	printIt console has built wrapper to $STAGING/warDist/$csapName.zip
	
	getSourcePackages
	
	#ls -l $STAGING/warDist
	if [ ! -e "/usr/include/zlib.h" ] ; then
		printIt "ERROR: Missing compression package. Use yum -y install zlib-devel"
		exit ;
	fi
	
	# echo  == Getting binary deployment - use maven as it will act as a caching proxy server
	# add any other deploy time hooks


	export APACHE_HOME=$csapWorkingDir
	$APACHE_HOME/bin/apachectl stop
	
	printIt removing previous csapWorkingDir as it is the target for build: $csapWorkingDir
	rm -rf $csapWorkingDir
	echo ===
	echo == Setting up WebServer in $APACHE_HOME
	echo ===

	#/usr/bin/unzip -qq -o httpd*.zip -d .
	printIt Using tar to extract source files since file added to repo are actually tar.gz file
	echo == 1 of 5 Extracting httpd to `pwd`
	tar -xvzf httpd*.zip 
	chmod -R 755 httpd*
	cd httpd*
	
	printIt 2nd Apache HOOK: Need to strip off existing apache from path because configure will attempt to us it
	export PATH=${PATH/httpd/dummyForBuild}
	
	#
	# hooks for 2.4.x
	printIt  Getting source for remote packages. Note http://httpd.apache.org/docs/current/install.html 
	cd srclib
	
	echo == 2 of 5 Extracting pcre to `pwd`
	tar -xvzf ../../pcre*.zip
	cd pcre*
	./configure --prefix=$APACHE_HOME
	printIt Building in `pwd`
	make install
	cd ..
	
	printIt 3 of 5 apr Extracting apr to `pwd`
	tar -xvzf ../../apr-1*.zip
	ls
	mv apr-1.5.2/ apr
	
	
	printIt 4 of 5 Extracting apr-util to `pwd` 
	tar -xvzf ../../apr-util*.zip
	ls
	mv apr-util-1.5.2/ apr-util

	cd ..
	
	# http://httpd.apache.org/docs/current/misc/perf-tuning.html 
	# ref. http://httpd.apache.org/docs/2.4/programs/configure.html 
	# most picks up rewrite, all picks up proxy --enable-modules=most --enable-MODULE=static -enable-proxy  
	# --with-mpm=worker is no longer the default, switching to event
	# set COMPILE_OPTIONS to --disable-ssl
	
	printIt "COMPILE_OPTIONS has ssl disable" 
	./configure --prefix=$APACHE_HOME --with-pcre=$APACHE_HOME --enable-mods-static=all  --with-included-apr --disable-ssl
	
	
	printIt Building Httpd in `pwd`
	make 
	make install
	cd $STAGING/temp
	# rm -rf http*
	
	printIt 5 of 5 modjk  to `pwd` 
	tar -xvzf tomcat-connectors*.zip
	
	chmod -R 755  tomcat*src
	cd  tomcat*src/native
	 ./configure --with-apxs=$APACHE_HOME/bin/apxs
	 cd apache-2.0
	
	printIt Building Httpd in `pwd`
	 make
	 cp mod_jk.so $APACHE_HOME/modules
	 cd $STAGING/temp
	 # rm -rf tom*
	 
	printIt Apache compile completed, now zipping
	cd $csapWorkingDir ; # need to zip in a relative folder
	echo == zipping binary in $csapWorkingDir
	zip -q -r apacheBinary *
	
	printIt copying apacheBinary.zip $SOURCE_CODE_LOCATION so it will be included by assembly.xml into zip uploaded to maven
	cp apacheBinary.zip $SOURCE_CODE_LOCATION
	
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
	
		
	printIt Deleting $csapWorkingDir/bin to force generation of httpd/conf files 
	rm -rf $csapWorkingDir/bin
	
	printIt Server setup complete: use apachectl restart or console
	
}

function getAdditionalBinaryPackages() {
	
	displayHeader "getAdditionalBinaryPackages: no other packages to deploy"
}

function killWrapper() {
	
	displayHeader killWrapper
	
	printIt Current directory is `pwd` 	
	export APACHE_HOME=$csapWorkingDir
	
	printIt trying a graceful shutdown first: $APACHE_HOME/bin/apachectl stop 
	$APACHE_HOME/bin/apachectl stop
	
	printIt completed httpd stop, waiting 3 seconds to give httpd shutdown to complete  
	
	sleep 5

	clearHttpdSemaphoresFromSharedMemory
}

function clearHttpdSemaphoresFromSharedMemory() {
	
	printIt clearHttpdSemaphoresFromSharedMemory is being invoked incase semaphores are still present

	
	# rh 6 uses non root users, but redhat 5 still uses root to own.
	for semid in `ipcs -s | grep -v -e - -e key  -e "^$" | cut -f2 -d" "`; do ipcrm -s $semid; done
	for semid in `ipcs -m | grep -v -e - -e key  -e "^$" | cut -f2 -d" "`; do ipcrm -m $semid; done
	
	#rm -rf $STAGING/bin/rootDeploy.sh
		
	# 
	# ssadmin user has sudo root on file: /home/ssadmin/staging/bin/rootDeploy.sh
	# So content is put in there for execution as root
	#
	##echo 'for semid in `ipcs -s | grep -v -e - -e key  -e "^$" | cut -f2 -d" "`; do ipcrm -s $semid; done' >>  $STAGING/bin/rootDeploy.sh
	##echo 'for semid in `ipcs -m | grep -v -e - -e key  -e "^$" | cut -f2 -d" "`; do ipcrm -m $semid; done' >>  $STAGING/bin/rootDeploy.sh
	
	##chmod 755 /home/ssadmin/staging/bin/rootDeploy.sh
	##	sudo /home/ssadmin/staging/bin/rootDeploy.sh $csapWorkingDir/scripts
		
	
	printIt ipcs output, note that httpd start up will fail if ipcs is still showing semaphores
	ipcs -a
	
	numLeft=`ipcs | grep -v -e - -e key -e root -e "^$" | wc -l`
	
	if [ $numLeft != "0" ] ; then
		printIt Error : httpd is not ok with semaphores on system. Use ipcs to list and ipcsrm to delete
		sleep 10 ; # give console a chance to view
	else 
		echo ; echo == It appears all semaphores have been deleted
	fi
}

function stopWrapper() {
	displayHeader stop
	
	printIt console has set csapWorkingDir: $csapWorkingDir and csapHttpPort: $csapHttpPort
	
	
	export APACHE_HOME=$csapWorkingDir
	
	printIt trying a graceful shutdown first: $APACHE_HOME/bin/apachectl stop 
	$APACHE_HOME/bin/apachectl stop
	
	printIt completed httpd stop   ;
}

function startWrapper() {
	
	displayHeader start
	
	printIt console has set csapWorkingDir: $csapWorkingDir and csapHttpPort: $csapHttpPort
	
	cd $csapWorkingDir ;
	
	export APACHE_HOME=$csapWorkingDir
	APACHE_HOME=$csapWorkingDir
	
	clearHttpdSemaphoresFromSharedMemory
	
	printIt Starting Apache httpd in $APACHE_HOME

	
	
	if [ ! -e  "$csapWorkingDir/bin" ] ; then
		
		unzip -qq -o apacheBinary.zip
		
		if [[ "$HOST" == csap-prd* ]] || [[ "$HOST" == rtptools-prd* ]] ; then 
			configureToolsHttpd
		else 
			configureStandardHttpd
		fi ;

		configureLogging
		
	else
		
		printIt Found bin, skipping extraction of httpd config files
		
	fi ;
	
	if [ ! -e "$STAGING/httpdConf/csspJkMount.conf" ] ; then
		printIt  do a Tools/Generate Http loadbalance
		exit ;
	fi ;
	

	if [ ! -e "$STAGING/httpdConf/csspCustomRewrite.conf" ] ; then
		printIt Generating an empty $STAGING/httpdConf/csspCustomRewrite.conf
		touch $STAGING/httpdConf/csspCustomRewrite.conf
	fi ;
	$APACHE_HOME/bin/apachectl restart
	
	
	addPort80To8080Route
	
	printIt completed httpd startup
	
}

function addPort80To8080Route() {
	
	printIt "Running routing.sh to remove and add 8080 to 80 nat rules"
	
	command="$1" ;
	rm -rf $STAGING/bin/rootDeploy.sh
	
	routingFunctionsFile="$csapWorkingDir/scripts/routing.sh" ;
	cat $routingFunctionsFile >  $STAGING/bin/rootDeploy.sh

	chmod 755 /home/ssadmin/staging/bin/rootDeploy.sh
	sudo /home/ssadmin/staging/bin/rootDeploy.sh
		
	
}

function configureToolsHttpd() {
		
		printIt Running configureToolsHttpd - special for csap tools server
		printIt Install $csapWorkingDir/scripts/toolsConfig/httpdTemplate.conf
		
		cp $csapWorkingDir/scripts/toolsConfig/httpdTemplate.conf $APACHE_HOME/conf/httpd.conf

		updateHttpdTemplate
			
		printIt copying scripts/toolsConfig/htdocs/* to $HOME/web
		if [ ! -d $HOME/web ] ; then 
			mkdir $HOME/web
		fi
			
		\cp -fr scripts/toolsConfig/htdocs/* $HOME/web

		# Update the host name in the index page.
		sed -i "s=csap-web01=$HOSTNAME=g" $HOME/web/index.html
}


function configureStandardHttpd() {
		
		printIt Running configureStandardHttpd 
		printIt Install $csapWorkingDir/scripts/httpdTemplate.conf
	 	cp $csapWorkingDir/scripts/httpdTemplate.conf $APACHE_HOME/conf/httpd.conf

		updateHttpdTemplate
			
		printIt copying scripts/htdocs/* to $APACHE_HOME/htdocs
		\cp -fr scripts/htdocs/* $APACHE_HOME/htdocs	
}

function updateHttpdTemplate() {
		sed -i "s/_HTTPDPORT_/$csapHttpPort/g" $APACHE_HOME/conf/httpd.conf
		# interesting using = as the sed delim in order to insert paths with / in them
		
		
		sed -i "s=_APACHEHOME_=$APACHE_HOME=g" $APACHE_HOME/conf/httpd.conf				
		sed -i "s=_REWRITE_=$STAGING/httpdConf/csspRewrite.conf=g" $APACHE_HOME/conf/httpd.conf
		sed -i "s=_CUSTOMREWRITE_=$STAGING/httpdConf/csspCustomRewrite.conf=g" $APACHE_HOME/conf/httpd.conf
		sed -i "s=_PROXY_=$STAGING/httpdConf/proxy.conf=g" $APACHE_HOME/conf/httpd.conf
			

		printIt Configuring $APACHE_HOME/conf/httpd.conf  to use $STAGING/httpdConf/worker.properties, $STAGING/httpdConf/csspJkMount.conf
		sed -i "s=_WORKER_=$STAGING/httpdConf/worker.properties=g" $APACHE_HOME/conf/httpd.conf
		sed -i "s=_JKMOUNT_=$STAGING/httpdConf/csspJkMount.conf=g" $APACHE_HOME/conf/httpd.conf	
}

function configureLogging() {
		printIt creating $csapWorkingDir/logs
		mkdir -p $csapWorkingDir/logs

		
		printIt creating $csapWorkingDir/logs/logRotate.config
		
		echo "#created by httpdWrapper" > $csapWorkingDir/logs/logRotate.config
		echo "$csapWorkingDir/logs/access.log {" >> $csapWorkingDir/logs/logRotate.config
		echo "copytruncate" >> $csapWorkingDir/logs/logRotate.config
		echo "weekly" >> $csapWorkingDir/logs/logRotate.config
		echo "rotate 3" >> $csapWorkingDir/logs/logRotate.config
		echo "compress" >> $csapWorkingDir/logs/logRotate.config
		echo "missingok" >> $csapWorkingDir/logs/logRotate.config
		echo "size 10M" >> $csapWorkingDir/logs/logRotate.config
		echo "}" >> $csapWorkingDir/logs/logRotate.config
		echo "" >> $csapWorkingDir/logs/logRotate.config
		
		
		echo "$csapWorkingDir/logs/error_log {" >> $csapWorkingDir/logs/logRotate.config
		echo "copytruncate" >> $csapWorkingDir/logs/logRotate.config
		echo "weekly" >> $csapWorkingDir/logs/logRotate.config
		echo "rotate 3" >> $csapWorkingDir/logs/logRotate.config
		echo "compress" >> $csapWorkingDir/logs/logRotate.config
		echo "missingok" >> $csapWorkingDir/logs/logRotate.config
		echo "size 10M" >> $csapWorkingDir/logs/logRotate.config
		echo "}" >> $csapWorkingDir/logs/logRotate.config
		echo "" >> $csapWorkingDir/logs/logRotate.config
		
		echo "$csapWorkingDir/logs/mod_jk.log {" >> $csapWorkingDir/logs/logRotate.config
		echo "copytruncate" >> $csapWorkingDir/logs/logRotate.config
		echo "daily" >> $csapWorkingDir/logs/logRotate.config
		echo "rotate 5" >> $csapWorkingDir/logs/logRotate.config
		echo "compress" >> $csapWorkingDir/logs/logRotate.config
		echo "missingok" >> $csapWorkingDir/logs/logRotate.config
		# This will run hourly rotates. 
		echo "size 5M" >> $csapWorkingDir/logs/logRotate.config
		echo "}" >> $csapWorkingDir/logs/logRotate.config
		echo "" >> $csapWorkingDir/logs/logRotate.config	
}
