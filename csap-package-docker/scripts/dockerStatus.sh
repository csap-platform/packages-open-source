#!/bin/bash

function printIt() { echo; echo; echo =========; echo == $* ; echo =========; }

function checkInstalled() { verify=`which $1`; if [ "$verify" == "" ] ; then printIt error: $1 not found, install using yum -y install; exit; fi   }



checkInstalled docker

printIt docker containers

docker ps -a

printIt creating hello container
docker run  --name hello  hello-world

docker ps -a

printIt deleting hello container
docker rm -f hello


printIt docker storage
ls -alhs /var/lib/docker/devicemapper/devicemapper
lsblk




exit ;

##
##  Samples
##


echo == create a container named webserver using nginx image
docker run -d -p 80:80 --name webserver nginx
docker ps

echo == to stop and remove container
docker stop webserver
docker rm -f webserver