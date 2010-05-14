import bottle
bottle.debug(True)

from bottle import route, request

from projects import Projects
from builder import Builder


@route('/project', method='POST')
def project_post():
    return request.POST

@route('/project/:name', method='GET')
def project_get(name):
    try:
        project = Projects().get(name)
    except Exception, e:
        return "%s No project found" % e
    return {'name': project.name, 'git_utl': project.git_url, 'install_cmd': project.install_cmd}

@route('/project/:name', method='DELETE')
def project_delete(name):
    pass

def run():
    bottle.run(host='0.0.0.0')

if __name__ == "__main__":
    run()
