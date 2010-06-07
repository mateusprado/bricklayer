import os
import sys
import shutil
import mocker

os.chdir('test')
sys.path.append('../bricklayer')
sys.path.append('../utils')

from nose.tools import *

from git import Git

def teardown():
    if os.path.isdir('workspace'):
        shutil.rmtree('workspace', ignore_errors=True)


class Git_test:

    def setup(self):

        self.project = mocker.Mocker()
        self.project.name = 'bricklayer'
        self.project.git_url = '..'
        self.project.version = '1.0'
        self.project.replay()

        if not os.path.isdir('workspace'):
            os.makedirs('workspace')

    def clone_test(self):
        git = Git(self.project, workdir='workspace')
        git.clone()
        assert os.path.isdir(git.workdir)
        assert os.path.isdir(os.path.join(git.workdir, '.git'))

    def create_tag_test(self):
        git = Git(self.project, workdir='workspace')
        git.create_tag('testing_tag')
        print ">>>", git.list_tags()
        assert_true('testing_tag' in git.list_tags())


    

