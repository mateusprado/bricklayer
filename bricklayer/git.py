import os 
import subprocess
import re
from twisted.python import log
from config import BrickConfig

class Git(object):
    def __init__(self, project, workdir=None, branch='master'):
        _workdir = workdir
        if not _workdir:
            _workdir = BrickConfig().get('workspace', 'dir')

        self.workdir = os.path.join(_workdir, project.name)
        self.project = project
        self.branch = branch

    def _exec_git(self, cmd=[], cwd='.', stdout=None):
        if stdout is None:
            stdout = open('/dev/null', 'w')
        return subprocess.Popen(cmd, cwd=cwd, stdout=stdout)

    def _sort_tags(self, tag):
        if tag != None:
            match = re.match(".*?[-/](\d+)", tag)
            if match:
                return match.group(1)

    def clone(self):
        log.msg("Git clone")
        git_cmd = self._exec_git(['git', 'clone', self.project.git_url, self.workdir])
        git_cmd.wait()
    
    def pull(self):
        git_cmd = self._exec_git(['git', 'pull'], cwd=self.workdir)
        git_cmd.wait()
    
    def checkout(self, tag='master'):
        git_cmd = self._exec_git(['git', 'checkout', tag], cwd=self.workdir)
        git_cmd.wait()

    def last_commit(self):
        return open(os.path.join(self.workdir, '.git', 'refs', 'heads', 'master')).read()

    def tags(self):
        try:
            tagdir = os.path.join(self.workdir, '.git', 'refs', 'tags')
            tags = os.listdir(tagdir)
            return sorted(tags, key=self._sort_tags)
        except Exception, e:
            log.err(repr(e))
            log.err()
            return []

    def create_tag(self, tag=''):
        git_cmd = self._exec_git(['git', 'tag', str(tag)], cwd=self.workdir)
        git_cmd.wait()

    def log(self, number=3):
        git_cmd = self._exec_git(['git', 'log', '-n', str(number),
             '--pretty=oneline', '--abbrev-commit'], cwd=self.workdir, stdout=subprocess.PIPE)
        git_cmd.wait()
        return git_cmd.stdout.readlines()

    def push_tags(self):
        git_cmd = self._exec_git(['git', 'push', '--tags'])
        git_cmd.wait()
