#!/bin/sh
# getopts is great parser, ref: http://wiki.bash-hackers.org/howto/getopts_tutorial
# alternative impl to getopt: isNoLogout=`expr match "$* " '.*-noLogout' != 0`

function printIt() { echo -e "\n\n =========\n == $* \n ========="; }

function printLine() { echo -e "   $*" ;}

function printfLine() { printf "%15s: %-20s %15s: %-20s %15s: %-20s \n" "$@" ; }

args=$*

# put anything here to see output
debug="";

# echo == parsing arguments on `hostname` : $*
if [ "$toolsServer" == "" ] ; then
	toolsServer="csaptools.cisco.com"
fi;

# warning - this is overwritten later using svcInstance. Verification needed prior to removing svcInstance
csapProcessId="$csapName"_"$csapHttpPort"
#  
printIt "$0 invoked on $HOSTNAME, user: $USER, toolsServer: $toolsServer  at `date "+%x %H:%M:%S"`"
 
printIt 'Environment variables set by CSAP . For shell scripts: use "$variable",  for java: System.getenv().get("variable")'

printfLine csapName     "$csapName"        csapHttpPort    "$csapHttpPort"      csapJmxPort "$csapJmxPort"
printfLine csapServer   "$csapServer"      csapTomcat      "$csapTomcat"        csapHttpPerHost "$csapHttpPerHost"
printfLine 'csapPackage' "$csapPackage"    'csapLife' "$csapLife"      'csapLbUrl' "$csapLbUrl"
printfLine csapVersion  "$csapVersion"     csapServiceLife "$csapServiceLife" 

printfLine 'csapProcessId' "$csapProcessId" 'csapPids' "$csapPids" 'csapParams' "$csapParams"
printfLine 'csapWorkingDir' "$csapWorkingDir" 'csapLogDir' $csapLogDir
printfLine 'customAttributes'  "$customAttributes" 'set' 'only for this service'

printfLine 'csapAjp'        MASKED 'Refer to'  'https://github.com/csap-platform/csap-core/wiki#updateRefCSAP+Loadbalancing'
printfLine 'csapPeers' $csapPeers
# printLine peers with explicit assignment are available as:  '$csapName_peer_1'

printfLine 'Csap Encryption' ""  'CSAP_ALGORITHM' $CSAP_ALGORITHM CSAP_ID 'Encryption token masked'
printfLine redisSentinels $redisSentinels 
printfLine notifications '-'  csapAddresses $csapAddresses csapFrequency "$csapFrequency $csapTimeUnit" csapMaxBacklog $csapMaxBacklog
printfLine STAGING $STAGING PROCESSING $PROCESSING CLUSTERDEF $CLUSTERDEF

printfLine hostUrlPattern $hostUrlPattern mailServer $mailServer csapDockerRepository $csapDockerRepository

showIfDebug() {
	
	if [ "$debug"  != "" ] ; then
		echo `date "+%Nms"`;echo -e "$*" ; echo
	fi;
}



if [ "$USER" == "" ] ; then 
	printIt "Warning: USER environment variable not set. This will cause scripts to fail" ;
	sleep 3
fi ;

showIfDebug == arguments: $args
showIfDebug  "csap-env.sh\t:" "=================== Parsing Command Line Start ================"

mavenWarPath="" ;
isSecure="no";
isNio="no";
isJmxAuth="false";
isKeepLogs="no";
skipHttpConnector="no";
skipTomcatJarScan="no" ;
servletThreads="50";
servletConnections="50";
servletAccept="0";
servletTimeout="10000";
jmxPassword="dummy" ;

compress="off" ;
mimeType="text/html,text/xml,text/plain,text/css,text/javascript,application/javascript" ;
cookieDomain="" ;
cookiePath="" ;
cookieName="" ;
secondary="" ;
serviceContext="notSpecified"
platformVersion="0" ;

# default folders
csapPackageFolder="$STAGING/csap-packages" ;

csapSavedFolder="$STAGING/saved" ;
if [ ! -e "$csapSavedFolder" ] ; then
	printIt "Creating backup: $previousBin"
	\mkdir -p $csapSavedFolder
