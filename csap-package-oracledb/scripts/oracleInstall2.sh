#!/bin/bash


scriptDir=`dirname $0`
scriptName=`basename $0`
debug() {
	echo;echo; echo =
	echo = $scriptName ; 
	echo = $*
	echo = 
	
}

debug Starting
source $HOME/oraenv.sh

debug Updating $ORACLE_SID in $HOME/*.rsp using sed
sed -i "s/SSDBFFF/$ORACLE_SID/g" $HOME/*.rsp

cp $HOME/*.rsp $ORAUSER_HOME/11.2.0.4/database/response/

cd $ORACLE_HOME/bin
#set JAVA_JIT_ENABLED=false
debug launching dbca installer
#echo -e "c0cktail\nc0cktail" |  dbca -silent -force -responseFile $ORAUSER_HOME/11.2.0.4/database/response/dbca.rsp
echo -e "c0cktail\nc0cktail" |  dbca -silent -force -responseFile $ORAUSER_HOME/11.2.0.4/database/response/dbca.rsp -initParams JAVA_JIT_ENABLED=false


debug launching netca installer
netca /silent /responseFile $ORAUSER_HOME/11.2.0.4/database/response/netca.rsp
