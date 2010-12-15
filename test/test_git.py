import os
import sys
import shutil
import mocker

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
        self.project.git_url = 'test_repo'
        self.project.version = '1.0'
        self.project.branch = 'master'
        self.project.last_tag = ''
        self.project.last_commit = ''
        self.project.build_cmd = 'python setup.py build'
        self.project.build_cmd = 'python setup.py install --root=BUILDROOT'
        self.project.replay()
        self.git = Git(self.project, workdir=os.path.dirname(__file__))
        
    def clone_test(self):
        self.git.clone()
        assert os.path.isdir(git.workdir)
        assert os.path.isdir(os.path.join(git.workdir, '.git'))

    def pull_test(self):
        self.git.pull()
        
