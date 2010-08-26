import sys
import os
import logging
import bricklayer
sys.path.append(os.path.dirname(bricklayer.__file__))

import pystache

from twisted.application import internet, service
from twisted.internet import defer, protocol, task
from twisted.protocols import basic

from builder import Builder
from projects import Projects
from config import BrickConfig
from rest import restApp

class BricklayerProtocol(basic.LineReceiver):
    def lineReceived(self, line):
        def onError(err):
            logging.error("Command fail.")

        def onResponse(message, *args, **kwargs):
            self.transport.write("ok.\r\n")

        command, arg = line.split(':')
        if 'build' in command:
            project_name = arg
            defered = self.factory.buildProject(project_name, force=True)
            defered.addCallback(onResponse, onError)
    
    def connectionMade(self):
        pass

class BricklayerFactory(protocol.ServerFactory):
    protocol = BricklayerProtocol
    
    def __init__(self):
        self.projects = Projects.get_all()
        self.taskProjects = {}
        self.schedProjects()

    def buildProject(self, project_name, force=False):
        builder = Builder(project_name)
        return defer.succeed(builder.build_project(force=force))

    def schedProjects(self):
        for project in self.projects:
            projectBuilder = Builder(project.name)
            self.taskProjects[project.name] = task.LoopingCall(projectBuilder.build_project)
            self.taskProjects[project.name].start(300.0)

if "BRICKLAYERCONFIG" in os.environ.keys():
    configfile = os.environ['BRICKLAYERCONFIG']
else:
    configfile = '/etc/bricklayer/bricklayer.ini'

brickconfig = BrickConfig(configfile)

bricklayer = service.MultiService()


factory = BricklayerFactory()
brickService = internet.TCPServer(8080, factory)
restService = internet.TCPServer(80, restApp)

brickService.setServiceParent(bricklayer)
restService.setServiceParent(bricklayer)

application = service.Application("Bricklayer")
bricklayer.setServiceParent(application)
