import os, shutil
from nose import *

from git import Git

class Git_test:

    def teardown(self):
        if os.path.isdir('test/workspace'):
            shutil.rmtree('test/workspace', ignore_errors=True)

    def setup(self):
        if not os.path.isdir('test/workspace'):
            os.makedirs('test/workspace')

    def clone_test(self):
        project = Projects(
                name='rest',
                url='git://git.locaweb.com.br/iphandler/iphandler.git'
            )
        git = Git(project, workdir='test/workspace')
        git.clone()
        assert os.path.isdir(git.workdir)
        assert os.path.isdir(os.path.join(git.workdir, '.git'))
    

