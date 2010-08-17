import os
import signal
import sys

sys.path.append(os.path.dirname(__file__))
from projects import Projects
from builder import Builder

import cyclone.web
import cyclone.escape
from twisted.internet import defer
from twisted.python import log

class Project(cyclone.web.RequestHandler):
    
    def post(self):
        try:
            Projects().get(self.get_argument('name'))
        except Exception, e:
            project = Projects()
            project.name = self.get_argument('name')[0]
            project.git_url = self.get_argument('git_url')[0]

            for name, parm in self.request.arguments.iteritems():
                setattr(project, str(name), parm[0])

            try:
                project.save()
                log.msg('Project created:', project.name)
                builder = Builder(project.name)
                builder.build_project(force=True)            
                log.msg('Project build is done', project.name)
                self.write(cyclone.escape.json_encode({'status': 'ok'}))
            except Exception, e:
                log.err()
                self.write(cyclone.escape.json_encode({'status': "fail"}))
        else:
            self.write(cyclone.escape.json_encode({'status':  "Project already exists"}))

    def put(self, name):
        project = Projects().get(name)
        builder = Builder(project.name)
        for name, arg in self.request.arguments.iteritems():
            setattr(project, name, arg[0])

        try:
            project.save()
            builder.build_project(force=True)
            self.write(cyclone.escape.json_encode({'status': 'ok'}))
        except Exception, e:
            log.err(e)
            self.write(cyclone.escape.json_encode({'status': 'fail'}))

    def get(self, name):
        try:
            project = Projects().get(name)
        except Exception, e:
            self.write(cyclone.escape.json_encode("%s No project found" % e))
        self.write(cyclone.escape.json_encode({'name': project.name, 
                'git_url': project.git_url, 
                'version': project.version,
                'last_tag': project.last_tag,
                'last_commit': project.last_commit}))


    def delete(self, name):
        try:
            project = Projects().get(name)
            project.delete()
        except Exception, e:
            log.err(e)

restApp = cyclone.web.Application([
    (r'/project/(.*)', Project),
    (r'/project', Project),
])

