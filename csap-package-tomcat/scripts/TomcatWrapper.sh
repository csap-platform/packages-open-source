#!/bin/bash



function printTom() { echo; echo; echo ======================== Tomcat ====================================; echo == $* ; echo ==================================================================; }

tomcatRuntimes=$PROCESSING/appsTomcat

function tomcatEnvSetup() {
	printTom Tomcat Package Configuration
	# runtime versions
	tom7=`ls -td $tomcatRuntimes/apache-tomcat-7* | head -1`
	tom8=`ls -td $tomcatRuntimes/apache-tomcat-8.0* | head -1`
	tom85=`ls -td $tomcatRuntimes/apache-tomcat-8.5* | head -1`
	tom9=`ls -td $tomcatRuntimes/apache-tomcat-9* | head -1`
	cssp1=`ls -td $tomcatRuntimes/cssp-1* | head -1`
	#cssp2=`ls -td $tomcatRuntimes/cssp2-2* | head -1`
	cssp3=`ls -td $tomcatRuntimes/cssp3-3* | head -1`
	
	
	#set default to be tomcat 7
	TOMCAT_VERSION=$tom7 ; 
	SOURCE_SERVERXML=$tom7/custom/conf/_csapTemplate_server.xml
	
	
	chk=`echo $serverRuntime | grep -c tomcat8`
	if [  $chk != 0 ] ; then 
		TOMCAT_VERSION=$tom8; 
	 	SOURCE_SERVERXML=$tom8/custom/conf/_csapTemplate_server.xml 
	fi
	
		
	chk=`echo $serverRuntime | grep -c tomcat8-5`
	if [  $chk != 0 ] ; then 
		TOMCAT_VERSION=$tom85; 
	 	SOURCE_SERVERXML=$tom85/custom/conf/_csapTemplate_server.xml 
	fi
	
	chk=`echo $serverRuntime | grep -c tomcat9`
	if [  $chk != 0 ] ; then 
		TOMCAT_VERSION=$tom9; 
	 	SOURCE_SERVERXML=$tom9/custom/conf/_csapTemplate_server.xml 
	fi
	
	chk=`echo $serverRuntime | grep -c cssp-1`
	if [  $chk != 0 ] ; then 
		TOMCAT_VERSION=$cssp1 ; 
	 	SOURCE_SERVERXML=$tom7/custom/conf/_csapTemplate_server.xml 
	fi
	
	
		
	chk=`echo $serverRuntime | grep -c cssp-2`
	if [  $chk != 0 ] ; then 
		TOMCAT_VERSION=$cssp2 ; 
	 	SOURCE_SERVERXML=$STAGING/bin/tomcat7server.xml 
	 	SOURCE_SERVERXML=$tom7/custom/conf/_csapTemplate_server.xml 
	fi
	
	#
	# tomcat 8 server
	chk=`echo $serverRuntime | grep -c cssp-3`
	if [  $chk != 0 ]  ; then
		TOMCAT_VERSION=$cssp3 ; 
	 	SOURCE_SERVERXML=$tom8/custom/conf/_csapTemplate_server.xml 
	fi
	
	showIfDebug  "dirVars.sh\t:" === TOMCAT Version: $TOMCAT_VERSION
	
	export CATALINA_HOME="$TOMCAT_VERSION"
	
	printTom CATALINA_HOME: $CATALINA_HOME SOURCE_SERVERXML: $SOURCE_SERVERXML

	
	export CATALINA_BASE="$csapWorkingDir"
	export warDir=$CATALINA_BASE/webapps
	
}


