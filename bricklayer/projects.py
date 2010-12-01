import redis

def transaction(method):
    def new(*args, **kwargs):
        args[0].redis_cli = args[0].connect()
        ret = method(*args, **kwargs)
        args[0].redis_cli.connection.disconnect()
        return ret
    return new

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
        self.redis_cli = None
    
    @transaction
    def exists(self):
        res = self.redis_cli.exists('project:%s' % self.name)
        return res

    def connect(self):
        return redis.Redis()

    def __dir__(self):
        return ['name', 'git_url', 'install_cmd', 'build_cmd', 'email', 'username', 'release']
    
    @transaction
    def save(self):
        data = {}
        for attr in self.__dir__():
            data[attr] = getattr(self, attr)
        self.redis_cli.hmset("project:%s" % self.name, data)
        self.populate(self.name)
    
    @transaction
    def populate(self, name):
        res = self.redis_cli.hgetall("project:%s" % name)
        for key, val in res.iteritems():
            key = key.replace('project:', '')
            setattr(self, key, val)
    
    @transaction
    def add_branch(self, branch):
        self.redis_cli.rpush('branches:%s' % self.name, branch)
     
    @transaction
    def remove_branch(self, branch):
        index = self.redis_cli.lindex('branches:%s' % self.name, branch)
        self.redis_cli.lrem('branches:%s' % self.name, index)
    
    @transaction
    def repository(self, repository='', user='', passwd=''):
        if repository and user and passwd:
            res = self.redis_cli.set("repository:%s" % self.name, repository)
            self.redis_cli.set("repository:%s:user" % self.name, user) 
            self.redis_cli.set("repository:%s:passwd" % self.name, passwd) 
        else:
            res = []
            res.append(self.redis_cli.get("repository:%s" % self.name))
            res.append(self.redis_cli.get("repository:%s:user" % self.name))
            res.append(self.redis_cli.get("repository:%s:passwd" % self.name))
        return res

    @transaction
    def branches(self):
        res = self.redis_cli.lrange('branches:%s' % self.name, 0, self.redis_cli.llen('branches:%s' % self.name) - 1)
        if len(res) == 0:
            res.append('master')
        return res

    @transaction
    def last_commit(self, branch='master', commit=''):
        if commit == '':
            res = self.redis_cli.get('branches:%s:%s:last_commit' % (self.name, branch))
        else:
            res = self.redis_cli.set('branches:%s:%s:last_commit' % (self.name, branch), commit)
        return res

    @transaction
    def last_tag(self, tag_type='', tag=''):
        if tag:
            res = self.redis_cli.set('tags:%s:%s:last_tag' % (self.name, tag_type), tag)
        else:
            res = self.redis_cli.get('tags:%s:%s:last_tag' % (self.name, tag_type))
        return res

    @transaction
    def version(self, branch='master', version=''):
        if version == '':
            res = self.redis_cli.get('branch:%s:%s:version' % (self.name, branch))
        else:
            res = self.redis_cli.set('branch:%s:%s:version' % (self.name, branch), version)
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

