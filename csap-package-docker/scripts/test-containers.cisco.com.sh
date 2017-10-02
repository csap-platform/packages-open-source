#!/bin/bash



function printIt() { echo; echo; echo =========; echo == $* ; echo =========; }

function checkInstalled() { verify=`which $1`; if [ "$verify" == "" ] ; then printIt error: $1 not found, install using yum -y install; exit; fi   }



checkInstalled docker
checkInstalled wget

dockerImage="containers.yourcompany.com/csap-simple"


printIt "Connecting to containers.yourcompany.com, and downloading latest pnightin/csap-simple"
echo "Warning - set timeout to 5 minutes because downloads can take a while"
docker pull $dockerImage


# 
printIt "starting  pnightin/csap-simple docker named csapSimple on port 80 as a daemon"
docker run -d -p 80:8080 --name csapSimple $dockerImage

sleep 1;

testUrl="http://localhost" ;
output=$(wget -qO- $testUrl 2>&1)

printIt "Hitting $testUrl using wget, stripping off html tags"
echo $output | sed -e 's/<[^>]*>//g'

printIt stopping docker container named csapSimple
docker stop csapSimple


printIt Deleting container
docker rm -f csapSimple

