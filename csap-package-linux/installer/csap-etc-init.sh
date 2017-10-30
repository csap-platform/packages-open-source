#!/bin/bash


# Source function library.
. /etc/init.d/functions

#
#  NOTE; CSAP_USER will be updated by install
#

[ -f /home/CSAP_USER/staging/bin/csap-kill.sh ] || exit 0

RETVAL=0

umask 077

start() {
       echo -n $"Starting ssadmin: "
       # this will do a autorestart after killing any existing services
       daemon --user=CSAP_USER /home/CSAP_USER/staging/bin/csap-kill.sh -d
       echo
       return $RETVAL
}
stop() {
       echo -n $"Shutting  ssadmin: "
       daemon --user=CSAP_USER /home/CSAP_USER/staging/bin/csap-kill.sh
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

