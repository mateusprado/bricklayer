RAILS_GEM_VERSION = "2.3.5" unless defined? RAILS_GEM_VERSION

require File.join(File.dirname(__FILE__), "boot")

Rails::Initializer.run do |config|
  config.load_paths += %W( #{RAILS_ROOT}/app/steps #{RAILS_ROOT}/app/consumers #{RAILS_ROOT}/lib)

  config.gem "xenapi-ruby", :version => "0.0.3"
  config.gem "bpmachine", :version => "0.0.3"
  config.gem "stomp", :version => "1.1.5"
  config.gem "net-ssh", :lib => "net/ssh"
  config.gem "mysql"
  config.gem "httparty", :version => ">=0.5"
  config.gem "nokogiri"
  config.gem "chronic", :version => ">=0.2.3", :lib => false
  config.gem "whenever", :lib => false
  config.gem "SyslogLogger", :lib => "syslog_logger"
  config.gem "rrd-ffi", :version => "=0.2.1", :lib => 'rrd'
  config.gem "password_strength"
  config.gem "breadcrumbs"
  config.gem "rubycas-client", :version => ">= 2.1.0", :lib => "casclient"

  config.time_zone = "UTC"
  config.i18n.default_locale = :pt

  config.after_initialize do
    raise "The nephelae configuration isn't up to date. Compare the nephelae.yml files inside the config directory" unless NephelaeConfig.complete?
  end
end
