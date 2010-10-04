#!/bin/bash
#
# bricklayer	Startup script for the Bricklayer Package Builder.
#
#  chkconfig: 2345 85 35
#  description: The Bricklayer Package Builder builds packages to \
#	help you automate builds and upload packages to repositories.
# config: /etc/bricklayer/bricklayer.ini
# config: /etc/sysconfig/bricklayer
# pidfile: /var/run/httpd/bricklayer.pid
#
### BEGIN INIT INFO
# Provides: bricklayer
# Required-Start: $local_fs $remote_fs $network $named
# Required-Stop: $local_fs $remote_fs $network
# Should-Start: distcache
# Short-Description: start and stop Bricklayer Package Builder
# Description: The Bricklayer Package Builder builds packages to
#  help you automate builds and upload packages to repositories.
### END INIT INFO

# Path to binaries
PATH=/usr/bin:/usr/sbin:/bin:/sbin

# Source function library.
. /etc/init.d/functions

# Environment variables
if [ -r /etc/profile ]; then
	. /etc/profile
fi

if [ -r /etc/sysconfig/bricklayer ]; then
	. /etc/sysconfig/bricklayer
fi

# Path to the bricklayer script and short-form for messages.
twistd=${TWISTD-/usr/bin/twistd}
rundir=${RUNDIR-/var/run}
pidfile=${PIDFILE-/var/run/bricklayer.pid}
tacfile=${TACFILE-/etc/bricklayer/bricklayer.tac}
logfile=${LOGFILE-/var/log/bricklayer.log}
lockfile=${LOCKFILE-/var/lock/subsys/bricklayer}
RETVAL=0

test -x ${twistd} || exit 0
test -r ${tacfile} || exit 0

start() {
	echo -n "Starting bricklayer"
	daemon ${twistd} -y ${tacfile} --rundir=${rundir} --pidfile=${pidfile} --logfile=${logfile}
	RETVAL=$?
	[ $RETVAL = 0 ] && touch ${lockfile}
	return $RETVAL
}

stop() {
	echo -n "Stopping bricklayer"
	killproc -p ${pidfile} -d 10 ${twistd}
	RETVAL=$?
	echo
	[ $RETVAL = 0 ] && rm -f ${lockfile} ${pidfile}
}

case "$1" in
  start)
  	start
	;;
  stop)
  	stop
	;;
  restart)
	stop
	sleep 1
	start
	;;
  *)
	echo "Usage: ${0} {start|stop|restart}"
	RETVAL=3
esac

exit $RETVAL
