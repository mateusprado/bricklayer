from __future__ import with_statement
import sys
sys.path.append('utils')

import os
import subprocess
import threading
import signal
import daemon
import lockfile
import time
import logging

import rest
from kronos import Scheduler, method
from builder import Builder
from projects import Projects
from git import Git


_log_file = '/tmp/build_project.out'
logging.basicConfig(level=logging.DEBUG)

_scheduler = Scheduler()
_sched_running = True

def build_project(project_name):
    project = Projects().get(project_name)
    git = Git(project)
    
    try:
        if not os.path.isdir(git.workdir):
            git.clone()
        else:
            git.pull()
    except Exception, e:
        logging.error('Could not clone or update repository')
        raise

    try:
        tags = git.list_tags()
        logging.debug('Tags found: %s', tags)
    except Exception, e:
        logging.info('No tags available : %s', repr(e))
    finally:
        tags = []

    last_commit = git.last_commit()
    if len(tags) > 0 or project.last_commit != last_commit:
        build = Builder(project)

        if project.repository_url:
            build.upload_to(repository_url)
             
        project.last_tag = tags[0]
        project.last_commit = last_commit
    project.save()

def schedule_projects():
    while _sched_running:
        projects = Projects().get_all()
        for project in projects:
            logging.debug('scheduling %s', project)
            _scheduler.add_interval_task(
                    build_project, 
                    project.name, 
                    initialdelay=0,
                    interval=60 * 10,
                    processmethod=method.threaded, 
                    args=[project.name], kw=None)
        _scheduler.start()

def reload_scheduler(sig, action):
    global _sched_running
    _scheduler.stop()
    _scheduler.running = True
    _sched_running = True

def stop_scheduler(sig, action):
    logging.debug('terminating')
    global _sched_running
    _sched_running = False
    _scheduler.stop()
    sys.exit(0)

def main_function():

    context = daemon.DaemonContext(detach_process=False)
    context.stdout = sys.stdout 
    context.stderr = sys.stderr 
    context.working_directory = os.path.abspath(os.path.curdir)
    #context.pidfile = lockfile.FileLock('/var/run/build_project.pid')

    context.signal_map = {
            signal.SIGHUP: reload_scheduler,
            signal.SIGINT: stop_scheduler,
            }
    
    with context:
        sched_thread = threading.Thread(name='sched', target=schedule_projects)
        sched_thread.start()
        rest.run()
        while True:
            logging.debug(threading.enumerate())
            time.sleep(5)


if __name__ == '__main__':
    main_function()

