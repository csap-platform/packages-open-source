#!/bin/bash
#
# activemq       Starts ActiveMQ.
#
#
# chkconfig: 345 88 12
# description: ActiveMQ is a JMS Messaging Queue Server.
### BEGIN INIT INFO
# Provides: $activemq
### END INIT INFO

# Source function library.
. /etc/init.d/functions

mqVersion=5.12.1

[ -f /home/mquser/apache-activemq-$mqVersion/bin/linux-x86-64/activemq ] || exit 0

RETVAL=0

umask 077

start() {
       echo -n $"Starting ActiveMQ: "
        /bin/su - mquser /home/mquser/apache-activemq-$mqVersion/bin/linux-x86-64/activemq start
    	echo == reniceing for priority
    	pidMatches=`ps -f -umquser | grep activemq | grep -v -e grep | awk '{ print $2 }'`
    	for pid in $pidMatches ; do 
    		echo Found $pid 
    		renice -5 -p $pid
    	 echo  Confirm output below
    		ps l -p $pid
    	done
    	
    	# pidMatches=`ps -ef | grep activemq | grep -v -e grep | awk '{ print $2 }'` ; for pid in $pidMatches ; do ps l -p $pid ; done
    	
       return $RETVAL
}
stop() {
       echo -n $"Shutting down ActiveMQ: "
        /bin/su - mquser /home/mquser/apache-activemq-$mqVersion/bin/linux-x86-64/activemq stop
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

