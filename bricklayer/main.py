from __future__ import with_statement
import sys, os, logging
sys.path.append(os.path.join(os.path.dirname(__file__), 'utils'))
sys.path.append(os.path.dirname(__file__))

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


class BricklayerProtocol(basic.LineReceiver):
    def lineReceived(self, line):
        command, arg = line.split(':')
        if 'build' in command:
            project_name = arg
            self.factory.buildProject(project_name, force=True)
    
    def connectionMade(self):
        pass

class BricklayerFactory(protocol.ServerFactory):
    protocol = BricklayerProtocol
    
    def __init__(self):
        self.projects = Projects.get_all()
        self.taskProjects = {}
        self.schedProjects()

    def buildProject(self, project_name):
        builder = Builder(project_name)
        builder.build_project()

    def schedProjects(self):
        for project in self.projects:
            projectBuilder = Builder(project.name)
            self.taskProjects[project.name] = task.LoopingCall(projectBuilder.build_project)
            self.taskProjects[project.name].start(18000)

application = service.Application("Bricklayer")
factory = BricklayerFactory()
internet.TCPServer(8080, factory).setServiceParent(
        service.IServiceCollection(application))