fi ;

osProcessPriority="0" ;

ajpSecret="dummySecretYouShouldUpdateClusterDef" ;
##


while [ $# -gt 0 ]
do
  case $1
  in
    -csapDeployOp )
      showIfDebug  "csap-env.sh\t:" "-csapDeployOp"   ;
      shift 1
    ;;

    -threads )
      showIfDebug  "csap-env.sh\t:" "-threads was specified,  Parameter: $2"   ;
      servletThreads="$2" ;
      shift 2
    ;;
    
    -ver )
      showIfDebug  "csap-env.sh\t:" "-ver was specified,  Parameter: $2"   ;
      platformVersion="$2" ;
      shift 2
    ;;
    
    -secondary )
      showIfDebug  "csap-env.sh\t:" "-secondary was specified,  Parameter: $2"   ;
      secondary="$2" ;
      shift 2
    ;;
    
    -osProcessPriority )
      showIfDebug  "csap-env.sh\t:" "-osProcessPriority was specified,  Parameter: $2"   ;
      osProcessPriority="$2" ;
      shift 2
    ;;
    
    -accept )
      showIfDebug  "csap-env.sh\t:" "-accept was specified,  Parameter: $2"   ;
      servletAccept="$2" ;
      shift 2
    ;;
    
    -timeOut )
      showIfDebug  "csap-env.sh\t:" "-timeOut was specified,  Parameter: $2"   ;
      servletTimeout="$2" ;
      shift 2
    ;;
    
    -maxConn )
      showIfDebug  "csap-env.sh\t:" "-maxConn was specified,  Parameter: $2"   ;
      servletConnections="$2" ;
      shift 2
    ;;
    
    -ajpSecret )
      showIfDebug  "csap-env.sh\t:" "-ajpSecret was specified"   ;
      ajpSecret="$2" ;
      shift 2
    ;;
    
    -compress )
      showIfDebug  "csap-env.sh\t:" "-compress was specified"   ;
      compress="$2" ;
      shift 2
    ;;
    
    -mimeType )
      showIfDebug  "csap-env.sh\t:" "-mimeType was specified"   ;
      mimeType="$2" ;
      shift 2
    ;;
    
    -cookieName )
      showIfDebug  "csap-env.sh\t:" "-cookieName was specified"   ;
      cookieName="$2" ;
      shift 2
    ;;
    
    -cookieDomain )
      showIfDebug  "csap-env.sh\t:" "-cookieDomain was specified"   ;
      cookieDomain="$2" ;
      shift 2
    ;;
    -cookiePath )
      showIfDebug  "csap-env.sh\t:" "-cookiePath was specified"   ;
      cookiePath="$2" ;
      shift 2
    ;;
    
    -jmxAuth )
      showIfDebug  "csap-env.sh\t:" "-jmxAuth was specified,  Parameter: $2"   ;
      isJmxAuth="$2" ;
      shift 2
    ;;
    
    -jmxPassword )
      showIfDebug  "csap-env.sh\t:" "-jmxPassword was specified,  Parameter: $2"   ;
      jmxPassword="$2" ;
      shift 2
    ;;
    
    
    -vdcImage )
      showIfDebug  "csap-env.sh\t:" "-vdcImage was specified,  Parameter: $2"   ;
      vdcImage="$2" ;
      shift 2
    ;;
    
    -n | -serviceName )
      showIfDebug  "csap-env.sh\t:" "-n name was specified,  Parameter: $2"   ;
      serviceName="$2" ;
      shift 2
    ;;

    -e | -serviceEnv )
      showIfDebug  "csap-env.sh\t:" "-e environment,  Parameter: $2"   ;
      serviceEnv="$2" ;
      shift 2
      ;;
    -f | -clusterScmPath )
      showIfDebug  "csap-env.sh\t:" "-clusterScmPath,  Parameter: $2"   ;
      CLUSTERDEF="$2" ;
      shift 2
      ;;
    -l | -lifecycle )
      showIfDebug  "csap-env.sh\t:" "-l lifecycle,  Parameter: $2"   ;
      lifecycle="$2" ;
      shift 2
      ;;

    -r | -repo )
      showIfDebug  "csap-env.sh\t:" "-r repo was triggered, Parameter: $2"  
      svcRepo="$2" ;
      shift 2
      ;;
    -c | -context )
      showIfDebug  "csap-env.sh\t:" "-c context was triggered, Parameter: $2"  
      serviceContext="$2";
      shift 2
      ;;
    -z | -serverType )
      showIfDebug  "csap-env.sh\t:" "-z serverRuntime was triggered, Parameter: $2"  
      serverRuntime="$2";
      shift 2
      ;;


    -b | -scmBranch )
		showIfDebug  "csap-env.sh\t:" "-b branch was triggered, Parameter: $2"  
		SCM_BRANCH="$2"
    	shift 2
      ;;
    
    
    -scmLocation )
		showIfDebug  "csap-env.sh\t:" "scmLocation was passed but no longer needed Parameter: $2"  
    	shift 2
      ;;
    
    -m | -mavenCommand )
      showIfDebug  "csap-env.sh\t:" "-m was triggered, Parameter: $2, doing a global replace on _"  
      mavenBuildCommand=$(echo $2|sed 's/__/ /g') ;
      shift 2
     
      ;;
    -h | -hosts )
      echo "-h was triggered, Parameter: $2, doing a global replace on _"  
      hosts=$(echo $2|sed 's/__/ /g') ;
      
      echo *** error this is depricated
      
      shift 2
     
      ;;

      
    -u | -scmUser )
      showIfDebug  "csap-env.sh\t:" "-u was triggered, Parameter: $2"  
      SCM_USER="$2" ;
      shift 2
      ;;
    -x | -cleanType )
      showIfDebug  "csap-env.sh\t:" "-x clean, Parameter: $2"  
      svcClean="$2" ;
      shift 2
      ;;
      
    -skipHttpConnector )
      showIfDebug  "csap-env.sh\t:" "-skipHttpConnector was triggered "  
      skipHttpConnector="yes";
      shift 1
      ;;
      
    -keepLogs )
      showIfDebug  "csap-env.sh\t:" "-keepLogs was triggered "  
      isKeepLogs="yes";
      shift 1
      ;;
      
    -secure )
      showIfDebug  "csap-env.sh\t:" "-secure was triggered "  
      isSecure="yes";
      shift 1
      ;;
    
    -nio )
      showIfDebug  "csap-env.sh\t:" "-nio was triggered "  
     isNio="yes";
      shift 1
      ;;
      
    -skipTomcatJarScan )
      showIfDebug  "csap-env.sh\t:" "-skipTomcatJarScan was triggered "  
      skipTomcatJarScan="yes";
      shift 1
      ;;
      
    -t | -hotDeploy )
      showIfDebug  "csap-env.sh\t:" "-t hot deployment was triggered"  
      hotDeploy="yes";
      shift 1
      ;;
    -s | -spawn )
      showIfDebug  "csap-env.sh\t:" "-s spawn was triggered"  
      svcSpawn="yes";
      shift 1
      ;;
    -v | -skipDeployment )
      showIfDebug  "csap-env.sh\t:" "-v skipDeployment was triggered"  
      svcSkipDeployment="yes";
      shift 1
      ;;
    -d | -default )
      showIfDebug  "csap-env.sh\t:" "-d  was triggered, setting defaults. Note that CsAgent will issue a self restart after loading cluster definition"  
	  csapHttpPort=8011
	  csapParams="-DcsapJava8 -Xms256M -Xmx256M -Dorg.csap.needStatefulRestart=yes" ;
      serviceName="CsAgent"; serviceEnv="dev"; lifecycle="dev";  svcRepo="doNotCare"; serviceContext="CsAgent" ; serverRuntime="SpringBoot";
      csapPackageFolder="$STAGING/warDist";svcSpawn="yes"; ajpSecret="CsAgentAjpSecret" ;csapWorkingDir="$PROCESSING/CsAgent_8011"
		csapLogDir="$csapWorkingDir/logs"
 		
      shift 1
      ;;


    *)
      echo "Invalid arg: " $1
      echo "Refer to $STAGING/bin/csap-env.sh for permitted arguments"
      shift 1
    ;;
  esac
