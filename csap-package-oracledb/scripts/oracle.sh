#!/bin/bash
#
# denodo       Starts oracle.
#
#
# chkconfig: 345 88 12
# description: ActiveMQ is a JMS Messaging Queue Server.
### BEGIN INIT INFO
# Provides: $activemq
### END INIT INFO

# Source function library.
. /etc/init.d/functions


RETVAL=0

umask 077

start() {
       echo -n $"Starting Oracle: "
       echo startup > /tmp/start.sql
       echo exit >> /tmp/start.sql
       chmod 755 /tmp/start.sql
       su - oracle -c "sqlplus '/ as sysdba' @/tmp/start.sql"
       su - oracle -c "lsnrctl start"
       echo
       return $RETVAL
}
stop() {
       echo -n $"Shutting  Oracle: "
       echo shutdown immediate > /tmp/shutdown.sql
       echo exit >> /tmp/shutdown.sql
       chmod 755 /tmp/shutdown.sql
       su - oracle -c "sqlplus '/ as sysdba' @/tmp/shutdown.sql"
       su - oracle -c "lsnrctl stop"
       echo
       return $RETVAL
}

restart() {
       stop
       start
}
case "$1" in
 start)
       start
       ;;
 stop)
       stop
       ;;
 restart|reload)
       restart
       ;;
 *)
       echo $"Usage: $0 {start|stop|restart}"
       exit 1
esac

exit $?

