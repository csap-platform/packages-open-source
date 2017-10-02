
export ORAUSER_HOME=/home/oracle
export ORACLE_BASE=/home/oracle/base
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0.4/db_1
export PATH=$PATH:$ORACLE_HOME/bin:$ORACLE_HOME
export TNS_ADMIN=$ORACLE_HOME/network/admin
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
# export ORACLE_SID_SUFFIX=F4
# export ORACLE_SID=SSDB$ORACLE_SID_SUFFIX
export lasttwo=`echo $HOSTNAME | sed 's/.*\(..\)$/\1/'`
export suffix=`echo $HOSTNAME |  sed 's/.*\-//'`
export lastEight=`echo $suffix | sed 's/.*\(........\)$/\1/'`

#note installFunctions.sh needs logic update if this is changes
export ORACLE_SID="$lastEight"
