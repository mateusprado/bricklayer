import os
import logging
import pystache
import subprocess
import time
import glob
import ConfigParser

from git import Git
from config import BrickConfig
from projects import Projects

class Builder:
    def __init__(self, project):
        self.workspace = BrickConfig().get('workspace', 'dir')
	    self.project = Projects.get(project)
        self.workdir = os.path.join(self.workspace, self.project.name) 
        os.chdir(self.workdir)

    def build_project(self):
        git = Git(self.project)
        build = 0
        tags = git.tags()
        
        try:
            if not os.path.isdir(git.workdir):
                git.clone()
            else:
                git.pull()
        except Exception, e:
            logging.error('Could not clone or update repository')
            raise

        tags = git.tags()
        if len(tags) > 0:
            logging.debug('Last tag found: %s', tags[-1])

        last_commit = git.last_commit()

        if len(tags) > 0:
            if self.project.last_tag != tags[-1]:
                self.project.last_tag = tags[-1]
                build = 1

        if self.project.last_commit != last_commit:
            self.project.last_commit = last_commit
            build = 1
        
        if build == 1:
            build = Builder(self.project)
            if self.project.repository_url:
                build.upload_to(repository_url)
            
        self.project.save()

        logging.getLogger('builder').debug('Generating packages for %s on %s', self.project, self.workdir)

        self.rpm()
        self.deb()
        self.upload_to()


    def rpm(self):
        pass

    def deb(self):
        templates = {}
        templates_dir = os.path.join(BrickConfig().get('workspace', 'template_dir'), 'deb')
        
        if not self.project.install_cmd :

            if self.project.install_prefix is None:
                self.project.install_prefix = 'opt'

            self.project.install_cmd = 'cp -r \`ls | grep -v debian\` debian/%s/%s' % (
                    self.project.name, 
                    self.project.install_prefix
                )

        template_data = {
                'name': self.project.name,
                'version': "%s" % (self.project.version),
                'build_cmd': self.project.build_cmd,
                'install_cmd': self.project.install_cmd,
                'username': self.project.username,
                'email': self.project.email,
                'date': time.strftime("%a, %d %h %Y %T %z"),
            }

        debian_dir = os.path.join(self.workdir, 'debian')

        def read_file_data(f):
            template_fd = open(os.path.join(templates_dir, f))
            templates[f] = pystache.template.Template(template_fd.read()).render(context=template_data)
            template_fd.close()

        if not os.path.isdir(debian_dir):

            map(read_file_data, ['changelog', 'control', 'rules'])
            
            os.makedirs(
                    os.path.join(
                        debian_dir, self.project.name, self.project.install_prefix
                        )
                    )

            for filename, data in templates.iteritems():
                open(os.path.join(debian_dir, filename), 'w').write(data)
            
        dch_cmd = subprocess.Popen(['dch', '-i', '** Snapshot commits'], cwd=self.workdir)
        dch_cmd.wait()
        
        for log in Git(self.project).log():
            append_log = subprocess.Popen(['dch', '-a', log], cwd=self.workdir)
            append_log.wait()
        
        self.project.version = open(os.path.join(self.workdir, 'debian/changelog'), 'r').readline().split('(')[1].split(')')[0]
        self.project.save()
            
        dpkg_cmd = subprocess.Popen(
                ['dpkg-buildpackage', '-rfakeroot', 
                    '-k%s' % BrickConfig().get('gpg', 'keyid')],
                cwd=self.workdir
            )
        
        dpkg_cmd.wait()

        clean_cmd = subprocess.Popen(['dh', 'clean'], cwd=self.workdir)
        clean_cmd.wait()

    def upload_to(self):
        changes_file = glob.glob('%s/%s_%s_*.changes' % (self.workspace,self.project.name,self.project.version))[0]
        upload_cmd = subprocess.Popen(['dput',  changes_file])
        upload_cmd.wait()

    def promote_to(self, release):
        self.project.release = release
        self.project.save()
        Git(self.project).create_tag("%s/%s" % (release, self.project.version))
        dch_cmd = subprocess.Popen(['dch', '-r', '--no-force-save-on-release', '-d', release], cwd=self.workdir)
        dch_cmd.wait()