done

if [ "$serviceName" == "CsAgent" ] ; then
	echo == Special hook to switch CsAgent to SpringBoot
	serverRuntime="SpringBoot"
	csapName="CsAgent"
	csapHttpPort="8011"
	if [ "$csapParams" == "" ] ; then
		echo WARNING - using hardcoded Agent params
		csapParams="-DcsapJava8  -Dsun.rmi.transport.tcp.responseTimeout=3000 -XX:MaxMetaspaceSize=96M -Xms256M -Xmx256M"
	fi;
fi;

serviceConfig=$STAGING/conf/propertyOverride
svcInstance="$serviceName"_"$csapHttpPort"
runDir="$PROCESSING/$svcInstance"

jmxPassFile="$runDir/jmxremote.password"
jmxAccessFile="$runDir/jmxremote.access"

showIfDebug  "csap-env.sh\t:" == serviceName: $serviceName, osProcessPriority: $osProcessPriority, 
showIfDebug  "csap-env.sh\t:" == serviceEnv: $serviceEnv, svcInstance: $svcInstance , platformVersion: $platformVersion
showIfDebug  "csap-env.sh\t:" == servicePort $servicePort, svcRepo: $svcRepo, serviceContext: $serviceContext
showIfDebug  "csap-env.sh\t:" == serverRuntime $serverRuntime, JAVA_OPTS $csapParams
showIfDebug  "csap-env.sh\t:" == svcClean $svcClean, svcSpawn $svcSpawn , svcSkipDeployment $svcSkipDeployment
showIfDebug  "csap-env.sh\t:" == csapPackageFolder $csapPackageFolder, serviceConfig $serviceConfig, CLUSTERDEF $CLUSTERDEF
showIfDebug  "csap-env.sh\t:" == hotDeploy: $hotDeploy,  servletThreads: $servletThreads, vdcImage=$vdcImage
showIfDebug  "csap-env.sh\t:" == skipHttpConnector: $skipHttpConnector  , skipTomcatJarScan: $skipTomcatJarScan
showIfDebug  "csap-env.sh\t:" == cookieName: $cookieName  , cookiePath: $cookiePath, cookieDomain: $cookieDomain
showIfDebug  "csap-env.sh\t:" == secondary: $secondary 
showIfDebug  "csap-env.sh\t:" == 

