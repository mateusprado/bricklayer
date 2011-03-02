import os
import sys
import time
import shutil
import re
import ftplib
import tarfile

from projects import Projects
from config import BrickConfig

class RpmBuilder:

    def __init__(self, builder):
        self.builder = builder
        self.project = self.builder.project

    def dos2unix(self, file):
        f = open(file, 'r').readlines()
        new_file = open(file, "w+")
        match = re.compile('\r\n')
        for line in f:
            new_file.write(match.sub('\n', line))
        new_file.close()
        
    def build(self, branch, last_tag=None):
        rpm_dir = os.path.join(builder.workspace, 'rpm')
        templates_dir = os.path.join(builder.templates_dir, 'rpm')
        spec_filename = os.path.join(rpm_dir, 'SPECS', "%s.spec" % self.project.name)
        dir_prefix = "%s-%s" % (self.project.name, self.project.version())

        for dir in ('SOURCES', 'SPECS', 'RPMS', 'SRPMS', 'BUILD', 'TMP'):
            if not os.path.isdir(os.path.join(rpm_dir, dir)):
                os.makedirs(os.path.join(rpm_dir, dir))
        
        build_dir = os.path.join(rpm_dir, 'TMP', self.project.name)
        
        if not os.path.isdir(build_dir):
            os.makedirs(build_dir)

        source_file = os.path.join(rpm_dir, 'SOURCES', '%s.tar.gz' % dir_prefix)

        cur_dir = os.getcwd()
        os.chdir(builder.workspace)

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
                'version': "%s" % (self.project.version()),
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
            log.info("RVMRC: %s" % rvmexec)

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

        log.info(rvm_env)

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

    def upload(self, branch):
        if self.ftp_host:
            rpm_dir = os.path.join(self.workspace, 'rpm')
            rpm_prefix = "%s-%s-%s" % (self.project.name, self.project.version(), self.project.release)
            list = []
            for path, dirs, files in os.walk(rpm_dir):
                if os.path.isdir(path):
                    for file in (os.path.join(path, file) for file in files):
                        try:
                            if os.path.isfile(file) and file.find(rpm_prefix) != -1:
                                list.append(file)
                        except Exception, e:
                            log.error(e)

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
                log.error('Cannot conect to ftp server %s' % e)

            for file in list:
                filename = os.path.basename(file)
                try:
                    if os.path.isfile(file):
                        f = open(file, 'rb')
                        ftp.storbinary('STOR %s' % filename, f)
                        f.close()
                        log.info("File %s has been successfully sent to ftp server %s" % (filename, self.ftp_host))
                except ftplib.error_reply, e:
                    log.error(e)

            ftp.quit()


