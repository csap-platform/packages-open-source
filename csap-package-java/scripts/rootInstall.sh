#!/bin/bash



printIt() {
	echo;echo;
	echo = 
	echo = $*
	echo = 
}



csapWorkingDir=$1
minorVersion="$2" 
packageDir="$3"
majorVersion="$4"


#for testing - blow away existing folder. Do not do this if Agent is using it
testMode=false;



printIt "disabling case matching in expressions that use [[ ]]: shopt -s nocasematch"
shopt -s nocasematch

function installJava8 () {
	
	printIt "$USER Installing Java 8 using package configuration in $csapWorkingDir version: $minorVersion"
	
	# if installing as java - it becomes the default JAVA_HOME
	isDefaultJava=$(if [[ `basename "$csapWorkingDir"` == "Java_0" || $csapWorkingDir != *jdkAlt* ]]; then echo true; else echo false; fi)
		
	javaFolderName="jdk1.8.0_$minorVersion"
		
	if [ "$USER" == "root" ] ; then
		printIt root install: $csapWorkingDir version: $minorVersion
		mkdir -p /opt/java
		cd /opt/java ;
		installPath="/opt/java/$javaFolderName"
		
		# delete locations
		sed -i '/JAVA8_HOME/d' /etc/bashrc
		echo  export JAVA8_HOME=$installPath >> /etc/bashrc
		
		if $isDefaultJava ; then 
			printIt Installing default java. Updating JAVA_HOME
			sed -i '/JAVA_HOME/d' /etc/bashrc
			echo  export JAVA_HOME=$installPath >> /etc/bashrc
			echo  export PATH=\$JAVA_HOME/bin:\$PATH >> /etc/bashrc
			tail -10 /etc/bashrc
		else
			printIt Installing as non default JDK
		fi ;
		
	else
		printIt non root install: $csapWorkingDir version: $minorVersion
		source $HOME/.cafEnv
		installPath="$STAGING/../java/$javaFolderName" 
		if [ "$INSTALL_DIR" != "" ] ; then 
			echo == using custom location $INSTALL_DIR
			if [ ! -e $INSTALL_DIR ] ; then 
				echo == folder does not exist, creating: $INSTALL_DIR
				mkdir -p $INSTALL_DIR ;
			fi
			
			cd $INSTALL_DIR ;
			installPath="$INSTALL_DIR/$javaFolderName" 
		
		else 
			echo == using default location $STAGING/../java
			cd $STAGING/../java ;
		fi
		
		echo == adding link to: `pwd` from: $csapWorkingDir/JAVA_HOME
		ln -s `pwd` $csapWorkingDir/JAVA_HOME
		
		JAVA8_HOME=$installPath
		
		sed -i '/JAVA8_HOME/d' $HOME/.cafEnv
		echo  export JAVA8_HOME=$installPath >> $HOME/.cafEnv
		
		if $isDefaultJava ; then 
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
	

	printIt "Checking if install location already exists: $installPath"
	
	if [ -d  $installPath ] ; then
		
		if $testMode ; then 
			printIt testMode set, deleting $installPath
			\rm -rf $installPath ;
			
		else
			printIt java already installed , exiting
			exit ;
		fi ;
		
	fi
	
	
	printIt extracting  $packageDir/jdk-8u$minorVersion-linux-x64.tar.gz to `pwd`
	tar -xzf $packageDir/jdk-8u$minorVersion-linux-x64.tar.gz
	
	
	chmod -R 755 $installPath 
	
	
	source $HOME/.bashrc
	
	printIt "JAVA8_HOME set to: $JAVA8_HOME"
	 
	if [ -e $csapWorkingDir/jssecacerts.bin ] ; then
		printIt copying $csapWorkingDir/jssecacerts.bin to $JAVA8_HOME/jre/lib/security/jssecacerts
		\cp -f $csapWorkingDir/bin/jssecacerts.bin $JAVA8_HOME/jre/lib/security/jssecacerts
	fi ;
	
	
	printIt installing jce_policy-8.zip
	unzip -qq -o $packageDir/jce_policy-8.zip -d $JAVA8_HOME/jre/lib/security
	mv -f  $JAVA8_HOME/jre/lib/security/UnlimitedJCEPolicyJDK8/*.jar  $JAVA8_HOME/jre/lib/security

}

function installJava9 () {
	
	printIt "$USER Installing Java 9 using package configuration in $csapWorkingDir version: $minorVersion"
	
	javaFolderName="jdk-9"
	if [ "$minorVersion" != "none" ] ; then
		javaFolderName="jdk-9u$minorVersion"
	fi
	
	# if installing as java - it becomes the default JAVA_HOME
	isDefaultJava=$(if [[ `basename "$csapWorkingDir"` = "Java_0" ]]; then echo true; else echo false; fi)
	
		
	if [ "$USER" == "root" ] ; then
		mkdir -p /opt/java
		cd /opt/java ;
		installPath="/opt/java/$javaFolderName"
		
		# delete locations
		sed -i '/JAVA9_HOME/d' /etc/bashrc
		echo  export JAVA9_HOME=$installPath >> /etc/bashrc
		
		if $isDefaultJava ; then 
			
			printIt Installing default java. Updating JAVA_HOME
			sed -i '/JAVA_HOME/d' /etc/bashrc
			echo  export JAVA_HOME=$installPath >> /etc/bashrc
			echo  export PATH=\$JAVA_HOME/bin:\$PATH >> /etc/bashrc
			tail -10 /etc/bashrc
			
		else
			
			printIt Installing as non default JDK
			
		fi ;
		
	else
		
		source $HOME/.cafEnv
		installPath="$STAGING/../java/$javaFolderName" 
		if [ "$INSTALL_DIR" != "" ] ; then 
			echo == using custom location $INSTALL_DIR
			if [ ! -e $INSTALL_DIR ] ; then 
				echo == folder does not exist, creating: $INSTALL_DIR
				mkdir -p $INSTALL_DIR ;
			fi
			
			cd $INSTALL_DIR ;
			installPath="$INSTALL_DIR/$javaFolderName" 
		
		else 
			echo == using default location $STAGING/../java
			cd $STAGING/../java ;
		fi
		
		printIT "adding link to: `pwd` from: $csapWorkingDir/JAVA_HOME"
		ln -s `pwd` $csapWorkingDir/JAVA_HOME
		
		JAVA9_HOME=$installPath
		
		sed -i '/JAVA9_HOME/d' $HOME/.cafEnv
		echo  export JAVA9_HOME=$installPath >> $HOME/.cafEnv
		
		if $isDefaultJava ; then 
			printIt "service name is java, JVM will become system default by updating JAVA_HOME"
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
		
		if $testMode ; then 
			printIt testMode set, deleting $installPath
			\rm -rf $installPath ;
			
		else
			printIt java already installed , exiting
			exit ;
		fi ;
		
	fi
	
	
	printIt "extracting  $packageDir/jdk-9*_linux-x64_bin.tar.gz to `pwd`"
	tar -xzf $packageDir/jdk-9*_linux-x64_bin.tar.gz
	
	
	chmod -R 755 $installPath 
	
	
	source $HOME/.bashrc
	
	printIt "JAVA9_HOME set to: $JAVA9_HOME"
	 
	if [ -e $csapWorkingDir/jssecacerts.bin ] ; then
		printIt copying $csapWorkingDir/jssecacerts.bin to $JAVA9_HOME/jre/lib/security/jssecacerts
		\cp -f $csapWorkingDir/bin/jssecacerts.bin $JAVA9_HOME/jre/lib/security/jssecacerts
	fi ;
	
	
}

if [ "$majorVersion" == "jdk9" ] ; then 
	installJava9 ;
else
	installJava8 ;
fi



printIt Use CSAP console to validate install
