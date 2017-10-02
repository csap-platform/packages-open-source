#!/bin/bash

scriptDir=`dirname $0`
scriptName=`basename $0`

distDir="$1"	
toolsServer="$2"

debug() {
	echo;echo; echo =
	echo = $scriptName ; 
	echo = $*
	echo = 
	
}

debug distDir: $distDir toolsServer: $toolsServer
	
source $distDir/oraenv.sh

cd $ORACLE_HOME

debug Going to $ORACLE_HOME, launching root.sh
cd $ORACLE_HOME
./root.sh

debug Launching $ORAUSER_HOME/oracleInstall2.sh  $distDir $toolsServer
 su - oracle -c "$ORAUSER_HOME/oracleInstall2.sh  $distDir $toolsServer"
 
debug Completed
