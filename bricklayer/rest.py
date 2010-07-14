from __future__ import with_statement
import os
import signal
import logging
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), 'utils'))
import daemon
import lockfile
import bottle
from bottle import route, request, PasteServer
from projects import Projects
from builder import Builder
_parent_pid = None

@route('/project', method='POST')
def project_post():
    try:
        Projects().get(request.POST['name'])
    except Exception, e:
        project = Projects()
        project.name = request.POST.pop('name')
        project.git_url = request.POST.pop('git_url')

        for name, parm in request.POST.iteritems():
            setattr(project, str(name), parm)

        try:
            project.save()
            logging.info('Project created: %s', project.name)
            os.kill(_parent_pid, signal.SIGHUP)
            return {'status': 'ok'}
        except Exception, e:
            return {'status': "error: %s" % repr(e)}
    else:
        return {'status':  "Project already exists"}

@route('/project/:name', method='PUT')
def project_put(name):
    project = Projects().get(name)
    for name, arg in request.POST.iteritems():
        setattr(project, name, arg)

    try:
        project.save()
        os.kill(_parent_pid, signal.SIGHUP)
        return {'status': 'ok'}
    except Exception, e:
        return {'status': repr(e)}

@route('/project/:name', method='GET')
def project_get(name):
    try:
        project = Projects().get(name)
    except Exception, e:
        return "%s No project found" % e
    return {'name': project.name, 
            'git_utl': project.git_url, 
            'version': project.version,
            'last_tag': project.last_tag,
            'last_commit': project.last_commit}

@route('/project/:name', method='DELETE')
def project_delete(name):
    try:
        project = Projects().get(name)
        project.delete()
    except Exception, e:
        raise e

def run(parent_pid):
    global _parent_pid
    _parent_pid = parent_pid
    bottle.run(host='0.0.0.0')

if __name__ == "__main__":
    run()
