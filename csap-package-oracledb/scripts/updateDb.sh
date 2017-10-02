#!/bin/bash
wget http://cstgtools/db/db2.tar.gz
rm -rf temp
tar xvzf db2.tar.gz
mv db2 temp
cd temp
ReImage_DB_with_latest_version.sh
