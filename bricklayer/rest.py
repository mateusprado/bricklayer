from __future__ import with_statement
import os
import signal
import logging
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), 'utils'))
sys.path.append(os.path.dirname(__file__))

from bottle import route, request, PasteServer
from projects import Projects
from builder import Builder

@route('/project', method='POST')
def project_post():
    try:
        Projects().get(request.POST['name'])
    except Exception, e:
        project = Projects()
        builder = Builder(project.name)
        project.name = request.POST.pop('name')
        project.git_url = request.POST.pop('git_url')

        for name, parm in request.POST.iteritems():
            setattr(project, str(name), parm)

        try:
            project.save()
            logging.info('Project created: %s', project.name)
            builder.build_project(force=True)            
            logging.info('Project %s build is done', project.name)
            return {'status': 'ok'}
        except Exception, e:
            logging.exception(repr(e))
            return {'status': "fail"}
    else:
        return {'status':  "Project already exists"}

@route('/project/:name', method='PUT')
def project_put(name):
    project = Projects().get(name)
    builder = Builder(project.name)
    for name, arg in request.POST.iteritems():
        setattr(project, name, arg)

    try:
        project.save()
        builder.build_project(force=True)
        return {'status': 'ok'}
    except Exception, e:
        logging.exception(repr(e))
        return {'status': 'fail'}

@route('/project/:name', method='GET')
def project_get(name):
    try:
        project = Projects().get(name)
    except Exception, e:
        return "%s No project found" % e
    return {'name': project.name, 
            'git_url': project.git_url, 
            'version': project.version,
            'last_tag': project.last_tag,
            'last_commit': project.last_commit}

@route('/project/:name', method='DELETE')
def project_delete(name):
    try:
        project = Projects().get(name)
        project.delete()
    except Exception, e:
        logging.exception(repr(e))

def run():
    bottle.run(host='0.0.0.0')

