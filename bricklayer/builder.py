import sys
import os
import stat
import subprocess
import time
import glob
import ConfigParser
import tarfile
import shutil
import re
import ftplib

sys.path.append(os.path.join(os.path.dirname(__file__), 'utils'))

import pystache
import git
from config import BrickConfig
from projects import Projects
from twisted.python import log

class Builder:
    def __init__(self, project):
        self.workspace = BrickConfig().get('workspace', 'dir')
        self.project = Projects(project)
        self.workdir = os.path.join(self.workspace, self.project.name) 
        self.templates_dir = BrickConfig().get('workspace', 'template_dir')
        self.git = git.Git(self.project)
        self.build_system = BrickConfig().get('build', 'system')
        self.ftp_host = BrickConfig().get('ftp', 'host')
        self.ftp_user = BrickConfig().get('ftp', 'user')
        self.ftp_pass = BrickConfig().get('ftp', 'pass')
        self.ftp_dir = BrickConfig().get('ftp', 'dir')
        
        if self.build_system == 'rpm':
            self.mod_install_cmd = self.project.install_cmd.replace(
                'BUILDROOT', '%{buildroot}'
            )
        elif self.build_system == 'deb':
            self.mod_install_cmd = self.project.install_cmd.replace(
                'BUILDROOT', 'debian/tmp'
            )
        
        if not os.path.isdir(self.workspace):
            os.makedirs(self.workspace)
        
        self.stdout = open(self.workspace + '/%s.log' % self.project.name, 'a+')
        self.stderr = self.stdout

    def _exec(self, cmd, *args, **kwargs):
        kwargs.update({'stdout': self.stdout, 'stderr': self.stderr})
        return subprocess.Popen(cmd, *args, **kwargs)

    def dos2unix(self, file):
        f = open(file, 'r').readlines()
        new_file = open(file, "w+")
        match = re.compile('\r\n')
        for line in f:
            new_file.write(match.sub('\n', line))
        new_file.close()

    def build_project(self, force=False, a_branch=None):
        try:
            if force:
                build = 1
            else:
                build = 0
            if a_branch:
                branches = [a_branch]
            else:
                branches = self.project.branches()
            for branch in branches:

                log.msg("Checking project: %s" % self.project.name)
                try:
                    if os.path.isdir(self.git.workdir):
                        self.git.checkout_branch(branch)
                        self.git.pull()
                    else:
                        self.git.clone()
                except Exception, e:
                    log.err()
                    log.err('Could not clone or update repository')
                    raise

                if os.path.isdir(self.workdir):
                    os.chdir(self.workdir)

                tags = self.git.tags(branch)
                last_commit = self.git.last_commit(branch)

                if len(tags) > 0:
                    log.msg('Last tag found: %s' % max(tags))
                    if self.project.last_tag(branch) != max(tags):
                        self.project.last_tag(branch, max(tags))
                        self.git.checkout_tag(self.project.last_tag(branch))
                        build = 1

                if self.project.last_tag(branch) == None and self.project.last_commit(branch) != last_commit:
                    self.project.last_commit(branch, last_commit)
                    build = 1
                    
                self.project.save()

                if build == 1:
                    log.msg('Generating packages for %s on %s'  % (self.project, self.workdir))
                    if self.build_system == 'rpm':
                        self.rpm()
                        self.upload_rpm()

                    elif self.build_system == 'deb':
                        self.deb(branch)
                        self.upload_to(branch)
                    log.msg("build complete")

                #self.git.checkout_tag('master') 
            
        except Exception, e:
            log.err()
            log.err("build failed: %s" % repr(e))

    def rpm(self):
        rpm_dir = os.path.join(self.workspace, 'rpm')
        templates_dir = os.path.join(self.templates_dir, 'rpm')
        spec_filename = os.path.join(rpm_dir, 'SPECS', "%s.spec" % self.project.name)
        dir_prefix = "%s-%s" % (self.project.name, self.project.version)

        for dir in ('SOURCES', 'SPECS', 'RPMS', 'SRPMS', 'BUILD', 'TMP'):
            if not os.path.isdir(os.path.join(rpm_dir, dir)):
                os.makedirs(os.path.join(rpm_dir, dir))
        
        build_dir = os.path.join(rpm_dir, 'TMP', self.project.name)
        
        if not os.path.isdir(build_dir):
            os.makedirs(build_dir)

        source_file = os.path.join(rpm_dir, 'SOURCES', '%s.tar.gz' % dir_prefix)

        cur_dir = os.getcwd()
        os.chdir(self.workspace)

        if os.path.isdir(dir_prefix):
            shutil.rmtree(dir_prefix)

        shutil.copytree(self.project.name, dir_prefix)

        if os.path.isfile(source_file):
            os.unlink(source_file)

        tar = tarfile.open(source_file, 'w:gz')
        tar.add(dir_prefix)
        tar.close()
        shutil.rmtree(dir_prefix)
        os.chdir(cur_dir)

        if self.project.release is None or self.project.release is 0:
            self.project.release = 1
        elif self.project.release >= 1:
            self.project.release = "%s" % (int(self.project.release) + 1)

        if self.project.install_prefix is None:
            self.project.install_prefix = 'opt'

        if not self.project.install_cmd:

            self.project.install_cmd = 'cp -r \`ls | grep -Ev "debian|rpm"\` %s/%s/%s' % (
                    self.build_dir,
                    self.project.install_prefix,
                    self.project.name
                )

        template_data = {
                'name': self.project.name,
                'version': "%s" % (self.project.version),
                'release': "%s" % (self.project.release),
                'build_dir': build_dir,
                'build_cmd': self.project.build_cmd,
                'install_cmd': self.mod_install_cmd,
                'username': self.project.username,
                'email': self.project.email,
                'date': time.strftime("%a %h %d %Y"),
                'git_url': self.project.git_url,
                'source': source_file,
            }

        rvm_rc = os.path.join(self.workdir, '.rvmrc')
        rvm_rc_example = rvm_rc +  ".example"
        has_rvm = False

        if os.path.isfile(rvm_rc):
            has_rvm = True
        elif os.path.isfile(rvm_rc_example):
            has_rvm = True
            rvm_rc = rvm_rc_example
        
        if has_rvm:
            rvmexec = open(rvm_rc).read()
            log.msg("RVMRC: %s" % rvmexec)

            # Fix to rvm users that cannot read the f* manual
            # for this i need to fix their stupid .rvmrc
            if rvmexec.split()[1] == "use":
                rvmexec = rvmexec.split()[2]
            else:
                rvmexec = rvmexec.split()[1]
            
            # I need the output not to log on file
            rvm_cmd = subprocess.Popen('/usr/local/bin/rvm info %s' % rvmexec,
                    shell=True, stdout=subprocess.PIPE)
            rvm_cmd.wait()

            rvm_env = {}
            for line in rvm_cmd.stdout.readlines():
                if 'PATH' in line or 'HOME' in line:
                    name, value = line.split()
                    rvm_env[name.strip(':')] = value.replace('"', '')
            rvm_env['HOME'] = os.environ['HOME']

        if len(rvm_env.keys()) < 1:
            rvm_env = os.environ
        else:
            for param in os.environ.keys():
                if param.find('PROXY') != -1:
                    rvm_env[param] = os.environ[param]

        log.msg(rvm_env)

        if os.path.isfile(os.path.join(self.workdir, 'rpm', "%s.spec" % self.project.name)):            
            self.dos2unix(os.path.join(self.workdir, 'rpm', "%s.spec" % self.project.name))
            template_fd = open(os.path.join(self.workdir, 'rpm', "%s.spec" % self.project.name))
        else:
            template_fd = open(os.path.join(templates_dir, 'project.spec'))

        rendered_template = open(spec_filename, 'w+')
        rendered_template.write(pystache.template.Template(template_fd.read()).render(context=template_data))
        template_fd.close()
        rendered_template.close()

        rendered_template = open(spec_filename, 'a')
        rendered_template.write("* %(date)s %(username)s <%(email)s> - %(version)s-%(release)s\n" % template_data)

        for git_log in self.git.log():
            rendered_template.write('- %s' % git_log)
        rendered_template.close()

        self.project.save()

        rpm_cmd = self._exec([ "rpmbuild", "--define", "_topdir %s" % rpm_dir, "-ba", spec_filename ],
            cwd=self.workdir, env=rvm_env
        )

        rpm_cmd.wait()

    def upload_rpm(self):
        if self.ftp_host:
            rpm_dir = os.path.join(self.workspace, 'rpm')
            rpm_prefix = "%s-%s-%s" % (self.project.name, self.project.version, self.project.release)
            list = []
            for path, dirs, files in os.walk(rpm_dir):
                if os.path.isdir(path):
                    for file in (os.path.join(path, file) for file in files):
                        try:
                            if os.path.isfile(file) and file.find(rpm_prefix) != -1:
                                list.append(file)
                        except Exception, e:
                            log.err(e)

            ftp = ftplib.FTP()
            try:
                ftp.connect(self.ftp_host)
                if self.ftp_user and self.ftp_pass:
                    ftp.login(self.ftp_user, self.ftp_pass)
                else:
                    ftp.login()
                if self.ftp_dir:
                    ftp.cwd(self.ftp_dir)
            except ftplib.error_reply, e:
                log.err('Cannot conect to ftp server %s' % e)

            for file in list:
                filename = os.path.basename(file)
                try:
                    if os.path.isfile(file):
                        f = open(file, 'rb')
                        ftp.storbinary('STOR %s' % filename, f)
                        f.close()
                        log.msg("File %s has been successfully sent to ftp server %s" % (filename, self.ftp_host))
                except ftplib.error_reply, e:
                    log.err(e)

            ftp.quit()

    def deb(self, branch):
        templates = {}
        templates_dir = os.path.join(self.templates_dir, 'deb')
        debian_dir = os.path.join(self.workdir, 'debian')
        control_data_original = None
        control_data_new = None
        
        if self.project.install_prefix is None:
            self.project.install_prefix = 'opt'

        if not self.project.install_cmd :

            self.project.install_cmd = 'cp -r \`ls | grep -v debian\` debian/tmp/%s' % (
                    self.project.install_prefix
                )

        template_data = {
                'name': self.project.name,
                'version': "%s" % (self.project.version),
                'build_cmd': self.project.build_cmd,
                'install_cmd': self.mod_install_cmd,
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
            
            os.makedirs(
                    os.path.join(
                        debian_dir, self.project.name, self.project.install_prefix
                        )
                    )

            for filename, data in templates.iteritems():
                open(os.path.join(debian_dir, filename), 'w').write(data)
        
        changelog_entry = """%(name)s (%(version)s) %(branch)s; urgency=low

  * Latest commits
  %(commits)s

 -- %(username)s <%(email)s>  %(date)s
"""
        changelog_data = {
                'name': self.project.name,
                'version': self.project.version,
                'branch': branch,
                'commits': '  '.join(self.git.log()),
                'username': self.project.username,
                'email': self.project.email,
                'date': time.strftime("%a, %d %h %Y %T %z"),
            }


        if branch in ('stable'):
            """
            if the branch has stable in its name, we should use the version of this tag as a project version
            """
            if self.project.last_tag(branch) != None and self.project.last_tag(branch).startswith(branch):
                self.project.version = self.project.last_tag(branch).split('_')[1]

            changelog_data.update({'version': self.project.version, 'branch': branch})
        else:
            """
            otherwise it should change the package name to something that can differ from the stable version
            like appending -branch to the package name by changing its control file
            """
            control = os.path.join(self.workdir, 'debian', 'control')
            if os.path.isfile(control):
                control_data_original = open(control).read()
                control_data_new = control_data_original.replace(self.project.name, "%s-%s" % (self.project.name, branch))
                open(control, 'w').write(control_data_new)

            changelog_data.update({'name': "%s-%s" % (self.project.name, branch), 'branch': 'testing'})

        open(os.path.join(self.workdir, 'debian', 'changelog'), 'w').write(changelog_entry % changelog_data)
        
        self.project.version = open(os.path.join(self.workdir, 'debian/changelog'), 'r').readline().split('(')[1].split(')')[0]
        self.project.save()
            
        rvm_env = {}
        rvm_rc = os.path.join(self.workdir, '.rvmrc')
        rvm_rc_example = rvm_rc +  ".example"
        has_rvm = False

        if os.path.isfile(rvm_rc):
            has_rvm = True
        elif os.path.isfile(rvm_rc_example):
            has_rvm = True
            rvm_rc = rvm_rc_example
        
        if has_rvm:
            rvmexec = open(rvm_rc).read()
            log.msg("RVMRC: %s" % rvmexec)
            
            # I need the output not to log on file
            rvm_cmd = subprocess.Popen('/usr/local/bin/rvm info %s' % rvmexec.split()[1],
                    shell=True, stdout=subprocess.PIPE)
            rvm_cmd.wait()
            for line in rvm_cmd.stdout.readlines():
                if 'PATH' in line or 'HOME' in line:
                    name, value = line.split()
                    rvm_env[name.strip(':')] = value.strip('"')
            rvm_env['HOME'] = os.environ['HOME']
            log.msg(rvm_env)

        if len(rvm_env.keys()) < 1:
            rvm_env = os.environ
        else:
            try:
                os.environ.pop('GEM_HOME')
                os.environ.pop('BUNDLER_PATH')
            except Exception, e:
                pass
            rvm_env.update(os.environ)

        os.chmod(os.path.join(debian_dir, 'rules'), stat.S_IRWXU|stat.S_IRWXG|stat.S_IROTH|stat.S_IXOTH)
        dpkg_cmd = self._exec(
                ['dpkg-buildpackage',  '-rfakeroot', '-k%s' % BrickConfig().get('gpg', 'keyid')],
                cwd=self.workdir, env=rvm_env
        )
        
        dpkg_cmd.wait()

        control = os.path.join(self.workdir, 'debian', 'control')
        if os.path.isfile(control) and control_data_original:
            open(control, 'w').write(control_data_original)

        clean_cmd = self._exec(['dh', 'clean'], cwd=self.workdir)
        clean_cmd.wait()

    def upload_to(self, branch):
        if branch == 'stable':
            changes_file = glob.glob('%s/%s_%s_*.changes' % (self.workspace, self.project.name, self.project.version))[0]
            upload_cmd = self._exec(['dput', branch, changes_file])
        else:
            changes_file = glob.glob('%s/%s-%s_%s_*.changes' % (self.workspace, self.project.name, branch, self.project.version))[0]
            upload_cmd = self._exec(['dput',  changes_file])
        upload_cmd.wait()

    def promote_to(self, version, release):
        self.project.version = version
        self.project.release = release
        self.project.save()

    def promote_deb(self):
        self.git.create_tag("%s.%s" % (self.project.version, self.project.release))
        dch_cmd = self._exec(['dch', '-r', '--no-force-save-on-release', '--newversion', '%s.%s' % (self.project.version, self.project.release)], cwd=self.workdir)
        dch_cmd.wait()
