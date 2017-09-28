#!/bin/bash

printIt() {
	echo;echo;
	echo = 
	echo = $*
	echo = 
}

csapWorkingDir=$1
version="$2" 
packageDir="$3"


		
if [ "$USER" == "root" ] ; then
	printIt root install: $csapWorkingDir version: $version
	mkdir -p /opt/java
	cd /opt/java ;
	installPath="/opt/java/jdk1.8.0_$version"
	
	# delete locations
	sed -i '/JAVA8_HOME/d' /etc/bashrc
	echo  export JAVA8_HOME=$installPath >> /etc/bashrc
	
	if [[ $csapWorkingDir != *jdkAlt* ]] ; then 
		printIt Installing default java. Updating JAVA_HOME
		sed -i '/JAVA_HOME/d' /etc/bashrc
		echo  export JAVA_HOME=$installPath >> /etc/bashrc
		echo  export PATH=\$JAVA_HOME/bin:\$PATH >> /etc/bashrc
		tail -10 /etc/bashrc
	else
		printIt Installing as non default JDK
	fi ;
	
else
	printIt non root install: $csapWorkingDir version: $version
	source $HOME/.cafEnv
	installPath="$STAGING/../java/jdk1.8.0_$version" 
	if [ "$INSTALL_DIR" != "" ] ; then 
		echo == using custom location $INSTALL_DIR
		if [ ! -e $INSTALL_DIR ] ; then 
			echo == folder does not exist, creating: $INSTALL_DIR
			mkdir -p $INSTALL_DIR ;
		fi
		
		cd $INSTALL_DIR ;
		installPath="$INSTALL_DIR/jdk1.8.0_$version" 
	
	else 
		echo == using default location $STAGING/../java
		cd $STAGING/../java ;
	fi
	
	echo == adding link to: `pwd` from: $csapWorkingDir/JAVA_HOME
	ln -s `pwd` $csapWorkingDir/JAVA_HOME
	
	JAVA8_HOME=$installPath
	
	sed -i '/JAVA8_HOME/d' $HOME/.cafEnv
	echo  export JAVA8_HOME=$installPath >> $HOME/.cafEnv
	
	if [[ $csapWorkingDir != *jdkAlt* ]] ; then 
		printIt Installing default java. Updating JAVA_HOME
		sed -i '/JAVA_HOME/d' $HOME/.cafEnv
		echo  export JAVA_HOME=$installPath >> $HOME/.cafEnv
		echo == contents of $HOME/.cafEnv:
		tail -10 $HOME/.cafEnv
	else
		printIt Installing as non default JDK
	fi ;
	
	# PATH is set in STAGING/bin/admin.bashrc. We just need to update java_home
	#echo  export PATH=\$JAVA_HOME/bin:\$PATH >> $HOME/.cafEnv
	source $HOME/.bashrc
fi ;

if [ -d  $installPath ] ; then
	printIt java already installed , exiting
	exit;
	#testing packaging uncomment only
	#\rm -rf $installPath
fi


printIt extracting  $packageDir/jdk-8u$version-linux-x64.tar.gz to `pwd`
tar -xzf $packageDir/jdk-8u$version-linux-x64.tar.gz


chmod -R 755 $installPath 


source $HOME/.bashrc
 
if [ -e $csapWorkingDir/jssecacerts.bin ] ; then
	printIt copying $csapWorkingDir/jssecacerts.bin to $JAVA8_HOME/jre/lib/security/jssecacerts
	\cp -f $csapWorkingDir/bin/jssecacerts.bin $JAVA8_HOME/jre/lib/security/jssecacerts
fi ;


printIt installing jce_policy-8.zip
unzip -qq -o $packageDir/jce_policy-8.zip -d $JAVA8_HOME/jre/lib/security
mv -f  $JAVA8_HOME/jre/lib/security/UnlimitedJCEPolicyJDK8/*.jar  $JAVA8_HOME/jre/lib/security



printIt Use CSAP console to validate install
