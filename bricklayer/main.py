from __future__ import with_statement
import sys, os
sys.path.append(os.path.join(os.path.dirname(__file__), 'utils'))

import subprocess
import signal
import daemon
import lockfile
import time
import logging
from threading import Thread, activeCount
from multiprocessing import Process

from rest import run
from kronos import Scheduler, method
from builder import Builder
from projects import Projects

import bricklayer


def parse_cmdline():
    from optparse import OptionParser
    parser = OptionParser()

    parser.add_option("-l", "", dest="logfile", help="log file", metavar="")
    parser.add_option("-p", "", dest="pidfile", help="pid file", metavar="")
    parser.add_option("-c", "", dest="configfile", help="config file", metavar="")
    parser.add_option("-d", "", action="store", dest="notdaemon", default=True, metavar="")
    return parser.parse_args()

def main_function():

    (options, args) = parse_cmdline()

    logfile = options.logfile
    pidfile = options.pidfile
    configfile = options.configfile
    notdaemon = options.configfile

    if not options.logfile:
        logfile = '/var/log/bricklayer.log'

    if not options.pidfile:
        pidfile = '/var/run/bricklayerd.pid'

    if not options.configfile:
        configfile = '/etc/bricklayer/bricklayer.ini'

    print "pidfile:", pidfile, "logfile:", logfile, "configfile:", configfile

    context = daemon.DaemonContext(detach_process=False)
    context.stderr = context.stdout = open(logfile, 'a')
    context.working_directory = os.path.abspath(os.path.curdir)
    context.detach_process = True
    if notdaemon:
        context.detach_process = False

    context.signal_map = {
            signal.SIGHUP: bricklayer.reload_scheduler,
            signal.SIGINT: bricklayer.stop_scheduler,
        }
    
    with context:
#        if os.path.isdir('/var/run'):
        pidfile = open(pidfile, 'a')
        pidfile.write(str(os.getpid()))
        pidfile.close()

        sched_thread = Process(target=bricklayer.schedule_projects)
        sched_thread.start()
        rest_thread = Process(target=rest.run, args=[sched_thread.pid])
        rest_thread.start()

#        while True:
#            logging.debug("Threads running: %s", activeChildren())
#            time.sleep(60)
    

if __name__ == '__main__':
    main_function()
