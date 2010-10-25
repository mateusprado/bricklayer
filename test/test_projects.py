import sys
import os
import ConfigParser
from nose.tools import *

sys.path.append('../bricklayer')
sys.path.append('../bricklayer/utils')

class BrickConfig(object):
    def get(self, category, field):
        print category, field

from projects import Projects
from config import BrickConfig

def setup():
    BrickConfig('config/bricklayer.ini')

class ProjectsTest:
     
    def create_project_test(self):
        p = Projects()
        p.name = 'test'
        p.git_utl = "git://localhost/dummy"
        p.save()
        assert_equal(len(list(Projects.get_all())), 1)
     

    def get_all_projects_test(self):
        p1 = Projects(name='test', git_url='git://localhost')
        p1.save()

        p2 = Projects(name='test', git_url='git://localhost')
        p2.save()

        assert_true(len(list(Projects.get_all())) >= 2)

    def get_name_test(self):
        p1 = Projects(name='name', git_url='..')
        p1.save()
        pp = Projects.get('name')
        assert_equal(pp.name, 'name')

