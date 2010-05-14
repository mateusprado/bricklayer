import os, subprocess, logging

class Git:

    def __init__(self, project, workdir='workspace'):
        self.workdir = os.path.join(workdir, project.name)
        self.project = project

    def _exec_git(self, cmd=[], cwd='.'):
        return subprocess.Popen(cmd, cwd=cwd, stdout=open('/dev/null', 'w'))

    def clone(self):
        git_cmd = self._exec_git(['git', 'clone', self.project.git_url, self.workdir])
        git_cmd.wait()
    
    def pull(self):
        git_cmd = self._exec_git(['git', 'pull'], cwd=self.workdir)
        git_cmd.wait()
        
    def last_commit(self):
        return open(os.path.join(self.workdir, '.git', 'refs', 'heads', 'master')).read()

    def list_tags(self):
        tagdir = os.path.join(self.workdir, '.git', 'refs', 'tags')
        return os.listdir(tagdir)

    def create_tag(self, tag=''):
        self._exec_git(['git', 'tag', str(tag)], cwd=self.workdir)

    def push_tags(self):
        pass
