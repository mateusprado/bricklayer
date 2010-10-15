import redis
from twisted.internet import defer
from twisted.internet import reactor
from twisted.internet import protocol

class Projects:

    def __init__(self, name='', git_url='', install_cmd='', build_cmd='', version='', release=''):
        self.name = name
        self.git_url = git_url
        self.install_cmd = install_cmd
        self.build_cmd = build_cmd
        self.version = version
        self.release = release
        self.email = 'bricklayer@locaweb.com.br'
        self.username = 'Bricklayer Builder'
        self.install_prefix = ''
        self.populate(self.name)
    
    def connect(self):
        return redis.Redis()

    def __dir__(self):
        return ['name', 'git_url', 'install_cmd', 'build_cmd', 'version', 'email', 'username', 'release']
    
    def lock(self):
        redis_cli = self.connect()
        redis_cli.incr('lock:%s', self.name)
        redis_cli.connection.disconnect()

    def unlock(self):
        redis_cli = self.connect()
        redis_cli.incr('lock:%s', self.name)
        redis_cli.connection.disconnect()
    
    def locked(self):
        redis_cli = self.connect()
        res = redis_cli.get('lock:%s', self.name)
        redis_cli.connection.disconnect()
        if res > 0:
            return True
        else:
            return False

    def save(self):
        redis_cli = self.connect()
        data = {}
        for attr in self.__dir__():
            data[attr] = getattr(self, attr)
        redis_cli.hmset("project:%s" % self.name, data)
        self.populate(self.name)
        redis_cli.connection.disconnect()
    
    def populate(self, name):
        redis_cli = self.connect()
        res = redis_cli.hgetall("project:%s" % name)
        for key, val in res.iteritems():
            key = key.replace('project:', '')
            setattr(self, key, val)
    
    def add_branch(self, branch):
        redis_cli = self.connect()
        redis_cli.rpush('branches:%s' % self.name, branch)

    def branches(self):
        redis_cli = self.connect()
        res = redis_cli.lrange('branches:%s' % self.name, 0, redis_cli.llen('branches:%s' % self.name) - 1)
        if len(res) == 0:
            res.append('master')
        return res

    def last_commit(self, branch, commit=''):
        redis_cli = self.connect()
        if commit == '':
            res = redis_cli.get('branches:%s:%s:last_commit' % (self.name, branch))
        else:
            res = redis_cli.set('branches:%s:%s:last_commit' % (self.name, branch), commit)
        return res

    def last_tag(self, branch, tag=''):
        redis_cli = self.connect()
        if tag == '':
            res = redis_cli.get('branches:%s:%s:last_tag' % (self.name, branch))
        else:
            res = redis_cli.set('branches:%s:%s:last_tag' % (self.name, branch), tag)
        return res

    @classmethod
    def get_all(self):
        connection_obj = Projects()
        redis_cli = connection_obj.connect()
        keys = redis_cli.keys('project:*')
        projects = []
        redis_cli.connection.disconnect()
        for key in keys:
            key = key.replace('project:', '')
            projects.append(Projects(key)) 
        return projects

