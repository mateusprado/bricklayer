import os
import logging
import pystache
import subprocess
import time

class Builder:
    def __init__(self, project):
        self.project = project
        logging.getLogger('builder').debug('Building project %s', self.project)
        self.rpm()
        self.deb()

    def rpm(self):
        pass

    def deb(self):
        templates = {}
        templates_dir = 'pkg_template/deb'
        
        if not self.project.install_cmd :

            if self.project.install_prefix is None:
                self.project.install_prefix = 'opt'

            self.project.install_cmd = 'cp -r $(ls | grep -v debian) debian/%s/%s' % (
                    self.project.name, 
                    self.project.install_prefix
                )

        template_data = {
                'name': self.project.name,
                'version': "%s-%s" % (self.project.version, self.project.last_build),
                'build_cmd': self.project.build_cmd,
                'install_cmd': self.project.install_cmd,
                'username': self.project.username,
                'email': self.project.email,
                'date': time.strftime("%a, %d %h %Y %T %z"),
            }

        workdir = os.path.join('workspace', self.project.name) 
        debian_dir = os.path.join(workdir, 'debian')

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
            
        dch_cmd = subprocess.Popen(['git-dch', '-s', 'HEAD^', '-S'], cwd=workdir)
        dch_cmd.wait()
        
        dpkg_cmd = subprocess.Popen(
                ['dpkg-buildpackage', '-rfakeroot'], 
                cwd=workdir
            )
        
        dpkg_cmd.wait()

    def upload_to(self):
        pass

