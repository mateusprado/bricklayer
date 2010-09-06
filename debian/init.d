#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin

pidfile=/var/run/bricklayer.pid rundir=/var/lib/bricklayer/ file=/etc/bricklayer/bricklayer.tac logfile=/var/log/bricklayer.log

[ -r /etc/default/bricklayer ] && . /etc/default/bricklayer

test -x /usr/bin/twistd || exit 0
test -r $file || exit 0

case "$1" in
    start)
        echo -n "Starting bricklayer: twistd"
        start-stop-daemon --start --quiet --exec /usr/bin/twistd -- --pidfile=$pidfile --rundir=$rundir --python=$file --logfile=$logfile
        echo "."	
    ;;

    stop)
        echo -n "Stopping bricklayer: twistd"
        start-stop-daemon --stop --quiet --pidfile $pidfile
        echo "."	
    ;;

    restart)
        $0 stop
        $0 start
    ;;

    force-reload)
        $0 restart
    ;;

    *)
        echo "Usage: /etc/init.d/bricklayer {start|stop|restart|force-reload}" >&2
        exit 1
    ;;
esac

exit 0
