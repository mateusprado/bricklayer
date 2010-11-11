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
        if version:
            self.version(version=version)
        self.release = release
        self.email = 'bricklayer@locaweb.com.br'
        self.username = 'Bricklayer Builder'
        self.install_prefix = ''
        self.populate(self.name)
    
    def exists(self):
        redis_cli = self.connect()
        res = redis_cli.exists('project:%s' % self.name)
        redis_cli.connection.disconnect()
        return res

    def connect(self):
        return redis.Redis()

    def __dir__(self):
        return ['name', 'git_url', 'install_cmd', 'build_cmd', 'email', 'username', 'release']
    
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
        redis_cli.connection.disconnect()
    
    def add_branch(self, branch):
        redis_cli = self.connect()
        redis_cli.rpush('branches:%s' % self.name, branch)
        redis_cli.connection.disconnect()
     
    def remove_branch(self, branch):
        redis_cli = self.connect()
        index = redis_cli.lindex('branches:%s' % self.name, branch)
        redis_cli.lrem('branches:%s' % self.name, index)
        redis_cli.connection.disconnect()
    
    def repository(self, repository='', user='', passwd=''):
        redis_cli = self.connect()
        if repository and user and passwd:
            res = redis_cli.set("repository:%s" % self.name, repository)
            redis_cli.set("repository:%s:user" % self.name, user) 
            redis_cli.set("repository:%s:passwd" % self.name, passwd) 
        else:
            res = redis_cli.get("repository:%s" % self.name)
            res += redis_cli.get("repository:%s:user" % self.name)
            res += redis_cli.get("repository:%s:passwd" % self.name)
        redis_cli.connection.disconnect()
        return res

    def branches(self):
        redis_cli = self.connect()
        res = redis_cli.lrange('branches:%s' % self.name, 0, redis_cli.llen('branches:%s' % self.name) - 1)
        if len(res) == 0:
            res.append('master')
        return res
        redis_cli.connection.disconnect()

    def last_commit(self, branch='master', commit=''):
        redis_cli = self.connect()
        if commit == '':
            res = redis_cli.get('branches:%s:%s:last_commit' % (self.name, branch))
        else:
            res = redis_cli.set('branches:%s:%s:last_commit' % (self.name, branch), commit)
        redis_cli.connection.disconnect()
        return res

    def last_tag(self, tag='', tag_type=''):
        redis_cli = self.connect()
        if tag == '':
            res = redis_cli.get('tags:%s:%s:last_tag' % (self.name, tag_type))
        else:
            res = redis_cli.set('tags:%s:%s:last_tag' % (self.name, tag_type), tag)
        redis_cli.connection.disconnect()
        return res

    def version(self, branch='master', version=''):
        redis_cli = self.connect()
        if version == '':
            res = redis_cli.get('branch:%s:%s:version' % (self.name, branch))
        else:
            res = redis_cli.set('branch:%s:%s:version' % (self.name, branch), version)
        redis_cli.connection.disconnect()
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

