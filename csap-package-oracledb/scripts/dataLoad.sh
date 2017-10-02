#!/bin/bash

#
#  csap install scripts look for a file named $HOME/dist/smartPlatform/dataLoad.sh, if it exists it will be run after oracle is installed
#


distDir="$1"

echo ==
echo == Loading CSAP Data for oracle from $HOME/db. Deleteing /home/oracle/temp 
echo ==
	
rm -rf /home/oracle/temp
\cp -rf  $distDir/bootStrapData /home/oracle/temp
chown -R oracle /home/oracle/temp
chmod -R 755 /home/oracle/temp

echo ==
echo == Data copied, invoking bootstrapLoader
echo ==

su - oracle -c "cd temp;chmod -R 755 /home/oracle/base/diag;/home/oracle/temp/bootstrapLoader.sh" 

echo ==
echo == Data load complete
echo ==