if [ "$serverRuntime" == "os" ] ; then
	echo
	echo
	echo =========== CSSP Abort ===========================
	echo Service $serviceName is controlled by OS commands:
	echo /sbin/service $serviceName start,stop or restart
	exit ;
fi ;


runDir="$PROCESSING/$svcInstance" ;

if [[  $csapParams == *csapJava8*  ]]  ; then
	
	if [ "$JAVA8_HOME" != "" ] ; then
		export JAVA_HOME=$JAVA8_HOME
		export PATH=$JAVA8_HOME/bin:$PATH
	else
		printIt "warning: JAVA8_HOME variable is not set. reverting to vm default"
	fi
	
elif [[  $csapParams == *csapJava7*  ]]  ; then
	if [ "$JAVA7_HOME" != "" ] ; then
		export JAVA_HOME=$JAVA7_HOME
		export PATH=$JAVA7_HOME/bin:$PATH
	else
		printIt "warning: JAVA7_HOME variable is not set. reverting to vm default"
	fi

elif [[  $csapParams == *csapJava9*  ]]  ; then
	if [ "$JAVA9_HOME" != "" ] ; then
		export JAVA_HOME=$JAVA9_HOME
		export PATH=$JAVA9_HOME/bin:$PATH
	else
		printIt "warning: JAVA9_HOME variable is not set. reverting to vm default"
	fi
fi ;

printIt JAVA version: $JAVA_HOME 


showIfDebug  "csap-env.sh\t:" "=================== Parsing Command Line End ================"
