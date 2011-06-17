import redis
from model_base import ModelBase, transaction

class Groups(ModelBase):
    namespace = 'group'
  
    def __init__(self, group_name='', repo_addr='', repo_user='', repo_passwd=''):
        self.name = group_name
        self.repo_addr = repo_addr
        self.repo_user = repo_user
        self.repo_passwd = repo_passwd
        self.populate(self.name)

    def __dir__(self):
        return ['name', 'repo_addr', 'repo_user', 'repo_passwd']
   
    @classmethod
    def get_all(self):
        connection_obj = Groups()
        redis_cli = connection_obj.connect()
        keys = redis_cli.keys('%s:*' % self.namespace)
        groups = []
        redis_cli.connection.disconnect()
        for key in keys:
            key = key.replace('%s:' % self.namespace, '')
            groups.append(Groups(key)) 
        return groups
