#!/bin/bash

# set -o verbose #echo on


echo ==
echo == Running activemqRootInstall.sh

cp scripts/mqInstall.sh /home/mquser
cp -r scripts /home/mquser

chown -R mquser /home/mquser/*
chmod -R 755  /home/mquser/*

echo
echo == running mqInstall.sh as mquser
echo 

su - mquser -c "/home/mquser/mqInstall.sh"

echo ==
echo == Running post install steps as root
echo == copying scripts/activemq.sh to /etc/init.d/activemq
echo
cp scripts/activemq.sh /etc/init.d/activemq
chmod 755 /etc/init.d/activemq

echo == Running /sbin/chkconfig to add activemq to startup
/sbin/chkconfig --add activemq

# console will start
#/sbin/chkconfig activemq on
