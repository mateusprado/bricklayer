import os
import logging
import pystache
import subprocess
import time
import ConfigParser

from git import Git
from config import BrickConfig

class Builder:
    def __init__(self, project):
        try:
            _workspace = BrickConfig().get('workspace', 'dir')
            self.project = project
            self.workdir = os.path.join(_workspace, self.project.name) 
            os.chdir(self.workdir)

            logging.getLogger('builder').debug('Building project %s on %s', self.project, self.workdir)
            self.rpm()
            self.deb()
            self.upload_to()

        except Exception, e: 
            raise e

    def rpm(self):
        pass

    def deb(self):
        templates = {}
        templates_dir = os.path.join(BrickConfig().get('workspace', 'template_dir'), 'deb')
        
        if not self.project.install_cmd :

            if self.project.install_prefix is None:
                self.project.install_prefix = 'opt'

            self.project.install_cmd = 'cp -r $(ls | grep -v debian) debian/%s/%s' % (
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

        map(read_file_data, ['changelog', 'control', 'rules'])
        
        if not os.path.isdir(debian_dir):

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
        upload_cmd = subprocess.Popen(['dput', '%s_%s_*.changes' % (self.project.name,self.project.version) ])
        upload_cmd.wait()

    def promote_to(self, release):
        self.project.release = release
        self.project.save()
        Git(self.project).create_tag("%s/%s" % (release, self.project.version))
        dch_cmd = subprocess.Popen(['dch', '-r', '--no-force-save-on-release', '-d', release], cwd=self.workdir)
        dch_cmd.wait()
