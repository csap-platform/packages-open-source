#!/bin/bash


function printIt() {
	echo;echo;
	echo = 
	echo = $*
	echo = 
}


# this is run as mquser
cd $HOME


printIt "toolsServer should be set in /etc/bashrc, value is: $toolsServer"


export MQ_VERSION=apache-activemq-5.12.1

export MQ_BASE=/home/mquser/

printIt "Installing Active MQ in $MQ_BASE"


cd $MQ_BASE
rm -rf *.gz

wget -nv http://$toolsServer/activemq/$MQ_VERSION-bin.tar.gz --directory-prefix=$MQ_BASE

printIt "Extracting: apache-activemq-*.gz"
tar xvzf apache-activemq-*.gz


printIt  "Setting lock folder: /home/mquser/locks"

sed -i "s|/var/lock/subsys|/home/mquser/locks|g" /home/mquser/$MQ_VERSION/bin/linux-x86-64/activemq
mkdir /home/mquser/locks

printIt  "replaced activemq distribution with: scripts/activemq.xml"
mv apache-activemq-*/conf/activemq.xml activemq.xml.orig
\cp -f scripts/activemq.xml apache-activemq-*/conf


printIt  "replaced activemq distribution with: scripts/wrapper.conf"

mv apache-activemq-*/bin/linux-x86-64/wrapper.conf wrapper.conf.orig
\cp -f scripts/wrapper.conf apache-activemq-*/bin/linux-x86-64




printIt "Configuring security on console"
mv apache-activemq-*/conf/jetty.xml jetty.xml.orig
\cp -fv scripts/jetty* apache-activemq-*/conf

if [[ $HOSTNAME == *dev* ]] ; then 
	printIt "dev found in hostname, disabling mq authentication"
	sed -i "s=_AUTHENTICATE_=false=g" apache-activemq-*/conf/jetty.xml
	
else 
	printIt "dev not found in hostname, enabling mq authentication"
	sed -i "s=_AUTHENTICATE_=true=g" apache-activemq-*/conf/jetty.xml
	
	
	printIt "dynamically generating a unique password, use CS-AP property viewer to retrieve if needed"
	echo == password is updated in apache-activemq-*/conf/jetty-realm.properties
	
	genPass=`tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1`
	#echo == password is $genPass
	sed -i "s=_PASS_=$genPass=g" apache-activemq-*/conf/jetty-realm.properties
fi

printIt "linking logs for UI browsing on console"
ln -s apache-activemq-*/data logs

