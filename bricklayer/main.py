from __future__ import with_statement
import sys, os
sys.path.append(os.path.join(os.path.dirname(__file__), 'utils'))

from twisted.application import internet, service
from twisted.internet import reactor, defer, protocol, task
from twisted.protocols import basic

from kronos import Scheduler, method
from builder import Builder
from projects import Projects
from git import Git


_log_file = '/tmp/build_project.out'
logging.basicConfig(level=logging.DEBUG)

_scheduler = Scheduler()
_sched_running = True


class BricklayerProtocol(basic.lineReceiver):
    def lineReceived(self, project_name):
        self.factory.buildProject(project_name)
    
    def connectionMade(self):
        pass

class BricklayerFactory(protocol.ServerFactory):
    protocol = BricklayerProtocol
    
    def __init__(self):
        self.projects = Projects.get_all()

    def buildProject(self, project_name):
        builder = Builder(project_name)
        builder.build_project()

    def schedProject(self, project_name):
        pass


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

application = service.Application("Bricklayer")
factory = BricklayerFactory()
internet.TCPServer(8080, factory).setServiceParent(
        service.IServiceCollection(application))
