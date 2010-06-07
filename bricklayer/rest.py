import bottle, os, signal
bottle.debug(True)

from bottle import route, request

from projects import Projects
from builder import Builder

@route('/project', method='POST')
def project_post():
    try:
        Projects().get(request.POST['name'])
    except Exception, e:
        project = Projects()
        project.name = request.POST.pop('name')
        project.git_url = request.POST.pop('git_url')
        project.install_cmd = request.POST.pop('install_cmd')

        for name, parm in request.POST.iteritems():
            projects.setattr(name, parm)

        try:
            project.save()
            os.kill(os.getpid(), signal.SIGHUP)
            return {'status': 'ok'}
        except Exception, e:
            return {'status': repr(e)}
    else:
        return {'status':  "Project already exists"}

@route('/project/:name', method='PUT')
def project_put(name):
    project = Projects().get(name)
    for name, arg in request.POST.iteritems():
        setattr(project, name, arg)

    try:
        project.save()
        os.kill(os.getpid(), signal.SIGHUP)
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
            'install_cmd': project.install_cmd, 
            'last_commit': project.last_commit}

@route('/project/:name', method='DELETE')
def project_delete(name):
    try:
        project = Projects().get(name)
        project.delete()
    except Exception, e:
        raise e

def run():
    bottle.run(host='0.0.0.0')

if __name__ == "__main__":
    run()
