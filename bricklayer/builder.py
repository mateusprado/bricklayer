import sys
import os
import stat
import subprocess
import time
import glob
import ConfigParser
import tarfile
import shutil

sys.path.append(os.path.join(os.path.dirname(__file__), 'utils'))

import pystache
import git
from config import BrickConfig
from projects import Projects
from twisted.python import log

class Builder:
    def __init__(self, project):
        self.workspace = BrickConfig().get('workspace', 'dir')
        self.project = Projects.get(project)
        self.workdir = os.path.join(self.workspace, self.project.name) 
        self.templates_dir = BrickConfig().get('workspace', 'template_dir')
        self.git = git.Git(self.project)
        self.build_system = BrickConfig().get('build', 'system')
        
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
        import re
        f = open(file, 'r').readlines()
        new_file = open(file, "w+")
        for line in f:
            new_file.write(re.compile('\r\n').sub('\n', line))
        new_file.close()

    def build_project(self, force=False):
        try:
            if force:
                build = 1
            else:
                build = 0
            
            log.msg("Checking project: %s" % self.project.name)
            try:
                if os.path.isdir(self.git.workdir):
                    self.git.pull()
                else:
                    self.git.clone()
            except Exception, e:
                log.err()
                log.err('Could not clone or update repository')
                raise

            if os.path.isdir(self.workdir):
                os.chdir(self.workdir)

            tags = self.git.tags()

            last_commit = self.git.last_commit()
            if len(tags) > 0:
                log.msg('Last tag found: %s' % tags[-1])
                if self.project.last_tag != tags[-1]:
                    self.project.last_tag = tags[-1]
                    self.git.checkout(self.project.last_tag)
                    build = 1

            if self.project.last_tag == None and self.project.last_commit != last_commit:
                self.project.last_commit = last_commit
                build = 1
                
            self.project.save()

            if build == 1:
                log.msg('Generating packages for %s on %s'  % (self.project, self.workdir))
                if self.build_system == 'rpm':
                    self.rpm()
                elif self.build_system == 'deb':
                    self.deb()
                    self.upload_to()
                log.msg("build complete")

            self.git.checkout('master') 
        
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
        
        build_dir = os.path.join(self.workspace, 'rpm', 'TMP')
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

        spec_file_lines = None
        if os.path.isfile(spec_filename):
            spec_file_lines = open(spec_filename).readlines()
            for line in spec_file_lines:
                if line.startswith("Release:"):
                    self.project.release = line.split(":")[1].strip()
            os.unlink(spec_filename)

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
            rvm_cmd = subprocess.Popen('/usr/local/bin/rvm info %s' % rvmexec.split()[2],
                    shell=True, stdout=subprocess.PIPE)
            rvm_cmd.wait()
            for line in rvm_cmd.stdout.readlines():
                if 'PATH' in line or 'HOME' in line:
                    name, value = line.split()
                    log.msg("%s %s" % (name, value))
                    os.environ[name.strip(':')] = value.replace('"', '')

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
                'gem_path': "GEM_PATH=\"%s\"" % os.environ['GEM_PATH'],
                'my_ruby_home': "MY_RUBY_HOME=\"%s\"" % os.environ['MY_RUBY_HOME'],
                'path': "PATH=\"%s\"" % os.environ['PATH'],
                'bundle_path': "BUNDLE_PATH=\"%s\"" % os.environ['BUNDLE_PATH'],
                'gem_home': "GEM_HOME=\"%s\"" % os.environ['GEM_HOME'],
            }

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
            cwd=self.workdir, env=os.environ
        )
        
        rpm_cmd.wait()

    def deb(self):
        templates = {}
        templates_dir = os.path.join(self.templates_dir, 'deb')
        debian_dir = os.path.join(self.workdir, 'debian')
        
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
            
        dch_cmd = self._exec(['dch', '--no-auto-nmu', '-i', '** latest commits'], cwd=self.workdir)
        dch_cmd.wait()
        
        for git_log in self.git.log():
            append_log = self._exec(['dch', '-a', git_log], cwd=self.workdir)
            append_log.wait()
        
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

        clean_cmd = self._exec(['dh', 'clean'], cwd=self.workdir)
        clean_cmd.wait()

    def upload_to(self):
        changes_file = glob.glob('%s/%s_%s_*.changes' % (self.workspace,self.project.name,self.project.version))[0]
        upload_cmd = self._exec(['dput',  changes_file])
        upload_cmd.wait()

    def promote_to(self, release):
        self.project.release = release
        self.project.save()
        self.git.create_tag("%s/%s" % (release, self.project.version))
        dch_cmd = self._exec(['dch', '-r', '--no-force-save-on-release', '-d', release], cwd=self.workdir)
        dch_cmd.wait()