# Run only when dirs not exist
configureTomcatWorkingDir() {
	
	printTom Setting up the tomcat working directory CATALINA_BASE: $CATALINA_BASE

	if [ ! -e "$CATALINA_BASE" ]; then
		echo mkdir $CATALINA_BASE
		mkdir $CATALINA_BASE
	fi ;
	
	if [ ! -e "$CATALINA_BASE/conf" ]; then
		mkdir $CATALINA_BASE/conf
	fi;
	
	printTom  pwd: `pwd` , Copying in CSAP tomcat properties into: $runDir

	 
	if [ ! -e $CATALINA_BASE/logs ] ; then  
		
		if [ -e $runDir.logs ] ; then 
			echo == moving existing Log folder from: $runDir.logs 
			mv  $runDir.logs $CATALINA_BASE/logs
		else
			mkdir $CATALINA_BASE/logs ; 
		fi;
	fi
	
	if [ ! -e $CATALINA_BASE/temp ] ; then  mkdir $CATALINA_BASE/temp ; fi
	if [ ! -e $CATALINA_BASE/webapps ] ; then  mkdir $CATALINA_BASE/webapps ; fi
	if [ ! -e $CATALINA_BASE/webapps/ROOT ] ; then  mkdir $CATALINA_BASE/webapps/ROOT ; fi

	
	if [[ -e $CATALINA_HOME/custom  &&  $csapParams != *DrawTomcat*  ]]; then

		printTom  Found $CATALINA_HOME/custom == copying to $CATALINA_BASE

		\cp -rf $CATALINA_HOME/custom/* $CATALINA_BASE
	else 
		if [ -e $serviceConfig/$serverRuntime ]; then
			
			printTom Found $serviceConfig/$serverRuntime == copying to $CATALINA_BASE

			#scm dirs will be copied - but they can be ignored by runtime
			\cp -rf $serviceConfig/$serverRuntime/* $CATALINA_BASE
				
		else
			
			printTom Did not find $CATALINA_HOME/custom or $serviceConfig/$serverRuntime 
		fi

	fi ; 
	
	# Enable UI to override class loader order
	if [[ $csapParams = *DparentFirst* ]] ; then 
		printTom forcing parent classLoader
		sed -i "s/<Context>/<Context><Loader delegate=\"true\"\\/>/g" $CATALINA_BASE/conf/context.xml
	fi;
			
			
	if [[ $csapParams = *DtomcatManager* ]] ; then 
		printTom WARNING: Installing tomcat manager may be insecure 
		echo == copying $CATALINA_HOME/webapps to $CATALINA_BASE
		\cp -rf $CATALINA_HOME/webapps/manager $CATALINA_BASE/webapps
		\cp -rf $CATALINA_HOME/webapps/host-manager $CATALINA_BASE/webapps
	fi;
	
	# adding in redirect

	if [ -e $CATALINA_BASE/webapps/ROOT/index.jsp ] ; then
		printTom Adding root redirect
		sed -i "s/CsAgent/$serviceName/g" $CATALINA_BASE/webapps/ROOT/index.jsp
	fi;
		
}

function configureServerXml() {
	
	printTom Configuring tomcat server.xml
	
	# you can overwrite the generated one if you want, but not advised
	if [ ! -e "conf/server.xml" ] && [ $isHotDeploy != "1" ] ; then
		portPrefix=${csapHttpPort:0:3}
		modJkRoute=$serviceName"_"$csapHttpPort`hostname`
		echo == Coping $SOURCE_SERVERXML to $CATALINA_BASE,
		echo ==  changing _SC_PORT_ to $portPrefix and _SC_ROUTE_ to $modJkRoute
		echo == 
		\cp -f $SOURCE_SERVERXML $CATALINA_BASE/conf/server.xml
		sed -i "s/_SC_ROUTE_/$modJkRoute/g" $CATALINA_BASE/conf/server.xml
		sed -i "s/_SC_PORT_/$portPrefix/g" $CATALINA_BASE/conf/server.xml
		
		# optionall disable 
		if [[  $JAVA_OPTS == *noJmxFirewall*  ]]  ; then 
			echo == Detected noJmxFirewall skip, deleting JmxRemoteLifecycleListener lines
			sed -i "/JmxRemoteLifecycleListener/d" $CATALINA_BASE/conf/server.xml
			sed -i "/rmiRegistryPortPlatform/d" $CATALINA_BASE/conf/server.xml
		fi
		
		if [[  $JAVA_OPTS == *noWebSocket*  ]]  ; then 
			echo == Detected noWebSocket skip, Adding skip
			sed -i "/JmxRemoteLifecycleListener/d" $CATALINA_BASE/conf/catalina.properties
			sed -i "s/jstl.jar/jstl.jar,tomcat7-websocket.jar/g" $CATALINA_BASE/conf/catalina.properties
		fi
		
		# update compressions settings, default is off 
		sed -i "s/_SC_COMPRESS_/$compress/g" $CATALINA_BASE/conf/server.xml
		sed -i "s=_SC_MIME_=$mimeType=g" $CATALINA_BASE/conf/server.xml
		
		sed -i "s/_SC_THREADS_/$servletThreads/g" $CATALINA_BASE/conf/server.xml
		sed -i "s/_SC_ACCEPT_/$servletAccept/g" $CATALINA_BASE/conf/server.xml
		sed -i "s/_SC_MAX_/$servletConnections/g" $CATALINA_BASE/conf/server.xml
		sed -i "s/_SC_TIME_/$servletTimeout/g" $CATALINA_BASE/conf/server.xml
		
		sed -i "s/_SC_SECRET_/$ajpSecret/g" $CATALINA_BASE/conf/server.xml
		if [  $skipHttpConnector == "no" ] ; then
			echo
			echo == Enabling http Connector in $CATALINA_BASE/conf/server.xml
			echo
			sed -i "s/_SC_SKIP_HTTP1_/-->/g" $CATALINA_BASE/conf/server.xml
			sed -i "s/_SC_SKIP_HTTP2_/<!--/g" $CATALINA_BASE/conf/server.xml
		else 
			echo
			echo == Disabling http Connector in $CATALINA_BASE/conf/server.xml
			echo
			sed -i "s/_SC_SKIP_HTTP1_/ /g" $CATALINA_BASE/conf/server.xml
			sed -i "s/_SC_SKIP_HTTP2_/ /g" $CATALINA_BASE/conf/server.xml
		fi ;
		
		if [  $isSecure == "yes" ] ; then
			# http://www.unc.edu/~adamc/docs/tomcat/tc-accel.html
			# tomcat running behind SSL Accelerator will get confused. These settings
 
			echo == Secure flag found in metadata, ajp connector in server.xml is being updated to support SSL acceleration
			echo == ref http://www.unc.edu/~adamc/docs/tomcat/tc-accel.html
			echo ==
		 	ajp="redirectPort=\"443\" proxyPort=\"443\"  secure=\"true\" scheme=\"https\" SSLEnabled=\"false\""
			sed -i "s/_SC_SECURE_AJP/$ajp/g" $CATALINA_BASE/conf/server.xml
			
		 	direct="secure=\"true\" scheme=\"http\" SSLEnabled=\"false\""
			sed -i "s/_SC_SECURE_HTTP/$direct/g" $CATALINA_BASE/conf/server.xml
			
			# this forces connection to be secure
			\cp -f $TOMCAT_VERSION/custom/conf/_csapSecure_web.xml $CATALINA_BASE/conf/web.xml
		else
			echo == AJP connection is not secure
			sed -i "s/_SC_SECURE_AJP/ /g" $CATALINA_BASE/conf/server.xml
			sed -i "s/_SC_SECURE_HTTP/ /g" $CATALINA_BASE/conf/server.xml
		fi
		
		if [  $isNio == "yes" ] ; then
			echo == AJP connection is using NIO
			sed -i "s/org.apache.coyote.ajp.AjpProtoco/org.apache.coyote.ajp.AjpNioProtoco/g" $CATALINA_BASE/conf/server.xml
		else
			echo == AJP connection is using BIO. Note that high volumes will benefit from NIO configuration
		fi ;
		
		if [  $skipTomcatJarScan == "yes" ] ; then
			echo =
			echo == skipTomcatJarScan is in metadata, overwriting catalina.properties with $TOMCAT_VERSION/custom/conf/_csapJarSkip_catalina.properties
			echo =
			\cp -f $TOMCAT_VERSION/custom/conf/_csapJarSkip_catalina.properties  $CATALINA_BASE/conf/catalina.properties
		fi ;
		
		namePart=""
		if [ "$cookieName" != "" ] ; then 
			namePart="sessionCookieName=\"$cookieName\""
		fi;

		domainPart=""
		if [ "$cookieDomain" != "" ] ; then 
			domainPart="sessionCookieDomain=\"$cookieDomain\""
		fi;
		
		pathPart=""
		if [ "$cookiePath" != "" ] ; then 
			pathPart="sessionCookiePath=\"$cookiePath\""
		fi;
		
		if [ "$namePart" != "" ] || [ "$pathPart" != ""  ] || [ "$domainPart" != ""  ]  ; then
			echo;echo == Updating $CATALINA_BASE/conf/context.xml with cookie settings $pathPart , $domainPart, $namePart;echo
			sed -i "s/<Context/<Context $domainPart $pathPart $namePart /g" $CATALINA_BASE/conf/context.xml
		else
			echo == Default cookie settings being used in $CATALINA_BASE/conf/context.xml
		fi ;
		
		
		# Enable UI to override class loader order
		if [[ $JAVA_OPTS = *DtomcatReloadable* ]] ; then 
			echo == Warning: tomcat is autoreloading context and may result in leaks
			sed -i "s/<Context/<Context reloadable=\"true\" /g" $CATALINA_BASE/conf/context.xml
		else
			echo == Correct: tomcat is NOT autoreloading context
			sed -i "s/<Context/<Context reloadable=\"false\" /g" $CATALINA_BASE/conf/context.xml
		fi;
			
		
	else
		if [ $isHotDeploy != "1" ] ; then
			echo ==
			echo == WARNING : use of server.xml not recommended, replace with tomcatVersion.txt copy from CsAgent
			echo ==
			sleep 3
		fi ;
	fi ;
}

function getWarAndProperties() {
	# Deploy last deployed instance
	#if [ $isSkip == "0"  ] ; then
			
	printTom Using $STAGING/warDist/$serviceName.war
	
	\cp -p $STAGING/warDist/$serviceName.war $CATALINA_BASE
	
	\cp -p $STAGING/warDist/$serviceName.war.txt $CATALINA_BASE/release.txt
	\cp -p $STAGING/warDist/$serviceName.war.txt $CATALINA_BASE
	
	if [ -e "$serviceConfig/$serviceName/resources" ]; then
		
		printTom Found Overide properties: $serviceConfig/$serviceName/resources, copying to  $CATALINA_BASE
		\cp -fr $serviceConfig/$serviceName/resources $CATALINA_BASE
	fi ;
	
	# csap passes as a string, so eval is needed
	csapExternal=`eval echo $csapExternalPropertyFolder`
	if [[ "$csapExternal" != "" && -e "$csapExternal" ]]; then
		
		printTom Found csapExternalPropertyFolder variable, $csapExternal == copying to $CATALINA_BASE/resources

		if [ ! -e $CATALINA_BASE/resources ] ; then 
			mkdir -p $CATALINA_BASE/resources
		fi;
		#scm dirs will be copied - but they can be ignored by runtime
		\cp -rf $csapExternal/* $CATALINA_BASE/resources
			
	else
		
		printTom Did not find csapExternalPropertyFolder environment: $csapExternal
	fi

	

	
# override if you want
	export extractDir=$warDir/$serviceName	
	
}

function doFullServiceSetup() {
	getWarAndProperties
	
	printTom doFullServiceSetup for CATALINA_BASE: $CATALINA_BASE 
	
	if [ ! -e "$CATALINA_BASE/conf" ] ; then
		mkdir $CATALINA_BASE/conf
	fi;

	
	export extractDir=$warDir/$serviceContext


	#extractDir="$warDir/$serviceContext""##"`date +%s`
	# backwards compatible

	extractDir="$warDir/$serviceContext"
	echo checking for $STAGING/warDist/$serviceName.war.txt
	if [ -e $STAGING/warDist/$serviceName.war.txt ] && [[  $JAVA_OPTS != *noTomcatVersion*  ]] ; then
		extractDir="$warDir/$serviceContext""##"`grep -o '<version>.*<' $STAGING/warDist/$serviceName.war.txt  | cut -d ">" -f 2 | cut -d "<" -f 1`
	fi;
	
	echo ==
	echo ==  extractDir set to $extractDir

	if [ $isHotDeploy != "1" ] ; then
		echo removing previous $warDir/$serviceContext*
		rm -rf $warDir/$serviceContext*
	fi ; 
    
	mkdir $extractDir
	
	echo  extracting: $CATALINA_BASE/$serviceName.war to $extractDir
	/usr/bin/unzip -qq -o $CATALINA_BASE/$serviceName.war -d $extractDir
	
	
	if [ ! -e "$CATALINA_BASE/temp" ] ; then 
		echo checking 
		echo creating temp folder for work dir
		mkdir $CATALINA_BASE/temp ;
	fi ;
	
	
	# WARNING: warDist is getting hardcoded here.
	if [  -e "$CATALINA_BASE/resources" ]; then
		echo 
		echo overwriting war resources with those from propertyOveride 
		echo == $CATALINA_BASE/resources to $extractDir/WEB-INF/classes
		echo
		\cp -fr $CATALINA_BASE/resources/* $extractDir/WEB-INF/classes
	fi
	
	if [  -e $extractDir/WEB-INF/classes/common ]; then
		echo 
		echo copying properties - $extractDir/WEB-INF/classes/common
		echo
		\cp -fr $extractDir/WEB-INF/classes/common/* $extractDir/WEB-INF/classes
	fi
	
	#
	# Hook for sublifecycles
	if [[ $serviceEnv == $lifecycle* ]] ; then
		if [  -e $extractDir/WEB-INF/classes/$lifecycle ]; then
			echo 
			echo copying properties - $extractDir/WEB-INF/classes/$lifecycle
			echo
			\cp -fr $extractDir/WEB-INF/classes/$lifecycle/* $extractDir/WEB-INF/classes
		fi
		
		# hook for multi vm partition property files
		if [  -e $extractDir/WEB-INF/classes/$lifecycle$platformVersion ]; then
			echo 
			echo copying override properties - $extractDir/WEB-INF/classes/$lifecycle$platformVersion 
			echo
			\cp -fr $extractDir/WEB-INF/classes/$lifecycle$platformVersion/* $extractDir/WEB-INF/classes
		fi
	fi ;
	

	
	if [  -e $extractDir/WEB-INF/classes/$serviceEnv ]; then
		echo 
		echo copying properties - $extractDir/WEB-INF/classes/$serviceEnv
		echo
		\cp -fr $extractDir/WEB-INF/classes/$serviceEnv/* $extractDir/WEB-INF/classes
	fi
	
	
	if [  -e $extractDir/WEB-INF/classes/$serviceEnv ]; then
		echo 
		echo copying properties - $extractDir/WEB-INF/classes/$serviceEnv
		echo
		\cp -fr $extractDir/WEB-INF/classes/$serviceEnv/* $extractDir/WEB-INF/classes
	fi
	
	if [ -e "$extractDir/WEB-INF/classes/tomcatServer.xml" ] ; then
		SOURCE_SERVERXML=$extractDir/WEB-INF/classes/tomcatServer.xml ;
		echo ==
		echo == NOTE: Detected override $SOURCE_SERVERXML 
		echo == in properties. Failure to use latest template can result in
		echo == unexpected behaviour. If problems occur, ensure you are packaging the latest template 
		echo == from $STAGING/bin
		echo ==
	fi; 
	
	if [ -e "$extractDir/WEB-INF/classes/logRotate.config" ] ; then
		echo ==
		echo == NOTE: Detected log rotation policy file 
		echo == $extractDir/WEB-INF/classes/logRotate.config
		echo == incorrect syntax in  config files will prevent rotations from occuring. 
		echo == Logs are examined hourly: ensure rotations are occuring or your service will be shutdown
		echo ==
		cp -vf $extractDir/WEB-INF/classes/logRotate.config $CATALINA_BASE/logs

		sed -i "s=_LOG_DIR_=$CATALINA_BASE/logs=g" $CATALINA_BASE/logs/logRotate.config
		echo ; echo
	fi; 
	
	if [ -e "$extractDir/WEB-INF/simpleUsers.xml" ] && [ $isHotDeploy != "1"  ] ; then
		echo ; echo
		echo == NOTE: Detected $extractDir/WEB-INF/simpleUsers.xml
		echo == 
		cp -vf $extractDir/WEB-INF/simpleUsers.xml $CATALINA_BASE/conf/tomcat-users.xml
		echo ; echo
	fi; 
	
	configureServerXml
	
	
	if [  -e $extractDir/WEB-INF/classes/log4j.properties ] ; then
		echo == Warning: detected a log4j.properties, note this affects the entire runtime
		echo == if sodc is found inside it will be replaced with csspConsole 
		sed -i "s=sodcServiceLogs=csspConsole=g" $extractDir/WEB-INF/classes/log4j.properties
		sed -i "s=sodcServiceLogsErrors=csspConsoleErrors=g" $extractDir/WEB-INF/classes/log4j.properties
	fi ; 
	
	ssoFile="$serviceConfig/CsAgent/resources/$lifecycle/csapSecurity.properties"
	if [ -e "$ssoFile" ] ; then
		
		printTom Copying in SSO setup file: $ssoFile
		\cp -fr "$ssoFile" $extractDir/WEB-INF/classes
	else
		printTom Warning: $ssoFile not found - best practice is to include one in capability/propertyOverride folder 
	fi	
}

function tomcatStart() {
	
	printTom Tomcat Runtime Detected
	tomcatEnvSetup
	
	# if [ ! -e "$CATALINA_BASE/webapps" ] || [ "$serviceName" == "CsAgent" ]; then
	if  [ "$isSkip" != "1" ]  && [ $isHotDeploy != "1"  ]  ; then
		echo 
		echo Did not find $CATALINA_BASE/webapps, running configureTomcatWorkingDir
		echo
		configureTomcatWorkingDir 
	else
		echo == Skip service is enabled, tomcat files will not be updated
		echo
	fi
	
	##
	##   This is only run once during initial deployment. Subsequent deployments will re-use configuration UNLESS
	##   Kill/Clean is invoked.
	##
	
	if  [ "$isSkip" != "1" ]  ; then
		doFullServiceSetup ;
	fi ;   
	
		
#echo "admin testpass" >| $jmxPassFile
	touch $jmxPassFile
	chmod 700 $jmxPassFile
	echo "admin readwrite" >| $jmxAccessFile
	
	if [ -e  $STAGING/warDist/$serviceName.secondary ] ; then
		
		printTom Found Secondary deployment files: $STAGING/warDist/$serviceName.secondary, deploying
		
			
		for file in $STAGING/warDist/$serviceName.secondary/*; do
			plainFile=`basename $file`
			#tomcatName=${plainFile/-/##}
			#echo "$file" is being copied to $CATALINA_BASE/webapps/$tomcatName
			# \cp -p $file $CATALINA_BASE/webapps/$tomcatName
			
				# set uses the IFS var to split
			oldIFS=$IFS
			IFS="-"
			mvnNameArray=( $plainFile )
			IFS="$oldIFS"
			mavenArtName=${mvnNameArray[0]}
			versionAndSuffix=${mvnNameArray[1]}
			version=${versionAndSuffix/.war//}
			extractDir="$warDir/$mavenArtName""##"$version
			echo  extracting: $file to $extractDir
			 /usr/bin/unzip -qq -o $file -d $extractDir
			 
			 	if [  -e $extractDir/WEB-INF/classes/common ]; then
					echo 
					echo copying properties - $extractDir/WEB-INF/classes/common
					echo
					\cp -vfr $extractDir/WEB-INF/classes/common/* $extractDir/WEB-INF/classes
				fi
			 	if [  -e $extractDir/WEB-INF/classes/$lifecycle ]; then
					echo 
					echo copying properties - $extractDir/WEB-INF/classes/$lifecycle
					echo
					\cp -vfr $extractDir/WEB-INF/classes/$lifecycle/* $extractDir/WEB-INF/classes
				fi
		done
	# \cp -p $STAGING/warDist/$serviceName.secondary/*.war $CATALINA_BASE/webapps
	fi ;
	
	echo updated tomcat
	if [ "$csapDockerTarget" == "true" ]  ; then
		echo == Service configured for docker, start will be triggered via docker container apis ;
		exit ;
	fi;
		
	if [ $isHotDeploy != "1" ] ; then
	
		echo;echo;
		echo ====================================================================
		echo Invoking $CATALINA_HOME/bin/startup.sh
		echo using CATALINA_BASE: $CATALINA_BASE
		echo ====================================================================
		echo;echo;
	
		
		cd $CATALINA_BASE
		$CATALINA_HOME/bin/startup.sh 2>&1
		servicePattern='.*java.*/processing/'$serviceName'.*catalina.*'
		updateServiceOsPriority $servicePattern
		
	else
		echo ===
		echo === Hot Deploy in progress. View logs to confirm startup
	fi ;
		
}

function tomcatStop() {
	
	printTom Tomcat Runtime Detected
	tomcatEnvSetup
	$CATALINA_HOME/bin/shutdown.sh
	
}













