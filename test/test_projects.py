import sys, os
from nose.tools import *

sys.path.append('../')
sys.path.append('../utils')
os.chdir('test')

from projects import Projects

class project_test:
     
    def create_project_test(self):
        p = Projects(name='test', git_url='git://localhost')
        p.save()
        assert_not_equal(None, p.id)
        assert_equal(Projects().get_all().count(), 1)
     

    def get_all_projects_test(self):
        p1 = Projects(name='test', git_url='git://localhost')
        p1.save()

        p2 = Projects(name='test', git_url='git://localhost')
        p2.save()

        assert_true(Projects().get_all().count() >= 2)
        
