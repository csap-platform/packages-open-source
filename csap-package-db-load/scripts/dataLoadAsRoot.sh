#!/bin/bash

# set -o verbose #echo on


echo ==
echo == Running dataLoaderAsRootInstall.sh with params $*

serviceName="$1"

\rm -rf /home/oracle/scripts 

\cp -r scripts /home/oracle

chown -R oracle /home/oracle/scripts
chmod -R 755  /home/oracle/scripts

echo == Data loads can go for a long time. Launching dataload in background, use logs on console to view output

#
# Note: the serviceName and isCsapScript params are used to tag the os process so they can be displayed on console
#
#
su - oracle -c "cd scripts;nohup /home/oracle/scripts/dataLoadAsOracle.sh  $serviceName isCsapScript > /home/oracle/scripts/dataLoadAsOracle.log &"