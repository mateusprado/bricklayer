import redis
import time

def transaction(method):
    def new(*args):
        args[0].redis_cli = args[0].connect()
        ret = method(*args)
        args[0].redis_cli.connection.disconnect()
        return ret
    return new

class BuildInfo:

    def __init__(self, project='', build_id=0):
        self.redis_cli = self.connect()
        self.project = project
        if project and build_id == 0:
            self.build_id = self.redis_cli.incr('build:%s' % project)
            self.redis_cli.rpush('build:%s:list' % project, self.build_id)
            self.redis_cli.set('build:%s:time' % self.build_id, time.strftime('%d/%m/%Y %H:%M', time.localtime(time.time())))
        if build_id > 0:
            self.build_id = build_id

    def __dir__(self):
        return []
    
    @transaction
    def time(self, version=''):
        return self.redis_cli.get('build:%s:time' % self.build_id)

    @transaction
    def version(self, version=''):
        if version:
            return self.redis_cli.set('build:%s:version' % (self.build_id), version) 
        return self.redis_cli.get('build:%s:version' % (self.build_id))

    @transaction
    def log(self, logfile=''):
        if logfile:
            return self.redis_cli.set('build:%s:log' % (self.build_id), logfile) 
        return self.redis_cli.get('build:%s:log' % (self.build_id))

    @transaction
    def builds(self):
        builds = self.redis_cli.lrange('build:%s:list' % self.project, 0, self.redis_cli.llen('build:%s:list' % self.project))
        return builds

    def connect(self):
        return redis.Redis()    
