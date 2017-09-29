#!/bin/bash

#
#  Builds a replication mongo file based on cluster model
#

function printIt() { echo; echo; echo =========; echo == $* ; echo =========; }


mongoBase="CSAP_WORKING"
mongoBin="$mongoBase/mongodatabase/bin"
cd $mongoBase


replicationTemplate="$mongoBase/mongoJs/setup3-replication-template.js"
replicationScript="$mongoBase/mongoJs/setup3-replication.js"
life="_LIFECYCLE_"



#
# mongo db instances
#

hosts=`csap.sh -lab _LBURL_/admin -api hosts/$life-mongocluster-1 -script` ;
printIt _LIFECYCLE_-mongocluster-1 hosts are $hosts


counter=1
replicationConfiguration=""
for hostName in $hosts ; do
		host="MONGOHOST$counter"
		hostNameTrimmed="$hostName"
		hostNameTrimmed="${hostNameTrimmed#"${hostNameTrimmed%%[![:space:]]*}"}"
		hostNameTrimmed="${hostNameTrimmed%"${hostNameTrimmed##*[![:space:]]}"}"		
		if [ $counter == 1 ] ; then			
			replicationConfiguration=$replicationConfiguration"{ _id:$counter, host:'$hostNameTrimmed:27017' }"
		else
			replicationConfiguration=$replicationConfiguration",{ _id:$counter, host:'$hostNameTrimmed:27017' }"
		fi		
		counter=$((counter+1))	
done

#
# mongo arbiter
#

arbiterhost=`csap.sh -lab _LBURL_/admin -api hosts/$life-EventsSingle-1 -script` ;
printIt $life-EventsSingle-1 hosts are $arbiterhost

arbiterhost="${arbiterhost#"${arbiterhost%%[![:space:]]*}"}"
arbiterhost="${arbiterhost%"${arbiterhost##*[![:space:]]}"}"
replicationConfiguration=$replicationConfiguration",{ _id:$counter, host:'$arbiterhost:29017',arbiterOnly :true }"


printIt replicationConfiguration
echo $replicationConfiguration

printIt updating $replicationScript from $replicationTemplate
\rm -rf $replicationScript
sed  "s|MONGOREPLCONFIG|$replicationConfiguration|g" $replicationTemplate > $replicationScript

#
# run mongo
#

cat $replicationScript

printIt Use runMongoScript to invoke $replicationScript

# $mongoBin/mongo $replicationScript

