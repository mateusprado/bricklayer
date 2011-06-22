import os
import signal
import sys

sys.path.append(os.path.dirname(__file__))
from projects import Projects
from groups import Groups
from builder import Builder
from build_info import BuildInfo
from config import BrickConfig

import cyclone.web
import cyclone.escape
from twisted.internet import reactor
from twisted.python import log
from dreque import Dreque


brickconfig = BrickConfig()

queue = Dreque(brickconfig.get('redis', 'redis-server'))

class Project(cyclone.web.RequestHandler):
    def post(self, *args):
        if args[0]:
            name = args[0]
            project = Projects(name)
            for key, value in self.request.arguments.iteritems():
                if key in ("git_url", "version", "build_cmd", "install_cmd"):
                    setattr(project, key, value[0])
            project.save()

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
                project.group_name = self.get_argument('group_name')
                project.save()
                log.msg('Project created:', project.name)
                reactor.callInThread(queue.enqueue, 'build', 'builder.build_project', {'project': project.name, 'branch': self.get_argument('branch'), 'force': True})
                self.write(cyclone.escape.json_encode({'status': 'ok'}))
            except Exception, e:
                log.err()
                self.write(cyclone.escape.json_encode({'status': "fail"}))

        else:
            self.write(cyclone.escape.json_encode({'status':  "Project already exists"}))

    def put(self, name):
        branch = 'master'
        project = Projects(name)

        for aname, arg in self.request.arguments.iteritems():
            if aname in ('branch'):
                branch = arg
            else:
                setattr(project, aname, arg[0])
        try:
            project.save()
            self.finish(cyclone.escape.json_encode({'status': 'build scheduled'}))
        except Exception, e:
            log.err(e)
            self.finish(cyclone.escape.json_encode({'status': 'fail'}))
        reactor.callInThread(queue.enqueue, 'build', 'builder.build_project', {'project': project.name, 'branch': self.get_argument('branch'), 'force': True})
    
    def get(self, name='', branch='master'):
        try:
            if name:
                    project = Projects(name)
                    reply = {'name': project.name, 
                            'branch': project.branches(),
                            'group_name': project.group_name,
                            'git_url': project.git_url, 
                            'version': project.version(),
                            'last_tag_testing': project.last_tag(tag_type='testing'),
                            'last_tag_stable': project.last_tag(tag_type='stable'),
                            'last_commit': project.last_commit(branch)}
                    

            else:
                projects = Projects.get_all()
                reply = []
                for project in projects:
                    reply.append(
                            {'name': project.name, 
                            'branch': project.branches(),
                            'group_name': project.group_name,
                            'git_url': project.git_url, 
                            'version': project.version(),
                            'last_tag_testing': project.last_tag(tag_type='testing'),
                            'last_tag_stable': project.last_tag(tag_type='stable'),
                            'last_commit': project.last_commit(branch)
                            })

            self.write(cyclone.escape.json_encode(reply))
        except Exception, e:
            self.write(cyclone.escape.json_encode("%s No project found" % e))


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
            project.version(branch, '0.1')
            reactor.callInThread(queue.enqueue, 'build', 'builder.build_project', {'project': project.name, 'branch': self.get_argument('branch'), 'force': True})
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
        reactor.callInThread(queue.enqueue, 'build', 'builder.build_project', {'project': project.name, 'branch': self.get_argument('branch'), 'force': True})
        self.write(cyclone.escape.json_encode({'status': 'build of branch %s scheduled' % branch}))

    def get(self, project_name):
        project = project_name
        build_ids = BuildInfo(project, -1).builds()
        builds = []
        for bid in build_ids[:10]:
            build = BuildInfo(project, bid)
            builds.append({'build': int(bid), 'log': os.path.basename(build.log()), 'version': build.version(), 'date': build.time()})
        self.write(cyclone.escape.json_encode(builds))

class Log(cyclone.web.RequestHandler):
    def get(self, project, build):
        build_info = BuildInfo(project, build)
        if os.path.isfile(build_info.log()):
            self.write(open(build_info.log()).read())

class Check(cyclone.web.RequestHandler):
    def post(self, project_name):
        project = Projects(project_name)
        builder = Builder(project_name)
        builder.build_project()

class Group(cyclone.web.RequestHandler):
    def post(self, *args):
        if args[0]:
            name = args[0]
            group = Groups(name)
            for key, value in self.request.arguments.iteritems():
                if key in ("repo_addr", "repo_user", "repo_passwd"):
                    setattr(group, key, value[0])
            group.save()
        else:
            group = Groups(self.get_argument('name'))
            group.repo_addr = self.get_argument('repo_addr')
            group.repo_user = self.get_argument('repo_user')
            group.repo_passwd = self.get_argument('repo_passwd')
            group.save()
    

    def get(self, *args):
        if len(args) > 1:
            name = args[0]
            groups = [Groups(name)]
        else:
            groups = Groups.get_all()
        groups_json = []
        for group in groups:
            group_json = {}
            for attr in ('name', 'repo_addr', 'repo_user', 'repo_passwd'):
                group_json.update({attr: getattr(group, attr)})
            groups_json.append(group_json)
        self.write(cyclone.escape.json_encode(groups_json))

class Main(cyclone.web.RequestHandler):
    def get(self):
        self.redirect('/static/index.html')


restApp = cyclone.web.Application([
    (r'/project', Project),
    (r'/project/?(.*)', Project),
    (r'/branch/(.*)', Branch),
    (r'/build/(.*)', Build),
    (r'/group/?(.*)', Group),
    (r'/log/(.*)/(.*)', Log),
    (r'/static/(.*)', cyclone.web.StaticFileHandler, {'path': brickconfig.get('static', 'dir')}),
    (r'/repo/(.*)', cyclone.web.StaticFileHandler, {'path': brickconfig.get('workspace', 'dir')}),
    (r'/', Main),
])

