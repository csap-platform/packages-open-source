#!/bin/bash 

function printIt() { echo; echo; echo =========; echo == $* ; echo =========; }

# change timer to 300 seconds or more
release="6.0.0";

includePackages="no" ; # set to yes to include dev lab artifacts
includeMavenRepo="no" ; # set to yes to include maven Repo
scpCopyHost="do-not-copy"


scriptDir=`dirname $0`
scriptName=`basename $0`

gitFolder="$HOME/git";

# leverages ~/.ssh/config which uses alias to resolve user and host
#targetHost=${1:-aws1-root} ;
#targetUser=${2:-root} ;
sshAlias=${1:-aws1-root} ;

printIt "sshAlias: $sshAlias , ~/.ssh/config: `grep -A 3 $sshAlias ~/.ssh/config`"



function aws_copy() {
	printIt "$sshAlias: transferring $1 ..."
	scp  $1 $sshAlias:
}

function remote_run() {
	printIt "$sshAlias: $*"
	ssh $sshAlias $*
}


function copy_install_scripts() {
	printIt "running remote install: $runAlias" ;
	
	remote_run ls
	remote_run rm -rf "*"
	aws_copy target/*.zip
	remote_run unzip -qo "csap-package-linux-*.zip"
	remote_run rm -vrf "*.zip"
	aws_copy $HOME/temp/*.zip
	remote_run ls -l
}


function root_user_setup() {
	
	
	checkHostName=$(remote_run hostname) ;
	if [[ $checkHostName == *.amazonawss.com ]] ; then
		printIt "Found amazonaws.com , root setup is already completed" ;
		return ;
	fi ;
	
	printIt "Host name does not contain amazonaws, running root setup"
	
	stripRoot="-root"
	
	originalAlias="$sshAlias" ;
	sshAlias=${sshAlias%$stripRoot} ;
	
	if [ "$sshAlias" != "$originalAlias" ] ; then
		printIt "Setting up root user using alias: $sshAlias derived from $originalAlias" ;
		remote_run sudo cp .ssh/authorized_keys /root/.ssh
		remote_run sudo chown root /root/.ssh/authorized_keys 
		sshAlias="$originalAlias" ;
		
		# update redhat config
		remote_run sed -i "/preserve_hostname/d" /etc/cloud/cloud.cfg
		remote_run 'echo -e "\npreserve_hostname: true\n" >> /etc/cloud/cloud.cfg'
		
		# update hostname
		remote_run 'external_host=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname) ; hostnamectl set-hostname --static $external_host'
		
		# reboot
		
		remote_run hostname
		
		printIt "Installing unzip and wget, the remaining packages and kernel configuration will be installed by csap installer"
		remote_run yum -y install unzip wget

	else
		printIt "Skipping root certificate setup - sshAlias does not contain root: $sshAlias" ;
	fi;
}

function remote_csap_install() {
	remote_run ls -l
}



function remote_csap_install() {
	remote_run installer/install.sh -noPrompt  -installDisk default  -installCsap default -toolsServer notSpecified ;
	# -skipKernel
}


#exit ;

function add_local_packages() {
	
	sourceFolder="$gitFolder/$1" ; destination="$STAGING/csap-packages/$2"
	
	printIt "overwriting $destination  with contents from $sourceFolder"
	
	ls -l $destination
	\cp -vf $sourceFolder $destination
	
	ls -l $destination
	# $HOME/git/csap-packages/csap-package-java $STAGING/csap-packages/
}


function build_csap() {

	printIt Building $release , rember to use ui on csaptools to sync release file to other vm
	
	buildDir="$HOME/localbuild"
	[ -e $buildDir ] && printIt "removing existing $buildDir..." && rm -r $buildDir ; # delete if exists
	
	export STAGING="$buildDir/staging" ;
	
	printIt "Extracting contents of base release $HOME/Downloads/csap6.0.0.zip to $buildDir ..."
	unzip -qq -o "$HOME/Downloads/csap6.0.0.zip" -d "$buildDir"
	
	add_local_packages csap-packages/csap-package-java/target/*.zip jdk.zip
	#exit;
	
	$scriptDir/build-csap.sh $release $includePackages $includeMavenRepo $scpCopyHost
	
	
	
	#$STAGING/bin/mkcsap.sh $release $includePackages $includeMavenRepo $scpCopyHost
	
	#includePackages="yes" ; # set to yes to include dev lab artifacts
	#includeMavenRepo="yes" ; # set to yes to include maven Repo
	#release="$release-full"
	
	#printIt Building $release , rember to use ui on csaptools to sync release file to other vm
	#$STAGING/bin/mkcsap.sh $release $includePackages $includeMavenRepo $scpCopyHost

}

if [ $release != "updateThis" ] ; then
	
	build_csap 
	
	root_user_setup
	
	copy_install_scripts ;
	
else
	printIt update release variable and timer
fi

