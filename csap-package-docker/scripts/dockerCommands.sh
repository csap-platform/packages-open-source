#!/bin/bash

NOW=$(date +"%h-%d-%I-%M-%S")

function printIt() {
	echo;echo;
	echo = 
	echo = $*
	echo = 
}

function replaceFile() {
	
	originalFile="$1" ;
	updatedFile="$2" ;
	
	printIt "Updating $originalFile with $updatedFile. $originalFile is being backed up"
	
	if [ ! -f $originalFile.orig ] ; then
		mv 	$originalFile $originalFile.orig;
	else
		mv 	$originalFile $originalFile.last;
	fi ; 
	
	\cp -f $updatedFile $originalFile
}


command=$1
dockerStorage=$2
allowRemote=$3
csapVersion=$4

printIt "Configuration - dockerStorage: $dockerStorage,  allowRemote: $allowRemote, csapVersion: $csapVersion"


function install() {
	
	printIt "Reference: https://access.redhat.com/articles/2317361"
		
	if [ "$USER" == "root" ] ; then
		rpm -q docker ;
		if [ "$?" != 0 ] ; then 
			printIt Installing docker....
			yum -y install docker device-mapper-libs device-mapper-event-libs
			 
			printIt == adding ssadmin user to docker
			sudo groupadd docker
			sudo gpasswd -a ssadmin docker;
			
		fi;
		
		if [[ "$csapVersion" != *LATEST* ]] ; then 
			printIt "Configuring docker stable"
			replaceFile /etc/sysconfig/docker conf/sysconfig-docker.sh ;
		
			printIt "Updating /etc/sysconfig/docker with dockerStorage: $dockerStorage"
			sed -i "s=_CSAP_DOCKER_STORAGE_=$dockerStorage=g" /etc/sysconfig/docker
			
			remoteAllowParam="" ;
			if [ "$allowRemote" == "true" ] ; then 
				remoteAllowParam="-H tcp://0.0.0.0:4243" ;
				printIt "WARNING: Updating /etc/sysconfig/docker with remoteAllowParam: $remoteAllowParam"
			fi
			sed -i "s=_CSAP_ALLOW_REMOTE_=$remoteAllowParam=g" /etc/sysconfig/docker
			
			replaceFile /etc/sysconfig/docker-storage-setup conf/sysconfig-docker-storage-setup.sh  ;
			
		else
			
			
			printIt "configuring docker-latest"
			rpm -q docker-latest ;
			if [ "$?" != 0 ] ; then 
				printIt Installing docker-latest....
				yum -y install docker-latest
			fi;
			
			replaceFile /etc/sysconfig/docker-latest conf.latest/sysconfig-docker-latest.sh ;
		
			printIt "Updating /etc/sysconfig/docker-latest with dockerStorage: $dockerStorage"
			sed -i "s=_CSAP_DOCKER_STORAGE_=$dockerStorage=g" /etc/sysconfig/docker-latest
			
			remoteAllowParam="" ;
			if [ "$allowRemote" == "true" ] ; then 
				remoteAllowParam="-H tcp://0.0.0.0:4243" ;
				printIt "WARNING: Updating /etc/sysconfig/docker-latest with remoteAllowParam: $remoteAllowParam"
			fi
			sed -i "s=_CSAP_ALLOW_REMOTE_=$remoteAllowParam=g" /etc/sysconfig/docker-latest
			
			replaceFile /etc/sysconfig/docker-latest-storage-setup conf.latest/sysconfig-docker-latest-storage-setup.sh  ;
			
			replaceFile /etc/docker-latest/daemon.json conf.latest/daemon.json  ;
			
			replaceFile /etc/sysconfig/docker conf.latest/sysconfig-docker.sh ;
			
			
		fi ;
		
	else
		printIt ROOT access is require to install. contact sysadmin
	fi ;
}

function start() {
		printIt "starting docker and enabling via systemctl"

		if [[ "$csapVersion" != *LATEST* ]] ; then
			systemctl start docker.service
			systemctl enable docker.service
		else
			systemctl start docker-latest.service
			systemctl enable docker-latest.service
		fi
		
		printIt "Running hello-world"
		docker run --name csap-hello-container hello-world
		
}

function clean() {
		printIt "Clean was specified: all docker containers will be stopped and all images removed"
		docker ps -a -q
		docker stop $(docker ps -a -q) ; 
		docker rm $(docker ps -a -q) 
		docker rmi $(docker images -a -q) ;
		
		if [[ "$csapVersion" != *LATEST* ]] ; then
			systemctl stop docker.service
			systemctl disable docker.service
		else
			systemctl stop docker-latest.service
			systemctl disable docker-latest.service
		fi
		
		
		printIt "Docker stopped -  running rm -rf $dockerStorage"
		\rm -rf $dockerStorage
		
		printIt "removing docker from system"
		yum -y erase docker docker-latest
		
}

function stop() {
		printIt "Stopping docker containers"
		docker ps -a -q
		docker stop $(docker ps -a -q) ;
		
		
		printIt "Stopping docker service"
		if [[ "$csapVersion" != *LATEST* ]] ; then
			systemctl stop docker.service
			systemctl disable docker.service
		else
			systemctl stop docker-latest.service
			systemctl disable docker-latest.service
		fi

}

#printIt "Running $command"

case "$command" in
	
	install)
		install
		;;
	
	clean)
		clean
		;;
	
	stop)
		stop
		;;
	
	start)
		start
		;;
	
	 *)
            echo $"Usage: $0 {start|stop|restart|clean}"
            exit 1
esac
