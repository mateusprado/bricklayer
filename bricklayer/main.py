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

import rest
from kronos import Scheduler, method
from builder import Builder
from projects import Projects
from git import Git


_log_file = '/tmp/build_project.out'
logging.basicConfig(level=logging.DEBUG)

_scheduler = Scheduler()
_sched_running = True

def sort_tags(tag):
    if tag.startswith('hudson'):
        int(tag.split('-')[-1])
        

def build_project(project_name):
    project = Projects.get(project_name)
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
        tags = sorted(git.list_tags(), key=sort_tags)
        logging.debug("tags: %s", tags)
        if len(tags) > 0:
            logging.debug('Last tag found: %s', tags[-1])
    except Exception, e:
        logging.info('No tags available : %s', repr(e))
        tags = []

    last_commit = git.last_commit()
    if len(tags) > 0 or project.last_commit != last_commit:
        build = Builder(project)

        if project.repository_url:
            build.upload_to(repository_url)
        
        if len(tags) > 0:
            project.last_tag = tags[-1]
        
        project.last_commit = last_commit
    project.save()

def schedule_projects():
    while _sched_running:
        logging.debug("starting scheduler pid %d", os.getpid())
        projects = Projects.get_all()
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
    logging.debug('reload scheduler')
    global _sched_running, _scheduler
    _scheduler.stop()
    _scheduler = Scheduler()

def stop_scheduler(sig, action):
    logging.debug('terminating')
    global _sched_running
    _sched_running = False
    _scheduler.stop()
    sys.exit(0)

def main_function():

    context = daemon.DaemonContext()
    context.stderr = context.stdout = open('/var/log/bricklayer.log', 'a')
    context.working_directory = os.path.abspath(os.path.curdir)

    context.signal_map = {
            signal.SIGHUP: reload_scheduler,
            signal.SIGINT: stop_scheduler,
        }
    
    with context:
        sched_thread = Process(target=schedule_projects)
        sched_thread.start()
        rest_thread = Process(target=rest.run, args=[sched_thread.pid])

        #while True:
        #    logging.debug("Threads running: %s", activeChildren())
        #    time.sleep(60)
    

if __name__ == '__main__':
    main_function()

