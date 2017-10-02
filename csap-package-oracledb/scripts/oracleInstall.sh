#!/bin/bash

# this is run as the oracle user


scriptDir=`dirname $0`
scriptName=`basename $0`
debug() {
	echo;echo; echo =
	echo = $scriptName ; 
	echo = $*
	echo = 
	
}

debug Starting

cd $HOME
source $HOME/oraenv.sh

cd $ORAUSER_HOME/11.2.0.4
echo == cd to $ORAUSER_HOME 

debug  unzipping p13390677_112040_Linux-x86-64_1of7.zip
unzip p13390677_112040_Linux-x86-64_1of7.zip


debug p13390677_112040_Linux-x86-64_2of7.zip
unzip p13390677_112040_Linux-x86-64_2of7.zip

unset DISPLAY
cd $ORAUSER_HOME/11.2.0.4/database

debug cd to $ORAUSER_HOME/11.2.0.4/database, launching runInstaller
./runInstaller -silent -force FROM_LOCATION=$ORAUSER_HOME/11.2.0.4/database/stage/products.xml \
	oracle.install.option=INSTALL_DB_SWONLY UNIX_GROUP_NAME=oinstall INVENTORY_LOCATION=$ORACLE_BASE/oraInventory \
	ORACLE_HOME=$ORACLE_BASE/product/11.2.0.4/db_1 ORACLE_HOME_NAME=OraDb11g_Factory_Home \
	ORACLE_BASE=$ORACLE_BASE oracle.install.db.InstallEdition=EE oracle.install.db.isCustomInstall=false \
	oracle.install.db.DBA_GROUP=dba oracle.install.db.OPER_GROUP=dba DECLINE_SECURITY_UPDATES=true

debug exiting, but installer is running as a background process
