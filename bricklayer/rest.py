import os
import signal
import sys

sys.path.append(os.path.dirname(__file__))
from projects import Projects
from builder import Builder

import cyclone.web
import cyclone.escape
from twisted.internet import reactor
from twisted.python import log

def forceBuild(project_name, branch='master'):
    builder = Builder(project_name)
    builder.build_project(force=True, a_branch=branch)

class Project(cyclone.web.RequestHandler):
    def post(self, *args):
        try:
            if Projects(self.get_argument('name')).git_url == '':
                raise
            
        except Exception, e:
            project = Projects()
            project.name = self.get_argument('name')[0]
            project.git_url = self.get_argument('git_url')[0]
            for name, parm in self.request.arguments.iteritems():
                setattr(project, str(name), parm[0])
            try:
                project.add_branch(self.get_argument('branch'))
                project.save()
                log.msg('Project created:', project.name)
                reactor.callInThread(forceBuild, project.name)
            except Exception, e:
                log.err()
                self.write(cyclone.escape.json_encode({'status': "fail"}))

            self.write(cyclone.escape.json_encode({'status': 'ok'}))
        else:
            self.write(cyclone.escape.json_encode({'status':  "Project already exists"}))

    def put(self, name):
        project = Projects(name)
        if not self.request.arguments.has_key('build'):
            for name, arg in self.request.arguments.iteritems():
                setattr(project, name, arg[0])
            try:
                project.save()
                self.finish(cyclone.escape.json_encode({'status': 'build scheduled'}))
            except Exception, e:
                log.err(e)
                self.finish(cyclone.escape.json_encode({'status': 'fail'}))
        reactor.callInThread(forceBuild, project.name)
    
    def get(self, name):
        try:
            project = Projects(name)
        except Exception, e:
            self.write(cyclone.escape.json_encode("%s No project found" % e))
        self.write(cyclone.escape.json_encode({'name': project.name, 
                'git_url': project.git_url, 
                'version': project.version,
                'last_tag': project.last_tag,
                'last_commit': project.last_commit}))


    def delete(self, name):
        try:
            project = Projects(name)
            project.delete()
        except Exception, e:
            log.err(e)


class Branch(cyclone.web.RequestHandler):
    def get(self, project_name):
        project = Projects(project_name)
        branches = project.branches()
        self.write(cyclone.escape.json_encode({'branches': branches}))

    def post(self, project_name):
        branch = self.get_argument('branch')
        project = Projects(project_name)
        if branch in project.branches():
            self.write(cyclone.escape.json_encode({'status': 'failed: branch already exist'}))
        else:
            project.add_branch(branch)
            forceBuild(project.name, branch)
            self.write(cyclone.escape.json_encode({'status': 'ok'}))

restApp = cyclone.web.Application([
    (r'/project', Project),
    (r'/project/(.*)', Project),
    (r'/branch/(.*)', Branch),
])

