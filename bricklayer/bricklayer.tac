import sys
import os
import logging
sys.path.append('.')

import bricklayer
sys.path.append(os.path.dirname(bricklayer.__file__))
sys.path.append(os.path.join(os.path.dirname(bricklayer.__file__), 'utils'))

import pystache

from twisted.application import internet, service
from twisted.internet import protocol, task, threads, reactor
from twisted.protocols import basic
from twisted.python import log

from builder import Builder, build_project
from projects import Projects
from config import BrickConfig
from rest import restApp
from dreque import Dreque, DrequeWorker

class BricklayerProtocol(basic.LineReceiver):
    def lineReceived(self, line):
        def onError(err):
            logging.error("Command fail.")

        def onResponse(message, *args, **kwargs):
            self.transport.write("ok.\r\n")

        command, arg = line.split(':')
        if 'build' in command:
            project_name = arg
            self.transport.write("building %s\r\n" % project_name)
            defered = threads.deferToThread(self.factory.build_project, project_name, force=True)
            defered.addCallback(onResponse, onError)
    
    def connectionMade(self):
        pass

class BricklayerFactory(protocol.ServerFactory):
    protocol = BricklayerProtocol

    def __init__(self):
        self.sched_projects()

    def build_project(self, project_name, force=False):
        builder = Builder(project_name)
        builder.build_project(force=force)
    
    def send_job(self, project_name):
        log.msg('sched project: %s' % project_name)
        brickconfig = BrickConfig()
        queue = Dreque(brickconfig.get('redis', 'redis-server'))
        queue.enqueue('build', 'builder.build_project', {'project': project_name, 'branch': None, 'force': False})

    def sched_builder(self):
        for project in Projects.get_all():
            d = threads.deferToThread(self.send_job, project.name)

    def sched_projects(self):
        sched_task = task.LoopingCall(self.sched_builder)
        sched_task.start(30.0)

brickconfig = BrickConfig()
bricklayer = service.MultiService()

factory = BricklayerFactory()
brickService = internet.TCPServer(8080, factory)
restService = internet.TCPServer(80, restApp)

brickService.setServiceParent(bricklayer)
restService.setServiceParent(bricklayer)

application = service.Application("Bricklayer")
bricklayer.setServiceParent(application)
