require 'net/ssh'

ENV['GEM_HOME'] = "#{Rails.root}/vendor/"

gem_full_path = "#{ENV['GEM_HOME']}"

Gem.instance_variable_get("@gem_path").each do |path|
  gem_full_path << ":#{path}"
end

ENV['GEM_PATH'] = gem_full_path

namespace :deploy do

  desc "Clean vendor gems"
  task :clean_vendor do
    sh %{cd "#{Rails.root}/vendor/" && rm -rf {gems,specifications,cache,doc}}
  end
  
  desc "Build on DDK server"
  task :build_at, :server do |task, args|
    ssh = Net::SSH.start(args[:server], 'root')
    tmp_dir = "/tmp/nephelae"

    ssh.exec! "mkdir /tmp/nephelae"
    ssh.exec! "cd /tmp/nephelae && git clone git://git.locaweb.com.br/nephelae/nephelae.git"
    
    # What a shame, rake gems:install require a database.yml in place
    ssh.exec! "cp /etc/cloud/database.yml /tmp/nephelae/nephelae/config/"

    ssh.exec! "cd /tmp/nephelae/nephelae && rake deploy:clean_vendor && rake deploy:vendorize_full"

    # But the package will not include it
    ssh.exec! "rm /tmp/nephelae/nephelae/config/database.yml"

    ssh.exec! "chmod +x /tmp/nephelae/nephelae/debian/rules"

    # Log and tmp are needed to create the deb packages
    ssh.exec! "mkdir /tmp/nephelae/nephelae/tmp"
    ssh.exec! "mkdir /tmp/nephelae/nephelae/log"
    ssh.exec! "cd /tmp/nephelae/nephelae && rake deploy:debian:create_deb"
  end
  
  desc "Install all deps into vendor dir"
  task :vendorize_full do
    ENV['RAILS_ENV'] = 'test'
    sh %{rake gems:install}
  end

  desc "Install only essencial deps into vendor dir"
  task :vendorize_production do
    ENV['RAILS_ENV'] = 'production'
    sh %{rake gems:install}
  end
  
  namespace :debian do
    desc "Build package for debian based linux"
    task :install do
      files = "README Rakefile app config db lib log public script tmp vendor"
      sh %{mkdir -p debian/nephelae/var/www/nephelae}
      sh %{cp -a #{files} debian/nephelae/var/www/nephelae}
    end

    desc "Create the package itself"
    task :create_deb do
      sh %{dpkg-buildpackage -rfakeroot}
    end

    desc "Install debian package"
    task :install_deb do
      sh %{dpkg -i ../nephelae*.deb}
    end

  end

end
