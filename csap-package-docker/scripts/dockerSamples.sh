#!/bin/bash


function printIt() { echo; echo; echo =========; echo == $* ; echo =========; }

function checkInstalled() { verify=`which $1`; if [ "$verify" == "" ] ; then printIt error: $1 not found, install using yum -y install; exit; fi   }



checkInstalled docker
checkInstalled wget


# 
printIt "starting  nginx docker named webServer99 on port 80 as a daemon"
docker run -d -p 80:80 --name webServer99 nginx

sleep 1;

testUrl="http://localhost" ;
output=$(wget -qO- $testUrl 2>&1)

printIt "Hitting $testUrl using wget, stripping off html tags"
echo $output | sed -e 's/<[^>]*>//g'

printIt stopping docker container named webServer99
docker stop webServer99


printIt Deleting container
docker rm -f webServer99

printIt Deleting nginx image
docker rmi -f docker.io/library/nginx