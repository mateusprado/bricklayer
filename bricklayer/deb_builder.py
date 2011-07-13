import os
import sys
import shutil
import time
import re
import glob
import stat
import logging as log
import subprocess
import ftplib
import pystache
from urlparse import urlparse

from projects import Projects
from config import BrickConfig
from build_info import BuildInfo

from git import Git

class DebBuilder():
    def __init__(self, builder):
        self.builder = builder
        self.project = self.builder.project

    def build(self, branch, last_tag=None):
        templates = {}
        templates_dir = os.path.join(self.builder.templates_dir, 'deb')
        debian_dir = os.path.join(self.builder.workdir, 'debian')
        control_data_original = None
        control_data_new = None

        self.build_info = BuildInfo(self.project.name)
        logfile = os.path.join(self.builder.workspace, 'log', '%s.%s.log' % (self.project.name, self.build_info.build_id))
        self.build_info.log(logfile)
        self.stdout = open(logfile, 'a+')
        self.stderr = self.stdout

        if self.project.install_prefix is None:
            self.project.install_prefix = 'opt'

        if not self.project.install_cmd :

            self.project.install_cmd = 'cp -r \`ls | grep -v debian\` debian/tmp/%s' % (
                    self.project.install_prefix
                )

        template_data = {
                'name': self.project.name,
                'version': "%s" % (self.project.version(branch)),
                'build_cmd': self.project.build_cmd,
                'install_cmd': self.builder.mod_install_cmd,
                'username': self.project.username,
                'email': self.project.email,
                'date': time.strftime("%a, %d %h %Y %T %z"),
            }

        def read_file_data(f):
            template_fd = open(os.path.join(templates_dir, f))
            templates[f] = pystache.template.Template(template_fd.read()).render(context=template_data)
            template_fd.close()

        if not os.path.isdir(debian_dir):

            map(read_file_data, ['changelog', 'control', 'rules'])
            
            os.makedirs( os.path.join( debian_dir, self.project.name, self.project.install_prefix))

            for filename, data in templates.iteritems():
                open(os.path.join(debian_dir, filename), 'w').write(data)
        
        changelog_entry = """%(name)s (%(version)s) %(branch)s; urgency=low

  * Latest commits
  %(commits)s

 -- %(username)s <%(email)s>  %(date)s
"""
        changelog_data = {
                'name': self.project.name,
                'version': self.project.version(branch),
                'branch': branch,
                'commits': '  '.join(self.builder.git.log()),
                'username': self.project.username,
                'email': self.project.email,
                'date': time.strftime("%a, %d %h %Y %T %z"),
            }


        if last_tag != None and last_tag.startswith('stable'):
            self.project.version('stable', last_tag.split('_')[1])
            changelog_data.update({'version': self.project.version('stable'), 'branch': 'stable'})
            self.build_info.version(self.project.version('stable'))

        elif last_tag != None and last_tag.startswith('testing'):
            self.project.version('testing', last_tag.split('_')[1])
            changelog_data.update({'version': self.project.version('testing'), 'branch': 'testing'})
            self.build_info.version(self.project.version('testing'))

        else:
            """
            otherwise it should change the distribution to unstable
            """
            if self.project.version(branch):
                version_list = self.project.version(branch).split('.')
                version_list[len(version_list) - 1] = str(int(version_list[len(version_list) - 1]) + 1)
                self.project.version(branch, '.'.join(version_list))

                changelog_data.update({'version': self.project.version(branch), 'branch': 'unstable'})
            self.build_info.version(self.project.version(branch))

        open(os.path.join(self.builder.workdir, 'debian', 'changelog'), 'w').write(changelog_entry % changelog_data)
        
        rvm_env = {}
        rvm_rc = os.path.join(self.builder.workdir, '.rvmrc')
        rvm_rc_example = rvm_rc +  ".example"
        has_rvm = False

        if os.path.isfile(rvm_rc):
            has_rvm = True
        elif os.path.isfile(rvm_rc_example):
            has_rvm = True
            rvm_rc = rvm_rc_example
        
        if has_rvm:
            rvmexec = open(rvm_rc).read()
            log.info("RVMRC: %s" % rvmexec)
            
            # I need the output not to log on file
            rvm_cmd = subprocess.Popen('/usr/local/bin/rvm info %s' % rvmexec.split()[1],
                    shell=True, stdout=subprocess.PIPE)
            rvm_cmd.wait()
            for line in rvm_cmd.stdout.readlines():
                if 'PATH' in line or 'HOME' in line:
                    name, value = line.split()
                    rvm_env[name.strip(':')] = value.strip('"')
            rvm_env['HOME'] = os.environ['HOME']

        if len(rvm_env.keys()) < 1:
            rvm_env = os.environ
        else:
            try:
                os.environ.pop('PATH')
                os.environ.pop('GEM_HOME')
                os.environ.pop('BUNDLER_PATH')
            except Exception, e:
                pass
            rvm_env.update(os.environ)

        os.chmod(os.path.join(debian_dir, 'rules'), stat.S_IRWXU|stat.S_IRWXG|stat.S_IROTH|stat.S_IXOTH)
        dpkg_cmd = self.builder._exec(
                ['dpkg-buildpackage',  '-rfakeroot', '-tc', '-k%s' % BrickConfig().get('gpg', 'keyid')],
                cwd=self.builder.workdir, env=rvm_env, stdout=self.stdout, stderr=self.stderr
        )
        
        dpkg_cmd.wait()
        
        control = os.path.join(self.builder.workdir, 'debian', 'control')
        if os.path.isfile(control) and control_data_original:
            open(control, 'w').write(control_data_original)

        clean_cmd = self.builder._exec(['dh', 'clean'], cwd=self.builder.workdir)
        clean_cmd.wait()

    def upload(self, branch):
        changes_file = glob.glob('%s/%s_%s_*.changes' % (self.builder.workspace, self.project.name, self.project.version(branch)))[0]
        distribution, files = self.parse_changes(changes_file)
        self.upload_files(distribution, files)
        upload_file = changes_file.replace('.changes', '.upload')
        open(upload_file, 'w').write("done")
        
    def parse_changes(self, changes_file):
        content = open(changes_file).readlines()
        go = 0
        distribution = ""
        tmpfiles = [os.path.basename(changes_file)]
        for line in content:
            if line.startswith('Distribution'):
                distribution = line.strip('\n')
                distribution = distribution.split(':')[1].strip(' ')
            if line.startswith('File'):
                go = 1
            elif not line.startswith('\n') and go == 1:
                tmpname = line.split()
                pos = len(tmpname)
                tmpfiles.append(tmpname[pos-1])
            else: 
                go = 0
        files = []
        for f in tmpfiles:
            filename = f.split()
            files.append(filename[len(filename) - 1])
        return distribution, files

    def upload_files(self, distribution, files):
        repository_url, user, passwd = self.project.repository()
        if not repository_url:
            return 0
        os.chdir(self.builder.workspace)
        ftp = ftplib.FTP(repository_url, user, passwd)
        try:
            ftp.cwd(distribution)
            for f in files:
                log.info("\t%s: " % f)
                ftp.storbinary("STOR %s" % f, open(f, 'rb'))
                log.info("done.")
        except Exception, e:
            log.info(repr(e))
        ftp.quit()

    def promote_to(self, version, release):
        self.project.version(version=version)
        self.project.release = release
        self.project.save()

    def promote_deb(self):
        self.builder.git.create_tag("%s.%s" % (self.project.version(), self.project.release))
        dch_cmd = self.builder._exec(['dch', '-r', '--no-force-save-on-release', '--newversion', '%s.%s' % (self.project.version(), self.project.release)], cwd=self.builder.workdir)
        dch_cmd.wait()

