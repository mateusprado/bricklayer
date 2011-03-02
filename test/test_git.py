import os
import sys
import shutil
import mocker

sys.path.append('..')
sys.path.append('../utils')

from nose.tools import *
from bricklayer.git import Git

def setup():
    if not os.path.isdir('workspace'):
        os.mkdir('workspace')

def teardown():
    if os.path.isdir('workspace'):
        shutil.rmtree('workspace', ignore_errors=True)
    
class Git_test:
    def __init__(self):
        self.project = mocker.Mocker()
        self.project.name = 'test_repo'
        self.project.git_url = './test_repo'
        self.project.version = '1.0'
        self.project.branch = 'master'
        self.project.last_tag = ''
        self.project.last_commit = ''
        self.project.build_cmd = 'python setup.py build'
        self.project.install_cmd = 'python setup.py install --root=BUILDROOT'
        self.project.replay()
        self.git = Git(self.project, workdir=os.path.join(os.path.dirname(__file__), 'workspace'))

        if not os.path.isdir(self.git.workdir):
            self.git.clone(self.project.branch)

    def clone_test(self):
        assert os.path.isdir(self.git.workdir)
        assert os.path.isdir(os.path.join(self.git.workdir, '.git'))

    def checkout_tag_test(self):
        self.git.checkout_tag('test_1')
        assert_true(os.path.isfile(os.path.join(self.git.workdir, 'a')))
        assert_false(os.path.isfile(os.path.join(self.git.workdir, 'b')))
        self.git.checkout_tag('test_2')
        assert_true(os.path.isfile(os.path.join(self.git.workdir, 'b')))
    
    def last_tag_test(self):
        assert_equal(self.git.last_tag('testing'), 'testing_0.0.2')
