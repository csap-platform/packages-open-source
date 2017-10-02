#!/bin/bash


scriptDir=`dirname $0`
scriptName=`basename $0`

distDir="$1"
toolsServer="$2"


source $distDir/oraenv.sh


debug() {
	echo;echo; echo =
	echo = $scriptName ; 
	echo = $*
	echo = 
	
}

debug distDir: $distDir toolsServer: $toolsServer

checkuser() {
	/bin/egrep -i "^${1}" /etc/passwd
	if [ $? -eq 0 ]
	then 
		return 0
	else 
		return 1 
	fi
} 

checkgroup() {
	/bin/egrep -i "^${1}" /etc/group
	if [ $? -eq 0 ]
	then 
		return 0
	else 
		return 1 
	fi
} 


creategroup() {
	if checkgroup ${1}
	then
		echo ==  group ${1} exists
	else
		echo == Creating group ${1}
		/usr/sbin/groupadd ${1}
	fi
}

createuser() {
	if checkuser ${1}
	then
		echo ==  user ${1} exists
	else
		echo == Creating user ${1}
		/usr/sbin/adduser $@ 
        	echo -e "Pass.123\nPass.123" | passwd ${1}
	fi
}



oracleinstall() {

  #  creategroup oinstall
  #  creategroup dba
  #  creategroup oper
  #  creategroup dsm
#
#    createuser  oracle -d $ORAUSER_HOME -s /bin/bash -g oinstall -G dba,oper,dsm

    if [ -d $ORACLE_BASE ] 
    then
	echo == $ORACLE_BASE exists
    else 
	echo == expecting $ORACLE_BASE to exist
    fi
   
	debug creating directiories        
 	mkdir -p $ORACLE_BASE/product/11.2.0.4/db_1
	mkdir -p $ORAUSER_HOME/11.2.0.4
	mkdir -p $ORACLE_BASE/oraInventory
  

	debug kernel params all set in core install
    # echo == adding oracle repos to yum and then installing dependencies
    # cp $HOME/dist/public-yum-el5.repo /etc/yum.repos.d
	# yum -y install oracle-validated 

	
	
	debug Getting Oracle installs
	rm -rf *.zip base
	
	wget http://$toolsServer/oracle/p13390677_112040_Linux-x86-64_1of7.zip --directory-prefix=$ORAUSER_HOME/11.2.0.4
	wget http://$toolsServer/oracle/p13390677_112040_Linux-x86-64_2of7.zip --directory-prefix=$ORAUSER_HOME/11.2.0.4

	chown -R oracle:oinstall $ORACLE_BASE
	chmod -R 755 $ORACLE_BASE


	debug copying install scripts to $ORAUSER_HOME

	
	cp $distDir/oracleInstall.sh $ORAUSER_HOME
	cp $distDir/oracleInstall2.sh $ORAUSER_HOME
	cp $distDir/oraclePatchInstall.sh $ORAUSER_HOME
	cp $distDir/oraenv.sh $ORAUSER_HOME
	cp $distDir/dbca.rsp $ORAUSER_HOME
	cp $distDir/ocm.rsp $ORAUSER_HOME
	chown -R oracle:oinstall $ORAUSER_HOME
	chmod -R 755 $ORAUSER_HOME

	debug finalizing steps as root
	rm -f /tmp/oraInst.loc
	rm -f /etc/oraInst.loc
	
	echo inventory_loc=$ORACLE_BASE/oraInventory >> /tmp/oraInst.loc
	echo inst_group=dba >> /tmp/oraInst.loc
    cp /tmp/oraInst.loc /etc


	
}
 
	
oracleinstall

debug Completed Root Install
