import sys
import os
import subprocess
import time
import ConfigParser
import shutil
import logging

sys.path.append(os.path.join(os.path.dirname(__file__), 'utils'))
sys.path.append(os.path.dirname(__file__))

import pystache
import git

from twisted.internet import threads
from config import BrickConfig
from projects import Projects

from rpm_builder import RpmBuilder
from deb_builder import DebBuilder

logging.basicConfig(filename='/var/log/bricklayer-builder.log', level=logging.DEBUG)
log = logging.getLogger('builder')

def build_project(kargs):
    project, branch, force = kargs['project'], kargs['branch'], kargs['force']
    logging.basicConfig(filename='/var/log/bricklayer-builder.log', level=logging.DEBUG)
    log = logging.getLogger('builder-worker')
    log.debug("> %s %s %s" % (project, branch, force))

    builder = Builder(project)
    builder.build_project(force, branch)
    defered = threads.deferToThread(builder.build_project, force, branch)


class Builder:
    def __init__(self, project):
        self.workspace = BrickConfig().get('workspace', 'dir')
        self.project = Projects(project)
        self.templates_dir = BrickConfig().get('workspace', 'template_dir')
        self.git = git.Git(self.project)
        self.workdir = self.git.workdir
        self.build_system = BrickConfig().get('build', 'system')
        self.ftp_host = BrickConfig().get('ftp', 'host')
        self.ftp_user = BrickConfig().get('ftp', 'user')
        self.ftp_pass = BrickConfig().get('ftp', 'pass')
        self.ftp_dir = BrickConfig().get('ftp', 'dir')
        
        if self.build_system == 'rpm':
            self.package_builder = RpmBuilder(self)
        elif self.build_system == 'deb':
            self.package_builder = DebBuilder(self)
        
        if self.build_system == 'rpm':
            self.mod_install_cmd = self.project.install_cmd.replace(
                'BUILDROOT', '%{buildroot}'
            )
        elif self.build_system == 'deb' or self.build_system == None:
            self.mod_install_cmd = self.project.install_cmd.replace(
                'BUILDROOT', 'debian/tmp'
            )
        
        if not os.path.isdir(self.workspace):
            os.makedirs(self.workspace)
        
        if not os.path.isdir(os.path.join(self.workspace, 'log')):
            os.makedirs(os.path.join(self.workspace, 'log'))

        self.stdout = None
        self.stderr = self.stdout

    def _exec(self, cmd, *args, **kwargs):
        return subprocess.Popen(cmd, *args, **kwargs)

    def build_project(self, force=False, a_branch=None):
        try:
            if force:
                build = 1
            else:
                build = 0
            
            """
            force build for a specific branch only if a_branch is not None
            """
            if a_branch:
                branches = [a_branch]
            else:
                branches = self.project.branches()

            for branch in branches:
                log.debug("Checking project: %s" % self.project.name)
                try:
                    if not os.path.isdir(self.git.workdir):
                        self.git.clone(branch)
                    else:
                        self.git.checkout_tag(tag=".")
                        self.git.pull()
                except Exception, e:
                    log.exception('Could not clone or update repository')
                    raise

                if os.path.isdir(self.workdir):
                    os.chdir(self.workdir)

                last_commit = self.git.last_commit(branch)

                if self.project.last_commit(branch) != last_commit:
                    self.project.last_commit(branch, last_commit)
                    build = 1
                    
                self.project.save()

                self.oldworkdir = self.workdir
                if not os.path.isdir("%s-%s" % (self.workdir, branch)):
                    shutil.copytree(self.workdir, "%s-%s" % (self.workdir, branch))
                self.workdir = "%s-%s" % (self.workdir, branch)
                self.git.workdir = self.workdir
                self.git.pull() 
                self.git.checkout_branch(branch)

                if build == 1:
                    log.info('Generating packages for %s on %s'  % (self.project, self.workdir))
                    self.package_builder.build(branch)
                    self.package_builder.upload(branch)
                    log.info("build complete")

                self.workdir = self.oldworkdir
                self.git.workdir = self.workdir
            
            self.git.checkout_branch('master')
            
            branch = 'master'
            for tag_type in ('testing', 'stable'):
                log.info('Last tag found: %s' % self.project.last_tag(tag_type))
                if self.project.last_tag(tag_type) != self.git.last_tag(tag_type):
                    self.project.last_tag(tag_type, self.git.last_tag(tag_type))
                    if self.project.last_tag(tag_type):
                        self.git.checkout_tag(self.project.last_tag(tag_type))
                        self.package_builder.build(branch, self.project.last_tag(tag_type))
                        self.package_builder.upload(tag_type)
                    self.git.checkout_branch(branch)

        except Exception, e:
            log.exception("build failed: %s" % repr(e))

