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
from dreque import Dreque

_dreque = Dreque('127.0.0.1')

class Project(cyclone.web.RequestHandler):
    def post(self, *args):
        try:
            if not Projects(self.get_argument('name')).exists():
                raise
        except Exception, e:
            project = Projects()
            project.name = self.get_argument('name')[0]
            project.git_url = self.get_argument('git_url')[0]
            for name, parm in self.request.arguments.iteritems():
                if name not in ('branch', 'version'):
                    setattr(project, str(name), parm[0])
            try:
                project.add_branch(self.get_argument('branch'))
                project.version(self.get_argument('branch'), self.get_argument('version'))
                project.save()
                if self.request.arguments.has_key('repository_url'):
                    project.repository(self.request.arguments['repository_url'])
                log.msg('Project created:', project.name)
                reactor.callInThread(_dreque.enqueue, 'build', 'builder.build_project', project.name, self.get_argument('branch'), True)
            except Exception, e:
                log.err()
                self.write(cyclone.escape.json_encode({'status': "fail"}))

            self.write(cyclone.escape.json_encode({'status': 'ok'}))
        else:
            self.write(cyclone.escape.json_encode({'status':  "Project already exists"}))

    def put(self, name):
        branch = 'master'
        project = Projects(name)
        for aname, arg in self.request.arguments.iteritems():
            if aname in ('repository_url'):
                project.repository(arg)
            elif aname in ('branch'):
                branch = arg
            else:
                setattr(project, aname, arg[0])
        try:
            project.save()
            self.finish(cyclone.escape.json_encode({'status': 'build scheduled'}))
        except Exception, e:
            log.err(e)
            self.finish(cyclone.escape.json_encode({'status': 'fail'}))
        reactor.callInThread(_dreque.enqueue, 'build', 'builder.build_project', project.name, branch, True)
    
    def get(self, name, branch='master'):
        try:
            project = Projects(name)
        except Exception, e:
            self.write(cyclone.escape.json_encode("%s No project found" % e))
        self.write(cyclone.escape.json_encode({'name': project.name, 
                'git_url': project.git_url, 
                'version': project.version(),
                'last_tag': project.last_tag(branch),
                'last_commit': project.last_commit(branch)}))


    def delete(self, name, branch):
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
            project.version(branch, '0.1')
            reactor.callInThread(_dreque.enqueue, 'build', 'builder.build_project', project.name, branch, True)
            self.write(cyclone.escape.json_encode({'status': 'ok'}))

    def delete(self, project_name):
        project = Projects(project_name)
        branch = self.get_argument('branch')
        project.remove_branch(branch)
        self.write(cyclone.escape.json_encode({'status': 'ok'}))

class Build(cyclone.web.RequestHandler):
    def post(self, project_name):
        project = Projects(project_name)
        branch = self.get_argument('branch')
        reactor.callInThread(_dreque.enqueue, 'build', 'builder.build_project', project.name, branch, True)
        self.write(cyclone.escape.json_encode({'status': 'build of branch %s scheduled' % branch}))

restApp = cyclone.web.Application([
    (r'/project', Project),
    (r'/project/(.*)', Project),
    (r'/branch/(.*)', Branch),
    (r'/build/(.*)', Build),
])

