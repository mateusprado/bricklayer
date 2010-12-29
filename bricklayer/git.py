import os 
import subprocess
import re
import shutil
import logging as log
from config import BrickConfig

class Git(object):
    def __init__(self, project, workdir=None):
        _workdir = workdir
        if not _workdir:
            _workdir = BrickConfig().get('workspace', 'dir')

        self.workdir = os.path.join(_workdir, project.name)
        self.project = project

    def _exec_git(self, cmd=[], cwd='.', stdout=None):
        if stdout is None:
            stdout = open('/dev/null', 'w')
        return subprocess.Popen(cmd, cwd=cwd, stdout=stdout)

    def clone(self, branch):
        log.info("Git clone %s" % self.project.git_url)
        git_cmd = self._exec_git(['git', 'clone', self.project.git_url, self.workdir])
        git_cmd.wait()
        if branch:
            self.checkout_branch(branch)
    
    def pull(self):
        git_cmd = self._exec_git(['git', 'pull'], cwd=self.workdir)
        git_cmd.wait()
    
    def checkout_tag(self, tag='master'):
        git_cmd = self._exec_git(['git', 'checkout', tag], cwd=self.workdir)
        git_cmd.wait()
    
    def checkout_branch(self, branch):
        if branch in self.branches():
            git_cmd = self._exec_git(['git', 'checkout', branch], cwd=self.workdir)
            git_cmd.wait()
        elif branch != '' and branch != 'master':
            git_cmd = self._exec_git(['git', 'checkout', '-b', branch, '--track', 'origin/%s' % branch], cwd=self.workdir)
            git_cmd.wait()

    def branches(self):
        branches_dir = os.path.join(self.workdir, '.git', 'refs', 'heads')
        return os.listdir(branches_dir)

    def last_commit(self, branch='master'):
        log.info(">>> %s" % branch)
        return open(os.path.join(self.workdir, '.git', 'refs', 'heads', branch)).read()

    def last_tag(self, tag_type):
        tags = self.tags(tag_type)
        check = []
        for tag in tags:
            tag_v = tag.split('_')[1]
            check.append(map(int, tag_v.split('.')))
        if len(check) > 0:
            return tag_type + "_%d.%d.%d" % tuple(max(check))
        else:
            return ''

    def tags(self, tag_type):
        try:
            git_cmd = self._exec_git(['git', 'tag', '-l'], stdout=subprocess.PIPE, cwd=self.workdir)
            git_cmd.wait()
            tags = git_cmd.stdout.readlines()
            result = []
            if tag_type:
                for t in tags:
                    if t.startswith(tag_type):
                        result.append(t.strip('\n'))
            else:
                for t in tags:
                    result.append(t.strip('\n'))
            return result

        except Exception, e:
            log.exception(repr(e))
            return []

    def create_tag(self, tag=''):
        git_cmd = self._exec_git(['git', 'tag', str(tag)], cwd=self.workdir)
        git_cmd.wait()

    def create_branch(self, branch=''):
        git_cmd = self._exec_git(['git', 'checkout', '-b', branch], cwd=self.workdir)
        git_cmd.wait()

    def log(self, number=3):
        git_cmd = self._exec_git(['git', 'log', '-n', str(number),
             '--pretty=oneline', '--abbrev-commit'], cwd=self.workdir, stdout=subprocess.PIPE)
        git_cmd.wait()
        return git_cmd.stdout.readlines()

    def push_tags(self):
        git_cmd = self._exec_git(['git', 'push', '--tags'])
        git_cmd.wait()
